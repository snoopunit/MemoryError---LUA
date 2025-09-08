print("Taverly Summoning.")

local API = require("api")
local MISC = require("lib/MISC")

local AREA = {
    BANK = {x = 2876, y = 3417, z = 0},
    SHOP = {x = 2930, y = 3448, z = 0}
}

local function isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

local function goToLocation(location)
    --try to walk to the location if we're not already there
    if not isAtLocation(location) then

        API.logDebug("goToLocation()")

        if not API.DoAction_Tile(WPOINT.new(location.x + math.random(-4, 4), location.y + math.random(-4, 4), location.z)) then

            API.logWarn("DoAction_Tile(): {"..tostring(location.x)..", "..tostring(location.y).."} failed!")
            API.Write_LoopyLoop(false)
            return 

        end


        while not isAtLocation(location) and API.Read_LoopyLoop() do

            API.RandomSleep2(50,0,50)

        end

    end
end

local function hasPouch()
    local inv = API.ReadInvArrays33()
    for index, value in ipairs(inv) do
        if string.find(value.textitem, "pouch") then
            return true
        end
    end
    return false
end

local function makePouches()

    API.logDebug("makePouches()")

    goToLocation(AREA.SHOP)

    local obeliskTimer = API.SystemTime()

    if not Interact:Object("Obelisk", "Infuse-pouch", 30) then
        API.logWarn("Unable to interact with obelisk!")
        API.Write_LoopyLoop(false)
        return
    end

    MISC.waitForCraftingInterface()
    MISC.clickStart()

    while (API.SystemTime() - obeliskTimer < 30000) and API.Read_LoopyLoop() do
    
        if hasPouch() then

            while API.CheckAnim(25) do
                API.RandomSleep2(600,0,600)
            end

            return true
        end

    end

    API.logWarn("Didn't find pouches in inventory after 30s!")
    API.Write_LoopyLoop(false)
    return false

end

local function loadLastPreset()
    API.logDebug("loadLastPreset()")

    goToLocation(AREA.BANK)

    local bankTimer = API.SystemTime()

    if not Interact:Object("Counter", "Load Last Preset from", 30) then
        if not Interact:NPC("Banker", "Load Last Preset from", 30) then
            API.logWarn("Unable to bank!!")
            API.Write_LoopyLoop(false)
            return
        end
    end

    while ((API.SystemTime() - bankTimer < 30000) or API.ReadPlayerMovin()) and API.Read_LoopyLoop() do
    
        if Inventory:IsFull() then
            return true
        end

    end

    API.logWarn("Didn't get a full inventory after 30 s!")
    API.Write_LoopyLoop(false)
    return false

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    
    if not hasPouch() then

        makePouches()

    else

        loadLastPreset()

    end 
end----------------------------------------------------------------------------------