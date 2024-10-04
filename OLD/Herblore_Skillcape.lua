print("Run Lua script Herblore Skillcape.")

local API = require("api")

local bankchest = 79036
local ge_banker = 3418

local Cselect = API.ScriptDialogWindow2("Bank selection", {
    "Grand Exchange South", "Lumbridge Bank Chest",
    },"Start", "Close").Name;

local Min_AFK = (15000 + math.random(1000,30000))
local Max_AFK = 200000

----Script Timers----
local Start_Timer = 0
local AFK_Timer
local Script_Timer

local loops = 0

function Check_Timer(int)
    return (API.SystemTime() - int)
end

---@param ms
function RunTime(ms)
    if ms == nil then
        return
    end
    local seconds = math.floor(ms / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    local remainingSeconds = seconds % 60
    local remainingMinutes = minutes % 60
    if hours > 0 then
        io.write(tostring(hours), "h ")    
    end
    if remainingMinutes > 0 then
        io.write(tostring(remainingMinutes), "m ")
    end
    io.write(tostring(remainingSeconds), "s", "\n")
end

---@return boolean
function antiban()
    --set time to AFK at random point between min/max
    local AFK_Time = (Min_AFK + API.Math_RandomNumber(Max_AFK/5) + API.Math_RandomNumber(Max_AFK/5) + API.Math_RandomNumber(Max_AFK/5) + API.Math_RandomNumber(Max_AFK/5) + API.Math_RandomNumber(Max_AFK/5))
    
    if (Check_Timer(AFK_Timer) < AFK_Time) then
        return false
    end

    print("---------------------------")
    io.write("Runtime: ")
    RunTime(Check_Timer(Script_Timer))
    io.write("AFK Timer: ")
    RunTime(Check_Timer(AFK_Timer))
    
    local ab = API.Math_RandomNumber(1000)
    if ab >= 750 then
        API.PIdle1()
    elseif (ab < 750) and (ab > 500) then 
        API.PIdle2()
    elseif (ab < 500) and (ab > 250) then
        API.PIdle22()
    elseif ab <= 250 then

        local num = API.Math_RandomNumber(1000)
        if num >= 750 then
            API.KeyboardPress('w', 50, 250)
        elseif (num < 750) and (num > 500) then 
            API.KeyboardPress('a', 50, 250)
        elseif (num < 500) and (num > 250) then
            API.KeyboardPress('s', 50, 250)
        elseif num <= 250 then
            API.KeyboardPress('d', 50, 250)
        end

    end

    result = true
    AFK_Timer = API.SystemTime()
    print("---------------------------") 
end

function doBank(preset)
    --click bank
    if Cselect == "Grand Exchange South" then
        API.DoAction_NPC(0x5,400,{ ge_banker },50)
    elseif Cselect == "Lumbridge Bank Chest" then
        API.DoAction_Object1(0x2e,0,{ bankchest },50)
    end
    API.RandomSleep2(1200, 0, 50)
    API.WaitUntilMovingEnds()
    
    API.DoAction_Interface(0x24,0xffffffff,1,517,119,preset,2480)

    API.RandomSleep2(1200, 0, 50)
end

function cleanHerbs()
    API.DoAction_Interface(0xffffffff, 0x85da, 2, 1670, 18, -1, 2480)
    API.RandomSleep2(1200, 0, 50)
end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    if (Start_Timer == 0) then
        AFK_Timer = API.SystemTime()
        Script_Timer = API.SystemTime()
        Start_Timer = 1     
    end

    doBank(5)
    cleanHerbs()
    antiban()

    loops = loops + 1
    print("Total:", loops*28)

    if API.InvItemcount_String("Clean") < 28 then
        print("Out of Grimy Herbs.")
        print("Shutting down!")
        API.Write_LoopyLoop(false)
        return
    end
end 