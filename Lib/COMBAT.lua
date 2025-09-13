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
    self.useAoE = false

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
    self._buffsInterval = 300 -- ms

    -- gcd seconds (engine side pacing; bar cooldowns still gate real readiness)
    self.gcd = 1.8

    self.pendingCast = nil
    self.pendingUntil = 600


    -- abilities (keep cd=0; rely on bar cooldowns to avoid bad assumptions)
    self.abilities = {
        ["Touch of Death"] = {
            adrenaline = 9,
            cd = 14400, -- 14.4s cooldown in ms
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                -- Skip if adrenaline already full
                local adren = API.GetAddreline_() or 0
                if adren >= 100 then
                    return 0.0
                end

                -- Get necrosis stacks from tracked buffs
                local nec = engine.buffs.necrosis
                local stacks = (nec and nec.stacks) or 0

                if stacks >= 6 then
                    return 1.0 -- low priority at 6+
                else
                    return 8.0 -- high priority if <6 stacks
                end
            end
        },

        ["Soul Sap"] = { 
            adrenaline = 9, 
            cd = 5400, -- 5.4s cooldown in ms
            lastUsed = -1e12, 
            expectedValue = function(_, engine)
                -- Skip if adrenaline is already capped
                local adren = API.GetAddreline_() or 0
                if adren >= 100 then
                    return 0.0
                end

                -- Check residual souls buff stacks
                local rs = engine.buffs.residualSouls
                local stacks = (rs and rs.stacks) or 0

                if stacks < 3 then
                    return 6.0 
                else
                    return 1.0  
                end
            end 
        },

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
                if stacks >= 6 then
                    return 10.0
                else
                    return 0.5 -- very low priority otherwise
                end
            end
        },

        ["Volley of Souls"] = {
            adrenaline = 0, 
            cd = 0, -- if it has one, add it here in ms
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                local rs = engine.buffs.residualSouls
                local stacks = (rs and rs.stacks) or 0

                if stacks == 3 then
                    return 7.0   
                else
                    return 0.0   
                end
            end
        },

        ["Bloat"] = {
            adrenaline = -20,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                if not engine.useAoE then return 0.0 end
                -- If the target has the "bloated" debuff, deprioritize it
                if engine:targetHasDebuff(engine.enemyDebuffIDs.bloated) then
                    return 0.1 -- very low priority
                else
                    return 9.5 -- strong priority if target is not bloated
                end
            end
        },

        ["Soul Strike"] = { 
            adrenaline = 0,   
            lastUsed = -1e12, 
            expectedValue = function(_, engine)
                -- Don’t cast if target has immune_stun debuff
                if engine:targetHasDebuff(engine.enemyDebuffIDs.immune_stun) then 
                    return 0.0 
                end
                
                -- Only cast when AoE mode is active
                if not engine.useAoE then 
                    return 0.0 
                end

                -- Require at least 1 Residual Souls stack
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
            cd = 60000, -- 60 seconds (ms)
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                -- Must have AoE mode enabled
                if not engine.useAoE then return 0.0 end

                -- Must be at 100% adrenaline
                if API.GetAddreline_() < 100 then return 0.0 end

                -- Respect cooldown
                local t = API.SystemTime()
                local desc = engine.abilities["Death Skulls"]
                if desc and (t - desc.lastUsed < (desc.cd or 0)) then
                    return 0.0
                end

                return 10.0
            end
        },

        ["Living Death"] = {
            adrenaline = -100,
            cd = 90000, -- 1m30s
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                -- Require 100% adrenaline
                if API.GetAddreline_() < 100 then return 0.0 end

                -- Respect Living Death’s own cooldown
                local t = API.SystemTime()
                local desc = engine.abilities["Living Death"]
                if desc and (t - desc.lastUsed < (desc.cd or 0)) then
                    return 0.0
                end

                -- Check if Death Skulls is available
                local ds = engine.abilities["Death Skulls"]
                local dsReady = false
                if ds and engine:isAbilityReady("Death Skulls") then
                    if engine.useAoE then
                        dsReady = true
                    end
                end

                -- Only cast if Death Skulls is NOT ready or AoE disabled
                if dsReady then
                    return 0.0
                end

                return 9.0 -- high priority when eligible
            end,
            onCast = function(engine)
                local t = API.SystemTime()

                -- Reset Death Skulls & Touch of Death immediately
                if engine.abilities["Death Skulls"] then
                    engine.abilities["Death Skulls"].lastUsed = -1e12
                    engine.abilities["Death Skulls"].cd = 12000 -- 12s during LD
                end
                if engine.abilities["Touch of Death"] then
                    engine.abilities["Touch of Death"].lastUsed = -1e12
                end

                -- After 30s, restore Death Skulls’ normal cooldown
                engine:schedule(30000, function()
                    if engine.abilities["Death Skulls"] then
                        engine.abilities["Death Skulls"].cd = 60000 -- back to 1m
                    end
                end)

                API.logDebug("Living Death cast: DS/ToD reset, DS cd reduced to 12s for 30s")
            end
        },

        ["Conjure Skeleton Warrior"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasConjure("skeletonWarrior") and 0.0 or 1.8
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
                return engine:hasConjure("putridZombie") and 0.0 or 1.8
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
                return engine:hasConjure("vengefulGhost") and 0.0 or 1.8
            end
        },

        ["Command Vengeful Ghost"] = {
            adrenaline = 0,
            cd = 15000, -- ms
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                if engine:hasConjure("vengefulGhost") and engine:isAbilityReady("Command Vengeful Ghost") then
                    if engine:targetHasDebuff(engine.enemyDebuffIDs.haunted) then
                        return 1.5 -- can tweak if Haunted debuff is detected on enemy
                    else
                        return 9.0
                    end
                end
                return 0.0
            end
        },

        ["Conjure Phantom Guardian"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasConjure("phantomGuardian") and 0.0 or 1.8
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

        ["Spectral Scythe"] = {
            adrenaline = -10,
            cd = 15000, -- 15s full cooldown
            lastUsed = -1e12,
            stage = 0,       -- 0 = fresh, 1 = after first cast, 2 = after second
            stageExpire = 0, -- timestamp when the chain expires

            expectedValue = function(self, engine)
                if not engine.useAoE then return 0.0 end

                local rs = engine.buffs.residualSouls
                local stacks = (rs and rs.stacks) or 0
                if stacks >= 3 then return 0.0 end

                -- Check if stage window expired
                if nowMs() > self.stageExpire then
                    self.stage = 0
                end

                -- EV by stage
                if self.stage == 0 then
                    return 2.5
                elseif self.stage == 1 then
                    return 3.0
                elseif self.stage == 2 then
                    return 3.5
                end

                return 0.0
            end,

            onCast = function(self, engine)
                local t = nowMs()

                -- If chain expired, reset to stage 0 before advancing
                if t > self.stageExpire then
                    self.stage = 0
                end

                -- Advance stage
                if self.stage < 2 then
                    self.stage = self.stage + 1
                    -- Reset chain expiry window (15s to use next stage)
                    self.stageExpire = t + 15000
                else
                    -- Stage 3 cast -> reset to 0 and trigger full cooldown
                    self.stage = 0
                    self.lastUsed = t
                    self.stageExpire = 0
                end
            end
        },

        ["Conjure Undead Army"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasAnyConjure() and 0.0 or 10.0
            end
        },

        ["Blood Siphon"] = { 
            adrenaline = 0,
            cd = 45000, 
            lastUsed = -1e12, 
            expectedValue = function()
                local hp = API.GetHPrecent() or 100
                if hp > 100 then hp = 100 end
                if hp < 0 then hp = 0 end

                if hp >= 50 then
                    -- Scale linearly from 0.0 at 100% to 10.0 at 50%
                    local ev = (100 - hp) / 5.0
                    return ev
                else
                    -- At or below 50%, force max priority
                    return 10.0
                end
            end 
        },

        ["Death Grasp"] = {
            adrenaline = -25,        -- Costs 25% adrenaline
            cd = 30000,              -- 30 sec cooldown (ms)
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                -- Don’t cast if target has immune_stun debuff
                if engine:targetHasDebuff(engine.enemyDebuffIDs.immune_stun) then
                    return 0.0
                end

                -- Get necrosis stacks from buff data
                local nec = engine.buffs.necrosis
                local stacks = (nec and nec.stacks) or 0

                -- Only valid between 2 and 5 stacks
                if stacks >= 2 and stacks <= 5 then
                    return 9.0 -- strong priority
                elseif stacks >= 6 then
                    return 0.0 -- never cast at 6 or more
                end

                -- Default case (not in range)
                return 0.0
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

---Check if targetInfo has debuff id
---@param number id of enemy debuff
---@return boolean
function CombatEngine:targetHasDebuff(id)
    local tInfo = API.ReadTargetInfo(true)
    if not tInfo or not tInfo.Buff_stack then
        return false
    end
    for _, buffId in ipairs(tInfo.Buff_stack) do
        if buffId == id then
            return true
        end
    end
    return false
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

    -- hard block if any cast is already pending
    local now = nowMs()
    if self.pendingCast and now < self.pendingUntil then
        return
    end

    if not self:isAbilityReady(name) then return end

    if API.DoAction_Ability_Direct(ab, 1, API.OFF_ACT_GeneralInterface_route) then
        local t = nowMs()
        desc.lastUsed = t

        -- set GCD and hold pending through the whole GCD (+ small pad)
        self.lastGcdEnd = t + math.floor(self.gcd * 1000)

        self.pendingCast  = name
        self.pendingUntil = self.lastGcdEnd + 80  -- pad ~80ms past GCD

        API.logInfo("Casting: " .. name)
        if desc.onCast then desc.onCast(self) end
    end
end

function CombatEngine:planAndQueue()
    if not API.IsTargeting() then return end

    -- skip picking a new ability while a cast is pending
    if self.pendingCast and nowMs() < self.pendingUntil then
        return
    end

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

    -- Reset pending if ability shows cooldown now
    if self.pendingCast then
        local ab = self.abilityBars[self.pendingCast]
        if ab and ab.cooldown_timer and ab.cooldown_timer > 0 then
            self.pendingCast = nil
            self.pendingUntil = 0
        elseif nowMs() > self.pendingUntil then
            -- safety reset if too long
            self.pendingCast = nil
            self.pendingUntil = 0
        end
    end

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