--MAKE SURE TO HAVE POUCH PROTECTOR/NEXUS MOD RELICS ACTIVE

local API = require("api")
local UTILS = require("UTILS")

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

local AREA           = {
    EDGEVILLE_LODESTONE     = { x = 3067, y = 3505,  z = 0 },
    EDGEVILLE_BANK          = { x = 3094, y = 3493,  z = 0 },
    EDGEVILLE               = { x = 3087, y = 3503,  z = 0 },
    WILDY                   = { x = 3099, y = 3523,  z = 0 },
    ABBY                    = { x = 3040, y = 4843,  z = 0 },
    NATURE_ALTAR            = { x = 2400, y = 4843,  z = 0 },
    WARETREAT               = { x = 3294, y = 10127, z = 0 },
    SMALL_OBELISK           = { x = 3128, y = 3515,  z = 0 },
    DEATHS_OFFICE           = { x = 414,  y = 674,   z = 0 },
}

local function hasItem(item)
    return Inventory:Contains(item)    
end

local function canSeeMage()
    local Mage = API.GetAllObjArray1({2257}, 100, {1})
    if mage then return true
    else return false
    end
end

local function loadLastPreset()
    local bankTimer = API.SystemTime()

    if not Interact:Object("Counter", "Load Last Preset from", 30) then
        if not Interact:NPC("Banker", "Load Last Preset from", 30) then
            API.logWarn("Unable to bank!!")
            API.Write_LoopyLoop(false)
            return false
        end
    end

    while (API.SystemTime() - bankTimer < 15000) and API.Read_LoopyLoop() do
    
        if Inventory:IsFull() then
            return true
        end

    end

    API.logWarn("Didn't get a full inventory after banking!")
    API.Write_LoopyLoop(false)
    return false

end

local function isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

local function crossWildyWall()

    local crossAnim = 6703
  
    Interact:Object("Wilderness wall", "Cross", 40) 

    while API.ReadPlayerAnim() ~= crossAnim and API.Read_LoopyLoop() do
        API.RandomSleep2(50,0,50)
    end

end

local function clickTileNearMage()
    API.DoAction_Tile(WPOINT.new(3107 + math.random(-4, 4), 3559 + math.random(-4, 4), 0))
end

local function mageTeleport()
    Interact:NPC("Mage of Zamorak", "Teleport", 30)
end

local function wallToAbyss()

    local surgeAbility = API.GetABs_name("Surge")

    if surgeAbility then
        while surgeAbility.cooldown_timer == 0 and API.Read_LoopyLoop() do
            API.DoAction_Ability_Direct(surgeAbility, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(50,0,50)
            clickTileNearMage()
            API.RandomSleep2(50,0,50)
        end
    end

    while not canSeeMage() and API.Read_LoopyLoop() do
        clickTileNearMage()
        API.RandomSleep2(500,0,500)
    end

    while canSeeMage() and API.Read_LoopyLoop() do
        mageTeleport()
        API.RandomSleep2(1200,0,600)
    end

    while not isAtLocation(AREA.ABBY) and API.Read_LoopyLoop() do
        API.RandomSleep2(50,0,50)
    end

end

local function natureRift()
    Interact:Object("Nature rift", "Exit-through", 20)
    while not isAtLocation(AREA.NATURE_ALTAR) and API.Read_LoopyLoop() do
        API.RandomSleep2(50,0,50)
    end
end

local function natureAltar()
    Interact:Object("Nature altar", "Use", 10)
    API.RandomSleep2(600,0,600)
    while (API.ReadPlayerMovin() or API.CheckAnim(50)) and API.Read_LoopyLoop() do
        API.RandomSleep2(600,0,600)
    end
end

local function wildySwordTeleport()
    local ws = API.GetABs_name1("Wilderness sword")
    if ws.enabled and ws.action == "Edgeville" then
        API.logDebug("Use wilderness sword teleport.")
        API.DoAction_Ability_Direct(ws, 1, API.OFF_ACT_GeneralInterface_route)
    else
        API.logWarn("Wildy sword not found!")
        API.Write_LoopyLoop(false)
    end
end

local function mainLoop()

    if isAtLocation(AREA.EDGEVILLE, 10) then
        if Inventory:IsFull() then
            crossWildyWall()
        else
            loadLastPreset()
            return
        end
    end

    if isAtLocation(AREA.WILDY, 10) then
        wallToAbyss()
    end

    if isAtLocation(AREA.ABBY,10) then
        natureRift()
    end

    if isAtLocation(AREA.NATURE_ALTAR) then
        natureAltar()
        wildySwordTeleport()
    end

end

while API.Read_LoopyLoop() do


end