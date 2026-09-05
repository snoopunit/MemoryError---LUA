local API = require("api")
local HERB = require("lib/HERBLORE")
local MISC = require("lib/MISC")

local function loadLastPreset(herb) 
        if not Interact:NPC("Banker", "Load Last Preset from",10) then
            if not Interact:Object("Bank chest", "Load Last Preset from",10) then
                API.logWarn("Unable to interact with Banker!")
                API.Write_LoopyLoop(false)
            end
        end
        API.RandomSleep2(600, 0, 250)
        return Inventory:Contains(herb.Name)
end

local function main()

    local herb = HERB.findGrimyHerbs()

    if herb then
        if HERB.cleanHerbs(herb.ID) then
            MISC.doCrafting()
        end
    else
        if not loadLastPreset(herb) then
            API.logWarn("No grimy herbs in inventory!")
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