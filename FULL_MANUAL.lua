print("Combat rountine")

local API = require("api")

function playerLocation(playerName)
    local obj = API.ReadAllObjectsArray({2}, {1}, {playerName})
    if obj == nil then
        return nil
    end
    if #obj == 1 then
        return obj[1].Tile_XYZ
    end
end

-- Detect number of enemy NPCs near the local player
function detectEnemiesNearSelf()
    local npcs = API.ReadAllObjectsArray({1}, {-1}, {})
    local count = 0

    for _, npc in ipairs(npcs) do
        if npc.Distance <= 5 then
            count = count + 1
        end
    end

    return count
end

-- Detect number of enemy NPCs near another player
function detectEnemiesNearPlayer(playerName)
    local npcs = API.ReadAllObjectsArray({1}, {-1}, {})
    local players = API.ReadAllObjectsArray({2}, {1}, {})
    local targetTile = nil
    local count = 0

    -- Find the target player's tile
    for _, playerObj in ipairs(players) do
        if playerObj.Name == playerName then
            targetTile = playerObj.Tile_XYZ
            break
        end
    end

    if not targetTile then
        return 0
    end

    -- Count NPCs within distance <= 5 from target player
    for _, npc in ipairs(npcs) do
        -- Calculate 2D distance manually for NPCs relative to target
        local dx = npc.Tile_XYZ.x - targetTile.x
        local dy = npc.Tile_XYZ.y - targetTile.y
        if math.sqrt(dx*dx + dy*dy) <= 5 then
            count = count + 1
        end
    end

    return count
end


function handleCombat()

    --if in combat

    --if out of combat

end

while API.Read_LoopyLoop(true) 
do-----------------------------------------------------------------------------------
    handleCombat()
end----------------------------------------------------------------------------------