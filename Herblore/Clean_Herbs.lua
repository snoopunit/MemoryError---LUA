local API = require("api")
local HERB = require("lib/HERBLORE")
local MISC = require("lib/MISC")

local function loadLastPreset() 
    if not Interact:NPC("Banker", "Load Last Preset from",10) then
        if not Interact:Object("Bank chest", "Load Last Preset from",10) then
            API.logWarn("Unable to interact with Banker!")
            API.Write_LoopyLoop(false)
        end
    end
    return Inventory:IsFull()
end

local function main()

    local herb = HERB.findGrimyHerbs()

    if herb then
        if HERB.cleanHerbs(herb.ID) then
            MISC.doCrafting()
        end
    else
        if not loadLastPreset() then
            API.logWarn("Failed to load a full inventory!")
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