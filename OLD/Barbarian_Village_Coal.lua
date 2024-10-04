print("Run Lua script Barbarian_Village_Coal.")

local API = require("api")
local UTILS = require("utils")

API.SetDrawTrackedSkills(true)

local Min_AFK = 30000
local Max_AFK = 240000

local Barbarian_Forge = 113270

local Coal_Node = {}
table.insert(Coal_Node, 113041)
table.insert(Coal_Node, 113042)
table.insert(Coal_Node, 113043)

----Script Timers----
local Start_Timer = 0
local AFK_Timer
local Script_Timer

local antibans = 0

local function getTotalRuntime(timer)
    local currentTime = API.SystemTime()
    local elapsed = currentTime - timer
    local hours = math.floor(elapsed / 3600000)
    local minutes = math.floor((elapsed % 3600000) / 60000)
    local seconds = math.floor((elapsed % 60000) / 1000)
    return string.format("%dh,%dm,%ds", hours, minutes, seconds)
end

function mine()
    API.DoAction_Object1(0x3a,0,{ Coal_Node[3] },50)
end

---@return bool
function fillBox()
    local count = API.Invfreecount_()
    
    --FILL ORE BOX
    API.DoAction_Inventory1(44787,0,1,API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1200, 600, 1200);

    if (count < API.Invfreecount_()) then
        return true
    
    else 
        return false;
    end
end

function deposit()
    API.DoAction_Object1(0x29, 80, { Barbarian_Forge }, 50)
    API.WaitUntilMovingEnds()
end

---@param int
---@return int 
function Check_Timer(int)
    return (API.SystemTime() - int)
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

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if not (API.PlayerLoggedIn()) then
        print("Player is not logged in. Terminating Script.")
        return
    else
        if (Start_Timer == 0) then
            print("Initializing Timers")
            AFK_Timer = API.SystemTime()
            Script_Timer = API.SystemTime()
            Start_Timer = 1 
        end       
    end

    if API.InvFull_() then
        deposit()
    else
        if API.Invfreecount_() < API.Math_RandomNumber(14) then
            if not fillBox() then
                while not API.InvFull_() do
                    antiban()
                    API.RandomSleep2(2400, 0, 600)
                end
                deposit()
            end
        end
        mine()
    end
    API.RandomEvents()
    antiban()
    API.RandomSleep2(2400, 0, 600)

end----------------------------------------------------------------------------------
