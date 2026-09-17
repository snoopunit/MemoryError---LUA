print("FISHING KARAMJA LOBSTER")

local API = require("api")
local WC = require("lib/WOODCUTTING")
local BANK = require("lib/BANKING")

local canFillBox = true

local ACADIA = {
  Name = "Acadia tree",
  Location = {{3304,3246,1},{3309,3247,1},{3310,3243,1}},
  IDs = {},
  log_ID = 40285,
}

---@param point WPOINT
---@return number
function distanceFromPlayer(point)
    local playerPos = API.PlayerCoord()
    local dx = point.x - playerPos.x
    local dy = point.y - playerPos.y
    local dz = point.z - playerPos.z
    return math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
end

---@param endPoint WPOINT
---@param segments number
---@return WPOINT[]
function lineToPlayer(endPoint, segments)
    local startPoint = API.PlayerCoord()
    local distance = distanceFromPlayer(endPoint)
    local segmentLength = distance / segments

    local points = {}
    for i = 0, segments do
        local t = i / segments
        local x = math.floor(startPoint.x + (endPoint.x - startPoint.x) * t)
        local y = math.floor(startPoint.y + (endPoint.y - startPoint.y) * t)
        local z = math.floor(startPoint.z + (endPoint.z - startPoint.z) * t)
        table.insert(points, {x = x, y = y, z = z})
    end

    return points
end

---@param point WPOINT
---@return WPOINT
function randomizePoint(point)
    local xOffset = math.random(-5, 5)
    local yOffset = math.random(-5, 5)
    return {
        x = (point.x + xOffset),
        y = (point.y + yOffset),
        z = (point.z)
    }
end

---@param destination WPOINT
function walkPath(destination)
    local MAX_SEGMENT_LENGTH = 30
    local currentPosition = API.PlayerCoord()
    
    if distanceFromPlayer(destination) <= 30 then
        return true
    end

    while distanceFromPlayer(destination) > MAX_SEGMENT_LENGTH do
        local distance = distanceFromPlayer(destination)
        local segments = math.ceil(distance / MAX_SEGMENT_LENGTH)
        local nextPointArray = lineToPlayer(destination, segments)[2]  -- Get the next point as an array
        
        -- Convert the array to a WPOINT
        local nextPoint = WPOINT:new(nextPointArray.x, nextPointArray.y, nextPointArray.z)
        
        API.logDebug("NextPoint: x=" .. nextPoint.x .. ", y=" .. nextPoint.y .. ", z=" .. nextPoint.z)

        if API.DoAction_WalkerW(nextPoint) then
            API.RandomSleep2(1800, 200, 1200)
            while API.ReadPlayerMovin2() do
                if distanceFromPlayer(destination) < 40 then return true end
                API.RandomSleep2(50, 0, 50)   
            end
        else
            API.logError("Failed to walk to point: x=" .. nextPoint.x .. ", y=" .. nextPoint.y .. ", z=" .. nextPoint.z)
            return false
        end
        
        currentPosition = API.PlayerCoord()
        if distanceFromPlayer(destination) < 40 then
            return true
        end
    end
    
    -- Final movement to destination
    API.logDebug("Attempting final move to destination")
    if API.DoAction_WalkerW(destination) then
        API.RandomSleep2(1800, 200, 1200)
        while API.ReadPlayerMovin2() do
            if API.PinAreaW(destination, 40) then return true end
            API.RandomSleep2(50, 0, 50)   
        end
    else
        API.logError("Failed to walk to final destination: x=" .. destination.x .. ", y=" .. destination.y .. ", z=" .. destination.z)
        return false
    end
    
    if distanceFromPlayer(destination) < 40 then
        API.logDebug("Successfully reached destination")
        return true
    else
        API.logWarn("Reached end of path but not near destination")
        return false
    end
end

local function fillWoodBox()
    
  local ability = API.GetABs_name("ood box", false)
    
  if ability.action == "Fill" and ability.enabled then
        
    API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
        
  end
    
  API.RandomSleep2(1200,0,400)
    
  if Inventory:GetItemAmount("Acadia logs") ~= 0 and Inventory:GetItemAmount("Acadia logs") > 1 then
        
    return false
        
  end
    
  return true
    
end

local function isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

function goToTrees() 
    local locations = ACADIA.Location

    if #locations == 0 then
        API.logWarn("No locations defined for " .. ACADIA.Name)
        return false
    end

    local locationToUse
    if #locations ~= 1 then
        locationToUse = locations[math.random(1, #locations)]
    else
        locationToUse = locations[1]
    end

    -- Ensure locationToUse is a table with three elements
    if type(locationToUse) ~= "table" or #locationToUse ~= 3 then
        API.logError("Invalid location format for " .. ACADIA.Name)
        return false
    end

    API.logDebug("Location Chosen for " .. ACADIA.Name .. ": x=" .. locationToUse[1] .. ", y=" .. locationToUse[2] .. ", z=" .. locationToUse[3])

    local tile = WPOINT:new(locationToUse[1], locationToUse[2], locationToUse[3])

    API.logDebug("Attempting to walk to ACADIA location")
    if walkPath(randomizePoint(tile)) then
        API.logDebug("Walk path successful, waiting for player to stop moving")
        API.RandomSleep2(600, 200, 200)
        while API.ReadPlayerMovin2() do
            API.RandomSleep2(100, 50, 50)
        end
        API.logDebug("Player stopped moving")
    else
        API.logError("Failed to walk to ACADIA location")
        return false
    end

    local distance = distanceFromPlayer(tile)
    API.logDebug("Distance from ACADIA after walking: " .. distance)

    if distance > 40 then    
        API.logError("Not in " .. ACADIA.Name .. " location after successfully moving.")
        API.logError("Check locations for " .. ACADIA.Name)
        return false
    end

    API.logDebug("Successfully reached ACADIA location")
    return true
end

function Chopping_and_Banking()

    if Inventory:IsFull() then

        BANK.goTo(BANK.BANKERS.AL_KHARID)

        local failCounter = 0
    
        while API.Read_LoopyLoop() and not Bank:IsOpen() do
            
            if not Interact:NPC("Banker", "Bank", 40) then
              if not Interact:Object("Bank booth", "Bank", 40) then
                  API.logWarn("Unable to interact with the bankers or booths!")
                  failCounter = failCounter + 1
              end
            end  

            if failCounter >= 10 then
                API.logWarn("Failed to open bank after 10 attempts!")
                API.Write_LoopyLoop(false)
                return
            end

        end
    
        API.RandomSleep2(1800,0,1800)
        if not Bank:DepositAll(ACADIA.log_ID) then
          API.logWarn("Unable to deposit logs!")
          API.Write_LoopyLoop(false)
          return
        end
    
        API.RandomSleep2(1800,0,1800)
        if not Bank:WoodBoxDepositLogs() then
          API.logWarn("Unable to deposit woodbox logs!")
          API.Write_LoopyLoop(false)
          return
        end

        API.RandomSleep2(1800,0,1800)


        canFillBox = true

    else

        if not isAtLocation(ACADIA.location[1], 40) then
            if not goToTrees() then
                API.Write_LoopyLoop(false)
                return
            end
        end
        
        if not API.CheckAnim(15) then
            if not WC.chop() then
              API.Write_LoopyLoop(false)
              return
            end
        end
  
        if Inventory:FreeSpaces() <= math.random(1,16) and canFillBox then
            if not fillWoodBox() then
                canFillBox = false
            end
        end
    end

    API.RandomSleep2(2400, 0 ,600)

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

WC.GLOBALS.treeType = TREES.ACADIA
WC.GLOBALS.logType = LOGS.ACADIA

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
  Chopping_and_Banking()
end----------------------------------------------------------------------------------
