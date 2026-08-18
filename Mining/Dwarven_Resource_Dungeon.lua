print("Run Lua script Dwarven_Resource_Dungeon.")

local API = require("api")

local Min_AFK = 30000
local Max_AFK = 180000

local Mine_Gold = false
local Mine_Mithril = true

----Script Timers----
local Start_Timer = 0
local AFK_Timer
local Script_Timer

local antibans = 0

local Gold_Node = {}
table.insert(Gold_Node, 113061)
table.insert(Gold_Node, 113059)
table.insert(Gold_Node, 113060)

local Mithril_Node = 113051
local Deposit_Box = 25937

local Current_Node

function mineOre()
    --API.DoAction_Object1(0x3a,0,{ Current_Node },50)
    Interact:Object("Mithril rock", "Mine", 10)
end

---@return bool
function fillBox()
    local count = Inventory:FreeSpaces()
    
    --FILL ORE BOX
    API.DoAction_Interface(0x24,0xaef1,1,1473,5,0,API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1200, 600, 1200);

    if (count < Inventory:FreeSpaces()) then
        return true
    
    else 
        return false;
    end
end

function depositOre()
    --USE ORE BOX
    --API.DoAction_Interface(0x24, 0xaef1, 0, 1473, 5, 0, 1520);
    --Inventory:Use("Mithril ore box")
    API.DoAction_Interface(0x24,0xaef1,0,1473,5,0,API.OFF_ACT_Bladed_interface_route)
    API.RandomSleep2(600, 250, 600);

    --USE DEPOSIT BOX
    --API.DoAction_Object1(0x24, -80, { Deposit_Box }, 50);
    --Interact:Object("Bank deposit box", "Use Mithril ore box", 10)
    API.DoAction_Object1(0x24,API.OFF_ACT_GeneralObject_route00,{ 25937 },50);

    API.RandomSleep2(1200, 250, 600);
    --API.WaitUntilMovingEnds()
    --API.RandomSleep2(600, 250, 600);
    
    fillBox();

    --USE ORE BOX
    --Inventory:Use("Mithril ore box")
    API.DoAction_Interface(0x24,0xaef1,0,1473,5,0,API.OFF_ACT_Bladed_interface_route)
    API.RandomSleep2(600, 250, 600);

    --USE DEPOSIT BOX
    --Interact:Object("Bank deposit box", "Use Mithril ore box", 10)
    API.DoAction_Object1(0x24,API.OFF_ACT_GeneralObject_route00,{ 25937 },50);
    
    --API.DoAction_Object1(0x29,80,{ Deposit_Box },50)
    API.RandomSleep2(600, 250, 600)
    API.WaitUntilMovingEnds()
end

---@param int
---@return int 
function Check_Timer(int)
    return (API.SystemTime() - int)
end

---@return boolean
function antiban()
    --set time to AFK at random point between min/max
    local AFK_Time = (Min_AFK + API.Math_RandomNumber(Max_AFK/5) + API.Math_RandomNumber(Max_AFK/5) + API.Math_RandomNumber(Max_AFK/5) + API.Math_RandomNumber(Max_AFK/5) + API.Math_RandomNumber(Max_AFK/5))
    
    if (Check_Timer(AFK_Timer) < AFK_Time) then
        return false
    end

    print("=========================")
    print("AFK Timer:", Check_Timer(AFK_Timer)/1000)
    
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
    AFK_Timer = API.SystemTime()
    antibans = (antibans + 1)
    print("Antibans:", antibans)
    print("=========================") 
end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)
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
            if Mine_Gold then
                Current_Node = Gold_Node[math.random(1,3)]
            elseif Mine_Mithril then
                Current_Node = Mithril_Node    
            end    
        end       
    end
    
    if (Inventory:FreeSpaces() < API.Math_RandomNumber(6)) then
        if not (fillBox()) then
            API.RandomSleep2(2400, 0, 2400);
            depositOre()
        end  
    else
        mineOre()
    end

    antiban();
    API.RandomSleep2(2400, 0, 250);

end----------------------------------------------------------------------------------
