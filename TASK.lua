local API = require("api")

local TASK = {}
TASK.__index = TASK

---@param name string
---@param min_lvl number
---@param max_lvl number
---@param lodestone string
---@return boolean
function TASK:new(name, min_lvl, max_lvl, lodestone)
    local task = {
        Name = name or "",
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

---@param objects table --vector<string>
---@param banks table --vector<string>
---@param doors table --vector<string>
function TASK:initObjects(objects, banks, doors)

    self.Objects = objects
   
    self.Banks = banks
    
    self.Doors = doors
    
end
---@param object_locations table --{{x,y,z},{x,y,z}}
---@param bank_locations table ----{{x,y,z},{x,y,z}}
---@param door_locations table ----{{x,y,z},{x,y,z}}
function TASK:initLocations(object_locations, bank_locations, door_locations)

    self.Object_locations = object_locations

    self.Bank_locations = bank_locations

    self.Door_locations = door_locations

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
            self.Logic = logicFunctions
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
    if self.Routine then
        self.Routine()
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
function TASK:doBank(preset)

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

    local ACTIONS = {
        bank = 0x5
        collect = 0x5
        load_last = 0x33
    }

    local OFFSETS = {
        NPC = {
            bank = API.OFF_ACT_InteractNPC_route1
            collect = API.OFF_ACT_InteractNPC_route3
            load_last = API.OFF_ACT_InteractNPC_route4
        }
        OBJECT = {
            bank = API.OFF_ACT_GeneralObject_route1
            collect = API.OFF_ACT_GeneralObject_route2
            load_last = API.OFF_ACT_GeneralObject_route3
        }
    }

    local banktimer = API.SystemTime()

    if preset == "last" then

        while not API.InvFull() do
            if bank.Type == 1 then
                API.DoAction_NPC__Direct(ACTIONS.load_last, OFFSETS.NPC.load_last, bank[bankToUse])
            else
                API.DoAction_Object_Direct(ACTIONS.load_last, OFFSETS.OBJECT.load_last, bank[bankToUse])

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

    elseif preset >= 1 then

        while not API.CheckBankVarp() do
            if bank.Type == 1 then
                API.DoAction_NPC__Direct(ACTIONS.bank, OFFSETS.NPC.bank, bank[bankToUse])
            else
                API.DoAction_Object_Direct(ACTIONS.bank, OFFSETS.OBJECT.bank, bank[bankToUse])   
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

        API.DoAction_Interface(0x24,0xffffffff,1,517,119,preset,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(1200, 0, 250)

        if not API.CheckBankVarp() then
            return true
        end

    end
end

ores = {
    copper = {rock = "Copper rock", ore = "Copper ore", action = "Mine", min_lvl = 1, max_lvl = 15},
    tin = {rock = "Tin rock", ore = "Tin ore", action = "Mine", min_lvl = 1, max_lvl = 15},
    iron = {rock = "Iron rock", ore = "Iron ore", action = "Mine", min_lvl = 15, max_lvl = 30},
    coal = {rock = "Coal rock", ore = "Coal", action = "Mine", min_lvl = 30, max_lvl = 99},
    mithril = {rock = "Mithril rock", ore = "Mithril ore", action = "Mine", min_lvl = 55, max_lvl = 70},
    adamant = {rock = "Adamantite rock", ore = "Adamantite ore", action = "Mine", min_lvl = 70, max_lvl = 90},
    rune = {rock = "Runite rock", ore = "Runite ore", action = "Mine", min_lvl = 85, max_lvl = 99},
    luminite = {rock = "Luminite rock", ore = "Luminite", action = "Mine", min_lvl = 40, max_lvl = 70},
    orichalcite = {rock = "Orichalcite rock", ore = "Orichalcite ore", action = "Mine", min_lvl = 60, max_lvl = 70},
    drakolith = {rock = "Drakolith rock", ore = "Drakolith", action = "Mine", min_lvl = 60, max_lvl = 80}
}

herbs = {
    guam = {grimy = "Grimy guam leaf", clean = "Guam leaf", action = "Harvest", min_lvl = 9, max_lvl = 20},
    marrentill = {grimy = "Grimy marrentill", clean = "Marrentill", action = "Harvest", min_lvl = 14, max_lvl = 30},
    tarromin = {grimy = "Grimy tarromin", clean = "Tarromin", action = "Harvest", min_lvl = 19, max_lvl = 40},
    harralander = {grimy = "Grimy harralander", clean = "Harralander", action = "Harvest", min_lvl = 26, max_lvl = 50},
    ranarr = {grimy = "Grimy ranarr weed", clean = "Ranarr weed", action = "Harvest", min_lvl = 32, max_lvl = 60},
    toadflax = {grimy = "Grimy toadflax", clean = "Toadflax", action = "Harvest", min_lvl = 38, max_lvl = 70},
    avantoe = {grimy = "Grimy avantoe", clean = "Avantoe", action = "Harvest", min_lvl = 48, max_lvl = 80},
    kwuarm = {grimy = "Grimy kwuarm", clean = "Kwuarm", action = "Harvest", min_lvl = 54, max_lvl = 85},
    snapdragon = {grimy = "Grimy snapdragon", clean = "Snapdragon", action = "Harvest", min_lvl = 62, max_lvl = 90},
    torstol = {grimy = "Grimy torstol", clean = "Torstol", action = "Harvest", min_lvl = 85, max_lvl = 99}
}

divination = {
    pale = {wisp = "Pale wisp", energy = "Pale energy", memory = "Pale memory", action = "Harvest", min_lvl = 1, max_lvl = 10},
    flickering = {wisp = "Flickering wisp", energy = "Flickering energy", memory = "Flickering memory", action = "Harvest", min_lvl = 10, max_lvl = 20},
    bright = {wisp = "Bright wisp", energy = "Bright energy", memory = "Bright memory", action = "Harvest", min_lvl = 20, max_lvl = 30},
    glowing = {wisp = "Glowing wisp", energy = "Glowing energy", memory = "Glowing memory", action = "Harvest", min_lvl = 30, max_lvl = 40},
    sparkling = {wisp = "Sparkling wisp", energy = "Sparkling energy", memory = "Sparkling memory", action = "Harvest", min_lvl = 40, max_lvl = 50},
    gleaming = {wisp = "Gleaming wisp", energy = "Gleaming energy", memory = "Gleaming memory", action = "Harvest", min_lvl = 50, max_lvl = 60},
    vibrant = {wisp = "Vibrant wisp", energy = "Vibrant energy", memory = "Vibrant memory", action = "Harvest", min_lvl = 60, max_lvl = 70},
    lustrous = {wisp = "Lustrous wisp", energy = "Lustrous energy", memory = "Lustrous memory", action = "Harvest", min_lvl = 70, max_lvl = 80},
    brilliant = {wisp = "Brilliant wisp", energy = "Brilliant energy", memory = "Brilliant memory", action = "Harvest", min_lvl = 80, max_lvl = 85},
    radiant = {wisp = "Radiant wisp", energy = "Radiant energy", memory = "Radiant memory", action = "Harvest", min_lvl = 85, max_lvl = 90},
    luminous = {wisp = "Luminous wisp", energy = "Luminous energy", memory = "Luminous memory", action = "Harvest", min_lvl = 90, max_lvl = 99}
}

fish = {
    shrimp = {spot = "Fishing spot", action = "Net", raw = "Raw shrimp", cooked = "Shrimp", min_lvl = 1, max_lvl = 20},
    anchovies = {spot = "Fishing spot", action = "Net", raw = "Raw anchovies", cooked = "Anchovies", min_lvl = 15, max_lvl = 40},
    trout = {spot = "Fishing spot", action = "Lure", raw = "Raw trout", cooked = "Trout", min_lvl = 20, max_lvl = 50},
    salmon = {spot = "Fishing spot", action = "Lure", raw = "Raw salmon", cooked = "Salmon", min_lvl = 30, max_lvl = 70},
    tuna = {spot = "Fishing spot", action = "Harpoon", raw = "Raw tuna", cooked = "Tuna", min_lvl = 35, max_lvl = 80},
    swordfish = {spot = "Fishing spot", action = "Harpoon", raw = "Raw swordfish", cooked = "Swordfish", min_lvl = 50, max_lvl = 99},
    shark = {spot = "Fishing spot", action = "Harpoon", raw = "Raw shark", cooked = "Shark", min_lvl = 76, max_lvl = 99},
    monkfish = {spot = "Fishing spot", action = "Net", raw = "Raw monkfish", cooked = "Monkfish", min_lvl = 62, max_lvl = 90},
    rocktail = {spot = "Fishing spot", action = "Net", raw = "Raw rocktail", cooked = "Rocktail", min_lvl = 90, max_lvl = 99},
    crayfish = {spot = "Fishing spot", action = "Crayfish cage", raw = "Raw crayfish", cooked = "Crayfish", min_lvl = 1, max_lvl = 10}
}

trees = {
    normal = {tree = "Tree", action = "Chop", log = "Logs", min_lvl = 1, max_lvl = 15},
    oak = {tree = "Oak tree", action = "Chop", log = "Oak logs", min_lvl = 15, max_lvl = 30},
    willow = {tree = "Willow tree", action = "Chop", log = "Willow logs", min_lvl = 30, max_lvl = 50},
    maple = {tree = "Maple tree", action = "Chop", log = "Maple logs", min_lvl = 45, max_lvl = 60},
    yew = {tree = "Yew tree", action = "Chop", log = "Yew logs", min_lvl = 60, max_lvl = 75},
    magic = {tree = "Magic tree", action = "Chop", log = "Magic logs", min_lvl = 75, max_lvl = 90},
    elder = {tree = "Elder tree", action = "Chop", log = "Elder logs", min_lvl = 90, max_lvl = 99}
}

--=======================================================--
--                       TASK OBJECTS                    --
--=======================================================--

---@param object string --self.Objects[x]
---@return boolean
function TASK:mine(object)
    return API.DoAction_Object_string1(0x3a, API.OFF_ACT_GeneralObject_route0, object, 30, true)
end
---@param object string --self.Objects[x]
---@return boolean
function TASK:chop(object)
    return API.DoAction_Object_string1(0x3b, API.OFF_ACT_GeneralObject_route0, object, 30, true)
end

---@param object string --self.Objects[x]
---@return boolean
function TASK:smelt(object)
    return API.DoAction_Object_string1(0x3f, API.OFF_ACT_GeneralObject_route0, object, 30, true)
end
---@param object string --self.Objects[x]
---@return boolean
function TASK:talkTo(object)
    return API.DoAction_NPC_str(0x3f, API.OFF_ACT_GeneralObject_route0, {object}, 30, true, 1)
end

function TASK:doDoor(object) --WIP
end

function TASK:doLadder(object) --WIP
end

function TASK:useResourceDungeon(object) -- NECESSARY?
end

--=======================================================--
--                       TASK NPCS                       --
--=======================================================--

---@param object string --self.Objects[x]
---@return boolean
function TASK:fish(npc)
    return API.DoAction_NPC_str(0x3c, API.OFF_ACT_InteractNPC_route, {object}, 30, true, 1)
end

function TASK:attack(NPC) -- WIP
end

return TASK