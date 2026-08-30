print("Run Lua script Mining_Guild_Runite.")

local API = require("api")

local RUNITE = {
    ORE = 451,
    ROCK = {113066,113067,113065},
}
local gePrice = API.GetExchangePrice(RUNITE.ORE)

local Deposit_Box_ID = 25937
local Mining_Guild_Door_ID = 2112
local Mysterious_Entrance_ID = 52855
local Mysterious_Door_ID = 52864

local Entrance_Anim_Up = 13288
local Entrance_Anim_Down = 13285

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

local function isInsideMiningGuild()

    local door = API.ReadAllObjectsArray({12}, {Mining_Guild_Door_ID}, {"Door"})

    if not door or #door ~= 1 then
        API.logDebug("Unable to locate Mining Guild Door <object>")
        return false
    end

    local playerCoords = API.PlayerCoord()

    if math.floor(playerCoords.y) > Mining_Guild_Door.y then 
        return "outside"
    else
        return "inside"
    end

end

local function isInsideResourceDungeon()

    local dungeonExit = API.ReadAllObjectsArray({0}, {Mysterious_Door_ID}, {"Mysterious Door"})
    local bankDepositBox = API.ReadAllObjectsArray({12}, {Deposit_Box_ID}, {"Bank deposit box"})

    if dungeonExit and bankDepositBox then
        return true
    else
        return false
    end

end

local function openMiningGuildDoor()
    API.logDebug("Opening Mining Guild Door.")
    return Interact:Object("Door", "Open", 30)
end

local function enterResourceDungeon()
    API.logDebug("Entering Resource Dungeon.")
    return Interact:Object("Mysterious entrance","Enter",30)
end

local function exitResourceDungeon()
    API.logDebug("Exiting Resource Dungeon.")
    return Interact:Object("Mysterious door","Exit",30)
end

local function goToBank()
    API.logDebug("Starting banking traversal.")

    while isInsideMiningGuild() == "inside" and API.Read_LoopyLoop() do
        if not openMiningGuildDoor() then 
            API.logWarn("Unable to open the mining guild door!")
            return false
        end
        API.RandomSleep2(600, 0, 250)
    end

    while isInsideMiningGuild() == "outside" and API.Read_LoopyLoop() do
        if not enterResourceDungeon() then 
            API.logWarn("Unable to open the resource dungeon entrance!")
            return false
        end
        if API.ReadPlayerAnim() == Entrance_Anim_Up or API.ReadPlayerAnim() == Entrance_Anim_Down then
            API.RandomSleep2(600, 0, 250)
            break
        end
        API.RandomSleep2(600, 0, 250)
    end
    
    return isInsideResourceDungeon()

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

    local before = Inventory:FreeSpaces()
    
    if not useOreBox() then
        return false
    end
    if not useDepositBox() then
        return false
    end
    
    API.RandomSleep2(1200, 0, 600)
    
    if not fillBox() then
        return false
    end
    
    if not useOreBox() then
        return false
    end
    if not useDepositBox() then
        return false
    end

    local after = Inventory:FreeSpaces()

    if before ~= after then
        return true
    else
        return false
    end
    
end

local function returnToMine()
    API.logDebug("Returning to Runite rocks.")

    while isInsideResourceDungeon() and API.Read_LoopyLoop() do
        if not exitResourceDungeon() then 
            API.logWarn("Unable to open the resource dungeon exit!")
            return false
        end
        API.RandomSleep2(1600, 0, 1250)
        if API.ReadPlayerAnim() == Entrance_Anim_Up or API.ReadPlayerAnim() == Entrance_Anim_Down then
            API.RandomSleep2(600, 0, 250)
            break
        end
    end
    
    while isInsideMiningGuild() == "outside" and API.Read_LoopyLoop() do
        if not openMiningGuildDoor() then 
            API.logWarn("Unable to open the mining guild door!")
            return false
        end
        API.RandomSleep2(600, 0, 250)
    end
    
    return isInsideMiningGuild() == "inside"
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
            else
                API.logDebug("Failed to deposit!")    
                API.Write_LoopyLoop(false)
                return
            end
        else
            API.logDebug("Failed to go to bank!")    
            API.Write_LoopyLoop(false)
            return    
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
