print("Taverly Summoning.")

local API = require("api")

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

        if not API.DoAction_Tile(WPOINT.new(location.x + math.random(-4, 4), location.y + math.random(-4, 4), location.z)) then

            API.logWarn("DoAction_Tile(): {"..tostring(location.x)..", "..tostring(location.y).."} failed!")
            API.Write_LoopyLoop(false)
            return 

        end

        API.RandomSleep2(1200,0,600)

        if not API.ReadPlayerMovin() then

            API.logWarn("Failed to detect movement after walking to the bank!")
            API.Write_LoopyLoop(false)
            return

        end

        while API.ReadPlayerMovin() and API.Read_LoopyLoop() do

            API.RandomSleep2(50,0,50)

        end

    end
end

local function makePouches()

    goToLocation(AREA.SHOP)

    local obeliskTimer = API.SystemTime()

    --shutdown if Interact: doesn't work
    if not Interact:Object("Obelisk", "Infuse-pouch", 30) then
        API.logWarn("Unable to interact with obelisk!")
        API.Write_LoopyLoop(false)
        return
    end

    --wait up to 15s for a free inventory spaces. shutdown if we don't
    while (API.SystemTime() - obeliskTimer < 15000) and API.Read_LoopyLoop() do
    
        if Inventory:FreeSpaces() > 10 then
            return true
        end

    end

    API.logWarn("Didn't get 10 or more free inventory spaces after 15s!")
    API.Write_LoopyLoop(false)
    return false

end

local function loadLastPreset()

    goToLocation(AREA.BANK)

    local bankTimer = API.SystemTime()

    --shutdown if Interact: doesn't work
    if not Interact:Object("Counter", "Load Last Preset from", 30) then
        if not Interact:NPC("Banker", "Load Last Preset from", 30) then
            API.logWarn("Unable to bank!!")
            API.Write_LoopyLoop(false)
            return
        end
    end

    --wait up to 15s for a full inventory of items. shutdown if we don't
    while (API.SystemTime() - bankTimer < 15000) and API.Read_LoopyLoop() do
    
        if Inventory:IsFull() then
            return true
        end

    end

    API.logWarn("Didn't get a full inventory after 15s!")
    API.Write_LoopyLoop(false)
    return false

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    
    if Inventory:IsFull() then

        makePouches()

    else

        loadLastPreset()

    end 
end----------------------------------------------------------------------------------