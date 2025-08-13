print("TESTING TEMPLATE")

local API = require("api")
local UTILS = require("UTILS")
local WC = require("WOODCUTTING")
local BANK = require("BANKING")
local FIRE = require("FIREMAKING")
local FISH = require("FISHING")
local HERB = require("HERBLORE")

local do_stuff = true
local do_debug = true

local Max_AFK = 5

function Woodcutting_and_Firemaking(treeType, logType)
    local failTimer = 0
    if API.InvFull_() then
        if FIRE.makeIncense(logType) then
            API.RandomSleep2(1200,0,800)
            if FIRE.craftIncense() then
                while API.InvItemcount_String(logType.name) > 2 do
                    API.RandomSleep2(600,0,600)
                    API.DoRandomEvents()
                end
            end
        end
    else
        WC.gather(treeType, logType)
    end
    API.RandomSleep2(2400, 0 ,600)
end

function Fishing_and_Banking(spotType, bankType)
    if API.InvFull_() then
        API.logInfo("Noting...")
        BANK.doBank(bankType, "note")
    else
        FISH.gather(spotType)
    end
    API.RandomSleep2(2400, 0 ,600)
end

function Potionmaking()
    API.logDebug("Potionmaking()")
    local failTimer = API.SystemTime()
    BANK.loadLastPreset()
    API.RandomSleep2(600,0,600)
    while (API.SystemTime() - failTimer) < 30000 do
        if Inventory:IsFull() then
            API.logDebug("Got a full inventory!")
            break
        else
            API.RandomSleep2(250,0,250)
        end
    end
    if (API.SystemTime() - failTimer) > 30000 then
        API.logWarn("30s failTimer exceeded!")
        if not Inventory:IsFull() then
            API.logWarn("Didn't grab a full inventory!")
            API.Write_LoopyLoop(false)
            return
        end
    end
    HERB.mixPotionsAtPortableWell()
    failTimer = API.SystemTime()
    API.RandomSleep2(600,0,600)
    while (API.SystemTime() - failTimer) < 30000 do
        if UTILS.isCraftingInterfaceOpen() then
            API.logDebug("Detected Crafting Interface!")
            break
        else
            API.RandomSleep2(250,0,250)
        end
    end
    if (API.SystemTime() - failTimer) > 30000 then
        API.logWarn("30s failTimer exceeded!")
        if not UTILS.isCraftingInterfaceOpen() then
            API.logWarn("Didn't detect crafting interface!")
            API.Write_LoopyLoop(false)
            return
        end
    end
    HERB.clickStart()
    API.RandomSleep2(2500,0,2500)
    while API.CheckAnim(100) do
        API.RandomSleep2(250,0,250)
    end
end

function getLevel(skill)
    return API.XPLevelTable(API.GetSkillXP(skill))
end

--main loop
API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if do_debug then
        --API.DeBuffbar_GetAllIDs(true)
        --API.Buffbar_GetAllIDs(true)
        --BANK.getCoords(BANKERS.BURTHORPE)

    end

    if do_stuff then

        if API.GetLocalPlayerName() == "SirRylington" then    
            if getLevel("FIREMAKING") < 90 or getLevel("WOODCUTTING") < 90 then
                Woodcutting_and_Firemaking(TREES.YEW, LOGS.YEW)
            else
                API.Write_LoopyLoop(false)
            end
        end
        
        if API.GetLocalPlayerName() == "snoopunit666" then
            if getLevel("HERBLORE") < 120 then
                Potionmaking()
            else
                API.Write_LoopyLoop(false)
            end
        end

        if API.GetLocalPlayerName() == "playah8ah" then 
            if getLevel("FIREMAKING") < 90 or getLevel("WOODCUTTING") < 90 then
                Woodcutting_and_Firemaking(TREES.YEW, LOGS.YEW)
            else
                API.Write_LoopyLoop(false)
            end
        end
        
    end
    
end----------------------------------------------------------------------------------