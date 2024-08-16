print("Run Lua script Potions.")

local API = require("api")

local bankchest = 79036
local ge_banker = 3418

local Clean_Herbs = true
local Make_Unf = true

local Cselect = API.ScriptDialogWindow2("Bank selection", {
    "Grand Exchange South", "Lumbridge Bank Chest",
    },"Start", "Close").Name;

local Pselect = API.ScriptDialogWindow2("Potion selection", {
    "Attack potion", "Saradomin brew", "Adrenaline crystal", "Extreme attack",
    "Extreme strength", "Extreme ranging", "Prayer renewal", "Prayer potion",
    "Super magic potion", "Extreme magic", "Extreme defence", "Super attack",
    "Overload", "Runecrafting potion", "Super defence", "Super ranging potion",
    "Super strength"
    },"Start", "Close").Name; 

local unf_potion = "(unf)"
local grimy_herb = "Grimy"
local clean_herb = "Clean"

local Min_AFK = (15000 + math.random(1000,30000))
local Max_AFK = 140000

----Script Timers----
local Start_Timer = 0
local AFK_Timer
local Script_Timer

local loops = 0
local potions = 0
local potstomake = 14

local stop = false

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

function invnum(name, num)
    if (API.InvItemcount_String(name) == num) then
        return true
    end
    return false
end

function extremeAttack()
    API.DoAction_Interface(0x24,0x105,0,1473,5,14,1520)
    API.RandomSleep2(1000, 0, 600)
    API.DoAction_Interface(0x24,0x91,0,1473,5,13,2560)
    API.RandomSleep2(1000, 0, 600)
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,1600)
end

function extremeStrength()
    API.DoAction_Interface(0x24,0x10b,0,1473,5,13,1520)
    API.RandomSleep2(1000, 0, 600)
    API.DoAction_Interface(0x24,0x9d,0,1473,5,14,2560)
    API.RandomSleep2(1000, 0, 600)
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,1600)
end

function extremeRange()
    API.DoAction_Interface(0x24,0x30fb,0,1473,5,0,1520)
    API.RandomSleep2(1000, 0, 600)
    API.DoAction_Interface(0x24,0xa9,0,1473,5,1,2560)
    API.RandomSleep2(1000, 0, 600)
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,1600)
end

function extremeMagic()
    API.DoAction_Interface(0x24,0x257a,0,1473,5,0,1520)
    API.RandomSleep2(1000, 0, 600)
    API.DoAction_Interface(0x24,0xbe2,0,1473,5,1,2560)
    API.RandomSleep2(1000, 0, 600)
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,1600)
end

function extremeDefence()
    API.DoAction_Interface(0x24,0x9b1,0,1473,5,13,1520)
    API.RandomSleep2(1000, 0, 600)
    API.DoAction_Interface(0x24,0xa3,0,1473,5,14,2560)
    API.RandomSleep2(1000, 0, 600)
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,1600)
end

function cleanHerbs()
    --Clean Herb Button
    API.DoAction_Interface(0x2e,0xbe9,1,1670,109,-1,2480)
    API.RandomSleep2(1000, 0, 600)
    -- click clean
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,1600)
    API.RandomSleep2(600, 0, 600)
end

function makeUNF()
    --Click Make Vial
    API.DoAction_Interface(0x2e,0xe3,1,1670,122,-1,2480)
    API.RandomSleep2(1000, 0, 600)
    -- click Mix
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,1600)
    API.RandomSleep2(600, 0, 600)
end

function makePotions()
    --click unf potion
    API.DoAction_Interface(0x2e,0xbba,1,1670,135,-1,2480)
    API.RandomSleep2(1000, 0, 600)
    -- click mix
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,1600)
    API.RandomSleep2(600, 0, 600)
end

function doBank(preset)
    --click bank
    if Cselect == "Grand Exchange South" then
        API.DoAction_NPC(0x5,400,{ ge_banker },50)
    elseif Cselect == "Lumbridge Bank Chest" then
        API.DoAction_Object1(0x2e,0,{ bankchest },50)
    end
    API.RandomSleep2(1400, 250, 600)
    API.WaitUntilMovingEnds()
    
    API.DoAction_Interface(0x24,0xffffffff,1,517,119,preset,2480)

    API.RandomSleep2(1400, 250, 600)
end

function Action_Bar_1(slot)
    API.DoAction_Interface(0x2e,0xffffffff,1,1670,(18+(13*(slot-1))),-1,2480)
end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    if (Start_Timer == 0) then
        print("Making Potions")
        AFK_Timer = API.SystemTime()
        Script_Timer = API.SystemTime()
        if Pselect == "Extreme ranging" then
            Clean_Herbs = false
            Make_Unf = false
        elseif Pselect == "Extreme magic" then
            Clean_Herbs = false
            Make_Unf = false    
        elseif Pselect ==  "Adrenaline crystal" then
            Clean_Herbs = false
            Make_Unf = false
        elseif Pselect == "Extreme attack" then
            Make_Unf = false        
        elseif Pselect == "Extreme defence" then
            Make_Unf = false
        elseif Pselect == "Overload" then
            Clean_Herbs = false
            Make_Unf = false
        end
        print("Clean Herbs: ", Clean_Herbs)
        print("Make Unfinished Pots: ", Make_Unf)
        Start_Timer = 1     
    end 

    

    if Clean_Herbs then
        doBank(2)
        cleanHerbs()
        --API.DoAction_Interface(0xffffffff, 0x85da, 2, 1670, 18, -1, 2480)
        API.RandomSleep2(1200, 0, 250)
        while not invnum(grimy_herb, 0) do
            antiban()
            API.RandomSleep2(1200, 0, 250)
        end
    end
    if Make_Unf then
        makeUNF()
        while not (API.InvItemcount_String(unf_potion) >= 14) do
            antiban()
            API.RandomSleep2(1200, 0, 250)
        end
    end
    if Pselect == "Extreme attack" then
        extremeAttack()
    elseif Pselect == "Extreme strength" then
        extremeStrength() 
    elseif Pselect == "Extreme defence" then
        extremeDefence()  
    elseif Pselect == "Extreme ranging" then
        potstomake = 27
        doBank(2)
        extremeRange() 
    elseif Pselect == "Extreme magic" then
        potstomake = 27
        doBank(2)
        extremeMagic()
    elseif Pselect == "Overload" then
        potstomake = 4
        doBank(3)
        cleanHerbs()
        while not invnum(grimy_herb, 0) do
            antiban()
            API.RandomSleep2(1200, 0, 250)
        end
        makePotions()         
    else
        doBank(1)
        makePotions()
    end

    if Pselect == "Adrenaline crystal" then
        potstomake = 13
    end
  
    print("Waiting for", potstomake, Pselect)

    while not invnum(Pselect, potstomake) do
        antiban()
        API.RandomSleep2(1200, 0, 250)
    end

    loops = loops + 1
    potions = (loops * potstomake)
    print("Total:", potions)
end----------------------------------------------------------------------------------
