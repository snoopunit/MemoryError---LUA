print("Dwarf Weed Incense")

local API = require("api")
local MISC = require("lib/MISC")
local HERB = require("lib/HERBLORE")

local Max_AFK = 5

local function loadLastPreset(item) 
        if not Interact:NPC("Banker", "Load Last Preset from") then
            API.logWarn("Unable to interact with Banker!")
            API.Write_LoopyLoop(false)
        end
        API.RandomSleep2(1200, 0, 1200)
        return Inventory:IsFull()
end

local function addHerbs()

    local boxAB = API.GetABs_name("Infernal yew incense", false)

    if boxAB.action == "Add herb" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1200, 600, 1200)

    return MISC.doCrafting()
end

local function main()

  if Inventory:Contains("Infernal yew incense sticks") then
    local herb = HERB.findGrimyHerbs()

    if herb then
        if HERB.cleanHerbs(herb.ID) then
            API.RandomSleep2(1200, 0, 600)
            MISC.doCrafting()
        end
    end

    addHerbs()
        
  else
        if not loadLastPreset("Infenal yew incense sticks") then
            API.logWarn("No Infernal yew incense sticks in inventory!")
            API.Write_LoopyLoop(false)
            return false
        end
    end

end


API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    main()
    API.RandomSleep2(800, 0, 400)
end----------------------------------------------------------------------------------
