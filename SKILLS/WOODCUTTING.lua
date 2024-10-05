local API = require("api")

local Woodcutting = {}

Woodcutting.TREES = {
    [1] = {name = "Tree", min_lvl = 1, max_lvl = 10, members = false},
    [2] = {name = "Achey tree", min_lvl = 1, max_lvl = 14, members = true},
    [3] = {name = "Oak", min_lvl = 10, max_lvl = 20, members = false},
    [4] = {name = "Willow", min_lvl = 20, max_lvl = 40, members = false},
    [5] = {name = "Teak", min_lvl = 30, max_lvl = 40, members = true},
    [6] = {name = "Maple tree", min_lvl = 40, max_lvl = 50, members = false},
    [7] = {name = "Acadia tree", min_lvl = 50, max_lvl = 60, members = true},
    [8] = {name = "Mahogany", min_lvl = 60, max_lvl = 70, members = true},
    [9] = {name = "Arctic pine", min_lvl = 54, max_lvl = 57, members = true},
    [10] = {name = "Eucalyptus", min_lvl = 58, max_lvl = 59, members = true},
    [11] = {name = "Yew", min_lvl = 70, max_lvl = 99, members = false},
    [12] = {name = "Ivy", min_lvl = 68, max_lvl = 99, members = true},
    [13] = {name = "Magic tree", min_lvl = 80, max_lvl = 99, members = true},
    [14] = {name = "Elder tree", min_lvl = 90, max_lvl = 99, members = true},
    [15] = {name = "Crystal tree", min_lvl = 94, max_lvl = 99, members = true},
    [16] = {name = "Bloodwood tree", min_lvl = 85, max_lvl = 99, members = true},
    [17] = {name = "Blisterwood tree", min_lvl = 76, max_lvl = 99, members = true},
    [18] = {name = "Golden bamboo", min_lvl = 96, max_lvl = 120, members = true},
    [19] = {name = "Overgrown idols", min_lvl = 81, max_lvl = 99, members = true}
}

Woodcutting.LOGS = {
    [1] = {name = "Logs", id = 1511},
    [2] = {name = "Achey tree logs", id = 2862},
    [3] = {name = "Oak logs", id = 1521},
    [4] = {name = "Willow logs", id = 1519},
    [5] = {name = "Teak logs", id = 6333},
    [6] = {name = "Maple logs", id = 1517},
    [7] = {name = "Mahogany logs", id = 6332},
    [8] = {name = "Arctic pine logs", id = 10810},
    [9] = {name = "Eucalyptus logs", id = 12581},
    [10] = {name = "Yew logs", id = 1515},
    [11] = {name = "Magic logs", id = 1513},
    [12] = {name = "Elder logs", id = 29556},
    [13] = {name = "Crystal logs", id = 49692},
    [14] = {name = "Bloodwood logs", id = 24121},
    [15] = {name = "Blisterwood logs", id = 49669},
    [16] = {name = "Bamboo", id = 21777}
}

Woodcutting.WOOD_BOXES = {
    [1] = {name = "Wood box", id = 54895},
    [2] = {name = "Oak wood box", id = 54897},
    [3] = {name = "Willow wood box", id = 54899},
    [4] = {name = "Teak wood box", id = nil},
    [5] = {name = "Maple wood box", id = nil},
    [6] = {name = "Mahogany wood box", id = nil},
    [7] = {name = "Yew wood box", id = nil},
    [8] = {name = "Magic wood box", id = nil},
    [9] = {name = "Elder wood box", id = 54913}
}

---@param object string
---@return boolean -- returns true if we successfully start chopping a tree
function Woodcutting.chop(treeType)
    local trees = API.ReadAllObjectsArray({0,12},{-1},{treeType.name})

    if #trees == nil or #trees == 0 then
        API.logWarn("Couldn't find any: "..treeType.name.."s")
        API.Write_LoopyLoop(false)
        return false  
    end

    for _, tree in ipairs(trees) do
        if API.DoAction_Object_Direct(0x3b, API.OFF_ACT_GeneralObject_route0, tree) then
            API.RandomSleep2(800, 0, 250)
            while API.ReadPlayerMovin2() do
                API.RandomSleep2(50, 0, 50)
            end
            return true
        end
    end
    return false
end

---@return any -- returns the key of wood box found in inv or nil if none
function Woodcutting.findWoodBox()
    ---@type IInfo[]
    local invItems = API.ReadInvArrays33()
    
    for tableKey, tableInfo in pairs(Woodcutting.WOOD_BOXES) do
        for _, item in ipairs(invItems) do
            if item.textitem == tableInfo.name then
                -- Found a matching item, check if ID needs updating
                if tableInfo.id ~= item.itemid1 then
                    API.LogDebug("Updating " .. tableInfo.name .. " ID from " .. (tableInfo.id or "nil") .. " to " .. item.itemid1)
                    Woodcutting.WOOD_BOXES[tableKey].id = item.itemid1
                end
                return tableKey  -- This returns the actual key from the WOOD_BOXES table
            end
        end
    end
    return nil
end

---@param boxType table -- The wood box entry from Woodcutting.WOOD_BOXES table
---@param logType table -- The log type entry from Woodcutting.LOGS table
---@return number -- returns the # of logs of the specified type within the Wood Box
function Woodcutting.woodBoxCount(boxType, logType) 
    local container = API.Container_Get_all(boxType.id)
    for _, item in pairs(container) do
        if item.item_id ~= -1 and item.item_id == logType.id then
            return item.item_stack
        end
    end
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
    local box = self.findWoodBox()
    return API.DoAction_Inventory1(box.id,0,1,API.OFF_ACT_GeneralInterface_route)
end

---@return boolean -- returns true if we activate the use option for our Wood Box
function Woodcutting.useWoodBox()
    local box = self.findWoodBox()
    return --API.DoAction_Inventory1(box.id,0,1,API.OFF_ACT_GeneralInterface_route)
end

---@param boxID number -- Id of wood box
---@param itemID number -- Id of item to check
---@return boolean -- returns true if the Wood Box is full
function Woodcutting.woodBoxFull(boxType, logType)
    if self.woodBoxCount(boxType.id, logType.id) == self.woodBoxCapacity(boxId) then
        return true
    end
    return false
end

---@param treeType string
---@return boolean -- returns true when inv is full. fills the wood box along the way if we have one
function Woodcutting.gather(treeType, logType)
    while not API.InvFull() do
        local boxType = self.findWoodBox()
        if boxType ~= nil then
            if API.InvFreeCount() < math.random(2,8) then
                if not self.woodBoxFull(boxType.id, logType.id) then
                    API.LogDebug("Filling "..boxType.name.." with "..logType.name.."s.")
                    self.fillWoodBox()
                end
            end
        end
        if not self.chop(treeType.name) then
            API.logWarn("Unable to chop tree: "..treeType.name)
            API.Write_LoopyLoop(false)
            return false
        else
            while API.checkAnim(50) do
                API.DoRandomEvents()
                API.RandomSleep2(600, 0, 250)
            end
        end
    end
    return true
end

return Woodcutting