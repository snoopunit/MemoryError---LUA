local API = require("api")

local TASK = {}
TASK.__index = TASK

---@param name string
---@param skills table --vector<string>
---@param min_lvl number
---@param max_lvl number
---@param lodestone string
---@return boolean
function TASK:new(name, skills, min_lvl, max_lvl, lodestone)
    local task = {
        Name = name or "",
        Skills = skills or "",
        min_lvl = min_lvl or 1,
        max_lvl = max_lvl or 99,
        Lodestone = lode,
        Logic,
        Routine,
        State = 0,
        Stats,
        Objects,
        Banks,
        Doors,
        Object_locations,
        Bank_locations,
        Door_locations
    }
    setmetatable(task, TASK)
    return task
end

--[[ SKILL STRINGS:

ATTACK
STRENGTH
RANGED
COMBAT
MAGIC
DEFENCE
CONSTITUTION
PRAYER
SUMMONING
DUNGEONEERING
AGILITY
THIEVING
SLAYER
HUNTER
SMELTING
SMITHING
CRAFTING
FLETCHING
HERBLORE
RUNECRAFTING
COOKING
CONSTRUCTION
FIREMAKING
WOODCUTTING
FARMING
FISHING
MINING
DIVINATION
INVENTION
ARCHAEOLOGY
NECROMANCY

--]]

---@param objects table --vector<string>
---@param banks table --vector<string>
---@param doors table --vector<string>
function TASK:initObjects(objects, banks, doors)

    if type(objects) == "table" then
        self.Objects = objects
    else
        self.Objects = {} 
    end

    if type(banks) == "table" then
        self.Banks = banks
    else
        self.Banks = {}  
    end

    if type(doors) == "table" then
        self.Doors = doors
    else
        self.Doors = {}  
    end
    
end
---@param object_locations table --vector<string>
---@param bank_locations table --vector<string>
---@param door_locations table --vector<string>
function TASK:initLocations(object_locations, bank_locations, door_locations)

    if type(object_locations) == "table" then
        self.Object_locations = object_locations
    else
        self.Object_locations = {} 
    end

    if type(bank_locations) == "table" then
        self.Bank_locations = bank_locations
    else
        self.Bank_locations = {}  
    end

    if type(door_locations) == "table" then
        self.Door_locations = door_locations
    else
        self.Door_locations = {}  

end
---@param logicFunctions table --vector<function()>
---@param mainLoop function()
---@return boolean
function TASK:initLogic(logicFunctions, mainLoop)
    if type(logicFunctions) == "table" then
        if #logicFunctions > 0 then
            for x = 1, #logicFunctions do
                if not type(logicFunctions[x]) == "function" then
                    print("Warning: Invalid task logic provided in function["..tostring(x).."]")
                    return false
                end
            end
            self.Logic = {logicFunctions}
        end
    else
        self.Logic = {}
        print("Warning: No valid logic functions provided. Task logic initialized as empty.")
    end
    if type(mainLoop) == "function" then
        self.Routine = mainLoop
    else
        print("Warning: No valid main loop provided.")
        return false
    end
    print("Task: " .. self.Name .. " logic initialized.")
    return true
end
---@param statsTable table 
-- { kills = 0, loads = 0, breaks = 0 }
function TASK:initStats(statsTable)
    if type(statsTable) == "table" then
        self.Stats = statsTable
    else
        self.Stats = {}
        print("Warning: No valid stats table provided. Stats initialized as empty.")
    end
end
---@return boolean
function TASK:levelCheck()
    if #self.Skills > 1 then
        for x = 1, #self.Skills do
            local skillLvl = API.XPLevelTable(API.GetSkillXP(self.Skills))
            if skillLvl < self.min_lvl or skillLvl > self.max_lvl then
                print("Player does not meet the skill requirements for", self.Name)
                return false
            end 
        end
    else
        local skillLvl = API.XPLevelTable(API.GetSkillXP(self.Skills[#self.Skills]))
        if skillLvl < self.min_lvl or skillLvl > self.max_lvl then
            print("Player does not meet the skill requirements for", self.Name)
            return false
        end
    end  
    return true      
end
function TASK:guiTable()

    local TaskInfo = {
        {"Task Name: " .. self.Name},
        {"Current State:", currentTarget},
    }

    for stat, value in pairs(self.Stats) do
        table.insert(TaskInfo, {stat .. ": " .. tostring(value)})
    end

    API.DrawTable(TaskInfo)
end
function TASK:execute()
    if self.logic then
        self.logic()
    else
        print("No logic defined for task: " .. self.Name)
        return false
    end
end
---@param location coords --{x,y,z}
---@return boolean
function TASK:goTo(location)

    if #location == 0 then
        print("No location defined for task: " .. self.Name)
        return false
    end

    local locationToUse = nil
    if #location ~= 1 then
        locationToUse = math.random(1, #location)
        print("Location Chosen: " .. location[locationToUse])
    else
        locationToUse = 1
    end

    local tile = WPOINT:new(self.Bank_locations[locationToUse])
    if API.PinAreaW(tile, 20) then
        print("Already within range of location!")
        print("Consider removing goToBank() logic from this task!")
        return true
    end
    
    local xOffset = math.random(-4, 4)
    local yOffset = math.random(-4, 4)
    local randomTile = WPOINT:new(tile.x + xOffset, tile.y + yOffset, tile.z)

    if API.DoAction_WalkerW(randomTile) then
        API.RandomSleep2(1200, 0, 600)
    else
        print("Failed to DoAction_WalkerW()!")
        return false
    end

    while API.ReadPlayerMovin2() do
        API.RandomSleep2(50, 0, 50)   
    end
    
    if API.PinAreaW(tile, 20) then
        return true
    else
        print("Not in location after successfully moving.")
        print("Check locations for task: " .. self.Name)
        return false
    end 
end
---@param preset number or string --1,2,last
---@return boolean
function TASK:doBank(preset) --WIP

    if #self.Banks == 0 then
        print("No banks defined for task: " .. self.Name)
        return false
    end

    local bankToUse = nil
    if #self.Banks ~= 1 then
        bankToUse = math.random(1, #self.Banks)
        print("Bank Chosen: " .. self.Banks[bankToUse])
    else
        bankToUse = 1
    end

    local bank = API.ReadAllObjectsArray({0,12}, {-1}, self.Banks[bankToUse])
    if not #bank > 0 then
        print("Couldn't locate bank allObject!")
        return false
    end

    local banktimer = API.SystemTime()
    local presetType = type(preset)

    if presetType == "String" then

        while not API.InvFull() do
            if bank.Type == 1 then
                API.DoAction_NPC(0x33,API.OFF_ACT_InteractNPC_route4,{ bank[bankToUse] },50)
            else
                --API.DoAction_Object
            end
            API.RandomSleep2(600, 0, 250)
            while API.ReadPlayerMovin2() do
                API.RandomSleep2(50, 0, 50)   
            end
            if Check_Timer(banktimer) > 30000 then
                print("Out of supplies!")
                API.Write_LoopyLoop(false)
                return false
            end
        end
        return true

    elseif presetType == "Number" then

        while not API.CheckBankVarp() do
            if bank.Type == 1 then
                --API.DoAction_NPC
            else
                --API.DoAction_Object    
            end
            API.RandomSleep2(1200, 0, 250)
            while API.ReadPlayerMovin2() do
                API.RandomSleep2(50, 0, 50)   
            end
            if Check_Timer(banktimer) > 30000 then
                print("Bank didn't open after 30s!")
                API.Write_LoopyLoop(false)
                return false
            end
        end

        --API,DoAction_Interface(preset)
        API.RandomSleep2(1200, 0, 250)

        if not API.CheckBankVarp() then
            return true
        end

    end
end
---@param object string --self.Objects[x]
---@return boolean
function TASK:actionObject(object, quitCondition)

    local actionToUse = nil
    local actions = {
        mine = 0x3a,
        craft = 0x3e,
        chop = 0x3B,
        fish = ,
        smelt = 0x3f
        }

    local offsetToUse = nil
    local offsets = {
        attack_offset = API.OFF_ACT_AttackNPC_route
        object_offset = API.OFF_ACT_GeneralObject_route0
    }

    if #self.Skills == 1 then
        if self.Skills == "MINING" then
            actionToUse = actions.mine
        elseif self.Skills == "WOODCUTTING" then
            actionToUse = actions.chop
        elseif self.Skills == "CRAFTING" then
            actionToUse = actions.craft
        elseif self.Skills == "FISHING" then
            actionToUse = actions.fish
        elseif self.Skills == "SMELTING" then
            actionToUse = actions.smelt
        elseif self.Skills == "COMBAT" then
            actionToUse = actions.attack
        end
    end

    if actionToUse ~= nil and #API.ReadAllObjectsArray({0,12},{-1},self.Objects) > 0 then
        API.DoAction_Object_string1(actionToUse)
    end
end
return TASK
