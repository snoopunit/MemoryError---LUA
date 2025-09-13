local API = require("api")

local CombatEngine = {}
CombatEngine.__index = CombatEngine

-- ========= Helpers =========

local function parseDuration(text)
    if not text then return 0 end
    local m, s = text:match("(%d+):(%d+)")
    if m and s then return tonumber(m) * 60 + tonumber(s) end
    local n = text:match("(%d+)%s*s")
    if n then return tonumber(n) end
    return 0
end

local function nowMs()
    -- Your logs show millisecond values; treat SystemTime() as ms.
    return API.SystemTime()
end

-- ========= Engine =========

function CombatEngine.new()
    local self = setmetatable({}, CombatEngine)

    -- run-state
    self.running = false
    self.lastGcdEnd = 0
    self.scheduler = {}

    -- targeting
    self.primaryTargetName = nil      -- we keep the name; Interact finds the nearest
    self.scanInterval = 2400          -- ms between acquisition attempts
    self.lastScanTime = 0

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
    self._lastBuffPoll = 0
    self._buffsInterval = 300 -- ms

    -- gcd seconds (engine side pacing; bar cooldowns still gate real readiness)
    self.gcd = 1.8

    -- abilities (keep cd=0; rely on bar cooldowns to avoid bad assumptions)
    self.abilities = {
        ["Necromancy Auto"] = { 
            adrenaline = 0, 
            cd = 0, 
            lastUsed = -1e12, 
            expectedValue = function() return 1.0 end },
        ["Touch of Death"]  = { 
            adrenaline = 9, 
            cd = 0, 
            lastUsed = -1e12, 
            expectedValue = function() return 1.0 end },
        ["Soul Sap"]        = { 
            adrenaline = 9, 
            cd = 0, 
            lastUsed = -1e12, 
            expectedValue = function() return 1.0 end },

        ["Finger of Death"] = {
            adrenaline = -60,
            lastUsed   = -1e12,
            expectedValue = function(selfDesc, engine)
                -- make sure buffs are up to date
                engine:pollBuffsIfNeeded()

                local nec = engine.buffs.necrosis
                if not nec or not nec.found then
                    return 0.0 -- no stacks, don’t use
                end

                local stacks = nec.stacks or 0

                -- Adjust the effective adrenaline cost based on stacks:
                local costReduction = math.min(stacks * 10, 60)
                selfDesc._runtimeAdren = -60 + costReduction

                -- EV calculation: only “worth it” at 6 stacks
                if stacks == 6 then
                    return 10.0
                else
                    return 0.1 -- very low priority otherwise
                end
            end
        },


        ["Volley of Souls"] = {
            adrenaline = 0, lastUsed = -1e12,
            expectedValue = function(_, engine)
                local rs = engine.buffs.residualSouls
                local stacks = (rs and rs.stacks) or 0
                return 1.5 * stacks -- ~150% per stack
            end
        },

        ["Bloat"] =          { adrenaline = -20, lastUsed = -1e12, expectedValue = function() return 6.5 end },
        ["Soul Strike"] =    { adrenaline = 0,   lastUsed = -1e12, expectedValue = function() return 1.5 end },

        ["Death Skulls"] =   { adrenaline = -100,lastUsed = -1e12, expectedValue = function() return 5.0 end },
        ["Living Death"] =   { adrenaline = -100,lastUsed = -1e12, expectedValue = function() return 0   end },

        -- Conjures / Commands (utility EVs kept low or situational)
        ["Conjure Skeleton Warrior"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasConjure("skeletonWarrior") and 0.0 or 8.0
            end
        },
        ["Command Skeleton Warrior"] = {
            adrenaline = 0,
            cd = 15000,  -- cooldown in ms (15s)
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                if engine:hasConjure("skeletonWarrior") and engine:isAbilityReady("Command Skeleton Warrior") then
                    return 8.5
                end
                return 0.0
            end
        },


        ["Conjure Putrid Zombie"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasConjure("putridZombie") and 0.0 or 8.0
            end
        },
        ["Command Putrid Zombie"] = {
            adrenaline = 0,
            cd = 15000, -- ms
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                if engine:hasConjure("putridZombie") and engine:isAbilityReady("Command Putrid Zombie") then
                    return 3.5
                end
                return 0.0
            end
        },

        ["Conjure Vengeful Ghost"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasConjure("vengefulGhost") and 0.0 or 8.0
            end
        },
        ["Command Vengeful Ghost"] = {
            adrenaline = 0,
            cd = 15000, -- ms
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                if engine:hasConjure("vengefulGhost") and engine:isAbilityReady("Command Vengeful Ghost") then
                    return 9.0 -- can tweak if Haunted debuff is detected on enemy
                end
                return 0.0
            end
        },

        ["Conjure Phantom Guardian"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasConjure("phantomGuardian") and 0.0 or 8.0
            end
        },
        ["Command Phantom Guardian"] = {
            adrenaline = 0,
            cd = 15000, -- ms
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                if engine:hasConjure("phantomGuardian") and engine:isAbilityReady("Command Phantom Guardian") then
                    return 3.0
                end
                return 0.0
            end
        },

        -- Spectral Scythe stages (rough EVs)
        ["Spectral Scythe (Stage 1)"] = { adrenaline = -10, lastUsed=-1e12, expectedValue=function() return 0.8 end },
        ["Spectral Scythe (Stage 2)"] = { adrenaline = -20, lastUsed=-1e12, expectedValue=function() return 2.0 end },
        ["Spectral Scythe (Stage 3)"] = { adrenaline = -30, lastUsed=-1e12, expectedValue=function() return 2.5 end },

        ["Conjure Undead Army"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasAnyConjure() and 0.0 or 10.0
            end
        },
        ["Blood Siphon"]              = { 
            adrenaline = 0, 
            lastUsed=-1e12, 
            expectedValue=function()
                local hp = API.GetHPrecent() or 100
                -- Clamp to 0–100 just in case API gives weird values
                if hp > 100 then hp = 100 end
                if hp < 0 then hp = 0 end
                return (100 - hp) / 10
            end 
        },
    }

    -- cache ability-bar entries once
    self.abilityBars = {}
    for name, _ in pairs(self.abilities) do
        self.abilityBars[name] = API.GetABs_name(name, true)
    end

    return self
end

-- ======== Buffs ========

function CombatEngine:parseBbar(bbar)
    if not bbar or not bbar.found then
        return { found=false, stacks=0, raw=nil, duration=0 }
    end
    local raw = bbar.text or ""
    -- conv_text is unreliable; stacks often displayed in text, but we’ll keep stacks=0 default.
    local duration = parseDuration(raw)
    return { found=true, stacks=0, raw=raw, duration=duration }
end

function CombatEngine:pollBuffsIfNeeded()
    local t = nowMs()
    if t - self._lastBuffPoll < self._buffsInterval then return end
    self._lastBuffPoll = t

    for name, id in pairs(self.trackedBuffIDs) do
        local b = API.Buffbar_GetIDstatus(id, false)
        self.buffs[name] = self:parseBbar(b)
    end

    -- Heuristic: infer stacks from raw text if present like "x3" / "3 stacks"
    local function inferStacks(entry)
        if not entry or not entry.raw then return end
        local n = entry.raw:match("x%s*(%d+)") or entry.raw:match("(%d+)%s*st") or entry.raw:match("(%d+)")
        if n then entry.stacks = tonumber(n) or entry.stacks end
    end
    inferStacks(self.buffs.necrosis)
    inferStacks(self.buffs.residualSouls)
end

--- Check if any conjure buff is active
--- @return boolean
function CombatEngine:hasAnyConjure()
    return (self.buffs.skeletonWarrior and self.buffs.skeletonWarrior.found)
        or (self.buffs.vengefulGhost and self.buffs.vengefulGhost.found)
        or (self.buffs.putridZombie and self.buffs.putridZombie.found)
        or (self.buffs.phantomGuardian and self.buffs.phantomGuardian.found)
end

--- Check if a specific conjure is active
--- @param name string One of: "skeletonWarrior","vengefulGhost","putridZombie","phantomGuardian"
--- @return boolean
function CombatEngine:hasConjure(name)
    local b = self.buffs[name]
    return b and b.found or false
end

-- ======== Scheduler ========

function CombatEngine:schedule(delayMs, job)
    table.insert(self.scheduler, { time = nowMs() + (delayMs or 0), job = job })
end

function CombatEngine:processScheduler()
    local t = nowMs()
    for i = #self.scheduler, 1, -1 do
        local item = self.scheduler[i]
        if t >= item.time then
            local ok, err = pcall(item.job)
            -- (optional) log err
            table.remove(self.scheduler, i)
        end
    end
end

-- ======== Targeting (scheduled) ========

function CombatEngine:acquireTargetIfNeeded()
    if API.IsTargeting() then return end

    local startTime = nowMs()
    local closestNPC
    local closestDist = 9999
    local chosenName

    -- priorityList is a map { ["Name"] = weight }
    -- we’ll sort names by weight first
    local prios = {}
    for name, weight in pairs(self.priorityList) do
        table.insert(prios, { name = name, weight = weight })
    end
    table.sort(prios, function(a, b) return a.weight < b.weight end)

    -- check each name in priority order
    for _, entry in ipairs(prios) do
        local npcs = API.ReadAllObjectsArray({1}, {-1}, {entry.name})
        if npcs and #npcs > 0 then
            for _, npc in ipairs(npcs) do
                if npc.Life and npc.Life > 0 then
                    local d = npc.Distance or 999
                    if d < closestDist then
                        closestNPC = npc
                        closestDist = d
                        chosenName = entry.name
                    end
                end
            end
        end
        if closestNPC then
            break -- ✅ stop after first priority with a living NPC
        end
    end

    -- try to attack
    if closestNPC then

        local ok = API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, closestNPC)
        local elapsed = nowMs() - startTime
        if ok then
            API.logDebug("Engaging: " .. chosenName .. " took " .. elapsed .. "ms")
            self.primaryTargetName = chosenName
        else
            API.logDebug("Attack failed on: " .. chosenName .. " | time " .. elapsed .. "ms")
        end
    end
end




-- ======== Ability Casting ========

function CombatEngine:isAbilityReady(name)
    local ab = self.abilityBars[name]
    local desc = self.abilities[name]
    if not ab or not desc then return false end
    if not ab.enabled then return false end

    -- Check client-side cooldown timer
    if ab.cooldown_timer and ab.cooldown_timer > 0 then return false end

    -- Check engine’s own cooldown tracker
    local t = nowMs()
    if t - desc.lastUsed < (desc.cd or 0) then return false end

    -- Check global cooldown
    if t < self.lastGcdEnd then return false end

    return true
end


function CombatEngine:castAbility(name)
    local ab = self.abilityBars[name]
    local desc = self.abilities[name]
    if not ab or not desc then return end
    if not self:isAbilityReady(name) then return end

    if API.DoAction_Ability_Direct(ab, 1, API.OFF_ACT_GeneralInterface_route) then
        local t = nowMs()
        desc.lastUsed = t
        self.lastGcdEnd = t + math.floor(self.gcd * 1000)
        API.logInfo("Casting: "..name)
    end
end

function CombatEngine:planAndQueue()
    if not API.IsTargeting() then return end

    local bestName, bestScore = nil, -math.huge
    for name, desc in pairs(self.abilities) do
        if self:isAbilityReady(name) then
            local score = (desc.expectedValue and desc.expectedValue(desc, self, nil)) or 0
            if score > bestScore then
                bestScore = score
                bestName = name
            end
        end
    end

    if bestName then
        self:schedule(0, function() self:castAbility(bestName) end)
    end
end

-- ======== Update Loop ========

function CombatEngine:update()
    if not self.running then return end

    local t0 = nowMs()

    -- Buff polling
    local t1 = nowMs()
    self:pollBuffsIfNeeded()
    API.logDebug("Buff poll took " .. (nowMs()-t1) .. "ms")

    -- Ability planning
    t1 = nowMs()
    if API.IsTargeting() then
        self:planAndQueue()
        API.logDebug("PlanAndQueue took " .. (nowMs()-t1) .. "ms")
    else
        self:acquireTargetIfNeeded()
    end
    

    -- Run scheduled jobs (casts, delayed stuff)
    t1 = nowMs()
    self:processScheduler()
    API.logDebug("Scheduler took " .. (nowMs()-t1) .. "ms")

    API.logDebug("Engine update total " .. (nowMs()-t0) .. "ms")
end


function CombatEngine:start()
    if self.running then return end
    self.running = true

    -- Main combat update (abilities, buffs, scheduler)
    TickEvent.Register(function() self:update() end)


    API.logDebug("Combat engine started")
end


function CombatEngine:stop()
    self.running = false
    -- (optional) API.logDebug("Combat engine stopped")
end

return CombatEngine