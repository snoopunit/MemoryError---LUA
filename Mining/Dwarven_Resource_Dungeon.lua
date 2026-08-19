print("Run Lua script Dwarven_Resource_Dungeon.")

local API = require("api")

local Deposit_Box = 25937
local mithril_ore_id = 447

local totalOresMined = 0
local lastOreCount = 0

local startTime = API.SystemTime()

local function currentOres()
    return Inventory:GetItemAmount(mithril_ore_id)
end

function mineOre()
    Interact:Object("Mithril rock", "Mine", 10)
end

local function clickRockertunity()
    local rockertunity = API.ReadAllObjectsArray(
        {4},
        {7164, 7165},
        {}
    )

    if #rockertunity < 1 then
        return
    end

    local r = rockertunity[1]

    API.logDebug(
        "Found rockertunity at "
        .. tostring(r.TileX)
        .. ","
        .. tostring(r.TileY)
    )

    local mithrilRocks = API.ReadAllObjectsArray(
        {0},
        Mithril_Rocks,
        {"Mithril rock"}
    )

    if #mithrilRocks < 1 then
        return
    end

    local closestRock = nil
    local closestDist = math.huge

    for _, rock in ipairs(mithrilRocks) do
        local dist =
            math.abs(r.TileX - rock.TileX)
            + math.abs(r.TileY - rock.TileY)

        if dist < closestDist then
            closestDist = dist
            closestRock = rock
        end
    end

    if closestRock then
        API.RandomSleep2(800, 0, 1200)
        if API.DoAction_Object_Direct(
            0x3a,
            API.OFF_ACT_GeneralObject_route0,
            closestRock
        ) then
            API.RandomSleep2(1200, 600, 1200)
            API.WaitUntilMovingEnds()
        end
    end
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

function depositOre()
    function useOreBox()
        API.DoAction_Interface(0x24,0xaef1,0,1473,5,0,API.OFF_ACT_Bladed_interface_route)
        API.RandomSleep2(600, 250, 600)
    end

    function useDepositBox()
        API.DoAction_Object1(0x24,API.OFF_ACT_GeneralObject_route00,{ Deposit_Box },50);
        API.RandomSleep2(600, 250, 600)
    end

    useOreBox()
    useDepositBox()
    fillBox()
    useOreBox()
    useDepositBox()
    
end

function OresPerHour()   
    return math.floor((totalOresMined*60)/((API.SystemTime() - startTime)/60000))
end

function updateOreMined()
    local count = currentOres()
    if count ~= lastOreCount then
        if count > lastOreCount then
            totalOresMined = totalOresMined + (count - lastOreCount)
        end
        lastOreCount = count
    end
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
        return     
    end
    
    if (Inventory:FreeSpaces() < API.Math_RandomNumber(6)) then
        if not (fillBox()) then
            API.RandomSleep2(650, 0, 650);
            depositOre()
        end  
    else
        mineOre()
        clickRockertunity()
    end

    updateOreMined()

    ----METRICS----
    local metrics = {
        {"Script","Resource Dungeon Mithril - by Klamor"},
        {"Total Ores:", totalOresMined},
        {"Ores/H:", OresPerHour()},
        {"Est. Profit: ", (totalOresMined * API.GetExchangePrice(mithril_ore_id)).."gp"},
        {"Profit/H: ", 
            (function()
                local elapsed = (API.SystemTime() - startTime) / 3600000 -- convert ms to hours
                if elapsed > 0 then
                    return math.floor(( totalOresMined * API.GetExchangePrice(mithril_ore_id)) / elapsed) .. "gp"
                else
                    return "0gp"
                end
            end)()
        }
    }
    API.DrawTable(metrics)

    API.RandomSleep2(2400, 0, 250)

    if (API.SystemTime() - startTime) > 3600000 then
        print("Script has been running for over an hour. Terminating Script.")
        LoopyLoop = false
        return
    end

end----------------------------------------------------------------------------------
