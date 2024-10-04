print("Run Lua script Smelt Bars.")
--start smelting and update Smelt_Time accordingly before running Script

local API = require("api")
local UTILS = require("utils")

API.SetDrawTrackedSkills(true)

local furnace = 113261

local Min_AFK = 30000
local Max_AFK = 180000

----Script Timers----
AFK_Timer = API.SystemTime()
Script_Timer = API.SystemTime()

local antibans = 0

function Check_Timer(int)
    return (API.SystemTime() - int)
end
function antiban()
    local elapsedTime = Check_Timer(AFK_Timer)
    local afkThreshold = math.random(Min_AFK, Max_AFK)
    if elapsedTime > afkThreshold then
        antibans = antibans + 1
        local action = math.random(1, 7)
        if action == 1 then API.PIdle1()
        elseif action == 2 then API.PIdle2()
        elseif action == 3 then API.PIdle22()
        elseif action == 4 then API.KeyboardPress('w', 50, 250)
        elseif action == 5 then API.KeyboardPress('a', 50, 250)
        elseif action == 6 then API.KeyboardPress('s', 50, 250)
        elseif action == 7 then API.KeyboardPress('d', 50, 250)
        end
        AFK_Timer = API.SystemTime()
    end
end

function deposit()
    API.DoAction_Object1(0x29,80,{ furnace },50) -- depositOre
    API.RandomSleep2(600, 600, 1200)
end
function make()
    API.DoAction_Object1(0x3f,0,{ furnace },50) -- Smelt Items
    while not UTILS.isSmeltingInterfaceOpen() do
        API.RandomSleep2(50, 0, 50)
    end
    API.DoAction_Interface(0x24,0xffffffff,1,37,163,-1,API.OFF_ACT_GeneralInterface_route)
    while API.CheckAnim(100) do 
        antiban()
        API.RandomSleep2(600, 250, 600)    
    end
end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    if not (API.PlayerLoggedIn()) then
        print("Player is not logged in. Terminating Script.")
        API.Write_LoopyLoop(false)
        break      
    end

    if (API.InvFull_()) then
        deposit()
    else
        make()    
    end
end----------------------------------------------------------------------------------
