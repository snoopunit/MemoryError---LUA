print("Run Lua script Mining_Guild_Runite.")

local API = require("api")

local RUNITE = {
    ORE = 451,
    ROCK = {113066,113067,113065},
}
local gePrice = API.GetExchangePrice(RUNITE.ORE)

local Deposit_Box_ID = 25937

local Runite_Location = WPOINT:new(3033, 9737, 1)
local Mining_Guild_Door = WPOINT:new(3046, 9756, 1)
local Mysterious_Entrance = WPOINT:new(3033, 9772, 1)
local Deposit_Box = WPOINT:new(1042, 4578, 3)
local Mysterious_Door = WPOINT:new(1040, 4576, 3)

local totalOresMined = 0
local lastOreCount = 0
local startTime = API.SystemTime()
local lastClick = 0

local function currentOres()
    return Inventory:GetItemAmount(451)
end

local function walkToObject(coords)
    API.DoAction_WalkerW(coords)
    API.RandomSleep2(1200, 0, 600)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(800, 300, 800)
end

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
        RUNITE.ROCK,
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
        API.RandomSleep2(800, 0, 1200)
        if API.DoAction_Object_Direct(
            0x3a,
            API.OFF_ACT_GeneralObject_route0,
            closestRock
        ) then
            API.RandomSleep2(1200, 600, 1200)
            API.WaitUntilMovingEnds()
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

local function goToBank()
    API.logDebug("Starting banking traversal.")

    if not openMiningGuildDoor() then
        return false
    end

    if not enterResourceDungeon() then
        return false
    end

    API.logDebug("Walking to Bank Deposit Box.")
    walkToObject()

    return true
end

function useOreBox()
    if API.DoAction_Interface(0x24,0xaef1,0,1473,5,0,API.OFF_ACT_Bladed_interface_route) then
        API.RandomSleep2(600, 250, 600)
        return true
    else
        API.logDebug("Failed to use ore box.")
        return false
    end
end

function useDepositBox()
    if API.DoAction_Object1(0x24,API.OFF_ACT_GeneralObject_route00,{ Deposit_Box_ID },50) then
        API.RandomSleep2(600, 250, 600)
        API.WaitUntilMovingEnds()
        return true
    else
        API.logDebug("Failed to use deposit box.")
        return false
    end
end

function deposit()

    useOreBox()
    useDepositBox()
    fillBox()
    useOreBox()
    useDepositBox()
    
end

local function returnToMine()
    if not exitResourceDungeon() then
        return false
    end

    if not openMiningGuildDoor() then
        return false
    end

    API.logDebug("Returning to Runite rocks.")
    walkToObject(Runite_Location)

    return true
end

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

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

lastOreCount = currentOres()

while API.Read_LoopyLoop() do

    if not API.PlayerLoggedIn() then
        print("Player is not logged in. Terminating script.")
        return
    end

    if Inventory:IsFull() then

        API.logDebug("Inventory full. Starting banking sequence.")

        if goToBank() then
            if deposit() then

                API.logDebug("Deposit successful.")
                returnToMine()

            end
        end

    else

        if Inventory:FreeSpaces() < math.random(2, 8) then
            fillBox()
        end

        clickRockertunity()
        mine()

    end

    updateOreMined()

    local metrics = {
        {"Script", "Mining Guild Runite"},
        {"Total Ores:", totalOresMined},
        {"Ores/H:", OresPerHour()},
        {
            "Est. Profit:",
            (totalOresMined * gePrice) .. "gp"
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
                            * gePrice
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

    local elapsedTime =
        API.SystemTime() - startTime

    if elapsedTime > (3600000 * 2) then
        print("2 hours have passed. Terminating Script.")
        API.Write_LoopyLoop(false)
    end

end
