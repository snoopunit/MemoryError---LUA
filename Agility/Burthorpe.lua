local API = require("api")

local COORDS = {
    START = { x = 2922, y = 3575 },
    LOG = { x = 2916, y = 3578 },
    WALL = { x = 2912, y = 3578 },
    BALANCE_LEDGE = { x = 2910, y = 3571 },
    OBSTACLE_WALL = { x = 2912, y = 3571 },
    ROPE = { x = 2912, y = 3575 },
    MONKEY_BARS = { x = 2921, y = 3576 },
}

local function isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

local function walkLogBeam()
    return Interact:Object("Log beam", "Walk", 10)
end

local function climbWall()
    return Interact:Object("Wall", "Climb-up", 10)
end

local function walkBalanceLedge()
    return Interact:Object("Balancing ledge", "Walk-across", 10)
end

local function climbObstacleWall()
    return Interact:Object("Obstacle low wall", "Climb-over", 10)
end

local function swingRope()
    return Interact:Object("Rope swing", "Swing-on", 10)
end

local function swingMonkeyBars()
    return Interact:Object("Monkey bars", "Swing-across", 10)
end

local function jumpLedge()
    return Interact:Object("Ledge", "Jump-down", 10)
end

local function obstacleCourse()
    if isAtLocation(COORDS.START, 1) then
        walkLogBeam()
    end
    if isAtLocation(COORDS.LOG, 1) then
        climbWall()
    end
    if isAtLocation(COORDS.WALL, 1) then
        walkBalanceLedge()
    end
    if isAtLocation(COORDS.BALANCE_LEDGE, 1) then
        climbObstacleWall()
    end
    if isAtLocation(COORDS.OBSTACLE_WALL, 1) then
        swingRope()
    end
    if isAtLocation(COORDS.ROPE, 1) then
        swingMonkeyBars()
    end
    if isAtLocation(COORDS.MONKEY_BARS, 1) then
        jumpLedge()
    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while API.Read_LoopyLoop() do

    if not API.ReadPlayerMovin2() and not API.CheckAnim(20) then
        obstacleCourse()
    end
    API.RandomSleep2(600,0,250)

end