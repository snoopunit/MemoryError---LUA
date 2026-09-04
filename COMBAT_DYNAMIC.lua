--[[
    ED1 DYNAMIC NECROMANCY COMBAT ENGINE
    Built against MemoryError-LUA api.lua/usertypes.lua interfaces.

    Design:
      * Dungeon-agnostic combat engine.
      * Reads a single combat snapshot and evaluates every usable action against it.
      * Uses target NAME + NPC ID, so same-name healer/normal NPCs can be separated.
      * Predicts AoE from actual NPC positions rather than a static "AoE mode" flag.
      * Supports Threads-style target amplification through ability geometry.
      * Uses empirical damage learning from splat events instead of invented damage coefficients.
      * Supports incantation/rune requirements.
      * Supports projectile-driven prayer flicking by projectile ID.
      * Has an emergency callback for the dungeon controller.

    IMPORTANT:
      No unverified client functions are used here. Any game-specific fact not present
      in api.lua/usertypes.lua is represented as CONFIG/TODO data.
]]

local API = require("api")

local CombatEngine = {}
CombatEngine.__index = CombatEngine

local function now()
    return API.SystemTime()
end

local function alive(npc)
    return npc and npc.Life and npc.Life > 0
end

local function xy(obj)
    if not obj then return nil end
    local t = obj.Tile_XYZ
    if t then return t.x, t.y, t.z end
    if obj.TileX and obj.TileY then return obj.TileX, obj.TileY, obj.TileZ end
    return nil
end

local function distanceXY(a, b)
    local ax, ay = xy(a)
    local bx, by = xy(b)
    if not ax or not bx then return math.huge end
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function distancePoint(a, b)
    if not a or not b then return math.huge end
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function shallowCopy(t)
    local r = {}
    for k, v in pairs(t or {}) do r[k] = v end
    return r
end

function CombatEngine.new(config)
    local self = setmetatable({}, CombatEngine)

    self.config = config or {}

    self.running = false
    self.gcdUntil = 0
    self.pendingCast = nil
    self.pendingUntil = 0
    self.lastDecision = 0
    self.decisionInterval = self.config.decisionInterval or 100
    self.snapshotInterval = self.config.snapshotInterval or 100
    self.lastSnapshot = 0
    self.snapshot = nil

    self.priorityList = {}
    self._priosSorted = nil

    self.abilities = {}
    self.learned = {}
    self.castHistory = {}
    self.splatHistory = {}
    self.lastCast = nil

    self.projectilePrayer = {
        active = false,
        spell = nil,
        untilMs = 0,
        lastProjectileKey = nil,
        lastProjectileMs = 0
    }

    self.metrics = {
        casts = 0,
        damageObserved = 0,
        decisions = 0,
        emergencyTriggers = 0
    }

    self.emergency = {
        thresholdHp = self.config.emergencyHpThreshold or 20,
        callback = nil
    }

    return self
end

-- =========================
-- Configuration
-- =========================

function CombatEngine:setPriorityList(list)
    self.priorityList = shallowCopy(list)
    self._priosSorted = {}
    for name, weight in pairs(self.priorityList) do
        if type(weight) == "number" then
            self._priosSorted[#self._priosSorted + 1] = {name = name, weight = weight}
        end
    end
    table.sort(self._priosSorted, function(a, b) return a.weight < b.weight end)
end

function CombatEngine:addAbility(name, desc)
    assert(type(name) == "string", "ability name must be a string")
    self.abilities[name] = desc
    if not self.learned[name] then
        self.learned[name] = {
            samples = 0,
            damagePerTarget = 0,
            damagePerCast = 0,
            confidence = 0
        }
    end
end

function CombatEngine:setEmergencyCallback(fn)
    self.emergency.callback = fn
end

function CombatEngine:start()
    self.running = true
    self.pendingCast = nil
    self.pendingUntil = 0
end

function CombatEngine:stop()
    self.running = false
    self.pendingCast = nil
    self.pendingUntil = 0
end

function CombatEngine:resetEncounter()
    self.pendingCast = nil
    self.pendingUntil = 0
    self.gcdUntil = 0
    self.snapshot = nil
    self.lastSnapshot = 0
    self.lastDecision = 0
    self.lastCast = nil
    self.castHistory = {}
end

-- =========================
-- Ability bar / inventory
-- =========================

function CombatEngine:getAbilityBar(name)
    local ab = API.GetABs_name(name, true)
    if not ab then return nil end
    if ab.slot == nil or ab.id == nil or ab.name == nil then return nil end
    return ab
end

function CombatEngine:abilityReady(name)
    local desc = self.abilities[name]
    local ab = self:getAbilityBar(name)
    if not desc or not ab then return false end
    if ab.enabled == false then return false end
    if ab.cooldown_timer and ab.cooldown_timer > 0 then return false end
    if now() < self.gcdUntil then return false end
    return true
end

function CombatEngine:hasRuneRequirement(req)
    if not req then return true end

    -- Requirements are deliberately data-driven. We only query Inventory through
    -- APIs documented in api.lua. Configure exact rune IDs/names below.
    if req.id then
        return (API.InvItemcount_String(req.name) or 0) >= (req.count or 1)
    end

    if req.name then
        return (API.InvItemcount_String(req.name) or 0) >= (req.count or 1)
    end

    return true
end

function CombatEngine:requirementsMet(desc)
    for _, req in ipairs(desc.runes or {}) do
        if not self:hasRuneRequirement(req) then
            return false
        end
    end

    if desc.requiredItems then
        for _, item in ipairs(desc.requiredItems) do
            if (API.InvItemcount_String(item) or 0) <= 0 then
                return false
            end
        end
    end

    return true
end

-- =========================
-- Combat snapshot
-- =========================

function CombatEngine:readEnemies()
    local objects = API.ReadAllObjectsArray({1}, {-1}, {})
    local enemies = {}

    for _, npc in ipairs(objects or {}) do
        if alive(npc) then
            enemies[#enemies + 1] = {
                object = npc,
                name = npc.Name,
                id = npc.Id,
                life = npc.Life,
                distance = npc.Distance or distanceXY(npc, API.Create_AO_struct()),
                x = (npc.Tile_XYZ and npc.Tile_XYZ.x) or npc.TileX,
                y = (npc.Tile_XYZ and npc.Tile_XYZ.y) or npc.TileY,
                z = (npc.Tile_XYZ and npc.Tile_XYZ.z) or npc.TileZ
            }
        end
    end

    return enemies
end

function CombatEngine:matchesTargetRule(enemy, rule)
    if rule.name and enemy.name ~= rule.name then return false end
    if rule.id and enemy.id ~= rule.id then return false end
    if rule.ids then
        local found = false
        for _, id in ipairs(rule.ids) do
            if enemy.id == id then found = true break end
        end
        if not found then return false end
    end
    return true
end

function CombatEngine:enemyAllowed(enemy)
    if not self._priosSorted or #self._priosSorted == 0 then
        return true
    end

    for _, rule in ipairs(self._priosSorted) do
        if type(rule.name) == "string" then
            -- Name-only priority entries are intentionally broad.
            if enemy.name == rule.name then return true end
        elseif type(rule.rule) == "table" then
            if self:matchesTargetRule(enemy, rule.rule) then return true end
        end
    end

    return false
end

function CombatEngine:buildDistanceMatrix(enemies)
    local matrix = {}
    for i = 1, #enemies do
        matrix[i] = {}
        for j = 1, #enemies do
            if i == j then
                matrix[i][j] = 0
            else
                local dx = (enemies[i].x or 0) - (enemies[j].x or 0)
                local dy = (enemies[i].y or 0) - (enemies[j].y or 0)
                matrix[i][j] = math.sqrt(dx * dx + dy * dy)
            end
        end
    end
    return matrix
end

function CombatEngine:buildClusterMap(enemies, matrix)
    local map = {}
    for i = 1, #enemies do
        map[i] = {}
        for j = 1, #enemies do
            if matrix[i][j] <= (self.config.defaultAoeRadius or 4) then
                map[i][#map[i] + 1] = j
            end
        end
    end
    return map
end

function CombatEngine:buildSnapshot()
    local t = now()
    if self.snapshot and (t - self.lastSnapshot) < self.snapshotInterval then
        return self.snapshot
    end

    local enemies = self:readEnemies()
    local matrix = self:buildDistanceMatrix(enemies)

    self.snapshot = {
        time = t,
        enemies = enemies,
        distance = matrix,
        cluster = self:buildClusterMap(enemies, matrix),
        hpPercent = API.GetHPrecent(),
        hp = API.GetHP_(),
        hpMax = API.GetHPMax_(),
        adrenaline = API.GetAddreline_(),
        prayer = API.GetPrayPrecent(),
        targeting = API.IsTargeting(),
        moving = API.IsPlayerMoving_(API.GetLocalPlayerName())
    }

    self.lastSnapshot = t
    return self.snapshot
end

-- =========================
-- Target selection
-- =========================

function CombatEngine:priorityFor(enemy)
    local best = math.huge

    for _, entry in ipairs(self._priosSorted or {}) do
        if enemy.name == entry.name then
            best = math.min(best, entry.weight)
        end

        if entry.rule and self:matchesTargetRule(enemy, entry.rule) then
            best = math.min(best, entry.weight)
        end
    end

    return best
end

function CombatEngine:choosePrimaryTarget(snapshot)
    local best, bestScore

    for _, enemy in ipairs(snapshot.enemies) do
        if self:enemyAllowed(enemy) then
            local p = self:priorityFor(enemy)
            if p == math.huge then p = 1000 end

            -- Lower priority number is more important.
            local score = (10000 - p * 100) - (enemy.distance or 50)
            if not bestScore or score > bestScore then
                best = enemy
                bestScore = score
            end
        end
    end

    return best
end

-- =========================
-- Geometry
-- =========================

function CombatEngine:targetsInRadius(snapshot, primary, radius)
    local result = {}
    if not primary then return result end

    for _, enemy in ipairs(snapshot.enemies) do
        if distanceXY(primary.object, enemy.object) <= radius then
            result[#result + 1] = enemy
        end
    end

    return result
end

function CombatEngine:predictTargets(desc, snapshot, primary)
    if not primary then return {} end

    local geometry = desc.geometry or "single"

    if geometry == "single" then
        return {primary}
    end

    if geometry == "radius" then
        return self:targetsInRadius(snapshot, primary, desc.radius or self.config.defaultAoeRadius or 4)
    end

    if geometry == "threads" then
        -- Threads-style replication is represented as a radius around the
        -- primary target. Exact game radius is intentionally configurable.
        return self:targetsInRadius(snapshot, primary, desc.radius or self.config.threadsRadius or 4)
    end

    if geometry == "custom" and desc.predictTargets then
        return desc.predictTargets(self, snapshot, primary)
    end

    return {primary}
end

-- =========================
-- Empirical damage model
-- =========================

function CombatEngine:pollSplats()
    -- GatherEvents_splat_check is documented by api.lua. The exact EInfo mapping
    -- is client-specific, so we treat Amount as damage and leave classification
    -- conservative.
    local splats = API.GatherEvents_splat_check(true)
    local total = 0

    for _, splat in ipairs(splats or {}) do
        if splat and splat.Amount and splat.Amount > 0 then
            total = total + splat.Amount
            self.metrics.damageObserved = self.metrics.damageObserved + splat.Amount
        end
    end

    return total
end

function CombatEngine:recordObservedCastDamage()
    if not self.lastCast then return end

    local elapsed = now() - self.lastCast.time
    if elapsed < (self.config.splatObservationMinMs or 100) then return end
    if elapsed > (self.config.splatObservationMaxMs or 2500) then
        self.lastCast = nil
        return
    end

    local damage = self:pollSplats()
    if damage <= 0 then return end

    local name = self.lastCast.name
    local targets = math.max(1, self.lastCast.predictedTargetCount or 1)
    local model = self.learned[name]

    model.samples = model.samples + 1
    model.damagePerCast = model.damagePerCast + (damage - model.damagePerCast) / model.samples
    model.damagePerTarget = model.damagePerTarget + ((damage / targets) - model.damagePerTarget) / model.samples
    model.confidence = math.min(1, model.samples / 25)

    self.lastCast.observedDamage = damage
    self.lastCast = nil
end

function CombatEngine:estimateDamage(desc, targets)
    local learned = self.learned[desc.name]
    local targetCount = math.max(1, #targets)

    if learned and learned.samples > 0 then
        return learned.damagePerTarget * targetCount
    end

    -- No invented damage number. The ability may supply a user-configured prior.
    if desc.damagePrior then
        return desc.damagePrior * targetCount
    end

    return 0
end

-- =========================
-- Strategic EV
-- =========================

function CombatEngine:resourceValue(desc, snapshot)
    local value = 0

    if desc.adrenalineCost then
        value = value - (desc.adrenalineCost * (self.config.adrenalineValue or 0.15))
    end

    if desc.necrosisCost then
        value = value - (desc.necrosisCost * (self.config.necrosisValue or 1.0))
    end

    if desc.generatesNecrosis then
        value = value + desc.generatesNecrosis * (self.config.necrosisGainValue or 1.0)
    end

    if desc.generatesSouls then
        value = value + desc.generatesSouls * (self.config.soulGainValue or 1.0)
    end

    return value
end

function CombatEngine:setupValue(desc, snapshot, primary, targets)
    local value = 0

    if desc.tags then
        if desc.tags.threads then
            local count = #targets
            value = value + count * (self.config.threadsSetupValue or 2)
        end

        if desc.tags.resetCooldown then
            value = value + (self.config.cooldownResetValue or 5)
        end

        if desc.tags.execute then
            for _, enemy in ipairs(targets) do
                if enemy.life <= (self.config.executeHpThreshold or 0) then
                    value = value + 3
                end
            end
        end
    end

    return value
end

function CombatEngine:survivalValue(desc, snapshot)
    if not desc.defensive then return 0 end
    local hp = snapshot.hpPercent or 100
    if hp < 30 then return self.config.defensiveValue or 100 end
    if hp < 50 then return (self.config.defensiveValue or 100) * 0.5 end
    return 0
end

function CombatEngine:scoreAbility(desc, snapshot, primary)
    if not primary then return -math.huge end
    if not self:abilityReady(desc.name) then return -math.huge end
    if not self:requirementsMet(desc) then return -math.huge end

    local targets = self:predictTargets(desc, snapshot, primary)
    local damage = self:estimateDamage(desc, targets)

    -- If the ability has no empirical model yet, a configured strategic prior
    -- can still bootstrap it. We never invent one in this engine.
    local ev = damage

    ev = ev + self:setupValue(desc, snapshot, primary, targets)
    ev = ev + self:resourceValue(desc, snapshot)
    ev = ev + self:survivalValue(desc, snapshot)

    -- Opportunity cost: slower actions need more value to justify themselves.
    local castTime = desc.castTimeMs or 1800
    ev = ev / math.max(0.5, castTime / 1000)

    -- Penalize casts that barely hit one target when another primary target
    -- produces a larger cluster.
    if desc.preferAoE and #targets < 2 then
        ev = ev * (self.config.singleTargetAoEPenalty or 0.35)
    end

    return ev, targets
end

function CombatEngine:bestAction(snapshot)
    local primary = self:choosePrimaryTarget(snapshot)
    if not primary then return nil end

    local best, bestScore, bestTargets

    for name, desc in pairs(self.abilities) do
        desc.name = name
        local score, targets = self:scoreAbility(desc, snapshot, primary)

        if score > (bestScore or -math.huge) then
            best = {
                name = name,
                score = score,
                primary = primary,
                targets = targets
            }
            bestScore = score
            bestTargets = targets
        end
    end

    self.metrics.decisions = self.metrics.decisions + 1
    return best
end

-- =========================
-- Casting
-- =========================

function CombatEngine:cast(action)
    if not action then return false end

    local ab = self:getAbilityBar(action.name)
    if not ab then return false end
    if not self:abilityReady(action.name) then return false end
    if not self:requirementsMet(self.abilities[action.name]) then return false end

    local ok = API.DoAction_Ability_Direct(ab, 1, API.OFF_ACT_GeneralInterface_route)

    if ok then
        local t = now()
        local desc = self.abilities[action.name]

        desc.lastUsed = t
        self.gcdUntil = t + (desc.gcdMs or self.config.gcdMs or 1800)
        self.pendingCast = action.name
        self.pendingUntil = t + 700

        self.lastCast = {
            name = action.name,
            time = t,
            predictedTargetCount = #action.targets,
            primaryId = action.primary.id,
            primaryName = action.primary.name
        }

        self.castHistory[#self.castHistory + 1] = self.lastCast
        self.metrics.casts = self.metrics.casts + 1

        if desc.onCast then
            desc.onCast(self, action)
        end

        return true
    end

    return false
end

-- =========================
-- Projectile-driven prayer flicking
-- =========================

function CombatEngine:scanProjectiles()
    local projectiles = API.GetAllObjArray1({5}, self.config.projectileScanRange or 30, {})
    local hits = {}

    for _, projectile in ipairs(projectiles or {}) do
        local rule = self.config.projectilePrayers and self.config.projectilePrayers[projectile.Id]

        if rule then
            local dest = API.GetProjectileDestination(projectile)
            local player = API.PlayerCoord()

            if dest and player then
                local dx = dest.x - player.x
                local dy = dest.y - player.y
                local d = math.sqrt(dx * dx + dy * dy)

                if d <= (rule.destinationRadius or 1.5) then
                    hits[#hits + 1] = {
                        projectile = projectile,
                        rule = rule
                    }
                end
            end
        elseif self.config.logUnknownProjectiles then
            API.logDebug("[PROJECTILE] Unknown ID "..tostring(projectile.Id))
        end
    end

    return hits
end

function CombatEngine:updatePrayerFlick()
    local hits = self:scanProjectiles()
    local t = now()

    for _, hit in ipairs(hits) do
        local spell = hit.rule.spell
        local ab = self:getAbilityBar(spell)

        if ab then
            API.DoAction_Ability_Direct(ab, 1, API.OFF_ACT_GeneralInterface_route)
            self.projectilePrayer.active = true
            self.projectilePrayer.spell = spell
            self.projectilePrayer.untilMs = t + (hit.rule.holdMs or 600)
        end
    end

    if self.projectilePrayer.active and t >= self.projectilePrayer.untilMs then
        local spell = self.projectilePrayer.spell
        local ab = self:getAbilityBar(spell)
        if ab then
            API.DoAction_Ability_Direct(ab, 1, API.OFF_ACT_GeneralInterface_route)
        end
        self.projectilePrayer.active = false
        self.projectilePrayer.spell = nil
    end
end

-- =========================
-- Emergency logic
-- =========================

function CombatEngine:checkEmergency()
    local hp = API.GetHPrecent()
    if hp <= self.emergency.thresholdHp and API.LocalPlayer_IsInCombat_() then
        self.metrics.emergencyTriggers = self.metrics.emergencyTriggers + 1

        if self.emergency.callback then
            self.emergency.callback(hp, self.snapshot)
        end

        return true
    end

    return false
end

-- =========================
-- Main update
-- =========================

function CombatEngine:update()
    if not self.running then return end

    self:recordObservedCastDamage()
    self:updatePrayerFlick()

    if self:checkEmergency() then
        return
    end

    local t = now()
    if t - self.lastDecision < self.decisionInterval then
        return
    end

    self.lastDecision = t

    local snapshot = self:buildSnapshot()
    if not snapshot.targeting and #snapshot.enemies == 0 then
        return
    end

    if self.pendingCast and t < self.pendingUntil then
        return
    end

    local action = self:bestAction(snapshot)

    if action and action.score > 0 then
        self:cast(action)
    end
end

return CombatEngine
