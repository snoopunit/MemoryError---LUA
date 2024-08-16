print("Run Lua script <NAME>.")

local API = require("api")

API.SetDrawTrackedSkills(true)

local Min_AFK = 30000
local Max_AFK = 180000

local usePortables = true

----BANK IDs----
local ca_chest = 79036
local ge_banker = 3418

----Herb Strings----
local skillCape = "Hooded herblore cape (t)"
local gFellstalk = "Grimy fellstalk"
local cFellstalk = "Clean fellstalk"

----Script Timers----
local AFK_Timer = API.SystemTime()
local Script_Timer = API.SystemTime()
local Make_Timer

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

function invnum(name, num)
    if (API.InvItemcount_String(name) == num) then
        return true
    end
    return false
end

---MUST BE ON ACTIONBARS
---@param string
function activate(name)
    API.DoAction_Ability(name, 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 50, 300)
end

function startProduction()
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,API.OFF_ACT_GeneralInterface_Choose_option)
    API.RandomSleep2(1200, 50, 300)    
end

---@param int
function doBank(preset)
    print("Banking:", tostring(preset))
    API.DoAction_Object1(0x2e,API.OFF_ACT_GeneralObject_route1,{ ca_chest },50)
    API.RandomSleep2(800, 50, 300)
    API.WaitUntilMovingEnds()
    API.DoAction_Interface(0x24,0xffffffff,1,517,119,preset,API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1800, 50, 300)
end

function cleanHerbs()
    print("Cleaning with cape...")
    API.DoAction_Ability("Hooded herblore cape (t)", 2, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(800, 50, 300)
end

function makeUNF()
    print("Making UNF Potions")
    activate("Vial of water")
    API.RandomSleep2(1200, 50, 300)
    startProduction()
    Make_Timer = API.SystemTime()
end

function useWell()
    print("Using Portable Well")
    API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,{ 89770 },50)
    API.RandomSleep2(800, 50, 300)
    API.WaitUntilMovingEnds()
    startProduction()
    Make_Timer = API.SystemTime()
end

function makePotion()
    API.DoAction_Inventory1(21624,0,0,API.OFF_ACT_Bladed_interface_route)
    API.DoAction_Inventory1(227,0,0,API.OFF_ACT_GeneralInterface_route1)
    startProduction()
    Make_Timer = API.SystemTime()
end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if not (API.PlayerLoggedIn()) then
        print("Player is not logged in. Terminating Script.")
        return   
    end

    doBank(1)
    cleanHerbs()
    makeUNF()

    local count = 0

    while not invnum("Avantoe potion (unf)", 14) do
        count = API.InvItemcount_String("Avantoe potion (unf)")
        print("Potions:", tostring(count))
        if Check_Timer(Make_Timer) > 24000 then
            if invnum("Avantoe potion (unf)", 13)
            then 
                break
            end
            API.Write_LoopyLoop(false)
            break
        end
        antiban()
        API.RandomSleep2(1200, 0, 250)
    end
    doBank(2)
    useWell()
    count = 0
    while not invnum("Super energy (3)", 14) do
        count = API.InvItemcount_String("Super energy (3)")
        print("Potions:", tostring(count))
        if Check_Timer(Make_Timer) > 24000 then
            if invnum("Super energy (3)", 13)
            then 
                break
            end
            API.Write_LoopyLoop(false)
            break
        end
        antiban()
        API.RandomSleep2(1200, 0, 250)
    end
    

end----------------------------------------------------------------------------------