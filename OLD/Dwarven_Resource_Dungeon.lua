print("Run Lua script Dwarven_Resource_Dungeon.")

local API = require("api")

API.SetDrawTrackedSkills(true)

local Min_AFK = 30000
local Max_AFK = 180000

local Mine_Gold = false
local Mine_Mithril = true

----Script Timers----
local AFK_Timer = API.SystemTime()
local Script_Timer = API.SystemTime()

local antibans = 0

--ore boxes--
local Bronze_Box

local Gold_Node = {}
table.insert(Gold_Node, 113061)
table.insert(Gold_Node, 113059)
table.insert(Gold_Node, 113060)

local Mithril_Node = 113051
local Deposit_Box = 25937

local Current_Node

function mineOre()
    API.DoAction_Object1(0x3a,0,{ Current_Node },50)
end

---@return bool
function fillBox()
    if not API.InventoryInterfaceCheckvarbit() then
        API.OpenInventoryInterface2()
    end

    local count = API.Invfreecount_()
    
    --FILL ORE BOX
    API.DoAction_Inventory1(44787,0,1,API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1200, 0, 0)

    if (count < API.Invfreecount_()) then
        return true
    
    else 
        return false;
    end
end

--add support for more boxes
function useOreBox()
    if not API.InventoryInterfaceCheckvarbit() then
        API.OpenInventoryInterface2()
    end
    API.DoAction_Inventory1(44787,0,0,API.OFF_ACT_Bladed_interface_route)
    API.RandomSleep2(600, 0, 0)    
end

function depositBox()
    API.DoAction_Object1(0x24, -80, { Deposit_Box }, 50)
    API.RandomSleep2(600, 0, 0)
end

function depositOre()
    
    useOreBox()
    depositBox()
    --API.WaitUntilMovingEnds()
    --API.RandomSleep2(600, 250, 600); 
    fillBox()

    useOreBox()
    depositBox()
    
end

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

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    if not (API.PlayerLoggedIn()) then
        print("Player is not logged in. Terminating Script.")
        API.Write_LoopyLoop(false)
    end
        
            if Mine_Gold then
                Current_Node = Gold_Node[math.random(1,3)]
            elseif Mine_Mithril then
                Current_Node = Mithril_Node    
            end    
               
    
    
    if (API.Invfreecount_() < API.Math_RandomNumber(6)) then
        if not (fillBox()) then
            API.RandomSleep2(600, 0, 250)
            depositOre()
        end  
    else
        mineOre()
    end

    API.RandomEvents()
    API.DoRandomEvents()
    antiban()
    API.RandomSleep2(2400, 0, 50)

end----------------------------------------------------------------------------------
