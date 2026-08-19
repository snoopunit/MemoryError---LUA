print("Run Lua script Mining_Guild_Runite.")

local API = require("api")

-- ============================================================
-- Mining Guild Runite
-- ============================================================

-- Runite rocks
local Runite_Rocks = {
    113066,
    113067,
    113065
}

local Runite_Location = WPOINT:new(3033, 9737, 1)

-- Mining Guild door
local Mining_Guild_Door = WPOINT:new(3046, 9756, 1)

-- Resource dungeon entrance
local Mysterious_Entrance = WPOINT:new(3033, 9772, 1)

-- Resource dungeon side / bank deposit box
local Deposit_Box = WPOINT:new(1042, 4578, 3)

-- Resource dungeon exit
local Mysterious_Door = WPOINT:new(1040, 4576, 3)

local totalOresMined = 0
local lastOreCount = 0
local startTime = API.SystemTime()
local lastClick = 0

-- ============================================================
-- Utility
-- ============================================================

local function currentOres()
    -- Runite ore ID
    return Inventory:GetItemAmount(451)
end

local function walkToObject(coords)
    API.DoAction_WalkerW(coords)
    API.RandomSleep2(1200, 0, 600)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(800, 300, 800)
end

-- ============================================================
-- Runite mining
-- ============================================================

local function clickRockertunity()
    local rockertunity = API.ReadAllObjectsArray(
        {4},
        {7164, 7165},
        {}
    )

    if #rockertunity < 1 then
        return
    end

    local r = rockertunity[1]

    API.logDebug(
        "Found rockertunity at "
        .. tostring(r.TileX)
        .. ","
        .. tostring(r.TileY)
    )

    local runiteRocks = API.ReadAllObjectsArray(
        {0},
        Runite_Rocks,
        {"Runite rock"}
    )

    if #runiteRocks < 1 then
        return
    end

    local closestRock = nil
    local closestDist = math.huge

    for _, rock in ipairs(runiteRocks) do
        local dist =
            math.abs(r.TileX - rock.TileX)
            + math.abs(r.TileY - rock.TileY)

        if dist < closestDist then
            closestDist = dist
            closestRock = rock
        end
    end

    if closestRock then
        if API.DoAction_Object_Direct(
            0x3a,
            API.OFF_ACT_GeneralObject_route0,
            closestRock
        ) then
            API.RandomSleep2(1200, 600, 1200)
            API.WaitUntilMovingEnds()
            API.RandomSleep2(2400, 0, 600)
        end
    end
end

local function mine()
    if (API.SystemTime() - lastClick) < 2400 then
        return
    end

    Interact:Object("Runite rock", "Mine", 20)

    lastClick = API.SystemTime()
end

-- ============================================================
-- Ore box
-- ============================================================

local function fillBox()
    local count = Inventory:FreeSpaces()

    local boxAB = API.GetABs_name("ore box", false)

    if boxAB.action == "Fill" and boxAB.enabled then
        API.DoAction_Ability_Direct(
            boxAB,
            1,
            API.OFF_ACT_GeneralInterface_route
        )
    end

    API.RandomSleep2(1200, 600, 1200)

    if count < Inventory:FreeSpaces() then
        lastOreCount = currentOres()
        return true
    end

    return false
end

-- ============================================================
-- Door / entrance traversal
-- ============================================================

local function openMiningGuildDoor()
    API.logDebug("Opening Mining Guild Door.")

    walkToObject(Mining_Guild_Door)

    local success = Interact:Object(
        "Door",
        "Open",
        30
    )

    if not success then
        API.logDebug("Failed to interact with Mining Guild Door.")
        return false
    end

    API.RandomSleep2(1200, 600, 1200)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(1000, 500, 1000)

    return true
end

local function enterResourceDungeon()
    API.logDebug("Entering Resource Dungeon.")

    walkToObject(Mysterious_Entrance)

    local success = Interact:Object(
        "Mysterious entrance",
        "Enter",
        30
    )

    if not success then
        API.logDebug("Failed to interact with Mysterious entrance.")
        return false
    end

    API.RandomSleep2(1800, 800, 1500)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(1200, 600, 1200)

    return true
end

local function exitResourceDungeon()
    API.logDebug("Exiting Resource Dungeon.")

    walkToObject(Mysterious_Door)

    local success = Interact:Object(
        "Mysterious door",
        "Exit",
        30
    )

    if not success then
        API.logDebug("Failed to interact with Mysterious door.")
        return false
    end

    API.RandomSleep2(1800, 800, 1500)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(1200, 600, 1200)

    return true
end

-- ============================================================
-- Banking
--
-- IMPORTANT:
-- Deposit route:
--     Door -> Mysterious entrance -> Deposit box
--
-- Return route:
--     Mysterious door -> Door -> Runite
-- ============================================================

local function goToBank()
    API.logDebug("Starting banking traversal.")

    -- STEP 1:
    -- Mining Guild -> outside
    if not openMiningGuildDoor() then
        return false
    end

    -- STEP 2:
    -- Outside -> Resource Dungeon
    if not enterResourceDungeon() then
        return false
    end

    -- STEP 3:
    -- Resource Dungeon -> Deposit Box
    API.logDebug("Walking to Bank Deposit Box.")

    walkToObject(Deposit_Box)

    return true
end

local function deposit()
    local failTimer = API.SystemTime()

    while Inventory:FreeSpaces() < 4
        and API.Read_LoopyLoop()
    do
        local success = Interact:Object(
            "Bank deposit box",
            "Deposit",
            30
        )

        if success then
            API.RandomSleep2(1000, 500, 1000)
        end

        if API.SystemTime() - failTimer > 30000 then
            print("Failed to deposit ores after 30 seconds.")
            return false
        end
    end

    API.RandomSleep2(1000, 500, 1000)

    return true
end

local function returnToMine()
    API.logDebug("Starting return traversal.")

    -- STEP 1:
    -- Resource Dungeon -> outside
    if not exitResourceDungeon() then
        return false
    end

    -- STEP 2:
    -- Outside -> Mining Guild
    if not openMiningGuildDoor() then
        return false
    end

    -- STEP 3:
    -- Mining Guild -> Runite
    API.logDebug("Returning to Runite rocks.")

    walkToObject(Runite_Location)

    return true
end

-- ============================================================
-- Metrics
-- ============================================================

local function OresPerHour()
    local elapsed = API.SystemTime() - startTime

    if elapsed <= 0 then
        return 0
    end

    return math.floor(
        (totalOresMined * 60)
        / (elapsed / 60000)
    )
end

local function updateOreMined()
    local count = currentOres()

    if count > lastOreCount then
        totalOresMined =
            totalOresMined
            + (count - lastOreCount)

        lastOreCount = count
    end
end

-- ============================================================
-- Initialization
-- ============================================================

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

lastOreCount = currentOres()

-- ============================================================
-- Main loop
-- ============================================================

while API.Read_LoopyLoop() do

    if not API.PlayerLoggedIn() then
        print("Player is not logged in. Terminating script.")
        return
    end

    -- ========================================================
    -- INVENTORY FULL
    -- ========================================================

    if Inventory:IsFull() then

        API.logDebug("Inventory full. Starting banking sequence.")

        -- Deposit traversal:
        --
        -- Door
        --   ↓
        -- Mysterious entrance
        --   ↓
        -- Bank deposit box
        --
        if goToBank() then

            if deposit() then

                API.logDebug("Deposit successful.")

                -- Return traversal:
                --
                -- Mysterious door
                --   ↓
                -- Door
                --   ↓
                -- Runite rocks
                --
                returnToMine()

            end

        end

    -- ========================================================
    -- MINING
    -- ========================================================

    else

        -- Keep ore box topped up while mining.
        if Inventory:FreeSpaces() < math.random(2, 8) then
            fillBox()
        end

        clickRockertunity()

        mine()

    end

    updateOreMined()

    -- ========================================================
    -- METRICS
    -- ========================================================

    local metrics = {
        {"Script", "Mining Guild Runite"},
        {"Total Ores:", totalOresMined},
        {"Ores/H:", OresPerHour()},
        {
            "Est. Profit:",
            (totalOresMined * API.GetExchangePrice(451)) .. "gp"
        },
        {
            "Profit/H:",
            (function()
                local elapsed =
                    (API.SystemTime() - startTime)
                    / 3600000

                if elapsed > 0 then
                    return math.floor(
                        (
                            totalOresMined
                            * API.GetExchangePrice(451)
                        ) / elapsed
                    ) .. "gp"
                else
                    return "0gp"
                end
            end)()
        }
    }

    API.DrawTable(metrics)

    API.DoRandomEvents()

    API.RandomSleep2(600, 0, 250)

    -- Stop after two hours, matching the original script.
    local elapsedTime =
        API.SystemTime() - startTime

    if elapsedTime > (3600000 * 2) then
        print("2 hours have passed. Terminating Script.")
        API.Write_LoopyLoop(false)
    end

end