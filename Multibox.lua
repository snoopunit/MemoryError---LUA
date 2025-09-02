print("Multibox Slave")

local API = require("api")
local UTILS = require("utils")

local Leader_Name = "playah8ah"

local Min_AFK = 30000
local Max_AFK = 240000
local Min_Eat_Percent = 40

----Buff IDs----
local Extreme_Magic_Buff = 25829
local Overload_Buff = 26093

----Debuff IDs----
local Enhanced_Excalibur_DeBuff = 14632

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

---@return boolean
function eatFood()
    if UTILS.canUseSkill("Eat Food") then
        API.logDebug("Low HP! Eating Food!")
        activateAbility("Eat Food")
        API.RandomSleep2(1200, 50, 300)
    end
end

---@return boolean
function healthcheck()
    if API.GetHPrecent() < Min_Eat_Percent then
        eatFood() 
    end
end

function buffcheck()
    if API.InvItemcount_String("Extreme magic") > 0 then
        if not hasBuff(Extreme_Magic_Buff) then
            API.DoAction_Interface(0x2e,0x3bda,1,1430,220,-1,2480)
        end
    end  
    if API.InvItemcount_String("Overload") > 0 then
        if not hasBuff(Overload_Buff) then
            API.DoAction_Interface(0x2e,0x3be4,1,1430,233,-1,2480)
        end
    end  
end

---@return boolean
function LeaderInRange(distance, walk)

    local allPlayers = API.ReadAllObjectsArray({2},{-1},{})
    local leader

    for i = 1, #allPlayers do
        if (allPlayers[i].Name == Leader_Name) then
            leader = allPlayers[i]
        end    
    end

    if not (leader == nil) then
        local p = API.PlayerCoord()
        local dist = math.sqrt(((leader.TileX / 512) - p.x)^2 + ((leader.TileY / 512) - p.y)^2)

        if math.floor(dist) <= distance then
            return true
        else
            if walk then
                API.DoAction_WalkerW(leader.TileXYZ)
            end
            return false
        end 
    end
   
    return false

end

function MoveToLeader()
    local allPlayers = API.ReadAllObjectsArray(true, 2)
    local leader

    for i = 1, #allPlayers do
        if (allPlayers[i].Name == Leader_Name) then
            leader = allPlayers[i]
        end    
    end

    if not (leader == nil) then
        AIP.DoAction_Tile(leader.TileXYZ)
    end
end

function findEnemyNearLeader()
    local allPlayers = API.ReadAllObjectsArray({2}, {-1}, {})
    local leader
    for i = 1, #allPlayers do
        if (allPlayers[i].Name == Leader_Name) then
            leader = allPlayers[i]
        end    
    end
    if not (leader == nil) then
        local NPCs = API.ReadAllObjectsArray({1}, {-1}, {})
        for i = 1, #NPCs do
            local dist = math.sqrt(((NPCs[i].TileX / 512) - (leader.TileX / 512))^2 + ((NPCs[i].TileY / 512) - (leader.TileY / 512))^2)
            if math.floor(dist) <= 2 then
                API.DoAction_NPC__Direct(0x24, 480, NPCs[i])
            end     
        end
    end
end

function EnemyInteractingLeader()
    local enemy = API.PlayerInterActingWith_(Leader_Name)

    if not enemy == nil then
        API.DoAction_NPC__Direct(0x24, 480, enemy)
    end
end

---@return boolean
function attack()

    findEnemyNearLeader()
    --EnemyInteractingLeader()  
    
    API.RandomSleep2(2400, 50, 600)

    if API.IsTargeting() then      
        return true
    else
        return false
    end 

end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if API.IsInCombat_(Leader_Name) then
        print(Leader_Name, "in combat!")
        buffcheck()
        if attack() then
            while API.IsTargeting() do
                healthcheck()
            end
        else
            print("Attack failed!")
        end
    end

    if not LeaderInRange(10) then
        API.DoAction_VS_Player_Follow({Leader_Name}, 50)
        API.RandomSleep2(800, 0, 0)
        while API.ReadPlayerMovin() and API.Read_LoopyLoop() do
            API.RandomSleep2(50, 0, 50)    
        end
        API.DoAction_Tile(API.PlayerCoord())    
    end
    
    healthcheck()
    API.RandomSleep2(2400, 50, 600)

end-----------------------------------------------------------------------
