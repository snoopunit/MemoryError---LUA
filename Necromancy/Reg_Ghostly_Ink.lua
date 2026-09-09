print("Regular Ghostly Ink")

local API = require("api")
local MISC = require("lib/MISC")


local Max_AFK = 5

local function loadLastPreset() 
        if not Interact:NPC("Banker", "Load Last Preset from") then
            API.logWarn("Unable to interact with Banker!")
            API.Write_LoopyLoop(false)
        end
        API.RandomSleep2(600, 0, 1200)
        return Inventory:Contains("Lesser necroplasm") and Inventory:Contains("Vial of water") and Inventory:Contains("Ashes")
end

local function makeRegInk()

    local boxAB = API.GetABs_name("Necroplasm", false)

    if boxAB.action == "Craft" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1400, 0, 600)

    return MISC.doCrafting()
end

local function main()

  
        if  loadLastPreset() then
            makeRegInk()
        else
            API.logWarn("No more inventory!")
            API.Write_LoopyLoop(false)
            return false
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
