--MAKE SURE TO HAVE POUCH PROTECTOR/NEXUS MOD RELICS ACTIVE

local API = require("api")
local UTILS = require("UTILS")

local AREA           = {
    CITY_OF_UM            = { x = 1164,  y = 1822,   z = 16 },
    RC_ALTARS           = { x = 1310,  y = 1951,   z = 4 },
}

local function loadLastPreset()

    if Interact:Object("Bank chest", "Load Last Preset from", 30) then
        API.logDebug("Loading last preset...")
        API.RandomSleep2(600,0,600)
        API.WaitUntilMovingandAnimEnds()
        return true
    end

    API.logWarn("Failed to load last preset from bank!")
    API.Write_LoopyLoop(false)
    return false

end

local function isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

local function enterDarkPortal()
    if Interact:Object("Dark portal", "Enter", 30) then
        API.logDebug("Entering dark portal.")
        API.RandomSleep2(600,0,600)
        API.WaitUntilMovingandAnimEnds()
        return true
    end
    return false
end

local function returnFromDarkPortal()
    if Interact:Object("Dark portal", "Exit", 30) then
        API.logDebug("Exiting dark portal.")
        API.RandomSleep2(600,0,600)
        API.WaitUntilMovingandAnimEnds()
        return true
    end
    return false
end

local function craftSpiritRunes()
    if Interact:Object("Spirit altar", "Craft runes", 30) then
        API.logDebug("Crafting spirit runes.")
        API.RandomSleep2(600,0,600)
        API.WaitUntilMovingandAnimEnds()
        return true
    end
    return false
end

local function craftBoneRunes()
    if Interact:Object("Bone altar", "Craft runes", 30) then
        API.logDebug("Crafting bone runes.")
        API.RandomSleep2(600,0,600)
        API.WaitUntilMovingandAnimEnds()
        return true
    end
    return false
end

local function mainLoop()    

    if isAtLocation(AREA.CITY_OF_UM, 30) then
        if Inventory:IsFull() then
            enterDarkPortal()
        else
            loadLastPreset()
        end
    end


    if isAtLocation(AREA.RC_ALTARS, 30) then
        if Inventory:IsFull() then
            craftBoneRunes()
        else
            returnFromDarkPortal()
        end
    end
    
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while API.Read_LoopyLoop() do

    mainLoop()
    API.RandomSleep2(600,0,250)

end
