print("TESTING TEMPLATE")

local API = require("api")
local UTILS = require("UTILS")
local WC = require("WOODCUTTING")
local BANK = require("BANKING")
local FIRE = require("FIREMAKING")
local FISH = require("FISHING")
local HERB = require("HERBLORE")
local MISC = require("MISC")

local do_stuff = true
local do_debug = true

local Max_AFK = 5

function Woodcutting_and_Firemaking(treeType, logType)
    local failTimer = 0
    if API.InvFull_() then
        if FIRE.makeIncense(logType) then
            API.RandomSleep2(1200,0,800)
            if isChooseToolOpen() then
                WC.logCraftingInterface("Incense")
                API.RandomSleep2(1800,0,800)   
            else
                API.RandomSleep2(1200,0,600)     
            end
            if not UTILS.isCraftingInterfaceOpen() then
                API.logWarn("Crafting Interface is not open!")
                API.Write_LoopyLoop(false)
                return
            end
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
    if BANK.doPreset(1) then
        if not Inventory:IsFull() then
            API.logWarn("Didn't grab a full inventory!")
            API.Write_LoopyLoop(false)
            return
        end
        if HERB.makeVials() then
            waitForCraftingInterface()
            if clickStart() then
                while API.CheckAnim(75) do
                    API.RandomSleep2(600,0,250)
                end
            end
        end
    else
        API.logWarn("Failed to load preset 1!")
        API.Write_LoopyLoop(false)
        return
    end
    if BANK.doPreset(2) then
        if not Inventory:IsFull() then
            API.logWarn("Didn't grab a full inventory!")
            API.Write_LoopyLoop(false)
            return
        end
        if HERB.mixPotionsAtPortableWell() then
            waitForCraftingInterface()
            if clickStart() then
                while API.CheckAnim(75) do
                    API.RandomSleep2(600,0,250)
                end
            end
        end
    else    
        API.logWarn("Failed to load preset 2!")
        API.Write_LoopyLoop(false)
        return
    end
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

        if API.GetLocalPlayerName() == "" then    
            if getLevel("HERBLORE") < 120 then
                Potionmaking()
            else
                API.Write_LoopyLoop(false)
            end
        end
        
        if API.GetLocalPlayerName() == "" then
            if getLevel("HERBLORE") < 120 then
                Potionmaking()
            else
                API.Write_LoopyLoop(false)
            end
        end

        if API.GetLocalPlayerName() == "" then 
            --[[if getLevel("FIREMAKING") < 90 then
                Woodcutting_and_Firemaking(TREES.WILLOW, LOGS.WILLOW)  
            else
                API.Write_LoopyLoop(false)
            end]]

            

        end
        
    end
    

end----------------------------------------------------------------------------------
