local API = require("api")
local CombatEngine = require("lib/COMBAT")

-- create engine
local engine = CombatEngine.new()

-- optional: define priority targets (boss > adds)
engine.priorityList = {
    ["Chicken"] = 1
}

-- start engine
engine:start()

-- main loop
while API.Read_LoopyLoop() do
    -- engine:update() is called automatically on TickEvent.Register
    API.RandomSleep2(200, 50, 200)
end

-- stop engine when script ends
engine:stop()
