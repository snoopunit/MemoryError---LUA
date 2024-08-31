print("Run Lua script <NAME>.")

local API = require("api")
local UTILS = require("utils")

local do_stuff = false
local do_debug = true

local Min_AFK = 30000
local Max_AFK = 180000
local Min_Eat_Percent = 50
local Min_HP_Percent = 20 --Min HP% to GTFO
local protect_Ranged_Buff = 25960
local protect_Magic_Buff = 25959
local protect_Melee_Buff = 25961
local Elven_Shard_Debuff = 43358

local Healer_IDs = {25582, 25577}
local Enemy_IDs = {25576, 25580}

----vars
local AFK_Timer = API.SystemTime()
local Script_Timer = API.SystemTime()
local NoTarget_Timer = API.SystemTime()

local antibans = 0

local Eat_Food = true
local Loot_Drops = false
local teleport = false
local Use_Familiar = false
local Note_Items = false
local Special_Attack = false

local currentEnemy = nil
----end vars

function Check_Timer(int)
    return (API.SystemTime() - int)
end

function getTotalRuntime(timer)
    local currentTime = API.SystemTime()
    local elapsed = currentTime - timer
    local hours = math.floor(elapsed / 3600000)
    local minutes = math.floor((elapsed % 3600000) / 60000)
    local seconds = math.floor((elapsed % 60000) / 1000)
    return string.format("%dh,%dm,%ds", hours, minutes, seconds)
end

function antiban()
        
    -- Calculate the time since the last afkTimer reset
    local elapsedTime = Check_Timer(AFK_Timer)
    
    -- Generate a random threshold between minAFK and maxAFK
    local afkThreshold = math.random(Min_AFK, Max_AFK)
    
    -- Check if the elapsed time exceeds the threshold
    if elapsedTime > afkThreshold then
        -- Print the scriptTimer, current elapsedTime, and separators
        antibans = antibans + 1

        local sTime = getTotalRuntime(Script_Timer)
        local eTime = getTotalRuntime(AFK_Timer)

        print("========================")
        print("Script Timer:" .. sTime)
        print("AFK Timer:" .. eTime)
        print("Antibans:" .. antibans)
        print("========================")
            
        -- Perform a random antiban action
        local action = math.random(1, 7)
        if action == 1 then API.PIdle1()
        elseif action == 2 then API.PIdle2()
        elseif action == 3 then API.PIdle22()
        elseif action == 4 then API.KeyboardPress('w', 50, 250)
        elseif action == 5 then API.KeyboardPress('a', 50, 250)
        elseif action == 6 then API.KeyboardPress('s', 50, 250)
        elseif action == 7 then API.KeyboardPress('d', 50, 250)
        end
    
        -- Reset the afkTimer
        AFK_Timer = API.SystemTime()
    end
end

---@return boolean
function hasBuff(buff)
    if API.Buffbar_GetIDstatus(buff, false).id == 0 then
        return false
    else
        return true
    end
end

---@return boolean
function hasDeBuff(debuff)
    if API.DeBuffbar_GetIDstatus(debuff, false).id == 0 then
        return false
    else
        return true
    end
end

---MUST BE ON ACTIONBARS
---@param string
function activate(name)
    print("Activate: "..name)
    API.DoAction_Ability(name, 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 50, 300)
end

---@return boolean
function healthCheck()
    if API.GetHPrecent() < Min_Eat_Percent then
        print("Low HP! Eating Food!")
        activate("Eat Food")
        API.RandomSleep2(600, 50, 300)
        if API.GetHPrecent() > Min_Eat_Percent then
            return true
        else
            return false
        end
    end
end

function buffCheck()
    if API.InvItemcount_String("Ancient elven ritual shard") > 0 then
        if not hasDeBuff(Elven_Shard_Debuff) and (API.GetPrayPrecent() <= 63) then
            API.DoAction_Interface(0x2e,0xa95e,1,1670,110,-1,API.OFF_ACT_GeneralInterface_route)
        end 
    end
    if (API.LocalPlayer_IsInCombat_() and API.IsTargeting()) and not hasBuff(protect_Ranged_Buff) then
        activate("Protect from Ranged")
        API.RandomSleep2(800, 50, 300)
    elseif (API.LocalPlayer_IsInCombat_() and  not API.IsTargeting()) and (Check_Timer(NoTarget_Timer) > 2000) and hasBuff(protect_Ranged_Buff) then
        activate("Protect from Ranged")
        API.RandomSleep2(800, 50, 300)
    elseif not API.LocalPlayer_IsInCombat_() and hasBuff(protect_Ranged_Buff) then
        activate("Protect from Ranged")
        API.RandomSleep2(800, 50, 300)    
    end 
end

function getEnemies(names)
    local NPCs = {}
    if names then
        NPCs = API.ReadAllObjectsArray({1}, {-1}, names)
    else
        NPCs = API.ReadAllObjectsArray({1}, {-1}, {})
    end
    return NPCs
end

function miniBossCount()
    local miniBoss_Names = {
        "Ahoeitu the Chef",
        "Olivia the Chronicler",
        "Xiang the Water-shaper",
        "Sarkhan the Serpentspeaker",
        "Oyu the Quietest"
    }
    local miniBosses = getEnemies(miniBoss_Names)
    if #miniBosses > 0 then
        print("Mini Bosses:"..tostring(#miniBosses))
        for k, v in pairs(miniBosses) do
            print("Name:"..v.Name.." ID:"..v.Id)
            end
        return #miniBosses
    end
end

function enemyCount(enemy_names)
    local enemies = getEnemies(enemy_names)
    if #enemies > 0 then
        print("Enemies:"..tostring(#enemies))
        return #enemies
    end
end

--Temple Locations
local START = WPOINT:new(14915, 15517, 0)

local FIRST_CHECKPOINT = WPOINT:new(START.x + 20, START.y + 4, 0)

local FIRST_STAIRS_FIGHT = {
    TOP_LEFT = WPOINT:new(START.x + 27, START.y + 7, 0),
    BOT_RIGHT = WPOINT:new(START.x + 28, START.y + 1, 0)
}

local RIGHT_SIDE_FIGHT = {
    TOP_LEFT = WPOINT:new(START.x + 27, START.y - 4, 0),
    BOT_RIGHT = WPOINT:new(START.x + 40, START.y - 11, 0)
}

local LEFT_SIDE_FIGHT = {
    TOP_LEFT = WPOINT:new(START.x + 27, START.y + 19, 0),
    BOT_RIGHT = WPOINT:new(START.x + 40, START.y + 12, 0)
}

local SECOND_STAIRS_FIGHT = {
    TOP_LEFT = WPOINT:new(START.x + 48, START.y + 13, 0),
    BOT_RIGHT = WPOINT:new(START.x + 57, START.y + 8, 0)
}

local CATHEDRAL_OUTSIDE = {
    TOP_LEFT = WPOINT:new(START.x + 62, START.y + 19, 0),
    BOT_RIGHT = WPOINT:new(START.x + 71, START.y + 11, 0)
}

local XIANG_MINIBOSS = {
    TOP_LEFT = WPOINT:new(START.x + 81, START.y + 10, 0),
    BOT_RIGHT = WPOINT:new(START.x + 85, START.y + 7, 0)
}

local OLIVIA_MINIBOSS = {
    TOP_LEFT = WPOINT:new(START.x + 94, START.y + 8, 0),
    BOT_RIGHT = WPOINT:new(START.x + 100, START.y, 0)
}

local CATHEDRAL_OUTSIDE_TWO = {
    TOP_LEFT = WPOINT:new(START.x + 78, START.y + 35, 0),
    BOT_RIGHT = WPOINT:new(START.x + 84, START.y + 24, 0)
}

local OYU_MINIBOSS = {
    TOP_LEFT = WPOINT:new(START.x + 92, START.y + 35, 0),
    BOT_RIGHT = WPOINT:new(START.x + 96, START.y + 32, 0)
}

local KITCHEN_OUTSIDE = {
    TOP_LEFT = WPOINT:new(START.x + 81, START.y - 2, 0),
    BOT_RIGHT = WPOINT:new(START.x + 93, START.y - 10, 0)
}

local AHOEITU_MINIBOSS = {
    TOP_LEFT = WPOINT:new(START.x + 94, START.y - 19, 0),
    BOT_RIGHT = WPOINT:new(START.x + 99, START.y - 21, 0)
}

local KITCHEN_OUTSIDE_TWO = {
    TOP_LEFT = WPOINT:new(START.x + 67, START.y - 12, 0),
    BOT_RIGHT = WPOINT:new(START.x + 65, START.y - 10, 0)
}

local LAST_GROUP = {
    TOP_LEFT = WPOINT:new(START.x + 48, START.y + 1, 0),
    BOT_RIGHT = WPOINT:new(START.x + 61, START.y - 5, 0)
}

local CATHEDRAL_INSIDE = {
    {
        TOP_LEFT = {},
        BOT_RIGHT = {}
    }
}

function EnemiesWithinLocation(enemy, location, obj)
    local topLeft = location.top_left
    local botRight = location.bot_right
    local NPCs = getEnemies({enemy})
    local enemies = {}

    for i = 0, #NPCs do
        local objectPosition = NPCs[i].TILE_XYZ

        if objectPosition.x >= topLeft.x and objectPosition.x <= botRight.x and
        objectPosition.y <= topLeft.y and objectPosition.y >= botRight.y then
            table.insert(enemies, NPCs[i])
        end
    end

    if obj then
        return enemies
    else
        return #enemies
    end
end

function activateAbility(name, m_action)

    ---MUST BE ON ACTIONBARS
    --m_action is selection menu #choice --- default to 1

    local action = 1
    if not m_action == 1 then
        action = m_action
    end
    API.DoAction_Ability(name, action, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 50, 300)
end

--main loop
API.Write_LoopyLoop(true)
API.SetDrawTrackedSkills(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if do_debug then
        
        --API.DeBuffbar_GetAllIDs(true)
        --print("Anim:", tostring(API.CheckAnim(50)))
        --print("Moving:", tostring(API.ReadPlayerMovin2()))
        --miniBossCount()
        --enemyCount({"Elite Sotapanna"})
        --uniqueEnemies()
        
    end

    if do_stuff then
        if UTILS.canUseSkill("Wilderness sword 1") then
            print("Teleport: Wilderness Sword")
            API.DoAction_Interface(0xffffffff,0x9410,2,1670,136,-1,API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600, 50, 300)
            API.KeyboardPress('1', 50, 250)
            API.RandomSleep2(600, 50, 300)
            API.KeyboardPress('1', 50, 250) 
        end    
       
    end
    
    API.Buffbar_GetAllIDs(true)

    antiban()
    API.RandomSleep2(5000, 0, 250)

end----------------------------------------------------------------------------------