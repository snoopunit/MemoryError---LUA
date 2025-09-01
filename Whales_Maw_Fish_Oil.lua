print("Run Lua script Whales_Maw_Fish_Oil.")

local API = require("api")

local Active_Client_Timer
local Script_Timer

local Start_Timer = 0

local Use_Potion = true
local JujuFishingPotion = 35739

function Action_Bar2(int)
    API.DoAction_Interface(0x2e,0xffffffff,1,1671,(13+(13*(int-1))),-1,2480)       
end

---@return int
function Script_Runtime()
    return (API.SystemTime() - Script_Timer)
end

---@return int
function Active_Runtime()
    return (API.SystemTime() - Active_Client_Timer)
end

---@return boolean
function antiban()
    --set time to AFK at random point between min/max
    local AFK_Time = (60000 + API.Math_RandomNumber(120000))
    
    if (Active_Runtime() < AFK_Time) then
        return false
    end

    print("______________________")
    print("AFK Timer:", Active_Runtime()/1000)
    
    local ab = API.Math_RandomNumber(1000)
    if ab >= 750 then
        API.PIdle1();
        result = true
    end
    if (ab < 750) and (ab > 500) then 
        API.PIdle2();
        result = true 
    end
    if (ab < 500) and (ab > 250) then
        API.PIdle22();
        result = true    
    end
    if ab <= 250 then
        API.KeyboardPress(' ', 600, 600)
        print("SPACE")
        result = true 
    end
    Active_Client_Timer = API.SystemTime()
    print("______________________") 
end

function fish()
    if not API.CheckAnim(100) then
        print("Fishing")
        --if not fishing then Net Fishing Spot
        API.DoAction_NPC(0x3c,400,{23133},50)        
        API.RandomSleep2(1200, 1200, 1800)
        API.WaitUntilMovingEnds()     
    end
    --wait while we are fishing
    antiban()
    if API.Buffbar_GetIDstatus(JujuFishingPotion, false).id == 0 then
        if Use_Potion then
            print("Drinking a new Perfect Juju Fishing Potion!")
            Action_Bar2(7)
            API.RandomSleep2(600, 600, 1200) 
        end         
    end
    API.RandomSleep2(3600, 3600, 7200) 
end

function cook()
    --abandon if we don't have a full inventory
    if (API.Invfreecount_() > 0) then
        return
    end
    --cook at campfire
    print("______________________")
    print("Making Fish Oil")
    API.DoAction_Object1(0x40,0,{104004},50)
    API.RandomSleep2(600, 600, 1200)
    API.WaitUntilMovingEnds()
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,1600)
    API.RandomSleep2(6000, 1050, 2000)
    API.DoAction_Object1(0x40,0,{104004},50)
    API.RandomSleep2(600, 600, 1200)
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,1600)
    API.RandomSleep2(6000, 1050, 2000)
    print("______________________")
end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    --Start timers
    if (Start_Timer == 0) then
        Active_Client_Timer = API.SystemTime()
        Script_Timer = API.SystemTime()
        Start_Timer = 1 
    end
    if (API.Invfreecount_() > 0) then
        fish()
    else
        cook()
    end 
end----------------------------------------------------------------------------------
