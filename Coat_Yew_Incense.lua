print("TESTING TEMPLATE")

local API = require("api")
local MISC = require("lib/MISC")


local Max_AFK = 5

local function loadLastPreset(item) 
        if not Interact:NPC("Banker", "Load Last Preset from") then
            API.logWarn("Unable to interact with Banker!")
            API.Write_LoopyLoop(false)
        end
        API.RandomSleep2(600, 0, 1200)
        return Inventory:Contains(item)
end

local function coatIncense()

    local boxAB = API.GetABs_name("Incense", false)

    if boxAB.action == "Coat" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1200, 600, 1200)

    return MISC.doCrafting()
end

local main()

  if Inventory:Contains("Infernal ashes") and Inventory:Contains("Yew incense sticks") then
        coatIncense() 
    else
        if not loadLastPreset("Infernal ashes") then
            API.logWarn("No Infernal ashes in inventory!")
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
