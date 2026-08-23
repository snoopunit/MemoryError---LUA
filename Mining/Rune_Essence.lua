print("Rune Essence & Air RC.")

local API = require("api")
local LODESTONES = require("lodestones")

--local gePrice = API.GetExchangePrice()

local Aubury_Door = WPOINT:new(3253, 3398, 2)

local Aubury_Shop = {
    WPOINT:new(3252, 3401, 2),
    WPOINT:new(3252, 3402, 2),
    WPOINT:new(3253, 3401, 2),
    WPOINT:new(3253, 3402, 2),
}

local Air_Altar = {
    Location = WPOINT:new(3127, 3405, 3),
    ID = 2452
}

local totalOresMined = 0
local lastOreCount = 0
local startTime = API.SystemTime()
local lastClick = 0

local function currentOres()
    return Inventory:GetItemAmount(451)
end

local function walkToObject(coords)
    API.DoAction_WalkerW(coords)
    API.RandomSleep2(2400, 0, 600)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(800, 300, 800)
end

local function isAtVarrockLodestone()
    local playerLoc = API.PlayerCoord()
    if playerLoc.x == 3214 and playerLoc.y == 3376 then
        return true
    else
        return false
    end
end

local function varrockTeleport()
    API.WaitUntilMovingandAnimEnds()
    local failTimer = API.SystemTime()

    while not isAtVarrockLodestone() and API.Read_LoopyLoop() do
        if LODESTONES.VARROCK.Teleport() then
            API.RandomSleep2(1000, 0, 500)
        end
        if (API.SystemTime() - failTimer) > 25000 then
            print("Failed to teleport to Varrock after 15 seconds. Exiting.")
            return false
        end
    end

    return true
    
end

local function findAuburyDoor(obj)
    local doors = API.ReadAllObjectsArray({12},{24384},{"Door"})

    if not doors or #doors < 1 then
        API.logDebug("No doors found.")
        return false
    end

    for _, object in ipairs(doors) do
        
        if math.floor(object.Tile_XYZ.x) == Aubury_Door.x and math.floor(object.Tile_XYZ.y) == Aubury_Door.y then
            if obj then
                return object
            else
                return true
            end
        end
    end

    return false
end

local function isAuburyDoorOpen()
    local door = findAuburyDoor(true)

    if not door then
        return false
    end

    return door.Bool1 == 1
end

local function openAuburyDoor()
    local door = findAuburyDoor(true)

    if not door then
        API.logDebug("Aubury door was not found.")
        return false
    end

    if door.Bool1 == 1 then
        return true
    else 
        API.logDebug("Aubury door is closed. Attempting to open.")
        local success = API.DoAction_Object_Direct(0x31, API.OFF_ACT_GeneralObject_route0, door)
        API.RandomSleep2(800, 0, 400)
        API.WaitUntilMovingEnds()
        if success then 
            return true
        end
    end

    return false
end

local function moveToAuburyShop()
    local coords = Aubury_Shop[math.random(1, #Aubury_Shop)]
    walkToObject(coords)
end

local function teleportAubury()

    moveToAuburyShop()

    if not isAuburyDoorOpen() then
        openAuburyDoor()
    end

    local success = Interact:NPC("Aubury", "Teleport", 20)
    API.RandomSleep2(2400, 0, 1200)
    API.WaitUntilMovingEnds()
    if success then 
        API.logDebug("Successfully teleported to Aubury.")
        return true
    else
        API.logDebug("Failed to teleport to Aubury.")
        return false
    end

end

local function mineEssence()

    API.WaitUntilMovingandAnimEnds()
    
    local failTimer = API.SystemTime()
    
    if not Interact:Object("Rune essence", "Mine", 60) then
        print("Failed to mine essence.")
        return false
    end

    while not Inventory:IsFull() and API.Read_LoopyLoop() do
        API.RandomSleep2(800, 0, 400)
        if (API.SystemTime() - failTimer) > 30000 then
            print("Failed to mine essence after 30 seconds. Exiting.")
            return false    
        end
    end

    return true
end

local function moveToAirAltar()
    walkToObject(Air_Altar.Location)
end

local function enterAirAltar()
    if not Interact:Object("Air ruins", "Enter", 20) then   
        print("Failed to enter Air Altar.")
        return false
    end

    API.RandomSleep2(600, 0, 600)
    API.WaitUntilMovingandAnimEnds()
    
end

local function craftRunes()

    if not Interact:Object("Air altar", "Use", 20) then
        print("Failed to use Air Altar.")
        return false
    end

    API.RandomSleep2(1200, 0, 600)
    API.WaitUntilMovingandAnimEnds()

    if Inventory:IsFull() then
        print("Inventory is full after attempting to crafting runes.")
        return false
    else
        return true
    end

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

        print("Inventory is full. Crafting runes.")
        moveToAirAltar()
        enterAirAltar()
        craftRunes()
        API.WaitUntilMovingandAnimEnds()
        varrockTeleport()

    else

        if not teleportAubury() then
            print("Failed to teleport to Aubury. Cannot proceed.")
            API.Write_LoopyLoop(false)
            return
        end
        if not mineEssence() then
            print("Failed to mine essence. Cannot proceed.")
            API.Write_LoopyLoop(false)
            return
        end
        API.WaitUntilMovingandAnimEnds()
        if not varrockTeleport() then
            print("Failed to teleport to Varrock. Cannot proceed.")
            API.Write_LoopyLoop(false)
            return
        end

    end


    --local metrics = {
    --    {"Script", "Mining Guild Runite"},
    --    {"Total Ores:", totalOresMined},
    --    {"Ores/H:", OresPerHour()},
    --    {
    --        "Est. Profit:",
    --        (totalOresMined * gePrice) .. "gp"
    --    },
    --    {
    --        "Profit/H:",
    --        (function()
    --            local elapsed =
    --                (API.SystemTime() - startTime)
    --                / 3600000
    --            if elapsed > 0 then
    --                return math.floor(
    --                    (
    --                        totalOresMined
    --                        * gePrice
    --                    ) / elapsed
    --                ) .. "gp"
    --            else
    --                return "0gp"
    --            end
    --        end)()
    --    }
    --}
    --API.DrawTable(metrics)

    --API.DoRandomEvents()


    API.RandomSleep2(600, 0, 250)

end