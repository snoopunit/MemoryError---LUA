-- Require the API module
local API = require("API")

-- User Variables
local Min_AFK = 30000
local Max_AFK = 240000
local Min_Eat_Percent = 40
local party1 = "Snoopunit666" -- Example party member names or IDs
local party2 = "Abttreefiddy" -- Example party member names or IDs
local DEBUG = true

-- Timer Variables
local AFK_Timer = API.SystemTime()
local Script_Timer = API.SystemTime()
local antibans = 0

-- Dungeon Variables
local startTile = WPOINT:new(0, 0, 0) -- use starting tile coords to traverse the dungeon

-- Fight Coordinates
-- separate each encounter into a fight with designated starting coordinates
local stairs_leader = WPOINT:new(startTile + 20, startTile + 6, 0)
local stairs_follower = WPOINT:new(startTile + 19, startTile + 6, 0)
local right_leader = WPOINT:new(110, 110, 0)
local right_follower = WPOINT:new(160, 160, 0)
local left_leader = WPOINT:new(120, 120, 0)
local left_follower = WPOINT:new(170, 170, 0)
local landing_leader = WPOINT:new(130, 130, 0)
local landing_follower = WPOINT:new(180, 180, 0)
local fight5_leader = WPOINT:new(140, 140, 0)
local fight5_follower = WPOINT:new(190, 190, 0)
local fight6_leader = WPOINT:new(150, 150, 0)
local fight6_follower = WPOINT:new(200, 200, 0)
local fight7_leader = WPOINT:new(160, 160, 0)
local fight7_follower = WPOINT:new(210, 210, 0)
local fight8_leader = WPOINT:new(170, 170, 0)
local fight8_follower = WPOINT:new(220, 220, 0)
local fight9_leader = WPOINT:new(180, 180, 0)
local fight9_follower = WPOINT:new(230, 230, 0)
local fight10_leader = WPOINT:new(190, 190, 0)
local fight10_follower = WPOINT:new(240, 240, 0)
local fight11_leader = WPOINT:new(200, 200, 0)
local fight11_follower = WPOINT:new(250, 250, 0)

----Buff IDs----
local Extreme_Magic_Buff = 25829
local Overload_Buff = 26093

----Debuff IDs----
local Enhanced_Excalibur_DeBuff = 14632

----Enemy Ids----
local Elite_Sotapanna_Attacker = {}
table.insert(Elite_Sotapanna_Attacker, 25574)
table.insert(Elite_Sotapanna_Attacker, 25575)
table.insert(Elite_Sotapanna_Attacker, 25576)
table.insert(Elite_Sotapanna_Attacker, 25578)
table.insert(Elite_Sotapanna_Attacker, 25580)
table.insert(Elite_Sotapanna_Attacker, 25581)
local Elite_Sotapanna_Healer = {}
table.insert(Elite_Sotapanna_Healer, 25577)
table.insert(Elite_Sotapanna_Healer, 25582)

---Ability strings---
local Eat_Food = "Eat Food"
local Surge = "Surge"
local Incite = "Incite" --Taunt for Aggro
local Special_Attack = "Weapon Special Attack"


---@return boolean
function hasBuff(buff)
    if API.Buffbar_GetIDstatus(buff, false).id == 0 then
        return false
    else
        return true
    end
end

---@return boolean
function hasDeBuff(debuff)
    if API.DeBuffbar_GetIDstatus(debuff, false).id == 0 then
        return false
    else
        return true
    end
end

---MUST BE ON ACTIONBARS
---@param string
function activate(name)
    API.DoAction_Ability(name, 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 50, 300)
end

---@return boolean
function healthcheck()
    if API.GetHPrecent() < Min_Eat_Percent then
        print("Low HP! Eating Food!")
        activate(Eat_Food)
        API.RandomSleep2(600, 50, 300)
        if API.GetHPrecent() > Min_Eat_Percent then
            return true
        else
            return false
        end
    end
end

---@param int
---@return int 
function Check_Timer(int)
    return (API.SystemTime() - int)
end

local function getTotalRuntime(timer)
    local currentTime = API.SystemTime()
    local elapsed = currentTime - timer
    local hours = math.floor(elapsed / 3600000)
    local minutes = math.floor((elapsed % 3600000) / 60000)
    local seconds = math.floor((elapsed % 60000) / 1000)
    return string.format("%dh,%dm,%ds", hours, minutes, seconds)
end

function antiban()
        
    -- Calculate the time since the last afkTimer reset
    local elapsedTime = Check_Timer(AFK_Timer)
    
    -- Generate a random threshold between minAFK and maxAFK
    local afkThreshold = math.random(Min_AFK, Max_AFK)
    
    -- Check if the elapsed time exceeds the threshold
    if elapsedTime > afkThreshold then
        -- Print the scriptTimer, current elapsedTime, and separators
        antibans = antibans + 1

        local sTime = getTotalRuntime(Script_Timer)
        local eTime = getTotalRuntime(AFK_Timer)

        print("========================")
        print("Script Timer: ", sTime)
        print("AFK Timer: ", eTime)
        print("Antibans: ", antibans)
        print("========================")
            
        -- Perform a random antiban action
        local action = math.random(1, 7)
        if action == 1 then API.PIdle1()
        elseif action == 2 then API.PIdle2()
        elseif action == 3 then API.PIdle22()
        elseif action == 4 then API.KeyboardPress('w', 50, 250)
        elseif action == 5 then API.KeyboardPress('a', 50, 250)
        elseif action == 6 then API.KeyboardPress('s', 50, 250)
        elseif action == 7 then API.KeyboardPress('d', 50, 250)
        end
    
        -- Reset the afkTimer
        AFK_Timer = API.SystemTime()
    end
end

---@param name string
---@param distance int
---@return boolean
function PlayerInRange(name, distance)

    local allPlayers = API.ReadAllObjectsArray(true, 2)
    local player

    for i = 1, #allPlayers do
        if (allPlayers[i].Name == name) then
            player = allPlayers[i]
        end    
    end

    if not (player == nil) then
        local p = API.PlayerCoord()
        local dist = math.sqrt(((player.TileX / 512) - p.x)^2 + ((player.TileY / 512) - p.y)^2)

        if math.floor(dist) <= distance then
            return true
        end 
    end
   
    return false

end

---@param enemyID int
---@param distance int
---@return int
function FindEnemyInRange(enemy, distance)
    local allPlayers = API.ReadAllObjectsArray(true, 2)
    local player
    for i = 1, #allPlayers do
        if (allPlayers[i].Name == Username) then
            player = allPlayers[i]
        end    
    end
    if not (player == nil) then
        local NPCs = API.ReadAllObjectsArray(true, 1)
        local enemylist = {}
        for i = 1, #NPCs do
            local dist = math.sqrt(((NPCs[i].TileX / 512) - (player.TileX / 512))^2 + ((NPCs[i].TileY / 512) - (player.TileY / 512))^2)
            if math.floor(dist) <= distance then
                if NPCs[i].Id == enemy then
                    table.insert(enemylist, NPCs[i])
                end
            end     
        end
        if #enemylist == nil then
            return 0
        else
            return #enemylist
        end
    end  
end

-- Function to check if inside the dungeon
local function isInsideDungeon()
    if DEBUG then print("isInsideDungeon()") end
    local maxDistanceToChest = 10
    local chestID = 12345 -- Example chest ID

    return API.objectDistance(chestID) <= maxDistanceToChest
end

-- Function to check if outside the dungeon
local function isOutsideDungeon()
    if DEBUG then print("isOutsideDungeon()") end
    local maxDistancetoDoor = 5
    local doorTile = WPOINT:new(200, 200, 0) -- Example door coordinates

    return API.objectDistance(doorTile) <= maxDistancetoDoor
end

-- Function to reset the dungeon
local function dungeonReset()
    if DEBUG then print("dungeonReset()") end

    if not isOutsideDungeon() then
        print("We're NOT outside the dungeon!")
        return false
    end

    API.dooractionreset()
    if API.checkResetMessage() then
        print("Dungeon reset successful.")
        return true
    else
        print("Dungeon reset failed.")
        return false
    end
end

-- Function to navigate to the dungeon
local function navToDungeon()
    if DEBUG then print("navToDungeon()") end

    local templeDoorID = 103952

    if isOutsideDungeon() then
        API.DoAction_Object1(0x39,API.OFF_ACT_GeneralObject_route0,{ templeDoorID },50); -- Click on the door to enter the dungeon
        API.waitUntilMovingEnds() -- Wait until the moving ends
        API.RandomSleep2(1200, 250, 650) -- Adjust sleep time for animation/loading screen

        --add logic to deal with popup confirmation windows

        if isInsideDungeon() then
            print("Successfully entered the dungeon.")
            return true
        else
            print("Failed to enter the dungeon.")
            return false
        end
    else
        print("Already inside the dungeon.")
        return true
    end
end

---@return boolean
function LeaderInRange(distance)
    local allPlayers = API.ReadAllObjectsArray(true, 2)
    local leader
    for i = 1, #allPlayers do
        if (allPlayers[i].Name == Leader) then
            leader = allPlayers[i]
        end    
    end
    if not (leader == nil) then
        local p = API.PlayerCoord()
        local dist = math.sqrt(((leader.TileX / 512) - p.x)^2 + ((leader.TileY / 512) - p.y)^2)
        if math.floor(dist) <= distance then
            return true
        else
            return false
        end 
    else
        return false
    end
end

-- Function to set up the dungeon
local function setupDungeon()
    if DEBUG then print("setupDungeon()") end

    if not dungeonReset() then
        print("Dungeon reset failed.")
        API.Write_LoopyLoop(false) -- Stop the loop
    elseif not navToDungeon() then
        print("Failed to enter the dungeon.")
        API.Write_LoopyLoop(false) -- Stop the loop
    elseif not partyCheck() then
        print("Not all party members are on the same tile.")
        API.Write_LoopyLoop(false) -- Stop the loop
    end
end

-- Function to check if all party members are on the same tile
local function partyCheck()
    if DEBUG then print("partyCheck()") end
    local function isOnSameTile(member1, member2)
        local tile1 = API.getPlayerTile(member1)
        local tile2 = API.getPlayerTile(member2)
        return tile1.x == tile2.x and tile1.y == tile2.y and tile1.z == tile2.z
    end

    if not isInParty then
        return true -- If not in a party, consider it as checked
    end

    if not isOnSameTile(party1, party2) then
        return false
    end

    return true
end

---@return boolean
function attack()

    if API.IsTargeting() then
        print("Already fighting!")
        return true
    end
         
    API.DoAction_NPC_str(42, 480, {"*"}, 20, false, 0)
    API.RandomSleep2(1200, 50, 600)

    if API.IsTargeting() then      
        return true
    else
        return false
    end 

end

-- Function to move to a specified tile and handle combat
local function fight(leaderCoordinates, followerCoordinates)
    if DEBUG then print("fight()") end

    if isLeader then
        API.doActionWalkerW(leaderCoordinates)
        API.waitUntilMovingEnds() -- Wait until the movement is complete
    elseif isFollower then
        API.doActionWalkerW(followerCoordinates)
        API.waitUntilMovingEnds() -- Wait until the movement is complete
    end

    -- Check conditions based on user role
    if isLeader then
        local leaderTile = API.getPlayerTile() -- Get the tile coordinates of the leader
        local follower1Tile = API.getPlayerTile(party1) -- Get the tile coordinates of the first follower
        local follower2Tile = API.getPlayerTile(party2) -- Get the tile coordinates of the second follower

        local function isWithinOneTile(tile1, tile2)
            return math.abs(tile1.x - tile2.x) <= 1 and
                   math.abs(tile1.y - tile2.y) <= 1 and
                   math.abs(tile1.z - tile2.z) <= 1
        end

        if isWithinOneTile(leaderTile, follower1Tile) and
           isWithinOneTile(leaderTile, follower2Tile) then
            print("Leader is 1 tile away from both followers. Initiating attack.")
            API.attackEnemy() -- Start attacking the first enemy
            -- Check if the user is in combat
            if API.isInCombat() then
                print("Leader has successfully engaged in combat.")
                return true
            else
                print("Leader failed to engage in combat.")
                return false
            end
        else
            print("Leader is NOT within 1 tile of both followers.")
            return false
        end

    elseif isFollower then
        local leaderTile = API.getPlayerTile(party1) -- Get the tile coordinates of the leader
        local followerTile = API.getPlayerTile() -- Get the tile coordinates of the follower (this instance)

        local function isWithinOneTile(tile1, tile2)
            return math.abs(tile1.x - tile2.x) <= 1 and
                   math.abs(tile1.y - tile2.y) <= 1 and
                   math.abs(tile1.z - tile2.z) <= 1
        end

        if isWithinOneTile(leaderTile, followerTile) then
            print("Follower is on the same tile as the leader. Waiting for leader to start combat.")
            -- Wait for the leader to start combat and have a target
            while not API.isLeaderInCombat() or not API.leaderHasTarget() do
                API.wait(500) -- Adjust waiting time as needed
            end
            API.attackEnemy() -- Start attacking the enemy once the leader is in combat
            if API.isInCombat() then
                print("Follower has successfully engaged in combat.")
                return true
            else
                print("Follower failed to engage in combat.")
                return false
            end
        else
            print("Follower is NOT on the same tile as the leader.")
            return false
        end
    end
end

-- Function to handle combat
local function handleCombat()
    if DEBUG then print("handleCombat()") end
    local minHealthThreshold = 50 -- Example threshold for healing
    local combatStartTime = os.time() * 1000 -- Track when combat starts

    if API.isInCombat() then
        local currentHealth = API.getHealth()
        if currentHealth < minHealthThreshold then
            print("Health is low. Healing.")
            API.heal() -- Heal the player
        end
        combatStartTime = os.time() * 1000 -- Reset combat start time while still in combat
    else
        -- Check if the player has been out of combat for at least 3 seconds
        local currentTime = os.time() * 1000
        if (currentTime - combatStartTime) >= 3000 then
            print("Combat has ended. Exiting handleCombat.")
            return
        end
    end
end

--useful util functions
--waitForPlayerAtCoords(coords, threshold, maxwaitinseconds)
--getSkillOnBar


-- Main Loop
initialize() -- Call the initialization function

-- Set initial states
api.Write_LoopyLoop(true)
api.Write_Doaction_paint(true)

while API.ReadLoopLoop() do
    -- Add your main loop logic here
end
