local API = require("api")

local Fishing = {}

FISH = {
    SHRIMPS =           {raw = "Raw shrimps",           cooked = "Shrimps",              id = nil},
    SARDINE =           {raw = "Raw sardine",           cooked = "Sardine",              id = nil},
    HERRING =           {raw = "Raw herring",           cooked = "Herring",              id = nil},
    ANCHOVIES =         {raw = "Raw anchovies",         cooked = "Anchovies",            id = nil},
    MACKEREL =          {raw = "Raw mackerel",          cooked = "Mackerel",             id = nil},
    TROUT =             {raw = "Raw trout",             cooked = "Trout",                id = nil},
    COD =               {raw = "Raw cod",               cooked = "Cod",                  id = nil},
    PIKE =              {raw = "Raw pike",              cooked = "Pike",                 id = nil},
    SALMON =            {raw = "Raw salmon",            cooked = "Salmon",               id = nil},
    TUNA =              {raw = "Raw tuna",              cooked = "Tuna",                 id = nil},
    RAINBOW_FISH =      {raw = "Raw rainbow fish",      cooked = "Rainbow fish",         id = nil},
    CAVE_EEL =          {raw = "Raw cave eel",          cooked = "Cave eel",             id = nil},
    LOBSTER =           {raw = "Raw lobster",           cooked = "Lobster",              id = nil},
    BASS =              {raw = "Raw bass",              cooked = "Bass",                 id = nil},
    SWORDFISH =         {raw = "Raw swordfish",         cooked = "Swordfish",            id = nil},
    MONKFISH =          {raw = "Raw monkfish",          cooked = "Monkfish",             id = nil},
    SHARK =             {raw = "Raw shark",             cooked = "Shark",                id = nil},
    SEA_TURTLE =        {raw = "Raw sea turtle",        cooked = "Sea turtle",           id = nil},
    MANTA_RAY =         {raw = "Raw manta ray",         cooked = "Manta ray",            id = nil},
    CAVEFISH =          {raw = "Raw cavefish",          cooked = "Cavefish",             id = nil},
    ROCKTAIL =          {raw = "Raw rocktail",          cooked = "Rocktail",             id = nil},
    SAILFISH =          {raw = "Raw sailfish",          cooked = "Sailfish",             id = nil}
}

SPOTS = {
    SHRIMP_ANCHOVY = {
        name = "Fishing spot",
        action = "Net",
        submenu = {"Small net", "Bait"},
        Location = {{2923,3180,0},{2925,3181,0},{2923,3179,0}}
    },
    SARDINE_HERRING = {
        name = "Fishing spot",
        action = "Bait",
        submenu = {"Net", "Harpoon"},
        Location = {}
    },
    TROUT_SALMON = {
        name = "Fishing spot",
        action = "Lure",
        submenu = {"Bait"},
        Location = {{3238,3251,0},{3238,3252,0}}
    },
    LOBSTER = {
        name = "Fishing spot",
        action = "Cage",
        submenu = {"Harpoon"},
        Location = {{2925,3181,0},{2926,3180,0},{2921,3178,0},{2924,3181,0},{2923,3179,0},{2923,3180,0},{2926,3176,0}}
    },
    TUNA_SWORDFISH = {
        name = "Fishing spot",
        action = "Cage",
        submenu = {"Harpoon"},
        Location = {{2925,3181,0},{2926,3180,0},{2921,3178,0},{2924,3181,0},{2923,3179,0},{2923,3180,0},{2926,3176,0}}
    },
    MACKEREL_COD_BASS = {
        name = "Fishing spot",
        action = "Net",
        submenu = {"Harpoon"},
        Location = {}
    },
    LEAPING_TROUT_SALMON_STURGEON = {
        name = "Rod Fishing spot",
        action = "Use-rod",
        submenu = {},
        Location = {}
    },
    TRAWLER_FISH = {
        name = "Trawler net",
        action = "Inspect",
        submenu = {},
        Location = {}
    },
    CRAYFISH = {
        name = "Crayfish spot",
        action = "Cage",
        submenu = {},
        Location = {}
    },
    KARAMBWAN = {
        name = "Fishing spot",
        action = "Fish",
        submenu = {},
        Location = {}
    },
    MONKFISH = {
        name = "Fishing spot",
        action = "Net",
        submenu = {},
        Location = {}
    },
    CAVE_FISH = {
        name = "Rocky outcrop",
        action = "Bait",
        submenu = {},
        Location = {}
    },
    SHARK = {
        name = "Fishing spot",
        action = "Net",
        submenu = {"Harpoon"},
        Location = {{2599,3419,0},{2601,3422,0},{2603,3417,0},{2605,3424,0},{2605,3425,0},{2605,3416,0}}
    },
    ROCKTAIL = {
        name = "Rocktail shoal",
        action = "Fish",
        submenu = {},
        Location = {}
    },
    SAILFISH = {
        name = "Fishing spot",
        action = "Fish",
        submenu = {},
        Location = {}
    },
    MINNOW_SHOAL = {
        name = "Minnow shoal",
        action = "Catch",
        submenu = {},
        Location = {{2131,7097,0},{2127,7091,0},{2142,7088,0},{2141,7094,0},{2129,7089,0}}
    },
    GREEN_JELLYFISH = {
        name = "Green Blubber Jellyfish",
        action = "Fish",
        submenu = {},
        Location = {}
    }
}

function Fishing.getSpotLocation(spotType)
    if not spotType or not spotType.Location or #spotType.Location == 0 then
        API.logError("Invalid spotType or empty Location provided to Fishing.getSpotLocation")
        return nil
    end

    -- Pick a random coordinate from spotType.Location
    local randomLocation = spotType.Location[math.random(#spotType.Location)]

    -- Log the selected fishing spot coordinates
    API.logDebug("Selected fishing spot: {" .. randomLocation[1] .. "," .. randomLocation[2] .. "," .. randomLocation[3] .. "}")

    -- Create and return a WPOINT from the randomly selected location
    return WPOINT:new(randomLocation[1], randomLocation[2], randomLocation[3])
end

function Fishing.goTo(spotType)
    local locations = spotType.Location

    if #locations == 0 then
        API.logWarn("No locations defined for " .. spotType.name)
        return false
    end

   local tile = Fishing.getSpotLocation(spotType)

    API.logDebug("Attempting to walk to fishing spot")
    if walkPath(randomizePoint(tile)) then
        API.RandomSleep2(600, 200, 200)
        while API.ReadPlayerMovin2() do
            if distanceFromPlayer(tile) < 10 then break end
            API.RandomSleep2(100, 50, 50)
        end
    else
        API.logError("Failed to walk to fishing spot")
        return false
    end

    local distance = distanceFromPlayer(tile)
    API.logDebug("Distance from fishing spot after walking: " .. distance)

    if distance > 40 then    
        API.logError("Not in " .. spotType.name .. " location after successfully moving.")
        API.logError("Check locations for " .. spotType.name)
        return false
    end

    API.logDebug("Successfully reached fishing spot")
    return true
end

function Fishing.findFishingSpots(spotType)
    local spots = API.ReadAllObjectsArray({1},{-1},{spotType.name})

    if spots == nil or #spots == 0 then
        API.logWarn("Couldn't find any: " .. spotType.name)
        return false  
    end

    API.logDebug("Found " .. #spots .. " total spots for " .. spotType.name)

    local validSpots = {}
    local newCoords = {}

    for _, spot in pairs(spots) do
        if spot.Distance < 40 and spot.Action == spotType.action then
            local x, y, z = math.floor(spot.Tile_XYZ.x), math.floor(spot.Tile_XYZ.y), math.floor(spot.Tile_XYZ.z)
            local isNew = true
            
            -- Check if this coordinate is already in spotType.Location
            for _, existingCoord in ipairs(spotType.Location) do
                if existingCoord[1] == x and existingCoord[2] == y and existingCoord[3] == z then
                    isNew = false
                    break
                end
            end
            
            if isNew then
                table.insert(newCoords, {x, y, z})
            end
            table.insert(validSpots, spot)
        end
    end

    API.logDebug("Found " .. #validSpots .. " valid spots for " .. spotType.name)

    if #validSpots > 0 then
        if #newCoords > 0 then
            -- Print out the new coordinates on one line
            local coordString = "New coordinates: Location = {"
            for i, coord in ipairs(newCoords) do
                coordString = coordString .. string.format("{%d,%d,%d}%s", 
                    coord[1], coord[2], coord[3],
                    i < #newCoords and "," or "")
            end
            coordString = coordString .. "}"
            API.logDebug(coordString)
        else
            API.logDebug("No new coordinates found.")
        end
        return validSpots
    else
        API.logWarn("Couldn't find any valid fishing spots for " .. spotType.name)
        API.Write_LoopyLoop(false)
        return false
    end
end

function Fishing.fish(spotType)

    local offset = nil

    if spotType == SPOTS.TUNA_SWORDFISH 
    or spotType == SPOTS.SHARK then
        offset = API.OFF_ACT_InteractNPC_route2
    else 
        offset = API.OFF_ACT_InteractNPC_route
    end

    local spots = Fishing.findFishingSpots(spotType)

    if not spots or #spots == 0 then
        API.Write_LoopyLoop(false)
        return false
    end

    for _, spot in pairs(spots) do
        if API.DoAction_NPC(0x3c, offset, { spot.Id }, 50) then
            API.RandomSleep2(800, 0, 250)
            if API.ReadPlayerMovin2() or API.CheckAnim(50) then
                return true
            end
        end
    end

    return false
end

---@return string|nil -- returns the key of fish type found in inv or nil if none
function Fishing.findRawFish()
    local invItems = API.ReadInvArrays33()

    API.logDebug("Found " .. #invItems .. " items in inventory")

    for fishKey, fishInfo in pairs(FISH) do
        for _, item in ipairs(invItems) do
            if item.textitem == "<col=ff9040>" .. fishInfo.raw then
                API.logDebug("Found: " .. fishInfo.raw)
                if fishInfo.id ~= item.itemid1 then
                    API.logDebug("Updating " .. fishInfo.raw .. " ID from " .. (fishInfo.id or "nil") .. " to " .. item.itemid1)
                    LOGS[fishKey].id = item.itemid1
                end
                API.logDebug("Log type found: " .. fishKey)
                return fishKey  -- This returns the actual key from the LOGS table
            end
        end
    end

    API.logDebug("No logs found in inventory")
    return nil
end

function Fishing.gather(spotType)
    if not spotType then
        API.logError("Invalid spotType provided to Fishing.gather")
        return false
    end

    while not API.InvFull_() and API.Read_LoopyLoop() do 
        -- Pick a random coordinate from spotType.Location
        local randomLocation = spotType.Location[math.random(#spotType.Location)]
        
        -- Create a WPOINT from the randomly selected location
        local fishingSpot = WPOINT:new(randomLocation[1], randomLocation[2], randomLocation[3])
        
        -- Log the selected fishing spot coordinates
        API.logDebug("Selected fishing spot: {" .. fishingSpot.x .. "," .. fishingSpot.y .. "," .. fishingSpot.z .. "}")

        if distanceFromPlayer(fishingSpot) > 30 then
            Fishing.goTo(spotType)
        end

        if not Fishing.fish(spotType) then
            API.logWarn("Unable to fish: " .. spotType.name)
            return false
        else
            API.RandomSleep2(1200, 0, 1200)
            API.logInfo("Fishing: " .. spotType.name)
            while API.CheckAnim(50) or API.ReadPlayerMovin2() do
                API.DoRandomEvents()
                API.RandomSleep2(600, 0, 250)
            end
        end
    end
    return true
end

return Fishing