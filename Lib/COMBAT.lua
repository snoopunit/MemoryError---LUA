local API = require("api")

local CombatEngine = {}
CombatEngine.__index = CombatEngine

-- ========= Helpers =========

local function parseDuration(text)
    if type(text) ~= "string" then return 0 end
    local m, s = text:match("(%d+):(%d+)")
    if m and s then
        local mm = tonumber(m) or 0
        local ss = tonumber(s) or 0
        return mm * 60 + ss
    end
    local n = text:match("(%d+)%s*s")
    if n then return tonumber(n) or 0 end
    return 0
end

local function nowMs()
    -- Your logs show millisecond values; treat SystemTime() as ms.
    local ok, t = pcall(API.SystemTime)
    if ok and type(t) == "number" then return t end
    return 0
end

local function isTable(x) return type(x) == "table" end
local function safeStr(x) return type(x) == "string" and x or "" end
local function safeNumber(x) return type(x) == "number" and x or 0 end

local function safeCall(label, fn)
    local ok, res = xpcall(fn, function(e)
        local msg = "[" .. (label or "safe") .. "] " .. tostring(e)
        return msg
    end)
    if not ok then
        API.logWarn(res)
        return nil, res
    end
    return res, nil
end

-- ========= Engine =========

function CombatEngine.new()
    local self = setmetatable({}, CombatEngine)

    -- run-state
    self.running = false
    self.lastGcdEnd = 0
    self.scheduler = {}
    self.startTime = nowMs()
    self.kills = 0

    -- targeting
    self.primaryTargetName = nil      -- we keep the name; Interact finds the nearest
    self.scanInterval = 2400          -- ms between acquisition attempts
    self.lastScanTime = 0
    self.useAoE = true
    self.isFirstTarget = true

    -- priorities: lower number = higher priority
    self.priorityList = {
        -- fill per-encounter, e.g. ["Dangerous Add"]=1, ["Boss"]=2
    }

    -- buffs (player)
    self.buffs = {}
    self.trackedBuffIDs = {
        necrosis        = 30101,
        residualSouls   = 30123,
        skeletonWarrior = 34177,
        vengefulGhost   = 34178,
        putridZombie    = 34179,
        phantomGuardian = 34180,
    }
    self.enemyDebuffIDs = {
        immune_poison = 30094,
        immune_stun = 26104,
        haunted = 30212,
        bloated = 30098
    }
    self._lastBuffPoll = 0
    self._buffsInterval = 750 -- ms (raised from 300ms for stability)

    -- gcd seconds (engine side pacing; bar cooldowns still gate real readiness)
    self.gcd = 1.8

    self.pendingCast = false
    self.pendingUntil = 600
    self._priosSorted = false
    self._targetSettledAt = 0
    self._settleDelayMs = 120

    -- feature flags
    self.enableDebuffReads = true       -- flip to false if target debuff reads are unstable
    self.enableTargetScan  = true

    -- abilities (keep cd=0; rely on bar cooldowns to avoid bad assumptions)
    self.abilities = {

        ["Finger of Death"] = {
            adrenaline = -60,
            lastUsed   = -1e12,
            expectedValue = function(engine)
                local nec = engine.buffs.necrosis
                local stacks = (nec and nec.stacks) or 0
                if stacks >= 6 then
                    return 10.0
                else
                    return 0.0
                end
            end
        },

        ["Volley of Souls"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(engine)
                local rs = engine.buffs.residualSouls
                local stacks = (rs and rs.stacks) or 0
                if stacks == 3 then
                    return 9.0
                else
                    return 0.0
                end
            end
        },

        ["Bloat"] = {
            adrenaline = -20,
            cd = 60000,
            lastUsed = -1e12,
            expectedValue = function(engine)
                if not engine.useAoE then return 0.0 end
                if engine:targetHasDebuff(engine.enemyDebuffIDs.bloated) then
                    return 0.0
                else
                    return 9.5
                end
            end
        },

        ["Soul Strike"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(engine)
                if engine:targetHasDebuff(engine.enemyDebuffIDs.immune_stun) then
                    return 0.0
                end
                if not engine.useAoE then
                    return 0.0
                end
                local rs = engine.buffs.residualSouls
                local stacks = (rs and rs.stacks) or 0
                if stacks < 1 then
                    return 0.0
                end
                return 2.5
            end
        },

        ["Death Skulls"] = {
            adrenaline = -100,
            cd = 60000,
            lastUsed = -1e12,
            expectedValue = function(engine)
                if not engine.useAoE then return 0.0 end
                local ok, ad = pcall(API.GetAddreline_)
                if not ok or safeNumber(ad) < 100 then return 0.0 end

                local t = nowMs()
                local desc = engine.abilities["Death Skulls"]
                if desc and (t - desc.lastUsed < (desc.cd or 0)) then
                    return 0.0
                end
                return 10.0
            end
        },

        ["Living Death"] = {
            adrenaline = -100,
            cd = 90000,
            lastUsed = -1e12,
            expectedValue = function(engine)
                local ok, ad = pcall(API.GetAddreline_)
                if not ok or safeNumber(ad) < 100 then return 0.0 end

                local t = nowMs()
                local desc = engine.abilities["Living Death"]
                if desc and (t - desc.lastUsed < (desc.cd or 0)) then
                    return 0.0
                end
                if engine:isAbilityReady("Death Skulls") and engine.useAoE then
                    return 0.0
                end
                return 9.0
            end,
            onCast = function(engine)
                local t = nowMs()
                if engine.abilities["Death Skulls"] then
                    engine.abilities["Death Skulls"].lastUsed = -1e12
                    engine.abilities["Death Skulls"].cd = 12000
                end
                if engine.abilities["Touch of Death"] then
                    engine.abilities["Touch of Death"].lastUsed = -1e12
                end
                engine:schedule(30000, function()
                    if engine.abilities["Death Skulls"] then
                        engine.abilities["Death Skulls"].cd = 60000
                    end
                end)
                API.logDebug("Living Death cast: DS/ToD reset, DS cd reduced to 12s for 30s")
            end
        },

        ["Command Skeleton Warrior"] = {
            adrenaline = 0,
            cd = 15000,
            lastUsed = -1e12,
            expectedValue = function(engine)
                if engine:hasConjure("skeletonWarrior") and engine:isAbilityReady("Command Skeleton Warrior") then
                    return 3.5
                end
                return 0.0
            end
        },

        ["Command Vengeful Ghost"] = {
            adrenaline = 0,
            cd = 15000,
            lastUsed = -1e12,
            expectedValue = function(engine)
                if engine:hasConjure("vengefulGhost") and engine:isAbilityReady("Command Vengeful Ghost") then
                    if engine:targetHasDebuff(engine.enemyDebuffIDs.haunted) then return 0.0 else return 4.0 end
                end
                return 0.0
            end
        },

        ["Spectral Scythe"] = {
            adrenaline = -10,
            cd = 15000,
            lastUsed = -1e12,
            stage = 0,
            stageExpire = 0,

            expectedValue = function(engine)
                local desc = engine.abilities["Spectral Scythe"]
                if not engine.useAoE then return 0.0 end

                local rs = engine.buffs.residualSouls
                local stacks = (rs and rs.stacks) or 0
                if stacks >= 3 then return 0.0 end

                if nowMs() > (desc.stageExpire or 0) then
                    desc.stage = 0
                end

                if desc.stage == 0 then
                    return 2.5
                elseif desc.stage == 1 then
                    return 3.0
                elseif desc.stage == 2 then
                    return 3.5
                end
                return 0.0
            end,

            onCast = function(engine)
                local desc = engine.abilities["Spectral Scythe"]
                local t = nowMs()
                if t > (desc.stageExpire or 0) then
                    desc.stage = 0
                end
                if desc.stage < 2 then
                    desc.stage = desc.stage + 1
                    desc.stageExpire = t + 15000
                else
                    desc.stage = 0
                    desc.lastUsed = t
                    desc.stageExpire = 0
                end
            end
        },

        ["Conjure Undead Army"] = {
            adrenaline = 0,
            cd = 60000,
            lastUsed = -1e12,
            expectedValue = function(engine)
                if engine:isSkillQueued("Conjure Undead Army") then return 0.0 end
                if engine:hasAnyConjure() then return 0.0 else return 11.0 end
            end
        },

        ["Blood Siphon"] = {
            adrenaline = 0,
            cd = 45000,
            lastUsed = -1e12,
            expectedValue = function(engine)
                local ok, hp = pcall(API.GetHPrecent)
                hp = safeNumber(hp)
                if hp >= 70 then
                    return 0.0
                else
                    return 7.5
                end
            end,
            onCast = function(self, engine)
                local t = nowMs()
                engine.pendingCast  = "Blood Siphon"
                engine.pendingUntil = t + 6000
                API.logDebug("[Blood Siphon] Channeling for 6000ms")
            end
        },

        ["Death Grasp"] = {
            adrenaline = -25,
            cd = 30000,
            lastUsed = -1e12,
            expectedValue = function(engine)
                if engine:targetHasDebuff(engine.enemyDebuffIDs.immune_stun) then
                    return 0.0
                end
                local nec = engine.buffs.necrosis
                local stacks = (nec and nec.stacks) or 0
                if stacks >= 2 and stacks <= 5 then
                    return 9.0
                elseif stacks >= 6 then
                    return 0.0
                end
                return 0.0
            end
        },

        ["Eat Food"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(engine)
                local ok, hp = pcall(API.GetHPrecent)
                hp = safeNumber(hp)
                if hp >= 40 then
                    return 0.0
                else
                    return 11.0
                end
            end
        },

    }

    -- cache ability-bar entries once (guarded)
    self.abilityBars = {}
    for name, _ in pairs(self.abilities) do
        local ok, ab = pcall(function() return API.GetABs_name(name, true) end)
        if ok and isTable(ab) then
            self.abilityBars[name] = ab
        else
            self.abilityBars[name] = nil
        end
    end

    return self
end

function CombatEngine:KillsPerHour()
    local elapsed = nowMs() - self.startTime
    if elapsed <= 0 then return 0 end
    return math.floor((self.kills*60)/((elapsed)/60000))
end

-- call this whenever you change priorityList externally
function CombatEngine:_rebuildPriosIfNeeded()
    if self._priosSorted and type(self._priosSorted) == "table" then return end
    local prios = {}
    for name, weight in pairs(self.priorityList) do
        prios[#prios+1] = { name = name, weight = weight }
    end
    table.sort(prios, function(a,b) return a.weight < b.weight end)
    self._priosSorted = prios
end

-- ======== Queued Ability Helpers ========
-- Credits to DEAD.UTILS

function CombatEngine:findBarWithQueuedSkill()
    local ok, state = pcall(function() return API.VB_FindPSettinOrder(5861, 0).state end)
    if not ok or type(state) ~= "number" then return nil end
    if state == 0 then return nil end
    if state == 1003 then return 0 end
    if state == 1032 then return 1 end
    if state == 1033 then return 2 end
    if state == 1034 then return 3 end
    if state == 1035 then return 4 end
    return nil
end

function CombatEngine:isAbilityQueued()
    local ok, state = pcall(function() return API.VB_FindPSettinOrder(5861, 0).state end)
    return ok and type(state) == "number" and state ~= 0
end

function CombatEngine:getSlotOfQueuedSkill()
    local ok, slot = pcall(function() return API.VB_FindPSettinOrder(4164, 0).state end)
    if ok and type(slot) == "number" then return slot end
    return 0
end

function CombatEngine:isSkillQueued(skill)
    if type(skill) ~= "string" then return false end
    if not self:isAbilityQueued() then return false end
    local barNumber = self:findBarWithQueuedSkill()
    if barNumber == nil then return false end
    local ok, skillbar = pcall(function() return API.GetAB_name(barNumber, skill) end)
    if not ok or not isTable(skillbar) then return false end
    local slot = self:getSlotOfQueuedSkill()
    if slot == 0 then return false end
    return skillbar.slot == slot
end

-- ======== Buffs ========

local function isBbar(x)
    if not x then return false end
    local t = type(x)
    if t ~= "table" and t ~= "userdata" then return false end
    -- must have the expected fields
    return (type(x.found) == "boolean")
end

function CombatEngine:parseBbar(bbar)
    if not bbar or not bbar.found then
        return { found=false, stacks=0, raw=nil, duration=0 }
    end
    local raw = (type(bbar.text) == "string") and bbar.text or ""
    local duration = parseDuration(raw)
    return { found=true, stacks=0, raw=raw, duration=duration }
end

function CombatEngine:refreshBuffs(force)
    local t = nowMs()
    if not force and (t - self._lastBuffPoll < self._buffsInterval) then
        return
    end
    self._lastBuffPoll = t

    for name, id in pairs(self.trackedBuffIDs) do
        local ok, b = pcall(function()
            return API.Buffbar_GetIDstatus(id, false)
        end)
        if ok and isBbar(b) then
            self.buffs[name] = self:parseBbar(b)
        else
            -- Only warn once per id to avoid log spam
            self._buffWarned = self._buffWarned or {}
            if not self._buffWarned[id] then
                API.logWarn("[Buffs] Invalid buff data for id " .. tostring(id) .. " (" .. tostring(name) .. ")")
                self._buffWarned[id] = true
            end
            self.buffs[name] = { found=false, stacks=0, raw=nil, duration=0 }
        end
    end

    -- heuristic stack parse
    local function inferStacks(entry)
        if not entry or type(entry.raw) ~= "string" then return end
        local n = entry.raw:match("x%s*(%d+)") or entry.raw:match("(%d+)%s*st") or entry.raw:match("(%d+)")
        if n then entry.stacks = tonumber(n) or entry.stacks end
    end
    inferStacks(self.buffs.necrosis)
    inferStacks(self.buffs.residualSouls)
end

function CombatEngine:pollBuffsIfNeeded()
    self:refreshBuffs(false)
end

function CombatEngine:hasAnyConjure()
    self:refreshBuffs(true)
    return (self.buffs.skeletonWarrior and self.buffs.skeletonWarrior.found)
        or (self.buffs.vengefulGhost and self.buffs.vengefulGhost.found)
        or (self.buffs.putridZombie and self.buffs.putridZombie.found)
        or (self.buffs.phantomGuardian and self.buffs.phantomGuardian.found)
end

function CombatEngine:hasConjure(name)
    if type(name) ~= "string" then return false end
    self:refreshBuffs(true)
    local b = self.buffs[name]
    return b and b.found or false
end

function CombatEngine:targetHasDebuff(id)
    if not self.enableDebuffReads then return false end
    if type(id) ~= "number" then return false end

    local ok, tInfo = pcall(function() return API.ReadTargetInfo(true) end)
    if not ok or not isTable(tInfo) then
        return false
    end
    local stack = tInfo.Buff_stack
    if not isTable(stack) then
        return false
    end
    -- iterate defensively
    for i = 1, #stack do
        local buffId = stack[i]
        if type(buffId) == "number" and buffId == id then
            return true
        end
    end
    return false
end

-- ======== Scheduler ========

function CombatEngine:schedule(delayMs, job)
    if type(job) ~= "function" then return end
    table.insert(self.scheduler, { time = nowMs() + (delayMs or 0), job = job })
end

function CombatEngine:processScheduler()
    local t = nowMs()
    for i = #self.scheduler, 1, -1 do
        local item = self.scheduler[i]
        if t >= item.time then
            local ok, err = pcall(item.job)
            if not ok then
                API.logWarn("[Scheduler] job error: " .. tostring(err))
            end
            table.remove(self.scheduler, i)
        end
    end
end

-- ======== Targeting (scheduled) ========

function CombatEngine:acquireTargetIfNeeded()
    if not self.enableTargetScan then return end
    local okTargeting, targeting = pcall(API.IsTargeting)
    if okTargeting and targeting then return end

    local t = nowMs()
    if t - (self.lastScanTime or 0) < (self.scanInterval or 2000) then
        return
    end
    if t < (self._targetSettledAt or 0) then
        return
    end

    self.lastScanTime = t

    local bestNpc, bestName, bestDist = nil, nil, 1e9

    if not self._priosSorted or type(self._priosSorted) ~= "table" then
        self:_rebuildPriosIfNeeded()
    end

    for _, entry in ipairs(self._priosSorted or {}) do
        local ok, npcs = pcall(function()
            return API.ReadAllObjectsArray({1}, {-1}, {entry.name})
        end)
        if ok and isTable(npcs) and #npcs > 0 then
            local count = math.min(#npcs, 50)
            for i = 1, count do
                local npc = npcs[i]
                if isTable(npc) and safeNumber(npc.Life) > 0 then
                    local d = safeNumber(npc.Distance)
                    if d == 0 then d = 999 end
                    if d < 30 and d < bestDist then
                        bestNpc, bestName, bestDist = npc, entry.name, d
                        if d < 6 then break end
                    end
                end
            end
            if bestNpc then break end
        end
    end

    if not bestNpc then
        return
    end

    local attackedOk, attacked = pcall(function()
        return API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, bestNpc)
    end)

    if attackedOk and attacked then
        API.logDebug(("Engaging: %s @%.1fm"):format(tostring(bestName), safeNumber(bestDist)))
        self.primaryTargetName = bestName
        if self.isFirstTarget then
            self.isFirstTarget = false
        else
            self.kills = self.kills + 1
        end
        self._targetSettledAt = nowMs() + self._settleDelayMs
    elseif not attackedOk then
        API.logWarn("[Targeting ERROR] C++ crash during targeting of: " .. tostring(bestName))
    end
end

-- ======== Ability Casting ========

function CombatEngine:getAbilityBar(name)
    if not name or type(name) ~= "string" then
        API.logWarn("[getAbilityBar] Invalid ability name: " .. tostring(name))
        return nil
    end

    local ok, ab = pcall(function()
        return API.GetABs_name(name, true)
    end)

    if not ok or not isTable(ab) then
        API.logWarn("[getAbilityBar] Failed to fetch ability bar for: " .. tostring(name))
        return nil
    end

    -- Normalize fields we rely on
    if type(ab.enabled) ~= "boolean" then ab.enabled = true end
    if type(ab.cooldown_timer) ~= "number" then ab.cooldown_timer = 0 end

    self.abilityBars[name] = ab
    return ab
end

function CombatEngine:isAbilityReady(name)
    local ab   = self:getAbilityBar(name)
    local desc = self.abilities[name]
    if not ab or not desc then return false end
    if ab.enabled == false then return false end
    if ab.cooldown_timer and ab.cooldown_timer > 0 then return false end
    local t = nowMs()
    if t - (desc.lastUsed or 0) < (desc.cd or 0) then return false end
    if t < (self.lastGcdEnd or 0) then return false end
    return true
end

function CombatEngine:castAbility(name)
    if not name then
        API.logWarn("[castAbility] Ability name is nil")
        return
    end

    local ab = self:getAbilityBar(name)
    local desc = self.abilities[name]

    if not ab or not desc then
        API.logWarn("[castAbility] Missing data for ability: " .. tostring(name))
        return
    end

    if self:isSkillQueued(name) then
        API.logDebug("[castAbility] Skipping " .. name .. " (already queued)")
        return
    end

    local t = nowMs()
    if self.pendingCast == name and t < (self.pendingUntil or 0) then
        API.logDebug("[castAbility] Skipping " .. name .. " (pending)")
        return
    end

    if not self:isAbilityReady(name) then
        API.logDebug("[castAbility] Skipping " .. name .. " (not ready)")
        return
    end

    local success, result = pcall(function()
        return API.DoAction_Ability_Direct(ab, 1, API.OFF_ACT_GeneralInterface_route)
    end)

    if not success then
        API.logWarn("[castAbility] C++ crash in DoAction for: " .. name)
        return
    end

    if result then
        self.pendingCast = name
        self.pendingUntil = t + 600
        desc.lastUsed = t
        self.lastGcdEnd = t + math.floor(self.gcd * 1000)

        API.logInfo("Casting: " .. name)
        if desc.onCast then
            local ok, err = pcall(function()
                desc.onCast(self)
            end)
            if not ok then
                API.logWarn("[castAbility] onCast error for " .. name .. ": " .. tostring(err))
            end
        end
    else
        API.logDebug("[castAbility] DoAction failed for: " .. name)
    end
end

function CombatEngine:planAndQueue()
    local okTargeting, targeting = pcall(API.IsTargeting)
    if not (okTargeting and targeting) then return end
    if self.pendingCast and nowMs() < (self.pendingUntil or 0) then return end

    local bestName, bestScore = nil, -math.huge

    for name, desc in pairs(self.abilities) do
        local ab = self:getAbilityBar(name)
        if ab then
            local ready = self:isAbilityReady(name)
            if ready then
                local score = 0
                if desc.expectedValue then
                    local ok, val = pcall(desc.expectedValue, self)
                    if ok and type(val) == "number" then score = val end
                end
                if score > bestScore then bestScore, bestName = score, name end
            end
        end
    end

    if bestName and bestScore > 0 then
        self:schedule(0, function() self:castAbility(bestName) end)
    end
end

-- ======== Update Loop ========

function CombatEngine:update()
    if not self.running then return end

    -- Reset pending if ability shows cooldown now
    if self.pendingCast then
        local ab = self.abilityBars[self.pendingCast]
        if isTable(ab) and type(ab.cooldown_timer) == "number" and ab.cooldown_timer > 0 then
            self.pendingCast = nil
            self.pendingUntil = 0
        elseif nowMs() > (self.pendingUntil or 0) then
            self.pendingCast = nil
            self.pendingUntil = 0
        end
    end

    -- Buff polling (guarded)
    local ok = pcall(function() self:pollBuffsIfNeeded() end)
    if not ok then
        API.logWarn("[update] pollBuffs error")
        return
    end

    -- Either cast or target
    if (pcall(API.IsTargeting)) then
        local ok2 = pcall(function() self:planAndQueue() end)
        if not ok2 then
            API.logWarn("[update] Ability error")
            return
        end
    else
        local ok3 = pcall(function() self:acquireTargetIfNeeded() end)
        if not ok3 then
            API.logWarn("[update] Targeting error")
            return
        end
    end

    -- Scheduled jobs
    local ok4 = pcall(function() self:processScheduler() end)
    if not ok4 then
        API.logWarn("[update] Scheduler error")
        return
    end
end

function CombatEngine:start()
    if self.running then return end
    self.running = true

    local function safeUpdate()
        local ok, err = xpcall(function()
            self:update()
        end, function(e)
            local msg = "[ENGINE CRASH] (" .. type(e) .. ") "
            if type(e) == "userdata" then
                local s = tostring(e)
                if s:find("AllObject") then
                    msg = msg .. "[AllObject?] " .. s
                else
                    msg = msg .. s
                end
            elseif type(e) == "string" then
                msg = msg .. e
            else
                msg = msg .. "Unknown error"
            end
            return msg
        end)

        if not ok then
            API.logWarn(err)
            self.running = false
        end
    end

    TickEvent.Register(safeUpdate)
end

function CombatEngine:stop()
    self.running = false
end

return CombatEngine
