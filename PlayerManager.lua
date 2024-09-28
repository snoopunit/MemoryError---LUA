local API = require("api")
local TASK = require("TASK")

local PlayerManager = {}
PlayerManager.__index = PlayerManager

function PlayerManager:new()
    local pManager = {
        tasks = {}
        availableTasks = {}
        currentTask,
        MIN_IDLE = 3,
        MAX_IDLE = 8,
        taskTimer = 60
    }
    setmetatable(pManager, PlayerManager)
    return pManager
end

function PlayerManager:setIdle()
    local idleTime = math.random(self.MIN_IDLE, self.MAX_IDLE)
    local percentage = math.random(1, 10) / 100  -- Random percentage between 0.01 and 0.10
    local addOrSubtract = math.random(1, 2)  -- 1 = subtract, 2 = add
    local adjustment = baseNumber * percentage
    if addOrSubtract == 1 then
        baseNumber = baseNumber - adjustment  -- Subtract the percentage
    else
        baseNumber = baseNumber + adjustment  -- Add the percentage
    end
    --baseNumber = math.floor(baseNumber + 0.5)
    print("Idle value set to:", baseNumber)  -- You can store or use this value in your game logic
    API.SetMaxIdleTime(baseNumber)
end
function PlayerManager:setupTasks()
    if #PlayerManager.tasks == 0 then
        print("Player Manager has no tasks!")
        return false
    else
        for x = 1, #PlayerManager.tasks do
            if PlayerManager.tasks[x].levelCheck() then
                table.insert(PlayerManager.availableTasks, PlayerManager.tasks[x])
            end
        end
        print("Available tasks: " .. tostring(#PlayerManager.availableTasks))
        return true
    end
end

return PlayerManager