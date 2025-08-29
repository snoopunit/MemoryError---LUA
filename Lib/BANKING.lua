local API = require("api")

local Banking = {}

BANKERS = {
    VARROCK_WEST = {
        Name = "Varrock west bank",
        Location = {{3181,3444,0},{3181,3438,0},{3190,3441,0},{3180,3440,0},{3191,3437,0},{3191,3443,0},{3181,3440,0},{3180,3442,0},{3191,3445,0},{3180,3436,0},{3180,3444,0},{3191,3441,0},{3190,3443,0},{3190,3435,0},{3181,3442,0},{3190,3439,0},{3191,3439,0},{3191,3435,0},{3181,3436,0},{3180,3433,0},{3180,3438,0},{3190,3437,0}} ,
        Types = { "Banker", "Bank booth" }
    },
    FALADOR_WEST = {
        Name = "Falador west bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    EDGEVILLE = {
        Name = "Edgeville bank",
        Location = {{3096,3493,0},{3096,3491,0},{3095,3493,0},{3096,3489,0},{3097,3495,0},{3095,3489,0},{3095,3491,0},{3097,3494,0}},
        Types = { "Banker", "Counter" }
    },
    DRAYNOR = {
        Name = "Draynor bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    VARROCK_EAST = {
        Name = "Varrock east bank",
        Location = {{3254,3419,0},{3256,3419,0},{3254,3418,0},{3251,3418,0},{3252,3418,0},{3251,3419,0},{3253,3419,0},{3255,3419,0},{3253,3418,0},{3252,3419,0},{3255,3418,0},{3256,3418,0}} ,
        Types = { "Banker", "Bank booth" }
    },
    FALADOR_EAST = {
        Name = "Falador east bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    AL_KHARID = {
        Name = "Al Kharid bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    CATHERBY = {
        Name = "Catherby bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    ZANARIS = {
        Name = "Zanaris bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    SEERS_VILLAGE = {
        Name = "Seers' Village bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    ARDOUGNE_SOUTH = {
        Name = "Ardougne south bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    ARDOUGNE_NORTH = {
        Name = "Ardougne north bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    YANILLE = {
        Name = "Yanille bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    TREE_GNOME_STRONGHOLD = {
        Name = "Tree Gnome Stronghold bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    GRAND_TREE = {
        Name = "Grand Tree bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    SHILO_VILLAGE = {
        Name = "Shilo Village bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    LEGENDS_GUILD = {
        Name = "Legends' Guild bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    MAGE_ARENA = {
        Name = "Mage Arena bank",
        Location = {},
        Types = { "Banker", "Bank chest" }
    },
    FISHING_GUILD = {
        Name = "Fishing Guild bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    HETS_OASIS = {
        Name = "Het's Oasis bank",
        Location = {},
        Types = { "Banker", "Bank chest" }
    },
    CANIFIS = {
        Name = "Canifis bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    ETCETERIA = {
        Name = "Etceteria bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    PORT_PHASMATYS = {
        Name = "Port Phasmatys bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    KELDAGRIM = {
        Name = "Keldagrim bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    ROGUES_DEN = {
        Name = "Rogues' Den bank",
        Location = {},
        Types = { "Emerald Benedict" }
    },
    LLETYA = {
        Name = "Lletya bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    TZHAAR_CITY = {
        Name = "Tzhaar City bank",
        Location = {},
        Types = { "TzHaar-Ket-Yil", "Bank booth" }
    },
    NARDAH = {
        Name = "Nardah bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    MOS_LE_HARMLESS = {
        Name = "Mos Le'Harmless bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    BURGH_DE_ROTT = {
        Name = "Burgh de Rott bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    VOID_KNIGHTS_OUTPOST = {
        Name = "Void Knights' Outpost bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    PISCATORIS = {
        Name = "Piscatoris bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    WARRIORS_GUILD = {
        Name = "Warriors' Guild bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    LUNAR_ISLE = {
        Name = "Lunar Isle bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    LUMBRIDGE_CASTLE = {
        Name = "Lumbridge Castle bank",
        Location = {{3208,3222,0},{3208,3221,0}},
        Types = { "Banker", "Bank booth" }
    },
    LUMBRIDGE_BANK_CHEST = {
        Name = "Lumbridge Bank Chest",
        Location = {{3215,3257,0}} ,
        Types = { "Bank chest" }
    },
    SOPHANEM = {
        Name = "Sophanem bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    NEITIZNOT = {
        Name = "Neitiznot bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    JATIZSO = {
        Name = "Jatizso bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    DORGESH_KAAN = {
        Name = "Dorgesh-Kaan bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    COOKS_GUILD = {
        Name = "Cooks' Guild bank",
        Location = {},
        Types = { "Banker", "Bank chest" }
    },
    VARROCK_GRAND_EXCHANGE = {
        Name = "Varrock Grand Exchange",
        Location = {{3159,3490,0},{3170,3493,0},{3163,3486,0},{3166,3497,0}} ,
        Types = { "Banker"--[[, "Grand Exchange clerk"]] }
    },
    OOGLOG = {
        Name = "Oo'glog bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    FIST_OF_GUTHIX = {
        Name = "Fist of Guthix bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    SOUL_WARS = {
        Name = "Soul Wars bank chest",
        Location = {},
        Types = { "Bank chest" }
    },
    DAEMONHEIM = {
        Name = "Daemonheim bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    THIEVES_GUILD = {
        Name = "Thieves' Guild bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    BURTHORPE = {
        Name = "Burthorpe bank",
        Location = {{2886,3535,0},{2888,3535,0}} ,
        Types = { "Gnome Banker", "Bank booth" }
    },
    TAVERLEY = {
        Name = "Taverley bank",
        Location = {{2874,3418,0},{2873,3418,0},{2874,3416,0},{2874,3417,0},{2873,3417,0},{2873,3416,0}} ,
        Types = { "Banker", "Counter" }
    },
    CITY_OF_UM = {
        Name = "City of Um bank",
        Location = {},
        Types = { "Banker", "Bank booth" }
    },
    STILES = {
        Name = "Noting: Stiles",
        Location = {{2851,3143,0}},
        Types = { "Stiles" }
    }
}

---@param point WPOINT
---@return number
function distanceFromPlayer(point)
    local playerPos = API.PlayerCoord()
    local dx = point.x - playerPos.x
    local dy = point.y - playerPos.y
    local dz = point.z - playerPos.z
    return math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
end

---@param endPoint WPOINT
---@param segments number
---@return WPOINT[]
function lineToPlayer(endPoint, segments)
    local startPoint = API.PlayerCoord()
    local distance = distanceFromPlayer(endPoint)
    local segmentLength = distance / segments

    local points = {}
    for i = 0, segments do
        local t = i / segments
        local x = math.floor(startPoint.x + (endPoint.x - startPoint.x) * t)
        local y = math.floor(startPoint.y + (endPoint.y - startPoint.y) * t)
        local z = math.floor(startPoint.z + (endPoint.z - startPoint.z) * t)
        table.insert(points, {x = x, y = y, z = z})
    end

    return points
end

---@param point WPOINT
---@return WPOINT
function randomizePoint(point)
    local xOffset = math.random(-5, 5)
    local yOffset = math.random(-5, 5)
    return {
        x = (point.x + xOffset),
        y = (point.y + yOffset),
        z = (point.z)
    }
end

---@param destination WPOINT
function walkPath(destination)
    local MAX_SEGMENT_LENGTH = 30
    local currentPosition = API.PlayerCoord()
    
    while distanceFromPlayer(destination) > MAX_SEGMENT_LENGTH do
        local distance = distanceFromPlayer(destination)
        local segments = math.ceil(distance / MAX_SEGMENT_LENGTH)
        local nextPointArray = lineToPlayer(destination, segments)[2]  -- Get the next point as an array
        
        -- Convert the array to a WPOINT
        local nextPoint = WPOINT:new(nextPointArray.x, nextPointArray.y, nextPointArray.z)
        
        API.logDebug("NextPoint: x=" .. nextPoint.x .. ", y=" .. nextPoint.y .. ", z=" .. nextPoint.z)

        if API.DoAction_WalkerW(nextPoint) then
            API.RandomSleep2(1800, 200, 1200)
            while API.ReadPlayerMovin2() do
                if distanceFromPlayer(destination) < 40 then return true end
                API.RandomSleep2(50, 0, 50)   
            end
        else
            API.logError("Failed to walk to point: x=" .. nextPoint.x .. ", y=" .. nextPoint.y .. ", z=" .. nextPoint.z)
            return false
        end
        
        currentPosition = API.PlayerCoord()
        if distanceFromPlayer(destination) < 40 then
            return true
        end
    end
    
    -- Final movement to destination
    API.logDebug("Attempting final move to destination")
    if API.DoAction_WalkerW(destination) then
        API.RandomSleep2(1800, 200, 1200)
        while API.ReadPlayerMovin2() do
            if API.PinAreaW(destination, 40) then return true end
            API.RandomSleep2(50, 0, 50)   
        end
    else
        API.logError("Failed to walk to final destination: x=" .. destination.x .. ", y=" .. destination.y .. ", z=" .. destination.z)
        return false
    end
    
    if distanceFromPlayer(destination) < 40 then
        API.logDebug("Successfully reached destination")
        return true
    else
        API.logWarn("Reached end of path but not near destination")
        return false
    end
end

function isBankOpen()
    if API.VB_FindPSettinOrder(2874, 0).state == 24 then
        return true
    else
        return false
    end
end

function waitForBankToOpen()
    local failTimer = API.SystemTime()
    while not isBankOpen() and API.Read_LoopyLoop() do
        API.RandomSleep2(250,0,250)
        if API.SystemTime() - failTimer > 30000 then
            API.logWarn("Failed to open Bank!")
            API.Write_LoopyLoop(false)
            return false
        end
    end
    return true
end

function waitForBankToClose()
    local failTimer = API.SystemTime()
    while isBankOpen() and API.Read_LoopyLoop() do
        API.RandomSleep2(250,0,250)
        if API.SystemTime() - failTimer > 30000 then
            API.logWarn("Failed to close Bank!")
            API.Write_LoopyLoop(false)
            return false
        end
    end
    return true
end

function Banking.getCoords(bankType)
    local bankInfo = bankType
    if not bankInfo then
        API.logError("Error: Invalid bank type provided")
        return
    else
        API.logDebug("Searching for: "..bankInfo.Name.."    Types: "..table.concat(bankInfo.Types, ", "))
    end

    local foundObjects = API.ReadAllObjectsArray({0,1,12}, {-1}, bankInfo.Types)
    local newCoords = {}
    
    API.logDebug("Found: "..tostring(#foundObjects).." objects.")

    for _, obj in pairs(foundObjects) do
        if obj.Distance < 30 then
            if (obj.Action == "Bank") or (obj.Action == "Use") then
                API.logDebug("Name: "..obj.Name.."   Action: "..obj.Action.."    Distance: "..tostring(obj.Distance))
                local newCoord = {math.floor(obj.Tile_XYZ.x), math.floor(obj.Tile_XYZ.y)}
                local isNewCoord = true
                
                for _, existingCoord in ipairs(bankInfo.Location) do
                    if existingCoord[1] == newCoord[1] and existingCoord[2] == newCoord[2] then
                        isNewCoord = false
                        break
                    end
                end
                
                if isNewCoord then
                    table.insert(bankInfo.Location, newCoord)
                    table.insert(newCoords, {newCoord[1], newCoord[2], 0})
                end
            end
        end
    end

    if #newCoords > 0 then
        API.logDebug("New coords found: "..tostring(#newCoords))
        local coordString = "Location = {"
        for i, coord in ipairs(newCoords) do
            coordString = coordString .. string.format("{%d,%d,0}", coord[1], coord[2])
            if i < #newCoords then
                coordString = coordString .. ","
            end
        end
        coordString = coordString .. "}"
        API.logDebug(coordString)
    else
        API.logDebug("No new coordinates found.")
    end
end

function Banking.isNearBank(bankType)
    local bankInfo = bankType
    if not bankInfo then
        API.logError("Error: Invalid bank type provided")
        return false
    end

    local banks = API.ReadAllObjectsArray({0,1,12}, {-1}, bankInfo.Types)

    if #banks == 0 then
        API.logWarn("Couldn't locate any banks!")
        return false
    end

    for _, bank in pairs(banks) do
        if math.floor(bank.Distance) <= 50 then
            return true
        end
    end
end

function Banking:goTo(bankType) 
    local locations = bankType.Location

    if #locations == 0 then
        API.logWarn("No locations defined for " .. bankType.Name)
        return false
    end

    local locationToUse
    if #locations ~= 1 then
        locationToUse = locations[math.random(1, #locations)]
    else
        locationToUse = locations[1]
    end

    -- Ensure locationToUse is a table with three elements
    if type(locationToUse) ~= "table" or #locationToUse ~= 3 then
        API.logError("Invalid location format for " .. bankType.Name)
        return false
    end

    API.logDebug("Location Chosen for " .. bankType.Name .. ": x=" .. locationToUse[1] .. ", y=" .. locationToUse[2] .. ", z=" .. locationToUse[3])

    local tile = WPOINT:new(locationToUse[1], locationToUse[2], locationToUse[3])

    API.logDebug("Attempting to walk to bank location")
    if walkPath(randomizePoint(tile)) then
        API.logDebug("Walk path successful, waiting for player to stop moving")
        API.RandomSleep2(600, 200, 200)
        while API.ReadPlayerMovin2() do
            API.RandomSleep2(100, 50, 50)
        end
        API.logDebug("Player stopped moving")
    else
        API.logError("Failed to walk to bank location")
        return false
    end

    local distance = distanceFromPlayer(tile)
    API.logDebug("Distance from bank after walking: " .. distance)

    if distance > 40 then    
        API.logError("Not in " .. bankType.Name .. " location after successfully moving.")
        API.logError("Check locations for " .. bankType.Name)
        return false
    end

    API.logDebug("Successfully reached bank location")
    return true
end

function Banking.doBank(bankType, preset)
    local bankInfo = bankType
    if not bankInfo then
        API.logError("Error: Invalid bank type provided")
        return false
    end

    local x,y,z = bankInfo.Location[1][1], bankInfo.Location[1][2], bankInfo.Location[1][3]
    local bankCoord = WPOINT:new(x,y,z)
    if distanceFromPlayer(bankCoord) > 40 then
        Banking:goTo(bankType)
    end

    local banks = API.ReadAllObjectsArray({0,1,12}, {-1}, bankInfo.Types)

    if #banks == 0 then
        API.logWarn("Couldn't locate any banks!")
        return false
    end

    -- Sort banks by distance
    table.sort(banks, function(a, b) return a.Distance < b.Distance end)

    -- Choose randomly from the three closest banks (or fewer if less than three are available)
    local closestBanks = math.min(3, #banks)
    local chosenBank = banks[math.random(1, closestBanks)]
    API.logDebug("Bank Chosen: Distance = " .. chosenBank.Distance)

    local ACTIONS = {
        bank = 0x5,
        collect = 0x5,
        load_last = 0x33
    }

    local OFFSETS = {
        NPC = {
            bank = API.OFF_ACT_InteractNPC_route1,
            exchange = API.OFF_ACT_InteractNPC_route2,
            collect = API.OFF_ACT_InteractNPC_route3,
            load_last = API.OFF_ACT_InteractNPC_route4
        },
        OBJECT = {
            bank = API.OFF_ACT_GeneralObject_route1,
            collect = API.OFF_ACT_GeneralObject_route2,
            load_last = API.OFF_ACT_GeneralObject_route3
        }
    }

    local banktimer = API.SystemTime()

    if preset == "last" then
        while API.InvFull_() do
            if chosenBank.Type == 1 then
                API.DoAction_NPC__Direct(ACTIONS.load_last, OFFSETS.NPC.load_last, chosenBank)
            else
                API.DoAction_Object_Direct(ACTIONS.load_last, OFFSETS.OBJECT.load_last, chosenBank)
            end
            API.logInfo("Loading last preset...")
            API.RandomSleep2(1800, 0, 1200)
            while API.ReadPlayerMovin2() do
                API.RandomSleep2(50, 0, 50)   
            end
            if API.SystemTime() - banktimer > 30000 then
                API.logInfo("Out of supplies!")
                API.Write_LoopyLoop(false)
                return false
            end
        end
        return true
    elseif type(preset) == "number" and preset >= 1 then
        if chosenBank.Type == 1 then
            API.DoAction_NPC__Direct(ACTIONS.bank, OFFSETS.NPC.bank, chosenBank)
        else
            API.DoAction_Object_Direct(ACTIONS.bank, OFFSETS.OBJECT.bank, chosenBank)   
        end
        while not API.CheckBankVarp() do
            API.RandomSleep2(800, 0, 250)
            while API.ReadPlayerMovin2() do
                API.RandomSleep2(60, 0, 25)   
            end
            if API.SystemTime() - banktimer > 30000 then
                API.logWarn("Bank didn't open after 30s!")
                API.Write_LoopyLoop(false)
                return false
            end
        end

        API.logInfo("Loading preset: "..tostring(preset))
        API.DoAction_Interface(0x24,0xffffffff,1,517,119,preset,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(1200, 0, 250)

        if not API.CheckBankVarp() then
            return true
        end 
    else
        return false
    end
end

function Banking.doPreset(presetNum)

    local bankTimer = API.SystemTime()
    if not Interact:NPC("Banker", "Bank", 10) then
        API.logWarn("Failed to interact with banker!")
        API.Write_LoopyLoop(false)
        return false
    end

    waitForBankToOpen()

    API.logInfo("Loading preset: "..tostring(presetNum))
    API.DoAction_Interface(0x24,0xffffffff,1,517,119,presetNum,API.OFF_ACT_GeneralInterface_route)
    bankTimer = API.SystemTime()

    waitForBankToClose()

    API.logInfo("Preset loaded successfully!")
    API.RandomSleep2(600,0,250)
    return true
end

function Banking.loadLastPreset()
    API.logDebug("Last Preset")
    local banktimer = API.SystemTime()
    --API.DoAction_NPC(0x33,API.OFF_ACT_InteractNPC_route4,{ banker },50)
    Interact:NPC("Banker", "Load Last Preset from", 6)
    API.RandomSleep2(600, 0, 250)
    while API.Invfreecount_() > 0 do
        if (API.SystemTime() - banktimer) > 30000 then
            API.logDebug("Out of supplies!")
            API.Write_LoopyLoop(false)
            return
        end
        API.RandomSleep2(50, 0, 50)
    end
end

return Banking