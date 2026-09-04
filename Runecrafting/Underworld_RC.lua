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
    local usedBank = false

    while not Inventory:IsFull() and API.Read_LoopyLoop() do

        if not usedBank then
            if Interact:Object("Bank chest", "Load Last Preset from", 30) then
                API.logDebug("Loading last preset...")
                API.RandomSleep2(600,0,600)
                usedBank = true
            else
                API.logDebug("Unable to interact with Bank chest!")
                API.Write_LoopyLoop(false)
                return
            end
        end

        if API.SystemTime() - failTimer > 30000 then
            API.logWarn("Banking fail timer reached 30s!")
            API.Write_LoopyLoop(false)
            return
        end

        if API.ReadPlayerMovin2() then
            API.RandomSleep2(600,0,600)
        end
        
    end

end

local function isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

local function enterDarkPortal()

    local hasInteracted = false
    local failTimer = API.SystemTime()

    while not isAtLocation(AREA.RC_ALTARS, 10) and API.Read_LoopyLoop() do
    
        if not hasInteracted then
            if Interact:Object("Dark portal", "Enter", 30) then
                API.logDebug("Entering dark portal.")
                hasInteracted = true
            else
                API.logWarn("Unable to Enter the Dark Portal!")
                API.Write_LoopyLoop(false)
                return
            end
        end

        if API.SystemTime() - failTimer > 30000 then
            API.logWarn("Enter portal fail timer reached 30s!")
            API.Write_LoopyLoop(false)
            return
        end

        if API.ReadPlayerMovin2() or API.CheckAnim(20) then
            API.RandomSleep2(600,0,600)
        end   
    
    end

end

local function returnFromDarkPortal()
    local hasInteracted = false
    local failTimer = API.SystemTime()

    while not isAtLocation(AREA.CITY_OF_UM, 30) and API.Read_LoopyLoop() do
    
        if not hasInteracted then
            if Interact:Object("Dark portal", "Exit", 30) then
                API.logDebug("Exiting dark portal.")
                hasInteracted = true
            else
                API.logWarn("Unable to Exit the Dark Portal!")
                API.Write_LoopyLoop(false)
                return
            end
        end

        if API.SystemTime() - failTimer > 30000 then
            API.logWarn("Exit portal fail timer reached 30s!")
            API.Write_LoopyLoop(false)
            return
        end

        if API.ReadPlayerMovin2() or API.CheckAnim(20) then
            API.RandomSleep2(600,0,600)
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
    local hasInteracted = false
    local failTimer = API.SystemTime()

    while Inventory:IsFull() and API.Read_LoopyLoop() do
    
        if not hasInteracted then
            if Interact:Object("Flesh altar", "Craft runes", 30) then
                API.logDebug("Crafting runes...")
                hasInteracted = true
            else
                API.logWarn("Unable to interact with runecrafting altar!")
                API.Write_LoopyLoop(false)
                return
            end
        end

        if API.SystemTime() - failTimer > 30000 then
            API.logWarn("Runecrafting fail timer reached 30s!")
            API.Write_LoopyLoop(false)
            return
        end

        if API.ReadPlayerMovin2() or API.CheckAnim(20) then
            API.RandomSleep2(600,0,600)
        end
    
    end

end

local function mainLoop()    

    if isAtLocation(AREA.CITY_OF_UM, 30) then
        API.RandomSleep2(600,0,600)
        if Inventory:IsFull() then
            enterDarkPortal()
        else
            loadLastPreset()
        end
    end


    if isAtLocation(AREA.RC_ALTARS, 30) then
        API.RandomSleep2(600,0,600)
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
