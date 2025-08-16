print("TESTING TEMPLATE")



local API = require("api")

local UTILS = require("UTILS")

local WC = require("WOODCUTTING")

local BANK = require("BANKING")

local FIRE = require("FIREMAKING")

local FISH = require("FISHING")

local HERB = require("HERBLORE")

local MISC = require("MISC")



local Max_AFK = 5

function setTreeAndLogType()

    local wcLvl = MISC.getLevel("WOODCUTTING")
    local fmLvl = MISC.getLevel("FIREMAKING")

    API.logDebug("Woodcutting Level: " .. wcLvl)
    API.logDebug("Firemaking Level: " .. fmLvl)

    local TIERS = {
        { tree = TREES.TREE,     log = LOGS.LOGS,         wc = 1,  fm = 1  },
        { tree = TREES.OAK,      log = LOGS.OAK_LOGS,     wc = 10, fm = 15 },
        { tree = TREES.WILLOW,   log = LOGS.WILLOW_LOGS,  wc = 20, fm = 30 },
        { tree = TREES.TEAK,     log = LOGS.TEAK_LOGS,    wc = 30, fm = 35 },
        { tree = TREES.MAPLE,    log = LOGS.MAPLE_LOGS,   wc = 40, fm = 45 },
        { tree = TREES.MAHOGANY, log = LOGS.MAHOGANY_LOGS,wc = 60, fm = 50 },
        { tree = TREES.YEW,      log = LOGS.YEW_LOGS,     wc = 70, fm = 60 },
        { tree = TREES.MAGIC,    log = LOGS.MAGIC_LOGS,   wc = 80, fm = 75 },
    }

    -- Choose the highest tier where BOTH wcLvl and fmLvl meet the requirements
    local function pickTier(wcLvl, fmLvl)

        local chosenTree, chosenLog = TIERS[1].tree, TIERS[1].log -- default to normal

        for i = #TIERS, 1, -1 do
        
            local t = TIERS[i]

            if wcLvl >= t.wc and fmLvl >= t.fm then

                chosenTree, chosenLog = t.tree, t.log
                break
                
            end

        end

        return chosenTree, chosenLog
    
    end

    treeToUse, logToUse = pickTier(wcLvl, fmLvl)

end


function Woodcutting_and_Firemaking(treeType, logType)

    local failTimer = 0

    if API.InvFull_() then

        --[[if FIRE.makeIncense(logType) then

            API.RandomSleep2(1200,0,800)

            if MISC.isChooseToolOpen() then

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

        end]]

        if not FIRE.findFires() then

            if not FIRE.lightLog(logType) then

                API.logWarn("Failed to light a fire with "..logType.name)
                API.Write_LoopyLoop(false)
                return

            end

        end

        if not FIRE.useLogOnFire(logType) then

            API.logWarn("Failed to use "..logType.name.." on fire.")
            API.Write_LoopyLoop(false)
            return

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



--main loop

API.Write_LoopyLoop(true)

API.SetDrawLogs(true)

API.SetDrawTrackedSkills(true)

API.SetMaxIdleTime(Max_AFK)

HERB.drawGUI()
--setTreeAndLogType()


while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------



    startHerbloreRoutine()
    --Woodcutting_and_Firemaking(treeToUse, logToUse)

    

end----------------------------------------------------------------------------------

