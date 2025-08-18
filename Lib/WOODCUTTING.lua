local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")
local FIRE = require("lib/FIREMAKING")

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

GLOBALS = {
    currentState = "Idle",
    boxType = nil,
    treeType = nil,
    logType = nil, 
    treesChopped = 0,
    logsGathered = 0,
    estProfit = 0,
    estProfitPerHour = 0
}

function Woodcutting.setTreeAndLogType()

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

    GLOBALS.treeType, GLOBALS.logType = pickTier(wcLvl, fmLvl)
    FIRE.GLOBALS.logType = GLOBALS.logType
    API.logDebug("Chosen Tree: " .. GLOBALS.treeType.name)
    API.logDebug("Chosen Log: " .. GLOBALS.logType.name)
    API.logDebug("update WC.setTreeAndLogType() if wrong tree selected!")
    
end

----METRICS----
function Woodcutting.metrics()
    if GLOBALS.treeType == nil or GLOBALS.logType == nil then
        API.logWarn("Tree type or log type is not set. Cannot display metrics.")
        return
    end

    local METRICS = {
        {"Current State: ", GLOBALS.currentState},
        {"Tree Type: ", GLOBALS.treeType.name},
        {"GE Value: ", MISC.fmt(API.GetExchangePrice(GLOBALS.logType.id))},
        {"# of logs: ", MISC.fmt(GLOBALS.logsGathered)},
        {"# of logs/hr: ", MISC.fmt(MISC.itemsPerHour(GLOBALS.logsGathered))},
        {"Est. profit: ", MISC.fmt(MISC.EstimatedProfit(GLOBALS.logType.id, GLOBALS.logsGathered))},
        {"Est. profit/hr: ", MISC.fmt(MISC.EstimatedProfitPerHour(GLOBALS.logType.id, GLOBALS.logsGathered))}
    }
    API.DrawTable(METRICS)
end

---@return boolean -- returns true if we successfully start chopping a tree
function Woodcutting.chop()
    API.logDebug("Woodcutting.chop(): " .. GLOBALS.treeType.name)
    return Interact:Object(GLOBALS.treeType.name, "Chop down", 30)
end

---@return any -- returns the key of wood box found in inv or nil if none
function Woodcutting.findWoodBox()

    local invItems = API.ReadInvArrays33()

    

    for tableKey, tableInfo in pairs(WOOD_BOXES) do

        for _, item in ipairs(invItems) do

            if item.textitem == "<col=b8d1d1>"..tableInfo.name then

                API.logDebug("Found: "..tableInfo.name.." check if ID needs updating")

                if tableInfo.id ~= item.itemid1 then

                    API.logDebug("Updating " .. tableInfo.name .. " ID from " .. (tableInfo.id or "nil") .. " to " .. item.itemid1)

                    WOOD_BOXES[tableKey].id = item.itemid1

                end

                API.logDebug("tableKey: "..tableKey)

                return tableKey  -- This returns the actual key from the WOOD_BOXES table

            end

        end

    end

    return nil

end

---@return number -- returns the # of logs of the specified type within the Wood Box
function Woodcutting.woodBoxCount() 

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
    local woodcuttingLevel = API.XPLevelTable(API.GetSkillXP("WOODCUTTING"))
    local baseCapacity = baseCapacities[GLOBALS.boxType.id]
    if baseCapacity then
        local levelBonus = math.floor(woodcuttingLevel / 10) * 10
        return math.min(baseCapacity + levelBonus, baseCapacity + 100)
    else
        return nil  -- Return nil if the boxId is not recognized
    end
end

---@return boolean -- returns true if the Wood Box gets filled with an # of items
function Woodcutting.fillWoodBox()

    local box = Woodcutting.findWoodBox()

    if box then

        API.logInfo("Filling: "..WOOD_BOXES[box].name)

        return API.DoAction_Inventory1(WOOD_BOXES[box].id,0,1,API.OFF_ACT_GeneralInterface_route)

    end

end

---@return boolean -- returns true if we activate the use option for our Wood Box
function Woodcutting.useWoodBox()

    local box = Woodcutting.findWoodBox()

    return API.DoAction_Inventory1(box.id,0,0,API.OFF_ACT_Bladed_interface_route) --API.DoAction_Inventory1(box.id,0,1,API.OFF_ACT_GeneralInterface_route)

end

---@return boolean -- returns true if the Wood Box is full
function Woodcutting.woodBoxFull()

end

---@return boolean -- returns true when inv is full. fills the wood box along the way if we have one
function Woodcutting.gather()

    GLOBALS.boxType = Woodcutting.findWoodBox()
    local checkWoodBox = GLOBALS.boxType ~= nil
    local failSafe = 0

    while not API.InvFull_() and (not checkWoodBox or not Woodcutting.woodBoxFull()) and API.Read_LoopyLoop() do        
        if not Woodcutting.chop() then
            API.logWarn("Unable to chop tree: "..GLOBALS.treeType.name)
            failSafe = (failSafe + 1)
            if failSafe >= 10 then
                API.Write_LoopyLoop(false)
                return false
            end
        else
            API.logInfo("Chopping tree: "..GLOBALS.treeType.name)
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