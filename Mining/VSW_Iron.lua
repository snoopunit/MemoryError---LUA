print("Run Lua script VSW_Iron.")

local API = require("api")

--Varrock West Furnace
local Iron_Location = WPOINT:new(3183,3374,0)
local Furnace_Location = WPOINT:new(3186,3425,0)

local totalOresMined = 0
local lastOreCount = 0
local startTime = API.SystemTime()
local lastClick = 0

local function currentOres()
    return Inventory:GetItemAmount(440) --Iron Ore ID
end

local function clickRockertunity()
    local rockertunity = API.ReadAllObjectsArray({4}, {7164,7165}, {})
    if #rockertunity >= 1 then
        API.logDebug("Found rockertunity at "..tostring(rockertunity[1].TileX)..","..tostring(rockertunity[1].TileY))
        local r = rockertunity[1]
        local iron_rocks = API.ReadAllObjectsArray({0}, {113038,113039,113040}, {"Iron rock"})
        if #iron_rocks < 1 then
            return
        end
        local closestRock = nil
        local closestDist = math.huge
        for _, ironRock in ipairs(iron_rocks) do
            local dist = math.abs(r.TileX - ironRock.TileX) + math.abs(r.TileY - ironRock.TileY)
            if dist < closestDist then
                closestDist = dist
                closestRock = ironRock
            end
        end
        if closestRock then
            if API.DoAction_Object_Direct(0x3a, API.OFF_ACT_GeneralObject_route0, closestRock) then
                API.RandomSleep2(1200, 600, 1200)
                API.WaitUntilMovingEnds()
                API.RandomSleep2(2400, 0, 600)
            end
        end
    end
end

function walkToObject(coords)
    API.DoAction_WalkerW(coords)
    API.RandomSleep2(1200, 0, 600)
    API.WaitUntilMovingEnds()
end

function deposit()
    local failTimer = API.SystemTime()    
    while (Inventory:FreeSpaces() < 4) and API.Read_LoopyLoop() do
        Interact:Object("Forge", "Deposit-all (into metal bank)", 30)
        API.RandomSleep2(600, 0, 250)
        if API.SystemTime() - failTimer > 30000 then
            print("Failed to deposit ores after 10 seconds. Aborting.")
            return
        end
    end
end

function mine() 
    --API.DoAction_Object1(0x3a, 0, { Iron_Node1 }, 50)
    if (API.SystemTime() - lastClick) < 2400 then
        return
    end
    Interact:Object("Iron rock", "Mine", 20)
    lastClick = API.SystemTime()
end

---@return bool
function fillBox()
    local count = Inventory:FreeSpaces()
    
    --FILL ORE BOX

    local boxAB = API.GetABs_name("ore box", false)

    if boxAB.action == "Fill" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1200, 600, 1200);

    if (count < Inventory:FreeSpaces()) then
        lastOreCount = currentOres()
        return true
    
    else 
        return false;
    end
end

function OresPerHour()   
    return math.floor((totalOresMined*60)/((API.SystemTime() - startTime)/60000))
end

function updateOreMined()
    local count = currentOres()
    if count > lastOreCount then
        totalOresMined = totalOresMined + (count - lastOreCount)
        lastOreCount = count
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

    if (Inventory:IsFull()) then
        walkToObject(Furnace_Location)
        deposit()
        walkToObject(Iron_Location)
    else
        if (Inventory:FreeSpaces() < math.random(2,8)) then
            fillBox()
        end
        clickRockertunity()
        mine()
    end

    updateOreMined()

    ----METRICS----
    local metrics = {
        {"Script","Varrock South West Iron - by Klamor"},
        {"Total Ores:", totalOresMined},
        {"Ores/H:", OresPerHour()},
        {"Est. Profit: ", (totalOresMined * API.GetExchangePrice(440)).."gp"},
        {"Profit/H: ", 
            (function()
                local elapsed = (API.SystemTime() - startTime) / 3600000 -- convert ms to hours
                if elapsed > 0 then
                    return math.floor(( totalOresMined * API.GetExchangePrice(440)) / elapsed) .. "gp"
                else
                    return "0gp"
                end
            end)()
        }
    }
    API.DrawTable(metrics)

    API.DoRandomEvents()
    API.RandomSleep2(600, 0, 250)

    local elapsedTime = API.SystemTime() - startTime
    if elapsedTime > (3600000*2) then -- 2 hour in milliseconds
        print("2 hours have passed. Terminating script.")
        API.Write_LoopyLoop(false)
    end

end----------------------------------------------------------------------------------
