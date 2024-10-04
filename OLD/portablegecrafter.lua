local API = require("api")
local UTILS = require("UTILS")

API.SetDrawTrackedSkills(true)

local Min_AFK = 30000
local Max_AFK = 180000

local banker = 3418
local craftID = 106594
local tanID = 106597
local antibans = 0

----Script Timers----
local AFK_Timer = API.SystemTime()
local Script_Timer = API.SystemTime()
local make_Timer

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

function loadLastPreset()
    print("Last Preset")
    local banktimer = API.SystemTime()
    API.DoAction_NPC(0x33,API.OFF_ACT_InteractNPC_route4,{ banker },50)
    API.RandomSleep2(600, 0, 250)
    while API.Invfreecount_() > 0 do
        if Check_Timer(banktimer) > 30000 then
            print("Out of supplies!")
            API.Write_LoopyLoop(false)
            return
        end
        API.RandomSleep2(50, 0, 50)
    end
end

function openBank()
    print("openBank")
    API.DoAction_NPC(0x5,API.OFF_ACT_InteractNPC_route,{ banker },50)
    API.RandomSleep2(2000, 0, 250)    
end

function preset(num)
    print("preset",num)
    API.DoAction_Interface(0x24,0xffffffff,1,517,119,num,API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(800, 0, 250)  
end

function craftCrafter()
    print("Crafter")
    local useTimer = API.SystemTime()
    API.DoAction_Object1(0x3e,API.OFF_ACT_GeneralObject_route0,{ craftID },50);
    while not UTILS.isCraftingInterfaceOpen() do
        if Check_Timer(useTimer) > 30000 then
            print("Crafter not available!")
            API.Write_LoopyLoop(false)
            return
        end
        API.RandomSleep2(50, 0, 50) 
    end   
end

function tanCrafter()
    print("Crafter")
    local useTimer = API.SystemTime()
    API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,{ tanID },50)
    while not UTILS.isCraftingInterfaceOpen() do
        if Check_Timer(useTimer) > 30000 then
            print("Crafter not available!")
            API.Write_LoopyLoop(false)
            return
        end
        API.RandomSleep2(50, 0, 50) 
    end
end

function startProduction()
    print("Start")
    if not UTILS.isCraftingInterfaceOpen() then
        print("something's fucked")
        API.Write_LoopyLoop(false)
            return
    end
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,API.OFF_ACT_GeneralInterface_Choose_option)  
    API.RandomSleep2(1200, 0, 250)  
end

function makeItems()
    --openBank()
    --preset(1)
    loadLastPreset()
    craftCrafter()
    startProduction()
    while API.CheckAnim(75) do

        antiban()
        API.RandomSleep2(600, 0, 250)
    
    end
end

function tanHides()
    openBank()
    preset(2)
    tanCrafter()
    startProduction() 
    antiban()
    API.RandomSleep2(600, 0, 250) 
end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    if not (API.PlayerLoggedIn()) then
        print("Player is not logged in. Terminating Script.")
        API.Write_LoopyLoop(false)
    end
    
    makeItems()
    --tanHides()

end----------------------------------------------------------------------------------