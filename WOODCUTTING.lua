local API = require("api")

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

--@return Location Data -- returns "Location = {{x,y,z}...}" 
function Woodcutting.updateTrees()
    
    API.logWarn("updateTrees() function has not been implemented yet!")

end

---@param object string
---@return boolean -- returns true if we successfully start chopping a tree
function Woodcutting.chop(treeType)

    API.logDebug("Searching for: "..treeType.name.."s")
    local trees = API.ReadAllObjectsArray({12},{-1},{treeType.name})
    API.logDebug("Found: "..#trees)

    if #trees == nil or #trees == 0 then
        API.logWarn("Couldn't find any: "..treeType.name.."s")
        API.Write_LoopyLoop(false)
        return false  
    end

    local validTrees = {}
    for _, tree in ipairs(trees) do
        if tree.Action == "Chop down" and tree.Bool1 == 0 and tree.Distance < 30 then
            table.insert(validTrees, tree)
        end
    end
    API.logDebug("Valid: "..#validTrees)

    local playerX, playerY = API.PlayerCoord().x, API.PlayerCoord().y

    -- Sort trees by distance
    table.sort(validTrees, function(a, b)
        local distA = a.Distance or API.Math_DistanceW(a.Tile.x, a.Tile.y, playerX, playerY)
        local distB = b.Distance or API.Math_DistanceW(b.Tile.x, b.Tile.y, playerX, playerY)
        return distA < distB
    end)

    for _, tree in ipairs(validTrees) do
        if API.DoAction_Object_r(0x3b,API.OFF_ACT_GeneralObject_route0,{ tree.Id },50,WPOINT.new(tree.Tile_XYZ.x,tree.Tile_XYZ.y,0),5) then
            API.RandomSleep2(800, 0, 250)
            if API.ReadPlayerMovin2() or API.CheckAnim(50) then
                return true
            end
        end
    end
    return false
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

---@return string|nil -- returns the key of log type found in inv or nil if none
function Woodcutting.findLogType()
    local invItems = API.ReadInvArrays33()

    API.logDebug("Found " .. #invItems .. " items in inventory")

    for logKey, logInfo in pairs(LOGS) do
        for _, item in ipairs(invItems) do
            if item.textitem == "<col=ff9040>" .. logInfo.name then
                API.logDebug("Found: " .. logInfo.name)
                if logInfo.id ~= item.itemid1 then
                    API.logDebug("Updating " .. logInfo.name .. " ID from " .. (logInfo.id or "nil") .. " to " .. item.itemid1)
                    Woodcutting.LOGS[logKey].id = item.itemid1
                end
                API.logDebug("Log type found: " .. logKey)
                return logKey  -- This returns the actual key from the LOGS table
            end
        end
    end

    API.logDebug("No logs found in inventory")
    return nil
end

---@param boxType table -- The wood box entry from Woodcutting.WOOD_BOXES table
---@param logType table -- The log type entry from Woodcutting.LOGS table
---@return number -- returns the # of logs of the specified type within the Wood Box
function Woodcutting.woodBoxCount(boxType, logType) 
    if not boxType then
        API.logDebug("boxType is nil")
        return 0
    end
    if not Woodcutting.WOOD_BOXES[boxType] then
        API.logDebug("No wood box found for type: " .. tostring(boxType))
        return 0
    end
    if not Woodcutting.WOOD_BOXES[boxType].id then
        API.logDebug("No id found for wood box type: " .. tostring(boxType))
        return 0
    end

    local container = API.Container_Get_all(WOOD_BOXES[boxType].id)
    
    if not container then
        API.logDebug("Container is nil for wood box id: " .. tostring(WOOD_BOXES[boxType].id))
        return 0
    end

    for _, item in pairs(container) do
        if item.item_id ~= -1 and item.item_id == LOGS[logType].id then
            API.logDebug("Logs found: "..item.item_stack)
            return item.item_stack
        end
    end
    API.logDebug("No logs found in wood box")
    return 0 
end

---@param boxId number
---@return capacity number -- returns the max capacity of current wood box or nil if none
function Woodcutting.woodBoxCapacity(boxType)
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
    local baseCapacity = baseCapacities[boxType.id]
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

---@param boxID number -- Id of wood box
---@param itemID number -- Id of item to check
---@return boolean -- returns true if the Wood Box is full
function Woodcutting.woodBoxFull(boxType, logType)
    --API.logDebug("Checking if "..Woodcutting.WOOD_BOXES[boxType].name.." is full")
    if Woodcutting.woodBoxCount(boxType, logType) == Woodcutting.woodBoxCapacity(WOOD_BOXES[boxType]) then
        return true
    end
    return false
end

--@return boolean -- returns trus if we successfully use ore box on the bank. waits for us to reach out destination
function Woodcutting.useBoxOnBank()
    local banks = API.ReadAllObjectsArray({0,1,12},{-1},{"Banker","Counter","Bank Chest","Bank Booth"})

    if banks == nil or #bank == 0 then
        API.logWarn("Didn't find any banks to deposit with!")
        return false
    end

    local box = Woodcutting.findWoodBox()

    if not box then
        API.logWarn("Didn't find any wood boxes to deposit with!")
        return false
    end

    local log = Woodcutting.findLogType()

    if not log then
        API.logWarn("Didn't find any logs!")
        return false
    end

    local ValidBanks = {}

    for _, bank in pairs(banks) do
        if bank.Action == "Bank" or bank.Action == "Use" then
            table.insert(bank, validBanks)
        end
    end

    if #validBanks == 0 then
        API.logWarn("Didn't find any valid banks!")
        return false
    end

    for _, bank in pairs(validBanks) do
        Woodcutting.useWoodBox()
        API.RandomSleep2(600, 0, 600)
        if API.DoAction_Object1(0x24,API.OFF_ACT_GeneralObject_route00,{ bank.Id },50) then
            break
        end
    end

    API.RandomSleep2(800, 0, 600)

    while API.ReadPlayerMovin2() do
        API.RandomSleep2(50, 0, 50)
    end

    API.RandomSleep2(1200,0,1200)

    if Woodcutting.woodBoxCount(box, log) > 0 then
        API.logWarn("Box count: "..tostring(Woodcutting.woodBoxCount(box, log)))
        return false
    end
    return true
end

---@param treeType string
---@return boolean -- returns true when inv is full. fills the wood box along the way if we have one
function Woodcutting.gather(treeType, logType)
    local boxType = Woodcutting.findWoodBox()
    local checkWoodBox = boxType ~= nil
    local failSafe = 0

    while not API.InvFull_() and (not checkWoodBox or not Woodcutting.woodBoxFull(boxType, logType)) and API.Read_LoopyLoop() do        
        if not Woodcutting.chop(treeType) then
            API.logWarn("Unable to chop tree: "..treeType.name)
            failSafe = (failSafe + 1)
            if failSafe >= 10 then
                API.Write_LoopyLoop(false)
                return false
            end
        else
            API.logInfo("Chopping tree: "..treeType.name)
            while API.CheckAnim(75) do
                if checkWoodBox then
                    if API.Invfreecount_() < math.random(0,8) then
                        if not Woodcutting.woodBoxFull(boxType, logType) then
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