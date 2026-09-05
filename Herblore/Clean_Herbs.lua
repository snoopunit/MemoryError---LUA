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
        API.RandomSleep2(600, 0, 250)
        return HERB.findGrimyHerbs()
end

local function cleanHerbs(herbID)
    if HERB.cleanHerbs(herbID) then
        MISC.doCrafting()
    else
        API.logWarn("Unable to clean herbs!")
        API.Write_LoopyLoop(false)
    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    if HERB.findGrimyHerbs() then
        if HERB.cleanHerbs(HERB.findGrimyHerbs().ID) then
            MISC.doCrafting()
        end
    else
        if not loadLastPreset() then
            API.logWarn("No grimy herbs in inventory!")
            API.Write_LoopyLoop(false)
            return false
        end
    end

    API.RandomSleep2(800, 0, 400)
end----------------------------------------------------------------------------------