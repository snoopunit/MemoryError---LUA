-- combat_engine_rs3.lua
local API = require("api")

local CombatEngine = {}
CombatEngine.__index = CombatEngine

-- helper: parse duration from buff text (e.g. "1:23", "12s")
local function parseDuration(text)
    if not text then return 0 end
    local mins, secs = text:match("(%d+):(%d+)")
    if mins and secs then
        return tonumber(mins) * 60 + tonumber(secs)
    end
    local n = text:match("(%d+)%s*s")
    if n then return tonumber(n) end
    return 0
end

-- constructor
function CombatEngine.new()
    local self = setmetatable({}, CombatEngine)
    self.running = false
    self.scheduler = {}
    self.targets = {}
    self.activeTargets = {}
    self.primaryTargetId = nil
    self.priorityList = {}

    self.lastScanTime = 0
    self.scanInterval = 1200 -- ms, adjust as needed (10s)

    -- buff tracking
    self.buffs = {}
    self.debuffs = {}
    self.trackedBuffIDs = {
        necrosis = 30101,
        residualSouls = 30123,
        skeletonWarrior = 34177,
        vengefulGhost = 34178,
        putridZombie = 34179,
        phantomGuardian = 34180
    }
    self.trackedDebuffIDs = {
        poison = 30097, -- placeholder
        stun = 26103    -- placeholder
    }

    -- abilities (Necromancy)
    self.abilities = {
        ["Necromancy Auto"] = { name="Necromancy Auto", cd=0, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 1.0 end },
        ["Touch of Death"] = { name="Touch of Death", cd=0, lastUsed=-1e9, adrenaline=9,
            expectedValue=function() return 1.0 end },
        ["Conjure Skeleton Warrior"] = { name="Conjure Skeleton Warrior", cd=30, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 0 end },
        ["Command Skeleton Warrior"] = { name="Command Skeleton Warrior", cd=15, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 3.5 end },
        ["Death Skulls"] = { name="Death Skulls", cd=60, lastUsed=-1e9, adrenaline=-100,
            expectedValue=function() return 5.0 end },
        ["Blood Siphon"] = { name="Blood Siphon", cd=45, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 2.0 end },
        ["Conjure Putrid Zombie"] = { name="Conjure Putrid Zombie", cd=30, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 0 end },
        ["Command Putrid Zombie"] = { name="Command Putrid Zombie", cd=0, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 4.0 end },
        ["Conjure Vengeful Ghost"] = { name="Conjure Vengeful Ghost", cd=30, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 0 end },
        ["Command Vengeful Ghost"] = { name="Command Vengeful Ghost", cd=0, lastUsed=-1e9, adrenaline=0,
            expectedValue=function(_, engine, target)
                if target.debuffs and target.debuffs.haunted then
                    return 0.1
                end
                return 0
            end },
        ["Bloat"] = { name="Bloat", cd=0, lastUsed=-1e9, adrenaline=-20,
            expectedValue=function() return 6.5 end },
        ["Soul Sap"] = { name="Soul Sap", cd=5.4, lastUsed=-1e9, adrenaline=9,
            expectedValue=function() return 1.0 end },
        ["Soul Strike"] = { name="Soul Strike", cd=0, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 1.5 end },
        ["Spectral Scythe (Stage 1)"] = { name="Spectral Scythe (Stage 1)", cd=15, lastUsed=-1e9, adrenaline=-10,
            expectedValue=function() return 0.8 end },
        ["Spectral Scythe (Stage 2)"] = { name="Spectral Scythe (Stage 2)", cd=0, lastUsed=-1e9, adrenaline=-20,
            expectedValue=function() return 2.0 end },
        ["Spectral Scythe (Stage 3)"] = { name="Spectral Scythe (Stage 3)", cd=0, lastUsed=-1e9, adrenaline=-30,
            expectedValue=function() return 2.5 end },
        ["Volley of Souls"] = { name="Volley of Souls", cd=0, lastUsed=-1e9, adrenaline=0,
            expectedValue=function(_, engine)
                local rs = engine.buffs.residualSouls or { stacks=0 }
                return 1.5 * (rs.stacks or 0)
            end },
        ["Conjure Phantom Guardian"] = { name="Conjure Phantom Guardian", cd=0, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 0 end },
        ["Command Phantom Guardian"] = { name="Command Phantom Guardian", cd=9, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 3.0 end },
        ["Finger of Death"] = { name="Finger of Death", cd=0, lastUsed=-1e9, adrenaline=-60,
            expectedValue=function(self, engine)
                local nec = engine.buffs.necrosis or { stacks=0 }
                local necStacks = nec.stacks or 0
                local costReduction = math.min(necStacks * 10, 60)
                self.adrenaline = -60 + costReduction
                return 3.0
            end },
        ["Living Death"] = { name="Living Death", cd=90, lastUsed=-1e9, adrenaline=-100,
            expectedValue=function() return 0 end },
        ["Conjure Undead Army"] = { name="Conjure Undead Army", cd=0, lastUsed=-1e9, adrenaline=0,
            expectedValue=function() return 0 end }
    }

    return self
end

-- parse Bbar into normalized table
function CombatEngine:parseBbar(bbar)
    if not bbar or not bbar.found then
        return { found=false, stacks=0, raw=nil, conv=nil, duration=0 }
    end
    local conv = tonumber(bbar.conv_text) or nil
    local raw = bbar.text or nil
    local stacks = conv or 0
    local duration = parseDuration(raw)
    return { found=true, stacks=stacks, raw=raw, conv=conv, duration=duration }
end

-- update buffs/debuffs
function CombatEngine:updateBuffs()
    for name, id in pairs(self.trackedBuffIDs) do
        local bbar = API.Buffbar_GetIDstatus(id, false)
        self.buffs[name] = self:parseBbar(bbar)
    end
    for name, id in pairs(self.trackedDebuffIDs) do
        local bbar = API.DeBuffbar_GetIDstatus(id, false)
        self.debuffs[name] = self:parseBbar(bbar)
    end
end

function CombatEngine:updateTargetsFromWorld()
    local now = API.SystemTime()

    -- throttle scanning
    if now - (self.lastScanTime or 0) < (self.scanInterval or 2000) then
        return
    end
    self.lastScanTime = now

    -- validate current lock
    if self.primaryTargetId then
        local cur = API.ReadAllObjectsArray({1}, {self.primaryTargetId}, {})
        if cur and cur[1] and cur[1].Life > 0 then
            return -- current target is still valid, keep it
        else
            self.primaryTargetId = nil -- drop lock if dead/invalid
        end
    end

    -- build name filter from priority list
    local nameTable = {}
    for name, _ in pairs(self.priorityList) do
        table.insert(nameTable, tostring(name))
    end

    -- query only priority targets
    local npcs = API.ReadAllObjectsArray({1}, {-1}, nameTable)
    if not npcs or #npcs == 0 then return end

    -- pick best by priority weight + distance
    local best, bestScore
    for _, npc in ipairs(npcs) do
        if npc.Life > 0 then
            local prio = self.priorityList[npc.Name] or 999
            local dist = npc.Distance or 999
            local score = (prio * 1000) + dist
            if not bestScore or score < bestScore then
                bestScore = score
                best = npc
            end
        end
    end

    if best then
        self.primaryTargetId = best.Unique_Id
    end
end


-- priority system
function CombatEngine:getPriorityForName(name)
    return self.priorityList[name] or 9999
end

function CombatEngine:priorityTargetOverride(candidates)
    local bestId, bestPriority
    for _, npc in ipairs(candidates) do
        local pri = self:getPriorityForName(npc.Name or "")
        if not bestPriority or pri < bestPriority then
            bestPriority = pri
            bestId = npc.Unique_Id
        end
    end
    return bestId
end

-- ability checks
function CombatEngine:isAbilityAvailable(name)
    local desc = self.abilities[name]
    if not desc then return false end
    local now = self:now()
    return now - desc.lastUsed >= desc.cd
end

-- planning
function CombatEngine:planNext()
    local best, bestScore = nil, -1/0
    if self.primaryTargetId then
        local t = self.targets[self.primaryTargetId]
        if t and not t.isDead then
            for name, desc in pairs(self.abilities) do
                if self:isAbilityAvailable(name) then
                    local score = desc.expectedValue(desc, self, t)
                    if score > bestScore then
                        bestScore = score
                        best = { abilityName=name, targetId=t.id }
                    end
                end
            end
        end
    end
    return best
end

-- schedule casts
function CombatEngine:scheduleCast(abilityName, targetId, now)
    local ability = self.abilities[abilityName]
    if not ability then return end
    ability.lastUsed = now
    self.lastGcdEnd = now + 1.8
    API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
end

-- helpers
function CombatEngine:now()
    return API.SystemTime() / 1000
end

-- tick update
function CombatEngine:update()
    local t0 = API.SystemTime()
    if not self.running then return end
    self:updateBuffs()
    self:updateTargetsFromWorld()
    local now = self:now()
    if now >= (self.lastGcdEnd or 0) then
        local choice = self:planNext()
        if choice then
            self:scheduleCast(choice.abilityName, choice.targetId, now)
        end
    end
    local t1 = API.SystemTime()
    API.logDebug(("Engine:update took %d ms"):format(t1 - t0))
end

-- start/stop
function CombatEngine:start()
    if not self.running then
        self.running = true
        TickEvent.Register(function() self:update() end)
    end
end
function CombatEngine:stop()
    self.running = false
end

return CombatEngine
