print("Run Lua script Smelt Bars.")
--start smelting and update Smelt_Time accordingly before running Script

local API = require("api")
local UTILS = require("utils")

API.SetDrawTrackedSkills(true)

local furnace = 113261

local Min_AFK = 30000
local Max_AFK = 180000

local Use_Timer = true

local cannonballs = 252000
local steel_bars = 52000

----Script Timers----
local Start_Timer = 0
local AFK_Timer
local Script_Timer
local Smelt_Timer
local Smelt_Time = cannonballs

local antibans = 0

---@param int
---@return int 
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

function deposit()
    ScripCuRunning2 = "Depositing";
    API.DoAction_Object1(0x29,80,{ furnace },50) -- depositOre
    API.RandomSleep2(600, 600, 1200)
end

function make()
    ScripCuRunning2 = "Smelting";
    API.DoAction_Object1(0x3f,0,{ furnace },50) -- Smelt Items
    API.RandomSleep2(600, 600, 1200)
    API.DoAction_Interface(0x24,0xffffffff,1,37,163,-1,API.OFF_ACT_GeneralInterface_route)
    --API.DoAction_Interface(0x24,0xffffffff,1,37,163,-1,2480) -- make items
    if Use_Timer then
        Smelt_Timer = API.SystemTime()
        print("Waiting for", (Smelt_Time/1000), "seconds")
        while Check_Timer(Smelt_Timer) < (Smelt_Time + math.random(600, 1200)) do 
            antiban()
            API.RandomSleep2(600, 250, 600)    
        end
        return
    else
        while not API.InvFull_() do
            print("Waiting for inventory")
            antiban()
            API.RandomSleep2(600, 250, 600)    
        end
    end
end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    if not (API.PlayerLoggedIn()) then
        print("Player is not logged in. Terminating Script.")
        LoopyLoop = false
    else
        if (Start_Timer == 0) then
            print("Initializing Timers")
            AFK_Timer = API.SystemTime()
            Script_Timer = API.SystemTime()
            Start_Timer = 1     
        end       
    end

    if (API.InvFull_()) then
        deposit()
    else
        make()    
    end
end----------------------------------------------------------------------------------
