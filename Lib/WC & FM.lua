print("Woodcutting & Firemaking")

local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")
local WC = require("lib/WOODCUTTING")
local FIRE = require("lib/FIREMAKING")

local makeIncense = true
local Max_AFK = 5

local GLOBALS = {
    logsCut = 0,
    logType = { ID = 0, Name = "None" },
    logsPerHour = 0,
    incenseMade = 0,
    incensePerHour = 0,
    estProfit = 0,
    estProfitPerHour = 0,
    currentState = "Idle"
}

function PotionsPerHour()

    if GLOBALS.potionsMade == 0 then

        return 0

    end



    local elapsedTime = API.ScriptRuntime() / 3600 

    

    return math.floor(GLOBALS.potionsMade / elapsedTime)

end

function EstimatedProfit() 

    local profitPerPotion = API.GetExchangePrice(GLOBALS.potionType.ID)

    return GLOBALS.potionsMade * profitPerPotion

end

function EstimatedProfitPerHour()

    local elapsedTime = API.ScriptRuntime() / 3600

    

    return math.floor(EstimatedProfit() / elapsedTime)    

end

function metrics() 

    GLOBALS.potionsPerHour = PotionsPerHour()
    GLOBALS.estProfit = EstimatedProfit()
    GLOBALS.estProfitPerHour = EstimatedProfitPerHour()

    local function fmt(value)
        if value > 999 then
            return MISC.comma_value(value)
        end
        return tostring(value)
    end

    return {
        {"Current State: ", GLOBALS.currentState},
        {"Potion Type: ", GLOBALS.potionType.Name},
        {"GE Value: ", fmt(API.GetExchangePrice(GLOBALS.potionType.ID))},
        {"# of potions: ", fmt(GLOBALS.potionsMade)},
        {"# of potions/hr: ", fmt(GLOBALS.potionsPerHour)},
        {"Est. profit: ", fmt(GLOBALS.estProfit)},
        {"Est. profit/hr: ", fmt(GLOBALS.estProfitPerHour)}
    }

end

function Herblore.updatePotionNum(potionsMade)

    GLOBALS.potionsMade = (GLOBALS.potionsMade + potionsMade)

    API.DrawTable(Herblore.metrics())

end

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
                    return
                end
            else
                if not FIRE.addToBonfire(logType) then
                    if not FIRE.useLogs(logType, 2) then
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

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)
setTreeAndLogType()

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    Woodcutting_and_Firemaking(treeToUse, logToUse)
end----------------------------------------------------------------------------------