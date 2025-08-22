local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")

local Woodcutting = {}

TREES = {

    TREE =              {name = "Tree",                 id = nil},
    ACHEY =             {name = "Achey tree",           id = nil},
    OAK =               {name = "Oak",                  id = nil},
    WILLOW =            {name = "Willow",               id = nil},
    TEAK =              {name = "Teak",                 id = nil},
    MAPLE =             {name = "Maple Tree",           id = nil},
    ACADIA =            {name = "Acadia tree",          id = nil},
    MAHOGANY =          {name = "Mahogany",             id = nil},
    ARCTIC_PINE =       {name = "Arctic pine",          id = nil},
    EUCALYPTUS =        {name = "Eucalyptus tree",      id = nil},
    YEW =               {name = "Yew",                  id = nil},
    IVY =               {name = "Ivy",                  id = nil},
    MAGIC =             {name = "Magic tree",           id = nil},
    ELDER =             {name = "Elder tree",           id = nil},
    CRYSTAL =           {name = "Crystal tree",         id = nil},
    BLOODWOOD =         {name = "Bloodwood tree",       id = nil},
    BLISTERWOOD =       {name = "Blisterwood tree",     id = nil},
    GOLDEN_BAMBOO =     {name = "Golden bamboo",        id = nil},
    OVERGROWN_IDOLS =   {name = "Overgrown idols",      id = nil}

}

LOGS = {

    LOGS =              {name = "Logs",                 id = 1511},
    ACHEY =             {name = "Achey tree logs",      id = 2862},
    OAK =               {name = "Oak logs",             id = 1521},
    WILLOW =            {name = "Willow logs",          id = 1519},
    TEAK =              {name = "Teak logs",            id = 6333},
    MAPLE =             {name = "Maple logs",           id = 1517},
    MAHOGANY =          {name = "Mahogany logs",        id = 6332},
    ARCTIC_PINE =       {name = "Arctic pine logs",     id = 10810},
    EUCALYPTUS =        {name = "Eucalyptus logs",      id = 12581},
    YEW =               {name = "Yew logs",             id = 1515},
    MAGIC =             {name = "Magic logs",           id = 1513},
    ELDER =             {name = "Elder logs",           id = 29556},
    CRYSTAL =           {name = "Crystal logs",         id = 49692},
    BLOODWOOD =         {name = "Bloodwood logs",       id = 24121},
    BLISTERWOOD =       {name = "Blisterwood logs",     id = 49669},
    BAMBOO =            {name = "Bamboo",               id = 21777}

}

TREE_TO_LOG_MAP = {
    TREE        = "LOGS",     -- normal "Tree" → LOGS.LOGS
    OAK         = "OAK",
    WILLOW      = "WILLOW",
    MAPLE       = "MAPLE",
    YEW         = "YEW",
    MAGIC       = "MAGIC",
    ELDER       = "ELDER",
}

WOOD_BOXES = {

    WOOD =      {name = "Wood box",             id = 54895},
    OAK =       {name = "Oak wood box",         id = 54897},
    WILLOW =    {name = "Willow wood box",      id = 54899},
    TEAK =      {name = "Teak wood box",        id = nil},
    MAPLE =     {name = "Maple wood box",       id = nil},
    MAHOGANY =  {name = "Mahogany wood box",    id = nil},
    YEW =       {name = "Yew wood box",         id = nil},
    MAGIC =     {name = "Magic wood box",       id = nil},
    ELDER =     {name = "Elder wood box",       id = 54913}

}

Woodcutting.GLOBALS = {
    currentState = "Idle",
    boxType = WOOD_BOXES.WOOD, -- Default wood box type
    treeType = nil, 
    logType = nil, 
    treesChopped = 0,
    logsGathered = 0,
    estProfit = 0,
    estProfitPerHour = 0
}

function Woodcutting.setTreeAndLogType()

    if API.GetLocalPlayerAddress() == 0 then
        API.logError("Woodcutting.setTreeAndLogType(): Local player address not found.")
        API.logDebug("Setting defaults for script.")
        Woodcutting.GLOBALS.treeType = TREES.TREE
        Woodcutting.GLOBALS.logType = LOGS.LOGS
        return
    end

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

    Woodcutting.GLOBALS.treeType, Woodcutting.GLOBALS.logType = pickTier(wcLvl, fmLvl)
    API.logDebug("Chosen Tree: " .. Woodcutting.GLOBALS.treeType.name)
    API.logDebug("Chosen Log: " .. Woodcutting.GLOBALS.logType.name)
    API.logDebug("update WC.setTreeAndLogType() if wrong tree selected!")
    
end

function Woodcutting.getLogType()
    if Woodcutting.GLOBALS.logType == nil then
        API.logWarn("Log type is not set. Cannot return log type.")
        return nil
    end
    return Woodcutting.GLOBALS.logType
end

function Woodcutting.getTreeType()
    if Woodcutting.GLOBALS.treeType == nil then
        API.logWarn("Tree type is not set. Cannot return tree type.")
        return nil
    end
    return Woodcutting.GLOBALS.treeType
end

----METRICS----
function Woodcutting.metrics()
    if Woodcutting.GLOBALS.treeType == nil or Woodcutting.GLOBALS.logType == nil then
        API.logWarn("Tree type or log type is not set. Cannot display metrics.")
        return
    end

    local METRICS = {
        {"Current State: ", Woodcutting.GLOBALS.currentState},
        {"Tree Type: ", Woodcutting.GLOBALS.treeType.name},
        {"GE Value: ", MISC.fmt(API.GetExchangePrice(Woodcutting.GLOBALS.logType.id))},
        {"# of logs: ", MISC.fmt(Woodcutting.GLOBALS.logsGathered)},
        {"# of logs/hr: ", MISC.fmt(MISC.itemsPerHour(Woodcutting.GLOBALS.logsGathered))},
        {"Est. profit: ", MISC.fmt(MISC.EstimatedProfit(Woodcutting.GLOBALS.logType.id, Woodcutting.GLOBALS.logsGathered))},
        {"Est. profit/hr: ", MISC.fmt(MISC.EstimatedProfitPerHour(Woodcutting.GLOBALS.logType.id, Woodcutting.GLOBALS.logsGathered))}
    }
    API.DrawTable(METRICS)
end

---@return number action -- 1-Craft, 2-Light, 3-Use, 4-Drop
function Woodcutting.useLogs(action)

    if WC.GLOBALS.logType == nil then
        return false
    end

    if action ~= 1 and action ~= 2 and action ~= 3 and action ~= 4 then
        API.logDebug("Firemaking useLogs action is not valid: ", action)
        API.Write_LoopyLoop(false)
        return false
    end

    if Inventory:DoAction(Woodcutting.GLOBALS.logType.id, action, API.OFF_ACT_GeneralInterface_route) then
        API.logDebug("Couldn't use log: " .. Woodcutting.GLOBALS.logType.name)
        return true
    else
        return false
    end
end

---@return boolean -- returns true if we successfully start chopping a tree
function Woodcutting.chop()
    API.logDebug("Woodcutting.chop(): " .. Woodcutting.GLOBALS.treeType.name)
    return Interact:Object(Woodcutting.GLOBALS.treeType.name, "Chop down", 30)
end

---@return any -- returns the key of wood box found in inv or nil if none
function Woodcutting.findWoodBox()
    return nil
end

---@return number -- returns the # of logs of the specified type within the Wood Box
function Woodcutting.woodBoxCount()
    return 0
end

---@return capacity number -- returns the max capacity of current wood box or nil if none
function Woodcutting.woodBoxCapacity()
    local baseCapacities = {
        [55767] = 70,  -- Wood box
        [55768] = 80,  -- Oak wood box
        [55769] = 90,  -- Willow wood box
        [55770] = 100, -- Teak wood box
        [55771] = 110, -- Maple wood box
        [55772] = 130, -- Mahogany wood box
        [55773] = 140, -- Yew wood box
        [55774] = 150, -- Magic wood box
        [55775] = 160  -- Elder wood box
    }
    return 0
end

---@return boolean -- returns true if the Wood Box gets filled with an # of items
function Woodcutting.fillWoodBox()
    return false
end

---@return boolean -- returns true if we activate the use option for our Wood Box
function Woodcutting.useWoodBox()
    return false
end

---@return boolean -- returns true if the Wood Box is full
function Woodcutting.woodBoxFull()
    return false
end

---@return boolean -- returns true when inv is full. fills the wood box along the way if we have one
function Woodcutting.gather()

    Woodcutting.GLOBALS.boxType = Woodcutting.findWoodBox()
    local checkWoodBox = Woodcutting.GLOBALS.boxType ~= nil
    local failSafe = 0

    while not API.InvFull_() and (not checkWoodBox or not Woodcutting.woodBoxFull()) and API.Read_LoopyLoop() do        
        if not Woodcutting.chop() then
            API.logWarn("Unable to chop tree: "..Woodcutting.GLOBALS.treeType.name)
            failSafe = (failSafe + 1)
            if failSafe >= 10 then
                API.Write_LoopyLoop(false)
                return false
            end
        else
            API.logInfo("Chopping tree: "..Woodcutting.GLOBALS.treeType.name)
            while API.ReadPlayerMovin() and API.Read_LoopyLoop() do
                API.RandomSleep2(600, 0, 250)
            end
            while API.CheckAnim(75) do
                if checkWoodBox then
                    if API.Invfreecount_() < math.random(0,8) then
                        if not Woodcutting.woodBoxFull() then
                            Woodcutting.fillWoodBox()
                            API.RandomSleep2(600, 0, 250)
                        end
                    end
                end
                API.DoRandomEvents()
                API.RandomSleep2(600, 0, 250)
            end
        end
    end

    return true

end

return Woodcutting