print("Rune Essence & Air RC.")

local API = require("api")
local LODESTONES = require("lodestones")

local Aubury_Door = {
    Location = WPOINT:new(3253, 3398, 2),
    ID = 24384,
    Type = 12
}

local Aubury_Shop = {
    Location = {WPOINT:new(3252, 3401, 2),
                WPOINT:new(3252, 3402, 2),
                WPOINT:new(3253, 3401, 2),
                WPOINT:new(3253, 3402, 2)},
    ID = 5913,
    Type = 1
}

local Air_Ruins = {
    Location = WPOINT:new(3127, 3405, 3),
    ID = 2452,
    Type = 12
}

local Air_Altar = {
    Location = WPOINT:new(2844, 4834, 9),
    ID = 2478,
    Type = 0
}

local Body_Ruins = {
    Location = WPOINT:new(3053, 3445, 8),
    ID = 2457,
    Type = 12
}

local Body_Altar = {
    Location = WPOINT:new(2523, 4840, 1),
    ID = 2483,
    Type = 0
}

local runeEssenceID = 1436
local airRuneID = 556
local bodyRuneID = 559

local essenceMined = 0
local runesCrafted = 0
local totalRuns = 0

local airRunePrice = API.GetExchangePrice(airRuneID)
local bodyRunePrice = API.GetExchangePrice(bodyRuneID)
local runeEssencePrice = API.GetExchangePrice(runeEssenceID)

local startTime = API.SystemTime()

local function airRuneCount()
    return Inventory:GetItemAmount(airRuneID)
end

local function bodyRuneCount()
    return Inventory:GetItemAmount(bodyRuneID)
end

local function runeEssenceCount()
    return Inventory:GetItemAmount(runeEssenceID)
end

local function walkToObject(coords)
    return API.DoAction_WalkerW(coords)
end

local function isAtVarrockLodestone()
    local playerLoc = API.PlayerCoord()
    if playerLoc.x == 3214 and playerLoc.y == 3376 then
        return true
    else
        return false
    end
end

local function isAtEdgevilleLodestone()
    local playerLoc = API.PlayerCoord()
    if playerLoc.x == 3067 and playerLoc.y == 3505 then
        return true
    else
        return false
    end
end

local function isAtRuneEssenceMine()
    local essenceRock = API.ReadAllObjectsArray({12}, {2491}, {"Rune essence"})
    return #essenceRock > 0
end

local function isAtAirRuins()
    local ruins = API.ReadAllObjectsArray({Air_Ruins.Type}, {Air_Ruins.ID}, {"Air ruins"})
    
    if #ruins < 0 then
        return false
    end

    if ruins[1].Distance and (ruins[1].Distance < 20) then
        return true
    else
        return false
    end
end

local function isAtAirAltar()
    local altar = API.ReadAllObjectsArray({Air_Altar.Type}, {Air_Altar.ID}, {"Air altar"})
    
    if #altar < 1 then
        return false
    end

    return true
end

local function isAtBodyRuins()
    local ruins = API.ReadAllObjectsArray({Body_Ruins.Type}, {Body_Ruins.ID}, {"Body ruins"})
    
    if #ruins < 0 then
        return false
    end

    if ruins[1].Distance and (ruins[1].Distance < 20) then
        return true
    else
        return false
    end
end

local function isAtBodyAltar()
    local altar = API.ReadAllObjectsArray({Body_Altar.Type}, {Body_Altar.ID}, {"Body altar"})
    
    if #altar < 1 then
        return false
    end

    return true
end

local function varrockTeleport()
    local failTimer = API.SystemTime()

    while not isAtVarrockLodestone() and API.Read_LoopyLoop() do
        if LODESTONES.VARROCK.Teleport() then
            break
        end
        if (API.SystemTime() - failTimer) > 25000 then
            print("Failed to teleport to Varrock after 15 seconds. Exiting.")
            return false
        end
    end

    return true
    
end

local function edgevilleTeleport()
    local failTimer = API.SystemTime()

    while not isAtEdgevilleLodestone() and API.Read_LoopyLoop() do
        if LODESTONES.EDGEVILLE.Teleport() then
            break
        end
        if (API.SystemTime() - failTimer) > 25000 then
            print("Failed to teleport to Edgeville after 15 seconds. Exiting.")
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
        
        if math.floor(object.Tile_XYZ.x) == Aubury_Door.Location.x and math.floor(object.Tile_XYZ.y) == Aubury_Door.Location.y then
            if obj then
                return object
            else
                return true
            end
        end
    end

    return false
end

local function isAtAuburyShop()
    local door = findAuburyDoor(true)
    
    if not door then
        return false
    end
    if door.Distance and (door.Distance < 10) then
        return true
    else
        return false
    end
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
        local failTimer = API.SystemTime()
        while not isAuburyDoorOpen() and API.Read_LoopyLoop() do
            if (API.SystemTime() - failTimer) > 15000 then
                print("Failed to open Aubury door after 15 seconds. Exiting.")
                return false    
            end
            local success = API.DoAction_Object_Direct(0x31, API.OFF_ACT_GeneralObject_route0, door)
            API.RandomSleep2(800, 0, 400)
            API.WaitUntilMovingEnds()
        end
    end

    return isAuburyDoorOpen()
end

local function moveToAuburyShop()
    local coords = Aubury_Shop.Location[math.random(1, #Aubury_Shop.Location)]
    walkToObject(coords)
end

local function teleportAubury()

    local failTimer = API.SystemTime()

    while not isAtAuburyShop() and API.Read_LoopyLoop() do
        moveToAuburyShop()
        API.RandomSleep2(1200, 0, 600)
        if (API.SystemTime() - failTimer) > 45000 then
            print("Failed to navigate to Aubury shop after 45 seconds. Exiting.")
            return false    
        end
    end
    
    failTimer = API.SystemTime()

    while not isAuburyDoorOpen() and API.Read_LoopyLoop() do
        openAuburyDoor()
        API.RandomSleep2(1200, 0, 600)
        if (API.SystemTime() - failTimer) > 15000 then
            print("Failed to open Aubury door after 15 seconds. Exiting.")
            return false    
        end
    end

    failTimer = API.SystemTime()

    while not isAtRuneEssenceMine() and API.Read_LoopyLoop() do
        local success = Interact:NPC("Aubury", "Teleport", 20)
        API.RandomSleep2(1200, 0, 600)
        API.WaitUntilMovingandAnimEnds()
        if (API.SystemTime() - failTimer) > 45000 then
            print("Failed to teleport to Rune Essence Mine after 45 seconds. Exiting.")
            return false    
        end
    end

    return true
end

local function mineEssence()
    
    local startCount = runeEssenceCount()

    if not Interact:Object("Rune essence", "Mine", 60) then
        print("Failed to mine essence.")
        return false
    end

    API.RandomSleep2(1800, 0, 600)  
    API.WaitUntilMovingEnds()

    local failTimer = API.SystemTime()

    while not Inventory:IsFull() and API.Read_LoopyLoop() do
        
        API.RandomSleep2(1800, 0, 600)
        if (API.SystemTime() - failTimer) > 60000 then
            print("Failed to mine essence after 60 seconds. Exiting.")
            return false    
        end
        if not API.CheckAnim(50) or API.ReadPlayerMovin2() then
            print("Player is not animating. Attempting to mine again.")
            if not Interact:Object("Rune essence", "Mine", 60) then
                print("Failed to mine essence.")
                return false
            end
        end
    end

    local endCount = runeEssenceCount()
    essenceMined = essenceMined + (endCount - startCount)
    print("Mined " .. (endCount - startCount) .. " rune essence. Total mined: " .. essenceMined)
    API.RandomSleep2(1800, 0, 600)
    return true
end

local function moveToAirAltar()
    
    local failTimer = API.SystemTime()
    while not isAtAirRuins() and API.Read_LoopyLoop() do
        walkToObject(Air_Ruins.Location)
        API.RandomSleep2(800, 0, 400)
        if (API.SystemTime() - failTimer) > 45000 then
            print("Failed to reach Air Ruins after 45 seconds. Exiting.")
            return false    
        end
    end
    API.logDebug("Reached Air Ruins.")
    return true
    
end

local function moveToBodyAltar()
    
    local failTimer = API.SystemTime()
    while not isAtBodyRuins() and API.Read_LoopyLoop() do
        walkToObject(Body_Ruins.Location)
        API.RandomSleep2(800, 0, 400)
        if (API.SystemTime() - failTimer) > 45000 then
            print("Failed to reach Body Ruins after 45 seconds. Exiting.")
            return false    
        end
    end
    API.logDebug("Reached Body Ruins.")
    return true
    
end

local function enterAirAltar()
    
    while not isAtAirAltar() and API.Read_LoopyLoop() do
        if not Interact:Object("Air ruins", "Enter", 20) then   
            print("Failed to enter Air Ruins.")
            return false
        end
        local failTimer = API.SystemTime()
        API.RandomSleep2(1200, 0, 600)
        API.WaitUntilMovingandAnimEnds()
        if (API.SystemTime() - failTimer) > 45000 then
            print("Failed to reach Air Ruins after 45 seconds. Exiting.")
            return false    
        end
        
    end
    API.logDebug("Entered Air Ruins.")
    return true
end

local function enterBodyAltar()
    
    while not isAtBodyAltar() and API.Read_LoopyLoop() do
        if not Interact:Object("Body ruins", "Enter", 20) then   
            print("Failed to enter Body Ruins.")
            return false
        end
        local failTimer = API.SystemTime()
        API.RandomSleep2(1200, 0, 600)
        API.WaitUntilMovingandAnimEnds()
        if (API.SystemTime() - failTimer) > 45000 then
            print("Failed to reach Body Ruins after 45 seconds. Exiting.")
            return false    
        end
        
    end
    API.logDebug("Entered Body Ruins.")
    return true
end

local function craftAirRunes()

    local startCount = airRuneCount()
    local failTimer = API.SystemTime()

    while Inventory:IsFull() and API.Read_LoopyLoop() do

        if not Interact:Object("Air altar", "Use", 20) then
            print("Failed to use Air Altar.")
            return false
        end

        API.RandomSleep2(3200, 0, 1200)

        if (API.SystemTime() - failTimer) > 45000 then
            print("Failed to craft runes after 45 seconds. Exiting.")
            return false    
        end

    end
    local endCount = airRuneCount()
    runesCrafted = runesCrafted + (endCount - startCount)
    print("Crafted " .. (endCount - startCount) .. " air runes. Total crafted: " .. runesCrafted)
    return true

end

local function craftBodyRunes()

    local startCount = bodyRuneCount()
    local failTimer = API.SystemTime()

    while Inventory:IsFull() and API.Read_LoopyLoop() do

        if not Interact:Object("Body altar", "Use", 20) then
            print("Failed to use Body Altar.")
            return false
        end

        API.RandomSleep2(3200, 0, 1200)

        if (API.SystemTime() - failTimer) > 45000 then
            print("Failed to craft runes after 45 seconds. Exiting.")
            return false    
        end

    end
    local endCount = bodyRuneCount()
    runesCrafted = runesCrafted + (endCount - startCount)
    print("Crafted " .. (endCount - startCount) .. " body runes. Total crafted: " .. runesCrafted)
    return true

end

local function runesPerHour()
    local elapsed = API.SystemTime() - startTime

    if elapsed <= 0 then
        return 0
    end

    return math.floor((runesCrafted * 60) / (elapsed / 60000))
end

local function updateMetrics()

    local metrics = {
        {"Script:", "Rune Essence & RC"},
        {"Total Essence Mined:", essenceMined},
        {"Total Runes Crafted:", runesCrafted},
        {"Runes/H:", runesPerHour()},
        {"Total Runs:", totalRuns},
        {"Est. Profit:", (runesCrafted * airRunePrice) .. "gp"},
        {"Profit/H:",   (function()
                            local elapsed = (API.SystemTime() - startTime) / 3600000

                            if elapsed > 0 then
                                return math.floor((runesCrafted * airRunePrice) / elapsed) .. "gp"
                            else
                                return "0gp"
                            end
                        end)()
        }
    }

    API.DrawTable(metrics)    
end

local function timeToStop()
    local elapsedTime = API.SystemTime() - startTime

    if elapsedTime > (3600000 * 2) then
        print("2 hours have passed. Terminating Script.")
        API.Write_LoopyLoop(false)
        return true
    end

    return false
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while API.Read_LoopyLoop() do

    if not API.PlayerLoggedIn() then
        print("Player is not logged in. Terminating script.")
        return
    end

    if timeToStop() then
        return
    end

    updateMetrics()

    if Inventory:IsFull() then

        print("Inventory is full. Crafting runes.")
        if not moveToBodyAltar() then
            print("Failed to move to Body Altar. Cannot proceed.")
            API.Write_LoopyLoop(false)
            return
        end
        if not enterBodyAltar() then
            print("Failed to enter Body Altar. Cannot proceed.")
            API.Write_LoopyLoop(false)
            return
        end
        if not craftBodyRunes() then
            print("Failed to craft runes. Cannot proceed.")
            API.Write_LoopyLoop(false)
            return
        end
        updateMetrics()
        if not varrockTeleport() then
            print("Failed to teleport to Varrock. Cannot proceed.")
            API.Write_LoopyLoop(false)
            return
        end
        totalRuns = totalRuns + 1
        API.logDebug("Completed run " .. totalRuns .. ". Total essence mined: " .. essenceMined .. ". Total runes crafted: " .. runesCrafted)
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
        updateMetrics()
        if not edgevilleTeleport() then
            print("Failed to teleport to Edgeville. Cannot proceed.")
            API.Write_LoopyLoop(false)
            return
        end

    end

    API.RandomSleep2(600, 0, 250)

end