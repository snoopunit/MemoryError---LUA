print("Multibox Slave")

local API = require("api")

API.SetDrawTrackedSkills(true)
API.SetDrawLogs(true)

local Leader_Name = "playah8ah"

local Min_AFK = 30000
local Max_AFK = 240000
local Min_Eat_Percent = 60
local Weapon_Special_Attack = true
local Weapon_Special_Percent = 50 --Adrenaline% for Special Attack

----Buff IDs----
local Extreme_Magic_Buff = 25829
local Overload_Buff = 26093

----Debuff IDs----
local Enhanced_Excalibur_DeBuff = 14632
local Elven_Shard_Debuff = 43358

----Script Timers----
local AFK_Timer = API.SystemTime()
local Script_Timer = API.SystemTime()

--script counters--
local antibans = 0

function Check_Timer(int)
    return (API.SystemTime() - int)
end

local function getTotalRuntime(timer)
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
        print("Script Timer: ", sTime)
        print("AFK Timer: ", eTime)
        print("Antibans: ", antibans)
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
    API.DoAction_Ability(name, 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 50, 300)
end

---@return boolean
function healthcheck()
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

function buffcheck()
    if API.InvItemcount_String("Extreme magic") > 0 then
        if not hasBuff(Extreme_Magic_Buff) then
            --activate("")--get text for potion on hotbar
        end
    end  
    if API.InvItemcount_String("Overload") > 0 then
        if not hasBuff(Overload_Buff) then
            --activate("")--get text for potion on hotbar
        end
    end
    if API.InvItemcount_String("Ancient elven ritual shard") > 0 then
        if not hasDeBuff(Elven_Shard_Debuff) and (API.GetPrayPrecent() <= 63) then
            API.DoAction_Interface(0x2e,0xa95e,1,1670,110,-1,API.OFF_ACT_GeneralInterface_route)
        end 
    end
end

function findLeader()
    local obj = API.ReadAllObjectsArray({2}, {1}, {Leader_Name})

    if #obj == 1 then
        return obj
    end    
end

function MoveToLeader(direction)
    local leader = findLeader()

    if not (leader == nil) then

        local tile = leader.Tile_XYZ

        if direction == "N" then
            tile.y = (tile.y - 2)
        elseif direction == "S" then
            tile.y = (tile.y + 2)
        elseif direction == "E" then
            tile.x = (tile.x + 2)
        elseif direction == "W" then
            tile.x = (tile.x - 2)
        end

        API.DoAction_WalkerF(tile)

    end
end

---@return boolean
function LeaderInRange(distance, walk)

    local leader = findLeader()

    --print("Leader: "..tostring(leader.Name))
    --print("ID: "..tostring(leader.Id)) 
    --print("Coords: ("..math.floor(tostring(leader.Tile_XYZ.x))..","..math.floor(tostring(leader.Tile_XYZ.y))..")")  
    --print("Distance: "..math.floor(leader.Distance))

    if math.floor(leader.Distance) <= distance then
        return true
    else
        if walk then
            MoveToLeader("W")       
        end
        return false
    end 

    return false

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

function findEnemyNearLeader()
    local leader = findLeader()
    local leaderX, leaderY = leader.Tile_XYZ.x, leader.Tile_XYZ.y
    
    local minDistanceSquared = math.huge
    local closestNPC = nil

    local validNames = {
        ["Elite Sotapanna"] = true,
        ["Ahoeitu the Chef"] = true,
        ["Olivia the Chronicler"] = true,
        ["Xiang the Water-shaper"] = true,
        ["Sarkhan the Serpentspeaker"] = true,
        ["Oyu the Quietest"] = true
    }

    local NPCs = getEnemies(validNames)

    local minDistanceSquared = math.huge
    local closestNPC = nil

    for i = 1, #NPCs do
        local npc = NPCs[i]
        local dx = leaderX - npc.Tile_XYZ.x
        local dy = leaderY - npc.Tile_XYZ.y
        local distanceSquared = dx * dx + dy * dy

        if distanceSquared < minDistanceSquared then
            minDistanceSquared = distanceSquared
            if distanceSquared <= 36 then
                closestNPC = npc
            end
        end
    end


    if closestNPC then
        API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, closestNPC)
    end

    API.RandomSleep2(600, 50, 600)

    if API.IsTargeting() then      
        return true
    else
        return false
    end 

end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
 
    if API.IsInCombat_(Leader_Name) then
        print(Leader_Name, "in combat!")
        --buffcheck()
        if findEnemyNearLeader() then
            while API.IsTargeting() do
                healthcheck()
                if Weapon_Special_Attack then
                    if API.GetAddreline_() >= Weapon_Special_Percent then
                        activate("Weapon Special Attack")
                        API.RandomSleep2(600, 0, 600)    
                    end            
                end 
            end
            API.RandomSleep2(2400, 50, 600)
        else
            print("Attack failed!")
        end
    end

    if not LeaderInRange(5, true) then
        API.RandomSleep2(800, 0, 50)    
    end
    
    buffcheck()
    healthcheck()
    antiban()
    API.RandomSleep2(1200, 50, 600)

end-----------------------------------------------------------------------
