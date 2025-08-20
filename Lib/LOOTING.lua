local API = require("api")
local UTILS = require("utils")

function checkGroundItems()
    local items = API.ReadAllObjectsArray({3}, lootlist, {})

    return #items
end

function openLoot()

    if not lootDrops or (STATS.kills == 0) or (checkGroundItems() < 1) then
        return
    end

    local data = API.LootWindow_GetData()
    local hasWindowItems = false
    
    if #data then
        for i = 1, #data, 1 do
            for j = 1, #notelist, 1 do
                if data[i].itemid1 == notelist[j] then
                    hasWindowItems = true
                    break
                end
            end
        end
    end

    local dist = 10
    local radius = 10

    if not API.LootWindowOpen_2() then
        API.logDebug("Opening Loot Window")
        API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1678, 8, -1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 0, 0)
    end
    
    if Loot_Type == (Loot_Types.CUSTOM or Loot_Types.BOTH) and hasWindowItems then
        API.logDebug("Loot custom button")
        API.DoAction_Interface(0x24,0xffffffff,1,1622,30,-1,API.OFF_ACT_GeneralInterface_route)
    elseif Loot_Type == (Loot_Types.LIST or Loot_Types.BOTH) then
        if not API.LootWindowOpen_2() then API.logDebug("Searching for loot...")
        else API.logDebug("Looting lootlist") end
        API.DoAction_Loot_w(lootlist, dist, API.PlayerCoordfloat(), radius)
    end

end

function noteStuff()
    if not noteItems then
        return
    end
    if API.Invfreecount_() < math.random(1,4) then
        for i = 1, #notelist do
            API.logDebug("Noting: "..tostring(notelist[i]))
            UTILS.NoteItem(notelist[i])
        end
    end
end