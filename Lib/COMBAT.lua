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
    self.awaitingCombat = false       -- prevent re-spamming Attack while the click resolves
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
        ["Necromancy Auto"] = { adrenaline = 0,  lastUsed = -1e12, expectedValue = function() return 1.0 end },
        ["Touch of Death"]  = { adrenaline = 9,  lastUsed = -1e12, expectedValue = function() return 1.0 end },
        ["Soul Sap"]        = { adrenaline = 9,  lastUsed = -1e12, expectedValue = function() return 1.0 end },

        ["Finger of Death"] = {
            adrenaline = -60, lastUsed = -1e12,
            expectedValue = function(selfDesc, engine)
                local nec = engine.buffs.necrosis
                local stacks = (nec and nec.stacks) or 0
                local costReduction = math.min(stacks * 10, 60)
                -- reflect runtime cost (optional)
                selfDesc._runtimeAdren = -60 + costReduction
                return 3.0 -- 300% baseline
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
        ["Conjure Skeleton Warrior"]  = { adrenaline = 0, lastUsed=-1e12, expectedValue=function() return 0 end },
        ["Command Skeleton Warrior"]  = { adrenaline = 0, lastUsed=-1e12, expectedValue=function() return 3.5 end },

        ["Conjure Putrid Zombie"]     = { adrenaline = 0, lastUsed=-1e12, expectedValue=function() return 0 end },
        ["Command Putrid Zombie"]     = { adrenaline = 0, lastUsed=-1e12, expectedValue=function() return 4.0 end },

        ["Conjure Vengeful Ghost"]    = { adrenaline = 0, lastUsed=-1e12, expectedValue=function() return 0 end },
        ["Command Vengeful Ghost"]    = {
            adrenaline=0, lastUsed=-1e12,
            expectedValue=function(_, engine, target)
                -- If you wire enemy debuffs later, bump value while Haunted is active.
                return 0.1
            end
        },

        ["Conjure Phantom Guardian"]  = { adrenaline = 0, lastUsed=-1e12, expectedValue=function() return 0   end },
        ["Command Phantom Guardian"]  = { adrenaline = 0, lastUsed=-1e12, expectedValue=function() return 3.0 end },

        -- Spectral Scythe stages (rough EVs)
        ["Spectral Scythe (Stage 1)"] = { adrenaline = -10, lastUsed=-1e12, expectedValue=function() return 0.8 end },
        ["Spectral Scythe (Stage 2)"] = { adrenaline = -20, lastUsed=-1e12, expectedValue=function() return 2.0 end },
        ["Spectral Scythe (Stage 3)"] = { adrenaline = -30, lastUsed=-1e12, expectedValue=function() return 2.5 end },

        ["Conjure Undead Army"]       = { adrenaline = 0, lastUsed=-1e12, expectedValue=function() return 0 end },
        ["Blood Siphon"]              = { adrenaline = 0, lastUsed=-1e12, expectedValue=function() return 2.0 end },
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

local function iterPriorityNamesSorted(priorityList)
    -- produce array of names sorted by priority ASC (lower number first)
    local arr = {}
    for name, pri in pairs(priorityList) do
        table.insert(arr, { name=name, pri=pri })
    end
    table.sort(arr, function(a,b)
        if a.pri == b.pri then return a.name < b.name end
        return a.pri < b.pri
    end)
    local i = 0
    return function()
        i = i + 1
        local r = arr[i]
        return r and r.name or nil
    end
end

function CombatEngine:acquireTargetIfNeeded()
    -- Already in combat or awaiting click to resolve? Do nothing.
    if API.IsTargeting() or self.awaitingCombat then return end

    local t = nowMs()
    if t - self.lastScanTime < self.scanInterval then return end
    self.lastScanTime = t

    -- Try by priority order; schedule ONE attack attempt
    for name in iterPriorityNamesSorted(self.priorityList) do
        self.awaitingCombat = true
        self:schedule(50, function()
            local ok = Interact:NPC(name, "Attack", 30)
            if ok then
                self.primaryTargetName = name
                API.logDebug("Engaging: "..name)
            end
            -- Whether it succeeded or not, allow next attempt on next interval.
            self.awaitingCombat = false
        end)
        break
    end
end

-- ======== Ability Casting ========

function CombatEngine:isAbilityReady(name)
    local ab = self.abilityBars[name]
    if not ab then return false end
    if not ab.enabled then return false end
    if ab.cooldown_timer and ab.cooldown_timer > 0 then return false end
    -- GCD check (ms)
    if nowMs() < self.lastGcdEnd then return false end
    return true
end

function CombatEngine:castAbility(name)
    local ab = self.abilityBars[name]
    local desc = self.abilities[name]
    if not ab or not desc then return end
    if not self:isAbilityReady(name) then return end

    if API.DoAction_Ability_Direct(ab, 1, 0) then
        local t = nowMs()
        desc.lastUsed = t
        self.lastGcdEnd = t + math.floor(self.gcd * 1000)
        API.logDebug("Casting: "..name)
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

function CombatEngine:targetLoop()
    if not self.running then return end

    local t0 = nowMs()

    -- Already in combat? Do nothing.
    if API.IsTargeting() then return end

    local t = API.SystemTime()
    if t - (self.lastScanTime or 0) < (self.scanInterval or 2000) then
        return
    end
    self.lastScanTime = t

    -- Try to acquire by priority order
    for name, _ in pairs(self.priorityList) do
        local t1 = nowMs()
        local ok = Interact:NPC(name, "Attack", 30)
        API.logDebug("Interact:NPC(" .. name .. ") took " .. (nowMs()-t1) .. "ms")

        if ok then
            API.logDebug("Targeting: " .. name)
            break
        end
    end

    API.logDebug("TargetLoop total " .. (nowMs()-t0) .. "ms")
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
    end
    API.logDebug("PlanAndQueue took " .. (nowMs()-t1) .. "ms")

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

    -- Separate targeting loop (slower cadence, only does Interact)
    TickEvent.Register(function() self:targetLoop() end)

    API.logDebug("Combat engine started")
end


function CombatEngine:stop()
    self.running = false
    -- (optional) API.logDebug("Combat engine stopped")
end

return CombatEngine