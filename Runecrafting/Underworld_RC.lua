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

local METRICS = {
    runs = 0,
    totalRunesCrafted = 0,
    spiritRunesCrafted = 0,
    boneRunesCrafted = 0,
    fleshRunesCrafted = 0,
    miasmaRunesCrafted = 0,
}

local RUNES = {
    SPIRIT = 55337,
    BONE = 55338,
    FLESH = 55339,
    MIASMA = 55340
}

local startTime = API.SystemTime()

local function updateMetrics()
    METRICS.runs = METRICS.runs + 1
    METRICS.totalRunesCrafted = METRICS.totalRunesCrafted + (Inventory:GetItemAmount(RUNES.SPIRIT) or 0) + (Inventory:GetItemAmount(RUNES.BONE) or 0) + (Inventory:GetItemAmount(RUNES.FLESH) or 0) + (Inventory:GetItemAmount(RUNES.MIASMA) or 0)
    METRICS.spiritRunesCrafted = METRICS.spiritRunesCrafted + (Inventory:GetItemAmount(RUNES.SPIRIT) or 0)
    METRICS.boneRunesCrafted = METRICS.boneRunesCrafted + (Inventory:GetItemAmount(RUNES.BONE) or 0)
    METRICS.fleshRunesCrafted = METRICS.fleshRunesCrafted + (Inventory:GetItemAmount(RUNES.FLESH) or 0)
    METRICS.miasmaRunesCrafted = METRICS.miasmaRunesCrafted + (Inventory:GetItemAmount(RUNES.MIASMA) or 0)
end

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

        
    
    end

end

local function craftRunes()

    --[[local function randomAltar()
        local num = math.random(0,100)

        if num >= 0 and num <= 23 then
            return ALTARS.SPIRIT
        elseif num >= 24 and num <= 56 then
            return ALTARS.BONE
        elseif num >= 57 and num <= 100 then
            return ALTARS.FLESH
        end
        
    end]]

    --local altar = randomAltar()
    local failTimer = API.SystemTime()
    local failCount = 0

    while Inventory:IsFull() and API.Read_LoopyLoop() do
    
        if not API.ReadPlayerMovin2() and not API.CheckAnim(20) then
            if Interact:Object("Flesh altar", "Craft runes", 30) then
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

        API.RandomSleep2(1200,0,600)

    end

end

local function RunesPerHour()
    local elapsed = API.SystemTime() - startTime

    if elapsed <= 0 then
        return 0
    end

    return math.floor(
        (METRICS.totalRunesCrafted * 60)
        / (elapsed / 60000)
    )
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
            updateMetrics()
        else
            returnFromDarkPortal()
        end
    end

    local metrics = {
        {"Total Runes:", METRICS.totalRunesCrafted},
        {"Runes/H:", RunesPerHour()},
        {"Spirit Runes:", METRICS.spiritRunesCrafted},
        {"Bone Runes:", METRICS.boneRunesCrafted},
        {"Flesh Runes:", METRICS.fleshRunesCrafted},
        {"Miasma Runes:", METRICS.miasmaRunesCrafted},
    }

    API.DrawTable(metrics)
    
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while API.Read_LoopyLoop() do

    mainLoop()
    API.RandomSleep2(600,0,250)

end
