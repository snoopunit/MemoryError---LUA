local API = require("api")

-- Temple of Aminishi Automation Skeleton
-- With static group pulls, patrol-safe start tiles, and timeout fallback

local TempleAminishi = {}

TempleAminishi.State = "INIT"

TempleAminishi.Metrics = {
    runs_completed = 0,
    restocks = 0,
    dungeon_times = {},
    start_time = os.time()
}

-- =====================
-- Utility
-- =====================
function TempleAminishi.log(msg)
    print("[" .. os.date("%X") .. "] " .. msg)
end

function TempleAminishi.nextState(state)
    TempleAminishi.log("Switching state → " .. state)
    TempleAminishi.State = state
end

function TempleAminishi.getAvgTime()
    local total, count = 0, #TempleAminishi.Metrics.dungeon_times
    if count == 0 then return 0 end
    for _, t in ipairs(TempleAminishi.Metrics.dungeon_times) do
        total = total + t
    end
    return math.floor(total / count)
end

function TempleAminishi.displayMetrics()
    TempleAminishi.log("=== Run Metrics ===")
    print("Runs Completed: " .. TempleAminishi.Metrics.runs_completed)
    print("Restocks: " .. TempleAminishi.Metrics.restocks)
    print("Avg Clear Time: " .. TempleAminishi.getAvgTime() .. "s")
end

-- =====================
-- Group Definitions (floor 1 placeholders)
-- =====================
TempleAminishi.Groups_F1 = {
    {
        id = 1,
        description = "Entry patrol + pack",
        start_tile   = {x = 102, y = 199},
        scan_area    = {x = 100, y = 200, r = 6},
        funnel_tile  = {x = 95,  y = 198},
        wait_timeout = 5,
        patrol_wait_max = 20  -- seconds to wait before forcing pull
    },
    {
        id = 2,
        description = "Right-side patrol",
        start_tile   = {x = 111, y = 212},
        scan_area    = {x = 110, y = 210, r = 8},
        funnel_tile  = {x = 107, y = 208},
        wait_timeout = 5,
        patrol_wait_max = 25
    },
    -- Add more groups here...
}

-- =====================
-- Group Handler
-- =====================
function TempleAminishi.handleGroup(group)
    TempleAminishi.log("Engaging group #" .. group.id .. ": " .. group.description)

    -- Step 0: Move to start tile
    if group.start_tile then
        Navigation.moveTo(group.start_tile)
        TempleAminishi.log("At start tile, waiting for patrol...")
    end

    -- Step 1: Wait until mobs are inside scan zone (with timeout)
    local mobs = {}
    local start_wait = os.time()
    while #mobs == 0 do
        mobs = Combat.findMobsInArea(group.scan_area)
        if os.time() - start_wait > group.patrol_wait_max then
            TempleAminishi.log("Timeout reached, forcing pull anyway.")
            break
        end
        os.execute("sleep 0.5")
    end
    if #mobs == 0 then
        TempleAminishi.log("No mobs found for group #" .. group.id .. " (skipping).")
        return
    end

    -- Step 2: Aggro group
    Combat.aggroGroup(mobs)

    -- Step 3: Retreat to funnel
    Navigation.moveTo(group.funnel_tile)

    -- Step 4–5: AoE rotation + straggler check
    local group_dead = false
    local last_target_time = os.time()
    while not group_dead do
        if Combat.hasTarget() then
            last_target_time = os.time()
            Combat.executeAoE()
        else
            if os.time() - last_target_time > group.wait_timeout then
                local stragglers = Combat.findMobsInArea(group.scan_area)
                if #stragglers > 0 then
                    Combat.attack(stragglers[1])
                else
                    group_dead = true
                end
            end
        end
        os.execute("sleep 0.2")
    end

    TempleAminishi.log("Group #" .. group.id .. " cleared.")
end

-- =====================
-- State Handlers
-- =====================
function TempleAminishi.init()
    TempleAminishi.log("Initializing...")
    TempleAminishi.nextState("TRAVEL_TO_DUNGEON")
end

function TempleAminishi.travelToDungeon()
    TempleAminishi.log("Traveling to Temple of Aminishi...")
    -- TODO: Add pathfinding / teleport handling
    TempleAminishi.nextState("CLEAR_FLOOR")
end

function TempleAminishi.clearFloor()
    TempleAminishi.log("Clearing first floor...")

    for _, group in ipairs(TempleAminishi.Groups_F1) do
        TempleAminishi.handleGroup(group)
    end

    TempleAminishi.Metrics.runs_completed = TempleAminishi.Metrics.runs_completed + 1
    table.insert(TempleAminishi.Metrics.dungeon_times, os.time() - TempleAminishi.Metrics.start_time)
    TempleAminishi.Metrics.start_time = os.time()
    TempleAminishi.nextState("RESET")
end

function TempleAminishi.resetDungeon()
    TempleAminishi.log("Resetting dungeon...")
    -- TODO: Walk out, re-enter
    local needRestock = false -- placeholder
    if needRestock then
        TempleAminishi.nextState("RESTOCK")
    else
        TempleAminishi.nextState("TRAVEL_TO_DUNGEON")
    end
end

function TempleAminishi.restock()
    TempleAminishi.log("Restocking at bank...")
    TempleAminishi.Metrics.restocks = TempleAminishi.Metrics.restocks + 1
    -- TODO: Teleport to bank, refill supplies
    TempleAminishi.nextState("TRAVEL_TO_DUNGEON")
end

-- =====================
-- Main Loop
-- =====================
function TempleAminishi.run()
    while true do
        if TempleAminishi.State == "INIT" then
            TempleAminishi.init()
        elseif TempleAminishi.State == "TRAVEL_TO_DUNGEON" then
            TempleAminishi.travelToDungeon()
        elseif TempleAminishi.State == "CLEAR_FLOOR" then
            TempleAminishi.clearFloor()
        elseif TempleAminishi.State == "RESET" then
            TempleAminishi.resetDungeon()
        elseif TempleAminishi.State == "RESTOCK" then
            TempleAminishi.restock()
        end

        TempleAminishi.displayMetrics()
        os.execute("sleep 1") -- tick interval
    end
end

-- Start
TempleAminishi.run()
