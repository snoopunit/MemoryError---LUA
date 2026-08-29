print("TESTING TEMPLATE")

local API = require("api")
local UTILS = require("UTILS")
local WC = require("lib/WOODCUTTING")
local COOK = require("lib/COOKING")
local BANK = require("lib/BANKING")
local FIRE = require("lib/FIREMAKING")
local FISH = require("lib/FISHING")
local HERB = require("lib/HERBLORE")
local MINE = require("lib/MINING")
local MISC = require("lib/MISC")
local TASK = require("lib/TASK")

local Max_AFK = 5

local function loadLastPreset() 
        if not Interact:NPC("Banker", "Load Last Preset from") then
            API.logWarn("Unable to interact with Banker!")
            API.Write_LoopyLoop(false)
        end
        API.RandomSleep2(600, 0, 1200)
        return Inventory:Contains("Accursed ashes")
end

local function coatIncense()

    local boxAB = API.GetABs_name("Incense", false)

    if boxAB.action == "Coat" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1200, 600, 1200)

    return MISC.doCrafting()
end

function craftIncense()

    if not Inventory:Contains("Maple logs") then
        API.logWarn("No Maple logs in inventory!")
        API.Write_LoopyLoop(false)
        return false
    end

    local boxAB = API.GetABs_name("logs", false)

    if boxAB.action == "Craft" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1200, 600, 1200)

    return MISC.doCrafting()

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    if Inventory:Contains("Accursed ashes") then
        coatIncense()
        --craftIncense()
    else
        if not loadLastPreset() then
            API.logWarn("No Maple logs in inventory!")
            API.Write_LoopyLoop(false)
            return false
        end
    end
    API.RandomSleep2(800, 0, 400)
end----------------------------------------------------------------------------------

