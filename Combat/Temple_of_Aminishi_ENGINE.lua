--[[
    TEMPLE OF AMINISHI DUNGEON ENGINE
    Uses the existing ED1 coordinate-offset work as the source of truth.

    This is deliberately separated from combat:
      DungeonEngine decides WHERE/WHEN to fight.
      CombatEngine decides HOW to fight.

    All client calls used below exist in api.lua. Anything requiring discovery
    in the live game is left as a CONFIG/TODO placeholder rather than guessed.
]]

local API = require("api")
local CombatEngine = require("Lib/COMBAT_DYNAMIC")

local DungeonEngine = {}
DungeonEngine.__index = DungeonEngine

local STATE = {
    WAITING = "WAITING",
    OUTSIDE = "OUTSIDE",
    ENTERING = "ENTERING",
    SETUP = "SETUP",
    ROUTING = "ROUTING",
    AGGRO = "AGGRO",
    GROUPING = "GROUPING",
    COMBAT = "COMBAT",
    LOOT = "LOOT",
    EXITING = "EXITING",
    EVACUATING = "EVACUATING",
    RESETTING = "RESETTING",
    STOPPED = "STOPPED"
}

local function now()
    return API.SystemTime()
end

local function alive(npc)
    return npc and npc.Life and npc.Life > 0
end

local function point(x, y, z)
    return WPOINT:new(x, y, z or 0)
end

local function inside(obj, zone)
    if not obj or not obj.Tile_XYZ or not zone then return false end
    local p = obj.Tile_XYZ
    return p.x >= zone.TOP_LEFT.x and p.x <= zone.BOT_RIGHT.x
       and p.y <= zone.TOP_LEFT.y and p.y >= zone.BOT_RIGHT.y
end

local function count(t)
    return t and #t or 0
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
    resetUntilMinibosses = 3,

    -- Emergency evacuation.
    emergencyHpThreshold = 20,

    -- If you later unlock an instant Wars' Retreat teleport, put its EXACT
    -- action-bar ability name here. Leave nil until verified in-game.
    emergencyTeleportAbility = nil, -- TODO: exact action-bar name

    -- Fallback route out of the dungeon.
    -- TODO: populate from your existing navigation offsets / exit tile.
    emergencyExitTile = nil,

    -- Loot chest profit.
    -- The API exposes LootWindow_GetData(), but the exact ED1 reward-chest
    -- interface layout is not specified in api.lua. Leave parser disabled until
    -- you inspect the live chest interface.
    enableChestProfit = false,

    -- Exact token award per miniboss must be verified in-game.
    tokensPerMiniboss = nil, -- TODO: verify exact ED1 miniboss token award

    -- Existing ED1 entrance IDs from your old script.
    templeDoorId = 103952,
    insideDoorId = 111710,

    -- Existing action/offset pair from your old script.
    objectEnterAction = 0x39,
    objectEnterOffset = API.OFF_ACT_GeneralObject_route0,

    npcAttackAction = 0x2a,
    npcAttackOffset = API.OFF_ACT_AttackNPC_route,

    -- Dynamic clustering.
    dynamicClusterMovement = false, -- enable only after validating in-game
    clusterRadius = 4,

    -- =========================================================================
    -- TARGET DEFINITIONS
    -- =========================================================================

    -- Use NAME + ID here when you have discovered the healer/normal IDs.
    -- Until the IDs are filled in, the engine cannot safely distinguish them.
    targets = {
        -- Example shape only; IDs intentionally unknown:
        -- {
        --     name = "Elite Sotapanna",
        --     id = nil, -- TODO: exact NPC ID
        --     priority = 1,
        --     healer = false
        -- }
    },

    -- Names currently known from your existing script.
    minibossNames = {
        "Ahoeitu the Chef",
        "Olivia the Chronicler",
        "Xiang the Water-shaper",
        "Sarkhan the Serpentspeaker",
        "Oyu the Quietest"
    },

    -- =========================================================================
    -- ROUTE
    -- =========================================================================

    -- The existing GitHub script contains your zone BOUNDS, but its current
    -- public version does not contain the AGGRO_TILE/SAFE_TILE assignments.
    -- Keep your existing offsets here rather than recreating them.
    zones = {
        FIRST_STAIRS_FIGHT = {
            name = "First Stairwell",
            topLeft = {24, 8},
            bottomRight = {30, 0},
            aggro = nil, safe = nil -- TODO: paste existing tiles
        },
        RIGHT_SIDE_FIGHT = {
            name = "Right Side",
            topLeft = {25, 0},
            bottomRight = {40, -11},
            aggro = nil, safe = nil -- TODO
        },
        LEFT_SIDE_FIGHT = {
            name = "Left Side",
            topLeft = {26, 19},
            bottomRight = {40, 12},
            aggro = nil, safe = nil -- TODO
        },
        SECOND_STAIRS_FIGHT = {
            name = "Bottom Stairwell",
            topLeft = {48, 14},
            bottomRight = {57, 2},
            aggro = nil, safe = nil -- TODO
        },
        CATHEDRAL_OUTSIDE = {
            name = "Cathedral Outside",
            topLeft = {62, 19},
            bottomRight = {76, 11},
            aggro = nil, safe = nil -- TODO
        },
        CATHEDRAL_INSIDE = {
            name = "Cathedral Inside",
            topLeft = {58, 36},
            bottomRight = {75, 24},
            aggro = nil, safe = nil -- TODO
        },
        SARKHAN_MINIBOSS = {
            name = "Sarkhan Miniboss",
            topLeft = {63, 43},
            bottomRight = {70, 39},
            aggro = nil, safe = nil -- TODO
        },
        XIANG_MINIBOSS = {
            name = "Xiang Miniboss",
            topLeft = {81, 10},
            bottomRight = {85, 7},
            aggro = nil, safe = nil -- TODO
        },
        OLIVIA_MINIBOSS = {
            name = "Olivia Miniboss",
            topLeft = {94, 9},
            bottomRight = {101, -1},
            aggro = nil, safe = nil -- TODO
        },
        TRAINING_GROUP = {
            name = "Training Group",
            topLeft = {80, 27},
            bottomRight = {98, 8},
            aggro = nil, safe = nil -- TODO
        },
        CATHEDRAL_OUTSIDE_TWO = {
            name = "Cathedral Outside Back",
            topLeft = {77, 35},
            bottomRight = {89, 25},
            aggro = nil, safe = nil -- TODO
        },
        OYU_MINIBOSS = {
            name = "Oyu Miniboss",
            topLeft = {90, 37},
            bottomRight = {97, 33},
            aggro = nil, safe = nil -- TODO
        },
        KITCHEN_OUTSIDE = {
            name = "Outside Kitchen",
            topLeft = {69, 0},
            bottomRight = {93, -11},
            aggro = nil, safe = nil -- TODO
        },
        AHOEITU_MINIBOSS = {
            name = "Ahoeitu Miniboss",
            topLeft = {92, -16},
            bottomRight = {104, -24},
            aggro = nil, safe = nil -- TODO
        },
        KITCHEN_OUTSIDE_TWO = {
            name = "Outside Kitchen Far",
            topLeft = {63, -11},
            bottomRight = {69, -16},
            aggro = nil, safe = nil -- TODO
        },
        LAST_GROUP = {
            name = "Bottom Stairwell Last",
            topLeft = {48, 1},
            bottomRight = {61, -5},
            aggro = nil, safe = nil -- TODO
        }
    }
}

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

function DungeonEngine.new(config)
    local self = setmetatable({}, DungeonEngine)

    self.config = config or CONFIG
    self.state = STATE.WAITING
    self.startX = nil
    self.startY = nil
    self.currentZone = nil
    self.currentZoneIndex = 1
    self.combat = CombatEngine.new({
        emergencyHpThreshold = self.config.emergencyHpThreshold,
        defaultAoeRadius = self.config.clusterRadius
    })

    self.metrics = {
        sessionStart = now(),
        runs = 0,
        minibossKills = 0,
        lastRunStart = nil,
        lastRunMs = 0,
        totalRunMs = 0,
        lootValue = 0,
        lootRuns = 0
    }

    self.minibossSeen = {}
    self.minibossAlive = {}
    self.runMinibossCount = 0
    self.lastLootRead = 0
    self.evacuating = false

    self.combat:setEmergencyCallback(function()
        self:beginEvacuation("combat emergency")
    end)

    return self
end

-- ============================================================================
-- EXISTING OFFSET SYSTEM
-- ============================================================================

function DungeonEngine:setupOffsets()
    local coords = API.PlayerCoord()
    self.startX = coords.x
    self.startY = coords.y

    -- Convert the existing relative bounds into live WPOINTs.
    for _, zone in pairs(self.config.zones) do
        zone.TOP_LEFT = point(self.startX + zone.topLeft[1], self.startY + zone.topLeft[2], 0)
        zone.BOT_RIGHT = point(self.startX + zone.bottomRight[1], self.startY + zone.bottomRight[2], 0)

        if zone.aggro then
            zone.AGGRO_TILE = point(self.startX + zone.aggro[1], self.startY + zone.aggro[2], zone.aggro[3] or 0)
        end

        if zone.safe then
            zone.SAFE_TILE = point(self.startX + zone.safe[1], self.startY + zone.safe[2], zone.safe[3] or 0)
        end
    end
end

function DungeonEngine:inZone(zone)
    local p = API.PlayerCoord()
    return p and p.x >= zone.TOP_LEFT.x and p.x <= zone.BOT_RIGHT.x
       and p.y <= zone.TOP_LEFT.y and p.y >= zone.BOT_RIGHT.y
end

-- ============================================================================
-- TARGET SCANNING / HEALER IDENTIFICATION
-- ============================================================================

function DungeonEngine:scanNPCs()
    return API.ReadAllObjectsArray({1}, {-1}, {})
end

function DungeonEngine:configuredTarget(npc)
    for _, rule in ipairs(self.config.targets or {}) do
        if npc.Name == rule.name then
            if rule.id == nil or npc.Id == rule.id then
                return rule
            end
        end
    end
    return nil
end

function DungeonEngine:buildPriorityTable()
    local priority = {}

    for _, rule in ipairs(self.config.targets or {}) do
        if rule.id then
            -- Combat engine accepts a name+ID rule through the rule field.
            -- We create a unique key so same-name NPC variants can coexist.
            priority[rule.name .. "#" .. tostring(rule.id)] = {
                rule = {name = rule.name, id = rule.id},
                weight = rule.priority or 100
            }
        else
            priority[rule.name] = rule.priority or 100
        end
    end

    -- The dynamic engine consumes a simple priority table. For ID-specific
    -- entries we additionally install the rule list directly.
    local simple = {}
    for _, rule in ipairs(self.config.targets or {}) do
        simple[rule.name] = math.min(simple[rule.name] or math.huge, rule.priority or 100)
    end

    self.combat:setPriorityList(simple)
end

function DungeonEngine:findHealers()
    local healers = {}

    for _, npc in ipairs(self:scanNPCs()) do
        if alive(npc) then
            for _, rule in ipairs(self.config.targets or {}) do
                if rule.healer and npc.Name == rule.name and npc.Id == rule.id then
                    healers[#healers + 1] = npc
                end
            end
        end
    end

    return healers
end

function DungeonEngine:targetExistsInZone(zone)
    for _, npc in ipairs(self:scanNPCs()) do
        if alive(npc) and inside(npc, zone) and self:configuredTarget(npc) then
            return true
        end
    end
    return false
end

function DungeonEngine:zoneCleared(zone)
    return not self:targetExistsInZone(zone)
end

-- ============================================================================
-- CLUSTERING / MOVEMENT
-- ============================================================================

function DungeonEngine:chooseClusterAnchor(zone)
    local npcs = {}

    for _, npc in ipairs(self:scanNPCs()) do
        if alive(npc) and inside(npc, zone) and self:configuredTarget(npc) then
            npcs[#npcs + 1] = npc
        end
    end

    if #npcs == 0 then return nil end

    local best, bestScore

    for _, candidate in ipairs(npcs) do
        local score = 0
        for _, other in ipairs(npcs) do
            local dx = candidate.Tile_XYZ.x - other.Tile_XYZ.x
            local dy = candidate.Tile_XYZ.y - other.Tile_XYZ.y
            local d = math.sqrt(dx * dx + dy * dy)

            if d <= self.config.clusterRadius then
                score = score + (1 / math.max(1, d))
            end
        end

        if not bestScore or score > bestScore then
            best = candidate
            bestScore = score
        end
    end

    return best
end

function DungeonEngine:moveTo(tile)
    if not tile then return false end
    return API.DoAction_WalkerW(tile)
end

function DungeonEngine:runToAggroTile()
    local zone = self.currentZone
    if not zone or not zone.AGGRO_TILE then
        API.logWarn("[ED1] AGGRO_TILE missing. Paste your existing navigation offset.")
        return false
    end

    return self:moveTo(zone.AGGRO_TILE)
end

function DungeonEngine:runToSafeTile()
    local zone = self.currentZone
    if not zone or not zone.SAFE_TILE then
        API.logWarn("[ED1] SAFE_TILE missing. Paste your existing navigation offset.")
        return false
    end

    return self:moveTo(zone.SAFE_TILE)
end

-- ============================================================================
-- ENCOUNTER CONTROL
-- ============================================================================

function DungeonEngine:beginZone(zone)
    self.currentZone = zone
    self.state = STATE.AGGRO
    self.combat:resetEncounter()
    self:buildPriorityTable()

    API.logInfo("[ED1] Starting "..zone.name)
end

function DungeonEngine:updateAggro()
    if self:runToAggroTile() then
        self.state = STATE.GROUPING
    else
        -- If the old script's aggro tile has not been pasted yet, stop instead
        -- of blindly improvising navigation.
        self.state = STATE.STOPPED
    end
end

function DungeonEngine:updateGrouping()
    if not self:runToSafeTile() then
        self.state = STATE.STOPPED
        return
    end

    self.state = STATE.COMBAT
    self.combat:start()
end

function DungeonEngine:updateCombat()
    self.combat:update()

    if self.evacuating then
        return
    end

    if self.currentZone and self:zoneCleared(self.currentZone) then
        self.combat:stop()
        self.state = STATE.LOOT
    end
end

-- ============================================================================
-- MINIBOSS ACCOUNTING
-- ============================================================================

function DungeonEngine:scanMinibosses()
    local found = {}

    for _, npc in ipairs(self:scanNPCs()) do
        if alive(npc) then
            for _, name in ipairs(self.config.minibossNames) do
                if npc.Name == name then
                    found[name .. "#" .. tostring(npc.Id)] = {
                        name = name,
                        id = npc.Id,
                        object = npc
                    }
                end
            end
        end
    end

    return found
end

function DungeonEngine:updateMinibossMetrics()
    local nowAlive = self:scanMinibosses()

    for key, data in pairs(self.minibossAlive) do
        if not nowAlive[key] then
            self.metrics.minibossKills = self.metrics.minibossKills + 1
            self.runMinibossCount = self.runMinibossCount + 1
        end
    end

    self.minibossAlive = nowAlive
end

function DungeonEngine:countVisibleMinibosses()
    local found = self:scanMinibosses()
    local n = 0
    for _ in pairs(found) do n = n + 1 end
    return n
end

-- ============================================================================
-- LOOT / PROFIT
-- ============================================================================

function DungeonEngine:readChestProfit()
    if not self.config.enableChestProfit then
        return nil
    end

    -- TODO:
    -- Inspect API.LootWindow_GetData() in the live ED1 reward chest and determine
    -- exactly which IInfo fields correspond to item ID and stack quantity.
    -- Once verified, use API.GetExchangePrice(itemId) to calculate GE value.
    --
    -- DO NOT guess the interface layout.
    return nil
end

function DungeonEngine:updateLootMetrics()
    local value = self:readChestProfit()

    if value then
        self.metrics.lootValue = self.metrics.lootValue + value
        self.metrics.lootRuns = self.metrics.lootRuns + 1
    end
end

-- ============================================================================
-- EMERGENCY EVACUATION
-- ============================================================================

function DungeonEngine:beginEvacuation(reason)
    if self.evacuating then return end

    self.evacuating = true
    self.state = STATE.EVACUATING
    self.combat:stop()

    API.logWarn("[ED1] EMERGENCY EVACUATION: "..tostring(reason))

    local abilityName = self.config.emergencyTeleportAbility

    if abilityName then
        local ab = API.GetABs_name(abilityName, true)
        if ab and ab.enabled ~= false and (not ab.cooldown_timer or ab.cooldown_timer <= 0) then
            if API.DoAction_Ability_Direct(ab, 1, API.OFF_ACT_GeneralInterface_route) then
                API.logInfo("[ED1] Emergency teleport activated.")
                return
            end
        end
    end

    -- Fallback: run out of the dungeon.
    if self.config.emergencyExitTile then
        self:moveTo(self.config.emergencyExitTile)
    else
        API.logError("[ED1] No emergency teleport and no emergencyExitTile configured.")
        API.Write_LoopyLoop(false)
    end
end

function DungeonEngine:updateEvacuation()
    if self.config.emergencyExitTile then
        self:moveTo(self.config.emergencyExitTile)
    else
        API.Write_LoopyLoop(false)
    end
end

-- ============================================================================
-- ENTER / RESET
-- ============================================================================

function DungeonEngine:isInside()
    local doors = API.ReadAllObjectsArray({12}, {self.config.insideDoorId}, {})
    return count(doors) > 0
end

function DungeonEngine:enterDungeon()
    local ok = API.DoAction_Object1(
        self.config.objectEnterAction,
        self.config.objectEnterOffset,
        {self.config.templeDoorId},
        25
    )

    if not ok then
        API.logWarn("[ED1] Could not interact with entrance.")
        return false
    end

    return true
end

function DungeonEngine:resetDungeon()
    -- The old script already documents the exact dialog text. We retain that
    -- logic rather than inventing a new reset API.
    while API.Check_Dialog_Open() do
        local text = API.Dialog_Read_NPC()

        if text == "Discard the progress you made with your last group?" then
            local option = API.Dialog_Option("Yes.")
            API.KeyboardPress(tostring(tonumber(option)), 50, 250)
        elseif text == "Do you want to continue from where you left off?" then
            local option = API.Dialog_Option("No.")
            API.KeyboardPress(tostring(tonumber(option)), 50, 250)
        elseif text == "Would you like to enter The Temple of Aminishi?" then
            local option = API.Dialog_Option("Normal mode")
            API.KeyboardPress(tostring(tonumber(option)), 50, 250)
        else
            -- Unknown dialog: stop rather than click blindly.
            API.logWarn("[ED1] Unknown reset dialog. Manual discovery required.")
            return false
        end

        API.RandomSleep2(600, 0, 250)
    end

    return true
end

function DungeonEngine:beginRun()
    self.metrics.lastRunStart = now()
    self.runMinibossCount = 0
    self.minibossAlive = {}
    self.currentZoneIndex = 1
    self.evacuating = false
end

function DungeonEngine:finishRun()
    if self.metrics.lastRunStart then
        self.metrics.lastRunMs = now() - self.metrics.lastRunStart
        self.metrics.totalRunMs = self.metrics.totalRunMs + self.metrics.lastRunMs
        self.metrics.runs = self.metrics.runs + 1
    end

    self:updateLootMetrics()
    self.state = STATE.RESETTING
end

-- ============================================================================
-- METRICS
-- ============================================================================

function DungeonEngine:runsPerHour()
    local elapsed = math.max(1, now() - self.metrics.sessionStart)
    return self.metrics.runs * 3600000 / elapsed
end

function DungeonEngine:profitPerHour()
    local elapsed = math.max(1, now() - self.metrics.sessionStart)
    return self.metrics.lootValue * 3600000 / elapsed
end

function DungeonEngine:tokenCount()
    if not self.config.tokensPerMiniboss then
        return nil
    end
    return self.metrics.minibossKills * self.config.tokensPerMiniboss
end

function DungeonEngine:metricsTable()
    local tokens = self:tokenCount()

    return {
        {"State", self.state},
        {"Runs", tostring(self.metrics.runs)},
        {"Runs/hr", string.format("%.2f", self:runsPerHour())},
        {"Miniboss kills", tostring(self.metrics.minibossKills)},
        {"DG tokens", tokens and tostring(tokens) or "CONFIG REQUIRED"},
        {"Profit", tostring(self.metrics.lootValue)},
        {"Profit/hr", string.format("%.0f", self:profitPerHour())},
        {"Zone", self.currentZone and self.currentZone.name or "-"}
    }
end

-- ============================================================================
-- MAIN STATE MACHINE
-- ============================================================================

function DungeonEngine:update()
    if self.state == STATE.STOPPED then return end

    self:updateMinibossMetrics()

    if self.state == STATE.EVACUATING then
        self:updateEvacuation()
        return
    end

    if self.state == STATE.WAITING then
        if not API.PlayerLoggedIn() then return end
        self.state = STATE.OUTSIDE
    end

    if self.state == STATE.OUTSIDE then
        self:beginRun()

        if not self:isInside() then
            self:enterDungeon()
            self.state = STATE.ENTERING
            return
        end

        self.state = STATE.SETUP
        return
    end

    if self.state == STATE.ENTERING then
        if self:isInside() then
            self.state = STATE.SETUP
        end
        return
    end

    if self.state == STATE.SETUP then
        self:setupOffsets()

        local visibleMinis = self:countVisibleMinibosses()
        if visibleMinis < self.config.resetUntilMinibosses then
            self.state = STATE.RESETTING
            return
        end

        self.currentZoneIndex = 1
        self.state = STATE.ROUTING
        return
    end

    if self.state == STATE.ROUTING then
        local ordered = {
            self.config.zones.FIRST_STAIRS_FIGHT,
            self.config.zones.RIGHT_SIDE_FIGHT,
            self.config.zones.LEFT_SIDE_FIGHT,
            self.config.zones.SECOND_STAIRS_FIGHT,
            self.config.zones.CATHEDRAL_OUTSIDE,
            self.config.zones.CATHEDRAL_INSIDE,
            self.config.zones.SARKHAN_MINIBOSS,
            self.config.zones.XIANG_MINIBOSS,
            self.config.zones.OLIVIA_MINIBOSS,
            self.config.zones.TRAINING_GROUP,
            self.config.zones.CATHEDRAL_OUTSIDE_TWO,
            self.config.zones.OYU_MINIBOSS,
            self.config.zones.KITCHEN_OUTSIDE,
            self.config.zones.AHOEITU_MINIBOSS,
            self.config.zones.KITCHEN_OUTSIDE_TWO,
            self.config.zones.LAST_GROUP
        }

        self.route = self.route or ordered

        local zone = self.route[self.currentZoneIndex]

        if not zone then
            self:finishRun()
            return
        end

        if self:targetExistsInZone(zone) then
            self:beginZone(zone)
        else
            self.currentZoneIndex = self.currentZoneIndex + 1
        end

        return
    end

    if self.state == STATE.AGGRO then
        self:updateAggro()
        return
    end

    if self.state == STATE.GROUPING then
        self:updateGrouping()
        return
    end

    if self.state == STATE.COMBAT then
        self:updateCombat()

        if self.state == STATE.LOOT then
            return
        end

        return
    end

    if self.state == STATE.LOOT then
        self:updateLootMetrics()
        self.currentZoneIndex = self.currentZoneIndex + 1
        self.state = STATE.ROUTING
        return
    end

    if self.state == STATE.RESETTING then
        if self:isInside() then
            -- TODO: paste/verify the exact ED1 exit object/action if reset requires
            -- a physical exit before the dungeon can be restarted.
            if self.config.emergencyExitTile then
                self:moveTo(self.config.emergencyExitTile)
            else
                API.logWarn("[ED1] Exit tile not configured; stopping before reset.")
                self.state = STATE.STOPPED
            end
        else
            self.state = STATE.OUTSIDE
        end
        return
    end
end

return DungeonEngine
