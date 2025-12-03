local API = require("api")

local CombatEngine = {}
CombatEngine.__index = CombatEngine

-- ========= Helpers =========
-- Safely stringify error objects for logging
local function safeErr(e)
    if type(e) == "string" then
        return e
    elseif type(e) == "table" and e.message then
        return tostring(e.message)
    else
        return tostring(e)
    end
end

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

local function areWefighting()
    return API.IsTargeting() and API.CheckAnim(25)
end

-- ========= Engine =========

function CombatEngine.new()
    local self = setmetatable({}, CombatEngine)

    -- run-state
    self.running = false
    self.lastGcdEnd = 0
    self.scheduler = {}
    self.startTime = API.SystemTime()
    self.kills = 0
    self.lastTTKStart = nil
    self.lastTTK = nil
    self.ttkHistory = {}

    -- targeting
    self.primaryTargetName = nil      -- we keep the name; Interact finds the nearest
    self.isFirstTarget = true         -- for kill counting
    self.scanInterval = 1800          -- ms between acquisition attempts
    self.lastScanTime = 0
    self.useAoE = true

    -- priorities: lower number = higher priority
    self.priorityList = {
        -- fill per-encounter, e.g. ["Dangerous Add"]=1, ["Boss"]=2
    }

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

    -- gcd seconds (engine side pacing; bar cooldowns still gate real readiness)
    self.gcd = 1.8

    self.pendingCast = false
    self.pendingUntil = 600
    self._priosSorted = false
    self._targetSettledAt = 0
    self._settleDelayMs = 120
    self._postTargetSleepUntil = 1800

    -- abilities (keep cd=0; rely on bar cooldowns to avoid bad assumptions)
    self.abilities = {
        --[[["Touch of Death"] = {
            adrenaline = 9,
            cd = 14400, -- 14.4s cooldown
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                if API.GetAddreline_() == 100 then return 0.0 end

                engine:pollBuffsIfNeeded()
                local nec = engine:getBuff("necrosis")
                local stacks = (nec and nec.stacks) or 0

                if stacks < 6 then
                    API.logDebug("ToD #Stacks: "..tostring(stacks))
                    return 7.5   -- slightly higher than Soul Sap
                else
                    return 0.5
                end
            end
        },
        ["Soul Sap"] = { 
            adrenaline = 9,
            cd = 5400, -- 5.4s cooldown
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                if API.GetAddreline_() == 100 then return 0.0 end

                engine:pollBuffsIfNeeded()
                local rs = engine:getBuff("residualSouls")
                local stacks = (rs and rs.stacks) or 0

                if stacks < 3 then
                    API.logDebug("Soul Sap #Stacks: "..tostring(stacks))
                    return 6.0  -- lower than ToD, still good filler
                else
                    return 0.0
                end
            end 
        },]]

        ["Finger of Death"] = {
            adrenaline = -60,
            lastUsed   = -1e12,
            expectedValue = function(engine)
                local nec = engine:getBuff("necrosis")
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
                local rs = engine:getBuff("residualSouls")
                local stacks = (rs and rs.stacks) or 0

                if stacks == 3 then
                    return 9.0   -- spender: high priority when capped
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
                -- If the target has the "bloated" debuff, deprioritize it
                if engine:targetHasDebuff(engine.enemyDebuffIDs.bloated) then
                    return 0.0
                else
                    return 9.5 -- strong priority if target is not bloated
                end
            end
        },

        ["Soul Strike"] = { 
            adrenaline = 0,   
            lastUsed = -1e12, 
            expectedValue = function(engine)
                
                -- Don’t cast if target has immune_stun debuff
                if engine:targetHasDebuff(engine.enemyDebuffIDs.immune_stun) then 
                    return 0.0 
                end
                
                -- Only cast when AoE mode is active
                if not engine.useAoE then 
                    return 0.0 
                end

                -- Require at least 1 Residual Souls stack
                local rs = engine:getBuff("residualSouls")
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
            expectedValue = function(engine)
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
            expectedValue = function(engine)
                -- Require 100% adrenaline
                if API.GetAddreline_() < 100 then return 0.0 end

                -- Respect Living Death’s own cooldown
                local t = API.SystemTime()
                local desc = engine.abilities["Living Death"]
                if desc and (t - desc.lastUsed < (desc.cd or 0)) then
                    return 0.0
                end

                -- Check if Death Skulls is available
                if engine:isAbilityReady("Death Skulls") and engine.useAoE then
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

        --[[["Conjure Skeleton Warrior"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasConjure("skeletonWarrior") and 0.0 or 1.8
            end
        },]]

        ["Command Skeleton Warrior"] = {
            adrenaline = 0,
            cd = 15000,  -- cooldown in ms (15s)
            lastUsed = -1e12,
            expectedValue = function(engine)
                if engine:isAbilityReady("Command Skeleton Warrior") then
                    return 3.5
                end
                return 0.0
            end
        },

        --[[["Conjure Putrid Zombie"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasConjure("putridZombie") and 0.0 or 1.8
            end
        },]]

        --[[["Command Putrid Zombie"] = {
            adrenaline = 0,
            cd = 15000, -- ms
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                if engine:hasConjure("putridZombie") and engine:isAbilityReady("Command Putrid Zombie") then
                    return 1.5
                end
                return 0.0
            end
        },]]

        --[[["Conjure Vengeful Ghost"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasConjure("vengefulGhost") and 0.0 or 1.8
            end
        },]]

        ["Command Vengeful Ghost"] = {
            adrenaline = 0,
            cd = 15000, -- ms
            lastUsed = -1e12,
            expectedValue = function(engine)
                if engine:isAbilityReady("Command Vengeful Ghost") then
                    return 4.0
                else    
                    return 0.0
                end
            end
        },

        --[[["Conjure Phantom Guardian"] = {
            adrenaline = 0,
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                return engine:hasConjure("phantomGuardian") and 0.0 or 1.8
            end
        },]]

        --[[["Command Phantom Guardian"] = {
            adrenaline = 0,
            cd = 15000, -- ms
            lastUsed = -1e12,
            expectedValue = function(_, engine)
                if engine:hasConjure("phantomGuardian") and engine:isAbilityReady("Command Phantom Guardian") then
                    return 3.0
                end
                return 0.0
            end
        },]]

        ["Spectral Scythe"] = {
            adrenaline = -10,
            cd = 15000,
            lastUsed = -1e12,
            stage = 0,
            stageExpire = 0,

            expectedValue = function(engine)
                local desc = engine.abilities["Spectral Scythe"]

                if not engine.useAoE then return 0.0 end

                local rs = engine:getBuff("residualSouls")
                local stacks = (rs and rs.stacks) or 0
                if stacks >= 3 then return 0.0 end

                -- Check if stage window expired
                if nowMs() > desc.stageExpire then
                    desc.stage = 0
                end

                -- EV by stage
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

                -- If chain expired, reset to stage 0 before advancing
                if t > desc.stageExpire then
                    desc.stage = 0
                end

                -- Advance stage
                if desc.stage < 2 then
                    desc.stage = desc.stage + 1
                    desc.stageExpire = t + 15000
                else
                    -- Stage 3 cast -> reset to 0 and trigger full cooldown
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
                local hp = API.GetHPrecent()
                if hp >= 70 then
                    return 0.0
                else
                    return 7.5
                end
            end,
            onCast = function(engine)
                local t = nowMs()
                -- Mark as pending for 6 seconds to simulate channel
                engine.pendingCast  = "Blood Siphon"
                engine.pendingUntil = t + 6000
                API.logDebug("[Blood Siphon] Channeling for 6000ms")
            end
        },

        ["Death Grasp"] = {
            adrenaline = -25,        -- Costs 25% adrenaline
            cd = 30000,              -- 30 sec cooldown (ms)
            lastUsed = -1e12,
            expectedValue = function(engine)
                -- Don’t cast if target has immune_stun debuff
                if engine:targetHasDebuff(engine.enemyDebuffIDs.immune_stun) then
                    return 0.0
                end

                -- Get necrosis stacks from buff data
                local nec = engine:getBuff("necrosis")
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

        ["Eat Food"] = { 
            adrenaline = 0,
            lastUsed = -1e12, 
            expectedValue = function(engine)
                local hp = API.GetHPrecent()
                if hp >= 40 then
                    return 0.0
                else
                    return 11.0
                end
            end 
        },

    }

    return self
end

function CombatEngine:KillsPerHour()   
    return math.floor((self.kills*60)/((API.SystemTime() - self.startTime)/60000))
end

-- Returns the average TTK in seconds (last 100 kills)
function CombatEngine:AverageTTK()
    if not self.ttkHistory or #self.ttkHistory == 0 then return 0 end
    local sum = 0
    for _, v in ipairs(self.ttkHistory) do
        sum = sum + v
    end
    return math.floor((sum / #self.ttkHistory) / 1000)
end

-- call this whenever you change priorityList externally
function CombatEngine:_rebuildPriosIfNeeded()
    if self._priosSorted then return end
    local prios = {}
    for name, weight in pairs(self.priorityList) do
        if type(weight) == "number" then
            prios[#prios+1] = { name = name, weight = weight }
        else
            API.logWarn("[_rebuildPriosIfNeeded] Priority for '"..tostring(name).."' is not a number! ("..type(weight)..")")
        end
    end
    table.sort(prios, function(a,b) return a.weight < b.weight end)
    self._priosSorted = prios
end

-- ======== Queued Ability Helpers ========
-- Credits to DEAD.UTILS

---Find which bar currently has a queued skill.
---@return number|nil
function CombatEngine:findBarWithQueuedSkill()
    local queuedBar = API.VB_FindPSettinOrder(5861, 0).state
    if queuedBar == 0 then return nil end
    if queuedBar == 1003 then return 0 end
    if queuedBar == 1032 then return 1 end
    if queuedBar == 1033 then return 2 end
    if queuedBar == 1034 then return 3 end
    if queuedBar == 1035 then return 4 end
    return nil
end

---Is any ability queued?
---@return boolean
function CombatEngine:isAbilityQueued()
    return API.VB_FindPSettinOrder(5861, 0).state ~= 0
end

---Get the slot index of the queued ability.
---@return number
function CombatEngine:getSlotOfQueuedSkill()
    return API.VB_FindPSettinOrder(4164, 0).state
end

--- Is a skill queued.
---@param skill string -- skillName
---@return boolean
function CombatEngine:isSkillQueued(skill)
    if not self:isAbilityQueued() then return false end
    local barNumber = self:findBarWithQueuedSkill()
    if barNumber == nil then return false end
    local skillbar = API.GetAB_name(barNumber, skill)
    local slot = self:getSlotOfQueuedSkill()
    if slot == 0 then return false end
    if skillbar.slot == slot then return true end
    return false
end

-- ======== Buffs ========

function CombatEngine:parseBbar(bbar)
    if not bbar or not bbar.found then
        return { found=false, stacks=0, raw=nil, duration=0 }
    end
    local raw = (type(bbar.text) == "string") and bbar.text or ""
    local duration = parseDuration(raw)
    -- Try to extract stack count from the raw text (matches xN, N st, or just a number)
    local n = raw:match("x%s*(%d+)") or raw:match("(%d+)%s*st") or raw:match("(%d+)")
    local stacks = n and tonumber(n) or 0
    return { found=true, stacks=stacks, raw=raw, duration=duration }
end

function CombatEngine:getBuff(name)
    local id = self.trackedBuffIDs[name]
    if not id then return nil end
    local ok, b = pcall(function()
        return API.Buffbar_GetIDstatus(id, false)
    end)
    if ok and b then
        return self:parseBbar(b)
    else
        return nil
    end
end

--- Check if any conjure buff is active
--- @return boolean
function CombatEngine:hasAnyConjure()
    return (self:getBuff("skeletonWarrior").found)
        or (self:getBuff("vengefulGhost").found)
        or (self:getBuff("putridZombie").found)
        or (self:getBuff("phantomGuardian").found)
end

--- Check if a specific conjure is active
--- @param name string One of: "skeletonWarrior","vengefulGhost","putridZombie","phantomGuardian"
--- @return boolean
function CombatEngine:hasConjure(name)
    local b = self:getBuff(name)
    return b and b.found or false
end

---Check if targetInfo has debuff id
---@param number id of enemy debuff
---@return boolean
function CombatEngine:targetHasDebuff(id)
    if not API.IsTargeting() then return false end
    local tInfo = API.ReadTargetInfo(true)
    if not tInfo or type(tInfo.Buff_stack) ~= "table" then
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
            item.job()
            table.remove(self.scheduler, i)
        end
    end
end

-- ======== Targeting (scheduled) ========

function CombatEngine:acquireTargetIfNeeded()
    if API.IsTargeting() then return end

    if not self._priosSorted or #self._priosSorted == 0 then
        API.logWarn("[Targeting] Priority list is empty! No targets will be acquired.")
        return
    end

    local t = nowMs()
    if t - (self.lastScanTime or 0) < (self.scanInterval) then
        return
    end
    -- non-blocking "settle": just wait a little before scanning again
    if t < (self._targetSettledAt or 0) then
        return
    end

    self.lastScanTime = t
    --self:_rebuildPriosIfNeeded() -- we shouldn't need this here

    local startTime = t
    local bestNpc, bestName, bestDist = nil, nil, 1e9

    -- find the nearest viable NPC across priorities, early-exiting on a hit
    for _, entry in ipairs(self._priosSorted) do
        local npcs = API.ReadAllObjectsArray({1}, {-1}, {entry.name})
        if npcs and #npcs > 0 then
            for i = 1, math.min(#npcs, 50) do  -- cap work per scan
                local npc = npcs[i]
                if npc and npc.Life and npc.Life > 0 then
                    local d = npc.Distance
                    if d < 50 and d < bestDist then
                        bestNpc, bestName, bestDist = npc, entry.name, d
                        if d < 6 then break end  -- good enough; stop digging
                    end
                end
            end
            if bestNpc then break end
        end
        -- no logs here to avoid spam; keep logs at higher level if needed
    end

    if not bestNpc then
        API.logDebug("[Targeting] No valid NPCs found. Check priority list and NPC names.")
        return
    end

    local attacked = API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, bestNpc)
    local elapsed = nowMs() - startTime
    if attacked then
        API.logInfo(("[ENGINE] Engaging: %s @%.1fm took %dms"):format(bestName, bestDist, elapsed))
        self.primaryTargetName = bestName
        if self.isFirstTarget then
            self.isFirstTarget = false
        else
            self.kills = self.kills + 1
            -- TTK: calculate and log time-to-kill, store in history
            if self.lastTTKStart then
                self.lastTTK = nowMs() - self.lastTTKStart
                table.insert(self.ttkHistory, self.lastTTK)
                if #self.ttkHistory > 100 then
                    table.remove(self.ttkHistory, 1)
                end
                API.logInfo(("[ENGINE] Target down! TTK: %.2fs | Total kills: %d | KPH: %d"):format(self.lastTTK/1000, self.kills, self:KillsPerHour()))
            else
                API.logInfo(("[ENGINE] Target down! Total kills: %d | KPH: %d"):format(self.kills, self:KillsPerHour()))
            end
        end
        -- TTK: reset timer when actively engaging a new target
        self.lastTTKStart = nowMs()
        -- set a non-blocking settle window instead of sleeping
        self._targetSettledAt = nowMs() + self._settleDelayMs

        -- Schedule a sleep to prevent actions for 2 seconds after targeting
        self._postTargetSleepUntil = nowMs() + 2000
    end
end

-- ======== Ability Casting ========
function CombatEngine:getAbilityBar(name)
    local ab = API.GetABs_name(name, true)
    if not ab then
        API.logWarn("[getAbilityBar] No bar data for '" .. tostring(name) .. "'")
        return nil
    end
    local abType = type(ab)
    if abType ~= "table" and abType ~= "userdata" then
        API.logWarn("[getAbilityBar] For ability '" .. tostring(name) .. "', got invalid type: " .. abType .. ", value: " .. tostring(ab))
        return nil
    end
    local hasSlot = ab.slot ~= nil
    local hasId = ab.id ~= nil
    local hasName = ab.name ~= nil
    if not (hasSlot and hasId and hasName) then
        API.logWarn("[getAbilityBar] For ability '" .. tostring(name) .. "', got type '" .. abType .. "' but missing Abilitybar fields")
        return nil
    end
    return ab
end

function CombatEngine:isAbilityReady(name)
    local ab   = self:getAbilityBar(name)
    local desc = self.abilities[name]
    if not ab or not desc then return false end
        local abType = type(ab)
        if abType ~= "table" and abType ~= "userdata" then
            API.logWarn("[isAbilityReady] For ability '" .. tostring(name) .. "', got invalid type: " .. abType)
            return false
        end
        local hasSlot = ab.slot ~= nil
        local hasId = ab.id ~= nil
        local hasName = ab.name ~= nil
        if not (hasSlot and hasId and hasName) then
            API.logWarn("[isAbilityReady] For ability '" .. tostring(name) .. "', got type '" .. abType .. "' but missing Abilitybar fields")
            return false
        end
    if ab.enabled == false then return false end
    if ab.cooldown_timer and ab.cooldown_timer > 0 then return false end
    local t = nowMs()
    if t - desc.lastUsed < (desc.cd or 0) then return false end
    if t < self.lastGcdEnd then return false end
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
        local abType = type(ab)
        if abType ~= "table" and abType ~= "userdata" then
            API.logWarn("[castAbility] For ability '" .. tostring(name) .. "', got invalid type: " .. abType)
            return
        end
        local hasSlot = ab.slot ~= nil
        local hasId = ab.id ~= nil
        local hasName = ab.name ~= nil
        if not (hasSlot and hasId and hasName) then
            API.logWarn("[castAbility] For ability '" .. tostring(name) .. "', got type '" .. abType .. "' but missing Abilitybar fields")
            return
        end

    -- Don't cast if ability is already queued
    if self:isSkillQueued(name) then
        return
    end

    -- Don't double-cast while pending
    local t = nowMs()
    if self.pendingCast == name and t < self.pendingUntil then
        return
    end

    if not self:isAbilityReady(name) then
        return
    end

    local result = API.DoAction_Ability_Direct(ab, 1, API.OFF_ACT_GeneralInterface_route)
    if result then
        self.pendingCast = name
        self.pendingUntil = t + 600
        desc.lastUsed = t
        self.lastGcdEnd = t + math.floor(self.gcd * 1000)
        if desc.onCast then
            desc.onCast(self)
        end
    end
end

function CombatEngine:planAndQueue()
    if not API.IsTargeting() then return end
    if self.pendingCast and nowMs() < self.pendingUntil then return end

    local bestName, bestScore = nil, -math.huge
    local evReady, evSkipped = {}, {}

    for name, desc in pairs(self.abilities) do
        local ab = self:getAbilityBar(name)
        if not ab then
            API.logDebug("[ENGINE] Skipping ability '" .. name .. "': no bar entry in cache.")
            evSkipped[#evSkipped+1] = {name=name, reason="no bar entry"}
        else
            local ready, reason = self:isAbilityReady(name), nil
            if ready then
                local score = (desc.expectedValue and desc.expectedValue(self)) or 0
                API.logDebug("[ENGINE] Ability ready: " .. name .. " | score: " .. tostring(score))
                evReady[#evReady+1] = { name = name, score = score }
                if score > bestScore then bestScore, bestName = score, name end
            else
                -- mirror isAbilityReady logic for reason
                if ab.enabled == false then reason = "disabled"
                elseif ab.cooldown_timer and ab.cooldown_timer > 0 then reason = "cd "..tostring(ab.cooldown_timer)
                elseif nowMs() - (desc.lastUsed or 0) < (desc.cd or 0) then reason = "engine cd"
                elseif nowMs() < self.lastGcdEnd then reason = "gcd"
                else reason = "unknown" end
                --API.logDebug("[ENGINE] Skipping ability '" .. name .. "': " .. reason)
                evSkipped[#evSkipped+1] = { name=name, reason=reason }
            end
        end
    end

    if bestName and bestScore > 0 then
        API.logInfo("[ENGINE] Scheduling cast: " .. bestName .. " | score: " .. tostring(bestScore))
        self:schedule(0, function() self:castAbility(bestName) end)
    else
        API.logDebug("[ENGINE] No positive-EV ability to cast this tick.")
    end
end

-- ======== Update Loop ========

function CombatEngine:update()
    if not self.running then return end

    -- Reset pending if ability shows cooldown now
    if self.pendingCast then
        local ab = self:getAbilityBar(self.pendingCast)
        if ab and ab.cooldown_timer and ab.cooldown_timer > 0 then
            self.pendingCast = nil
            self.pendingUntil = 0
        elseif nowMs() > self.pendingUntil then
            -- safety reset if too long
            self.pendingCast = nil
            self.pendingUntil = 0
        end
    end


    -- Prevent actions for a couple seconds after targeting
    if self._postTargetSleepUntil and nowMs() < self._postTargetSleepUntil then
        return
    end

    -- Ability planning
    if areWefighting() then
        -- Check for higher priority targets during combat
        if self._priosSorted and #self._priosSorted > 1 and self.primaryTargetName then
            local currentPrio = nil
            for _, entry in ipairs(self._priosSorted) do
                if entry.name == self.primaryTargetName then
                    currentPrio = entry.weight
                    break
                end
            end
            -- Find the highest priority available target
            local bestPrio = math.huge
            local bestName = nil
            for _, entry in ipairs(self._priosSorted) do
                local npcs = API.ReadAllObjectsArray({1}, {-1}, {entry.name})
                if npcs and #npcs > 0 then
                    for i = 1, math.min(#npcs, 50) do
                        local npc = npcs[i]
                        if npc and npc.Life and npc.Life > 0 then
                            if entry.weight < bestPrio then
                                bestPrio = entry.weight
                                bestName = entry.name
                            end
                        end
                    end
                end
            end
            -- If a higher priority target is available, switch to it using acquireTargetIfNeeded
            if bestPrio < (currentPrio or math.huge) and bestName ~= self.primaryTargetName then
                API.logInfo("[ENGINE] Switching to higher priority target: " .. tostring(bestName))
                -- Clear current target so acquireTargetIfNeeded will acquire the new one
                API.ClearTarget() -- or equivalent if available
                self.primaryTargetName = nil
                self.lastTTKStart = nowMs()
                self._targetSettledAt = nowMs() + self._settleDelayMs
                self._postTargetSleepUntil = nowMs() + 2000
                -- Call acquireTargetIfNeeded to handle attack and kill/TTK logic
                self:acquireTargetIfNeeded()
                return -- skip ability planning for this tick
            end
        end
        -- Ability casting
        self:planAndQueue()
        
    else
        self:acquireTargetIfNeeded()
    end

    -- Run scheduled jobs (casts, delayed stuff)
    self:processScheduler()
    
end

function CombatEngine:start()
    if self.running then return end
    self.running = true
    API.logInfo("[ENGINE] Started.")
end

function CombatEngine:stop()
    self.running = false
    API.logInfo("[ENGINE] Stopped.")
end

return CombatEngine
