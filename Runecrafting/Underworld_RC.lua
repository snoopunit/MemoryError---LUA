local API = require("api")

local AREA           = {
    CITY_OF_UM            = { x = 1164,  y = 1822,   z = 16 },
    RC_ALTARS           = { x = 1310,  y = 1951,   z = 4 },
}

local ALTARS        = {
    SPIRIT            = "Spirit altar",
    BONE              = "Bone altar",
    FLESH             = "Flesh altar",
    MIASMA            = "Miasma altar"
}

local function loadLastPreset()

    local failTimer = API.SystemTime()
    local failCount = 0

    while not Inventory:IsFull() and API.Read_LoopyLoop() do

        if not API.ReadPlayerMovin2() then
            if Interact:Object("Bank chest", "Load Last Preset from", 30) then
                API.logDebug("Loading last preset...")
            else
                API.logDebug("Unable to interact with Bank chest!")
                failCount = failCount + 1
            end    
        end

        API.RandomSleep2(600,0,600)

        if failCount > 10 then
            API.logWarn("loadLastPreset() failCount = "..tostring(failCount).."!")
            API.Write_LoopyLoop(false)
            return
        end

        if (API.SystemTime() - failTimer) > 30000 then
            API.logWarn("Banking fail timer reached 30s!")
            API.Write_LoopyLoop(false)
            return
        end
        
    end

end

local function isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

local function enterDarkPortal()

    local failTimer = API.SystemTime()
    local failCount = 0

    while not isAtLocation(AREA.RC_ALTARS, 10) and API.Read_LoopyLoop() do
    
        if not API.ReadPlayerMovin2() then
            if Interact:Object("Dark portal", "Enter", 30) then
                API.logDebug("Entering dark portal.")
            else
                failCount = failCount + 1
            end
        end

        API.RandomSleep2(600,0,600)

        if failCount > 10 then
            API.logWarn("enterDarkPortal() failCount = "..tostring(failCount).."!")
            API.Write_LoopyLoop(false)
            return
        end

        if (API.SystemTime() - failTimer) > 30000 then
            API.logWarn("enterDarkPortal() fail timer reached 30s!")
            API.Write_LoopyLoop(false)
            return
        end 
    
    end

end

local function returnFromDarkPortal()
    
    local failTimer = API.SystemTime()
    local failCount = 0

    while not isAtLocation(AREA.CITY_OF_UM, 30) and API.Read_LoopyLoop() do
    
        if not API.ReadPlayerMovin2() then
            if Interact:Object("Dark portal", "Exit", 30) then
                API.logDebug("Exiting dark portal.")
            else
                failCount = failCount + 1
            end
        end

        API.RandomSleep2(600,0,600)

        if failCount > 10 then
            API.logWarn("exitDarkPortal() failCount = "..tostring(failCount).."!")
            API.Write_LoopyLoop(false)
            return
        end

        if (API.SystemTime() - failTimer) > 30000 then
            API.logWarn("exitDarkPortal() fail timer reached 30s!")
            API.Write_LoopyLoop(false)
            return
        end 
    
    end

end

local function craftRunes()

    local function randomAltar()
        local num = math.random(0,100)

        if num >= 0 and num <= 33 then
            return ALTARS.SPIRIT
        elseif num >= 34 and num <= 66 then
            return ALTARS.BONE
        elseif num >= 67 and num <= 100 then
            return ALTARS.FLESH
        end
        
    end

    local altar = randomAltar()
    local failTimer = API.SystemTime()
    local failCount = 0

    while Inventory:IsFull() and API.Read_LoopyLoop() do
    
        if not API.ReadPlayerMovin2() or API.CheckAnim(20) then
            if Interact:Object(altar, "Craft runes", 30) then
                API.logDebug("Crafting runes...")
            else
                failCount = failCount + 1
            end
        end

        if failCount > 10 then
            API.logWarn("craftRunes() failCount = "..tostring(failCount).."!")
            API.Write_LoopyLoop(false)
            return
        end

        if (API.SystemTime() - failTimer) > 30000 then
            API.logWarn("Runecrafting fail timer reached 30s!")
            API.Write_LoopyLoop(false)
            return
        end

    end

end

local function mainLoop()    

    if isAtLocation(AREA.CITY_OF_UM, 30) then
        API.RandomSleep2(1200,0,600)
        if Inventory:IsFull() then
            enterDarkPortal()
        else
            loadLastPreset()
        end
    end


    if isAtLocation(AREA.RC_ALTARS, 30) then
        API.RandomSleep2(1200,0,600)
        if Inventory:IsFull() then
            craftRunes()
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
