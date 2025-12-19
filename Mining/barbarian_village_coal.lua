print("Run Lua script Barbarian Village Coal.")

local API = require("api")

local totalOresMined = 0
local lastOreCount = 0
local lastClick = 0
local startTime = API.SystemTime()

local function deposit()
    --API.DoAction_Object1(0x29, 80, { Furnace }, 50)
    local failTimer = API.SystemTime()
    Interact:Object("Barbarian forge", "Deposit-all (into metal bank)", 30)
    while (Inventory:FreeSpaces() < 4) and API.Read_LoopyLoop() do
        API.RandomSleep2(600, 0, 250)
        if API.SystemTime() - failTimer > 10000 then
            print("Deposit taking too long, terminating script.")
            API.Write_LoopyLoop(false)
            return
        end
    end
    lastOreCount = 0
end

local function mine() 
    --API.DoAction_Object1(0x3a, 0, { Coal_Node }, 50)
    if (API.SystemTime() - lastClick) < 2400 then
        return
    end
    Interact:Object("Coal rock", "Mine", 30)
    lastClick = API.SystemTime()
end

---@return bool
local function fillBox()
    local count = Inventory:FreeSpaces()
    
    --FILL ORE BOX

    local boxAB = API.GetABs_name("ore box", false)

    if boxAB.action == "Fill" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end

    API.RandomSleep2(1200, 600, 1200);

    if (count < Inventory:FreeSpaces()) then
        lastOreCount = 0
        return true
    
    else 
        return false;
    end
end

local function OresPerHour()   
    return math.floor((totalOresMined*60)/((API.SystemTime() - startTime)/60000))
end

local function updateOreMined()
    local currentOres = Inventory:GetItemAmount(453) --Coal ID
    if currentOres > lastOreCount then
        totalOresMined = totalOresMined + (currentOres - lastOreCount)
        lastOreCount = currentOres
    end
end

local function clickRockertunity()
    local rockertunity = API.ReadAllObjectsArray({4}, {7164,7165}, {})
    if #rockertunity >= 1 then
        API.logDebug("Found rockertunity at "..tostring(rockertunity[1].TileX)..","..tostring(rockertunity[1].TileY))
        local r = rockertunity[1]
        local iron_rocks = API.ReadAllObjectsArray({0}, {113041,113042,113043}, {"Coal rock"})
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
        deposit()
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
        {"Script","Barbarian Village Coal - by Klamor"},
        {"Total Ores:", totalOresMined},
        {"Ores/H:", OresPerHour()},
        {"Est. Profit: ", (totalOresMined * API.GetExchangePrice(453)).."gp"},
        {"Profit/H: ", 
            (function()
                local elapsed = (API.SystemTime() - startTime) / 3600000 -- convert ms to hours
                if elapsed > 0 then
                    return math.floor(( totalOresMined * API.GetExchangePrice(453)) / elapsed) .. "gp"
                else
                    return "0gp"
                end
            end)()
        }
    }
    API.DrawTable(metrics)
    
    API.DoRandomEvents()
    API.RandomSleep2(600, 0, 250)

    if totalOresMined >= 14000 then
        print("Mined 14000 ores. Terminating script.")
        API.Write_LoopyLoop(false)
    end

end----------------------------------------------------------------------------------
