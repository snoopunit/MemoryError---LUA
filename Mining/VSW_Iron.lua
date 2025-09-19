print("Run Lua script VSW_Iron.")

local API = require("api")

local Min_AFK = 30000
local Max_AFK = 180000

----Script Timers----
local Start_Timer = 0
local AFK_Timer
local Script_Timer

local loops = 0

local Iron_Node1 = 113038
local Furnace = 113259

--Varrock West Furnace
local Iron_Location = WPOINT:new(3183,3374,0)
local Furnace_Location = WPOINT:new(3186,3425,0)

function walkToObject(coords)
    API.DoAction_WalkerW(coords)
    API.RandomSleep2(1200, 0, 600)
    API.WaitUntilMovingEnds()
end

function deposit()
    API.DoAction_Object1(0x29, 80, { Furnace }, 50)
    API.RandomSleep2(1200, 0, 600)
end

function mine() 
    API.DoAction_Object1(0x3a, 0, { Iron_Node1 }, 50)
end

---@return bool
function fillBox()
    local count = API.Invfreecount_()
    
    --FILL ORE BOX

    local boxAB = API.GetABs_name("ore box", false)

    if boxAB.action == "Fill" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1200, 600, 1200);

    if (count < API.Invfreecount_()) then
        return true
    
    else 
        return false;
    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if not (API.PlayerLoggedIn()) then
        print("Player is not logged in. Terminating Script.")
        return      
    end

    if (API.InvFull_()) then
            walkToObject(Furnace_Location)
            deposit()
            walkToObject(Iron_Location)
            loops = (loops + 1)

    else
        
        if (API.Invfreecount_() < math.random(3,9)) then
            fillBox()
        end
        mine()
    end

    API.DoRandomEvents()
    API.RandomSleep2(2400, 0, 250)

end----------------------------------------------------------------------------------
