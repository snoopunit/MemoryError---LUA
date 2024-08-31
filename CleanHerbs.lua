print("Run Lua script <NAME>.")

local API = require("api")

local skillcape = true

----BANK IDs----
local ca_chest = 79036
local ge_banker = 3418
local banker = ge_banker

----Herb Strings----
local gGuam = "Grimy guam"
local gTarromin = "Grimy tarromin"
local gMarrentill = "Grimy marrentill"
local gHarralander = "Grimy harralander"
local gRanaar = "Grimy ranarr"
local gToadflax = "Grimy toadflax"
local gSpiritweed = "Grimy spirit weed"
local gIrit = "Grimy irit"
local gWergali = "Grimy wergali"
local gAvantoe = "Grimy avantoe"
local gKwuarm = "Grimy kwuarm"
local gBloodweed = "Grimy bloodweed"
local gSnapdragon = "Grimy snapdragon"
local gCadantine = "Grimy cadantine"
local gLantadyme = "Grimy lantadyme"
local gDwarfweed = "Grimy dwarf weed"
local gArbuck = "Grimy arbuck"
local gFellstalk = "Grimy fellstalk"
local Herb_to_clean = gKwuarm

----Script Timers----
local AFK_Timer = API.SystemTime()
local Script_Timer = API.SystemTime()
local Make_Timer
local Min_AFK = 30000
local Max_AFK = 180000
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

function startProduction()
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,API.OFF_ACT_GeneralInterface_Choose_option)
    API.RandomSleep2(600, 0, 50)    
end

function doBank(preset)
    print("Banking:", tostring(preset))
    if banker == ge_banker then
        API.DoAction_NPC(0x5,API.OFF_ACT_InteractNPC_route,{ banker },50) 
    elseif banker == ca_chest then
        API.DoAction_Object1(0x2e,API.OFF_ACT_GeneralObject_route1,{ banker },50)   
    end
    
    
    API.RandomSleep2(1200, 0, 50)
    API.DoAction_Interface(0x24,0xffffffff,1,517,119,preset,API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1200, 0, 50)
end

function cleanHerbs()
    if skillcape then
        print("Cleaning with cape...")
        API.DoAction_Ability("Hooded herblore cape (t)", 2, API.OFF_ACT_GeneralInterface_route) 
    else
        API.DoAction_Interface(0x2e,0xd3,1,1670,123,-1,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(800, 0, 50)
        startProduction()
    end
    API.RandomSleep2(800, 0, 50)
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
    API.RandomSleep2(800, 0, 50)

    if API.InvItemcount_String(Herb_to_clean) == 0 then
        API.Write_LoopyLoop(false)
        break
    end

    cleanHerbs()

    while (API.InvItemcount_String(Herb_to_clean) > 0) or API.CheckAnim(50) do
        antiban()
        API.RandomSleep2(250, 0, 50)
    end
    API.RandomSleep2(1200, 0, 50)
end----------------------------------------------------------------------------------