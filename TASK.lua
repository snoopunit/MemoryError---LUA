local API = require("api")

local TASK = {}
TASK.__index = TASK

local function createTask(config)
    assert(type(config.name) == "string", "Task name must be a string")
    assert(type(config.requirements) == "table", "Requirements must be a table")
    assert(type(config.routine) == "function", "Routine must be a function")
    assert(type(config.lodestone) == "string", "Lodestone must be a string")
    assert(type(config.items) == "table", "Items must be a table")
    assert(type(config.metrics) == "table", "Metrics must be a table")

    -- Assert that requirements are correctly formatted
    for _, req in ipairs(config.requirements) do
        assert(type(req.skill) == "string", "Skill name in requirements must be a string")
        assert(type(req.min_lvl) == "number", "Minimum level in requirements must be a number")
        assert(type(req.max_lvl) == "number", "Maximum level in requirements must be a number")
        assert(req.min_lvl <= req.max_lvl, "Minimum level must be less than or equal to maximum level")
    end

    -- Assert that all items are strings
    for _, item in ipairs(config.items) do
        assert(type(item) == "string", "All items must be strings")
    end

    -- Assert that all metrics are strings
    for _, metric in ipairs(config.metrics) do
        assert(type(metric) == "string", "All metrics must be strings")
    end

    local items = {}
    for _, itemName in ipairs(config.items) do
        items[itemName] = {name = itemName, count = 0}
    end

    local metrics = {}
    for _, metricName in ipairs(config.metrics) do
        metrics[metricName] = {name = metricName, count = 0}
    end

    local task = setmetatable({
        name = config.name,
        requirements = config.requirements,
        object = config.object or {},
        bank = config.bank or {},
        routine = config.routine,
        state = 0,
        lodestone = config.lodestone,
        items = items,
        metrics = metrics,
        quitCondition = nil  -- This will be set in the routine
    }, TASK)

    return task
end

function TASK:levelCheck()
    for _, req in ipairs(self.requirements) do
        local skillLvl = API.XPLevelTable(API.GetSkillXP(req.skill))
        if skillLvl < req.min_lvl or skillLvl > req.max_lvl then
            return false
        end
    end
    return true
end

function TASK:execute()
    self.routine(self)
end

function TASK:incrementMetric(metricName)
    if self.metrics[metricName] then
        self.metrics[metricName].count = self.metrics[metricName].count + 1
    else
        print("Warning: Metric '" .. metricName .. "' does not exist.")
    end
end

function TASK:getMetric(metricName)
    if self.metrics[metricName] then
        return self.metrics[metricName].count
    else
        print("Warning: Metric '" .. metricName .. "' does not exist.")
        return nil
    end
end

function TASK:guiTable()
    local TaskInfo = {
        {"Task Name: " .. self.name},
        {"Current State: " .. self.state}
    }

    -- Add requirements
    for _, req in ipairs(self.requirements) do
        table.insert(TaskInfo, {"Requirement: " .. req.skill .. " (" .. req.min_lvl .. "-" .. req.max_lvl .. ")"})
    end

    -- Add items
    for itemName, item in pairs(self.items) do
        table.insert(TaskInfo, {itemName .. ": " .. item.count})
    end

    -- Add metrics
    for metricName, metric in pairs(self.metrics) do
        table.insert(TaskInfo, {metricName .. ": " .. metric.count})
    end

    API.DrawTable(TaskInfo)
end

function TASK:goTo(target)
    local locations = target.locations

    if #locations == 0 then
        print("No locations defined for " .. target.name)
        return false
    end

    local locationToUse
    if #locations ~= 1 then
        locationToUse = locations[math.random(1, #locations)]
        print("Location Chosen for " .. target.name .. ": x=" .. locationToUse.x .. ", y=" .. locationToUse.y .. ", z=" .. locationToUse.z)
    else
        locationToUse = locations[1]
    end

    local tile = WPOINT:new(locationToUse.x, locationToUse.y, locationToUse.z)
    if API.PinAreaW(tile, 20) then
        print("Already within range of " .. target.name .. " location!")
        return true
    end
    
    local xOffset = math.random(-4, 4)
    local yOffset = math.random(-4, 4)
    local randomTile = WPOINT:new(tile.x + xOffset, tile.y + yOffset, tile.z)

    if API.DoAction_WalkerW(randomTile) then
        API.RandomSleep2(1200, 0, 600)
    else
        print("Failed to DoAction_WalkerW() for " .. target.name .. "!")
        return false
    end

    while API.ReadPlayerMovin2() do
        if API.PinAreaW(tile, 20) then return true end
        API.RandomSleep2(50, 0, 50)   
    end
        
    print("Not in " .. target.name .. " location after successfully moving.")
    print("Check locations for " .. target.name)
    return false
end

function TASK:doBank(preset)
    if #self.bank.locations == 0 then
        print("No banks defined for task: " .. self.name)
        return false
    end

    local banks = API.ReadAllObjectsArray({0,12}, {-1}, self.bank.name)
    if #banks == 0 then
        print("Couldn't locate any banks!")
        return false
    end

    -- Sort banks by distance
    table.sort(banks, function(a, b) return a.Distance < b.Distance end)

    -- Choose randomly from the three closest banks (or fewer if less than three are available)
    local closestBanks = math.min(3, #banks)
    local chosenBank = banks[math.random(1, closestBanks)]
    print("Bank Chosen: Distance = " .. chosenBank.Distance)

    local ACTIONS = {
        bank = 0x5,
        collect = 0x5,
        load_last = 0x33
    }

    local OFFSETS = {
        NPC = {
            bank = API.OFF_ACT_InteractNPC_route1,
            collect = API.OFF_ACT_InteractNPC_route3,
            load_last = API.OFF_ACT_InteractNPC_route4
        },
        OBJECT = {
            bank = API.OFF_ACT_GeneralObject_route1,
            collect = API.OFF_ACT_GeneralObject_route2,
            load_last = API.OFF_ACT_GeneralObject_route3
        }
    }

    local banktimer = API.SystemTime()

    if preset == "last" then
        while not API.InvFull() do
            if chosenBank.Type == 1 then
                API.DoAction_NPC__Direct(ACTIONS.load_last, OFFSETS.NPC.load_last, chosenBank)
            else
                API.DoAction_Object_Direct(ACTIONS.load_last, OFFSETS.OBJECT.load_last, chosenBank)
            end
            API.RandomSleep2(600, 0, 250)
            while API.ReadPlayerMovin2() do
                if API.InvFull() then return true end
                API.RandomSleep2(50, 0, 50)   
            end
            if API.SystemTime() - banktimer > 30000 then
                print("Out of supplies!")
                API.Write_LoopyLoop(false)
                return false
            end
        end
        return true
    elseif type(preset) == "number" and preset >= 1 then
        while not API.CheckBankVarp() do
            if chosenBank.Type == 1 then
                API.DoAction_NPC__Direct(ACTIONS.bank, OFFSETS.NPC.bank, chosenBank)
            else
                API.DoAction_Object_Direct(ACTIONS.bank, OFFSETS.OBJECT.bank, chosenBank)   
            end
            API.RandomSleep2(1200, 0, 250)
            while API.ReadPlayerMovin2() do
                API.RandomSleep2(50, 0, 50)   
            end
            if API.SystemTime() - banktimer > 30000 then
                print("Bank didn't open after 30s!")
                API.Write_LoopyLoop(false)
                return false
            end
        end

        API.DoAction_Interface(0x24,0xffffffff,1,517,119,preset,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(1200, 0, 250)

        if not API.CheckBankVarp() then
            return true
        end
    end
    
    return false
end

return {
    create = createTask
}