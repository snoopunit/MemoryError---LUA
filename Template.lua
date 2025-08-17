print("TESTING TEMPLATE")

local API = require("api")
local UTILS = require("UTILS")
local WC = require("WOODCUTTING")
local BANK = require("BANKING")
local FIRE = require("FIREMAKING")
local FISH = require("FISHING")
local HERB = require("HERBLORE")
local MISC = require("MISC")

local makeIncense = true
local Max_AFK = 5

function setTreeAndLogType()

    local wcLvl = MISC.getLevel("WOODCUTTING")
    local fmLvl = MISC.getLevel("FIREMAKING")

    API.logDebug("Woodcutting Level: " .. wcLvl)
    API.logDebug("Firemaking Level: " .. fmLvl)

    local TIERS = {
        { tree = TREES.TREE,     log = LOGS.LOGS,    wc = 1,  fm = 1  },
        { tree = TREES.OAK,      log = LOGS.OAK,     wc = 10, fm = 15 },
        { tree = TREES.WILLOW,   log = LOGS.WILLOW,  wc = 20, fm = 30 },
        { tree = TREES.YEW,      log = LOGS.YEW,     wc = 70, fm = 60 },
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

    if API.InvFull_() then
        while Inventory:GetItemAmount(logType.name) > 2 do
            if makeIncense then
                if not FIRE.makeIncense(logType) then
                    API.Write_LoopyLoop(false)
                    return
                else
                    while API.CheckAnim(75) do
                        API.RandomSleep2(600, 0, 250)
                    end
                end
            else
                if not FIRE.addToBonfire(logType) then
                    if not FIRE.useLogs(logType, 2) then
                        API.Write_LoopyLoop(false)
                        return
                    end
                end
            end
            API.RandomSleep2(800, 0, 600)
        end
    else
        WC.gather(treeType, logType)
    end

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

--HERB.drawGUI()
setTreeAndLogType()


while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------



    --startHerbloreRoutine()
    Woodcutting_and_Firemaking(treeToUse, logToUse)

    

end----------------------------------------------------------------------------------

