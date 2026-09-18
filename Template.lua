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

local function loadLastPreset(item) 
        if not Interact:NPC("Banker", "Load Last Preset from") then
            API.logWarn("Unable to interact with Banker!")
            API.Write_LoopyLoop(false)
        end
        API.RandomSleep2(1200, 0, 3600)
        return Inventory:Contains(item)
end

local function coatIncense()

    local boxAB = API.GetABs_name("Incense", false)

    if boxAB.action == "Coat" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1800, 0, 3200)

    return MISC.doCrafting()
end

function craftIncense()

    local boxAB = API.GetABs_name("logs", false)

    if boxAB.action == "Craft" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1800, 0, 3200)

    return MISC.doCrafting()

end

local function readChat()
    local chats = API.GatherEvents_chat_check()

    for index, value in ipairs(chats) do
        if value.text then
            API.logDebug("Chat: "..value.text)
            return value.text
        end
    end   
    return nil
end

local function woodBoxFullCheck()
    local check = readChat()
    if check  == "<col=EB2F2F>Your wood box is too full to deposit any items from your backpack." then
        return true
    else
        return false
    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------

    --[[if Inventory:Contains("Accursed ashes") and Inventory:Contains("Maple incense sticks") then
        coatIncense() 
    else
        if not loadLastPreset("Accursed ashes") then
            API.logWarn("No Accursed ashes in inventory!")
            API.Write_LoopyLoop(false)
            return false
        end
    end]]

    --[[if Inventory:Contains("Yew logs") then
        craftIncense() 
    else
        if not loadLastPreset("Yew logs") then
            API.logWarn("No Yew logs in inventory!")
            API.Write_LoopyLoop(false)
            return false
        end
    end]]

    print("Wood box full: "..tostring(woodBoxFullCheck()))

    API.RandomSleep2(800, 0, 400)
end----------------------------------------------------------------------------------

