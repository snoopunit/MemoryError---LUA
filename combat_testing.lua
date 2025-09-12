local API = require("api")
local CombatEngine = require("lib/COMBAT")

-- create engine
local engine = CombatEngine.new()

-- optional: define priority targets (boss > adds)
engine.priorityList = {
    ["Chicken"] = 1
}

local names = {"Chicken", "Cow"}

local function scanForNPCs()

    local npcs = API.ReadAllObjectsArray({1}, {-1}, names)

    if not npcs then
        API.logDebug("No NPCs found.")
    else
        API.logDebug("Found " .. tostring(#npcs) .. " NPCs")
        for i, npc in ipairs(npcs) do
            if i > 10 then break end -- don’t spam
            API.logDebug(string.format("[%d] %s (id=%d, dist=%.1f, hp=%d)",
                i,
                tostring(npc.Name),
                npc.Unique_Id or -1,
                npc.Distance or -1,
                npc.Life or -1
            ))
        end
    end

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

-- start engine
--engine:start()

-- main loop
while API.Read_LoopyLoop() do
    -- engine:update() is called automatically on TickEvent.Register
    scanForNPCs()
    API.RandomSleep2(200, 50, 200)
end

-- stop engine when script ends
engine:stop()
