print("Fletch & String bows")

local API = require("api")
local BANK = require("lib/BANKING")
local MISC = require("lib/MISC")

local logType = "Maple logs"
local unstrungType = "Maple longbow (unstrung)"
local strungType = "Maple longbow"

local Max_AFK = 5

local function loadLastPreset() 
        if not Interact:NPC("Banker", "Load Last Preset from") then
            API.logWarn("Unable to interact with Banker!")
            API.Write_LoopyLoop(false)
        end
        API.RandomSleep2(1200, 0, 3600)
        return Inventory:IsFull()
end

local function fletchUnstrungLongbows()

    local boxAB = API.GetABs_name("log", false)

    if boxAB.action == "Craft" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1800, 0, 3200)

    return MISC.doCrafting()
end

function stringLongbows()

    local boxAB = API.GetABs_name("unstrung", false)

    if boxAB.action == "String" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1800, 0, 3200)

    return MISC.doCrafting()

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------

    if Inventory:Contains("Maple logs") then
        fletchUnstrungLongbows() 
    end

    API.RandomSleep2(800, 0, 2400)

    if Inventory:Contains("Bowstring") then
        stringLongbows() 
    end

    API.RandomSleep2(800, 0, 2400)

    if not Inventory:IsFull() then
        loadLastPreset()
    end

    API.RandomSleep2(800, 0, 2400)

end----------------------------------------------------------------------------------
