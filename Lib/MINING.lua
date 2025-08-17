local API = require("api")

local Mining = {}

ROCKS = {
    copper = {
        name = "Copper rock",
        location = {}
    },
    tin = {
        name = "Tin rock",
        location = {}
    },
    iron = {
        name = "Iron rock",
        location = {}
    },
    coal = {
        name = "Coal rock",
        location = {}
    },
    mithril = {
        name = "Mithril rock",
        location = {}
    },
    adamantite = {
        name = "Adamantite rock",
        location = {}
    },
    luminite = {
        name = "Luminite rock",
        location = {}
    },
    runite = {
        name = "Runite rock",
        location = {}
    },
    orichalcite = {
        name = "Orichalcite rock",
        location = {}
    },
    drakolith = {
        name = "Drakolith rock",
        location = {}
    },
    necrite = {
        name = "Necrite rock",
        location = {}
    },
    phasmatite = {
        name = "Phasmatite rock",
        location = {}
    },
    banite = {
        name = "Banite rock",
        location = {}
    },
    light_animica = {
        name = "Light animica rock",
        location = {}
    },
    dark_animica = {
        name = "Dark animica rock",
        location = {}
    },
    primal = {
        name = "Primal rock",
        location = {}
    }
}

ORES = {
    copper =            { name = "Copper ore", id = 436 },
    tin =               { name = "Tin ore", id = 438 },
    iron =              { name = "Iron ore", id = 440 },
    coal =              { name = "Coal", id = 453 },
    mithril =           { name = "Mithril ore", id = 447 },
    adamantite =        { name = "Adamantite ore", id = 449 },
    luminite =          { name = "Luminite", id = 44820 },
    runite =            { name = "Runite ore", id = 451 },
    orichalcite =       { name = "Orichalcite ore", id = 44819 },
    drakolith =         { name = "Drakolith", id = 44821 },
    necrite =           { name = "Necrite ore", id = 44822 },
    phasmatite =        { name = "Phasmatite", id = 44823 },
    banite =            { name = "Banite ore", id = 44824 },
    light_animica =     { name = "Light animica", id = 44825 },
    dark_animica =      { name = "Dark animica", id = 44826 },
    primal =            { name = "Primal ore", id = 55826 },
}

ORE_BOXES = {
    bronze =            { name = "Bronze ore box", id = 44778 },
    iron =              { name = "Iron ore box", id = 44779 },
    steel =             { name = "Steel ore box", id = 44780 },
    mithril =           { name = "Mithril ore box", id = 44781 },
    adamant =           { name = "Adamant ore box", id = 44782 },
    rune =              { name = "Rune ore box", id = 44783 },
    orikalkum =         { name = "Orikalkum ore box", id = 44784 },
    necronium =         { name = "Necronium ore box", id = 44785 },
    bane =              { name = "Bane ore box", id = 44786 },
    elder_rune =        { name = "Elder rune ore box", id = 44787 }
}

function Mining.findRocks(spotType)
    local spots = API.ReadAllObjectsArray({0,12},{-1},{spotType.name})

    if spots == nil or #spots == 0 then
        API.logWarn("Couldn't find any: " .. spotType.name)
        return false  
    end

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
        API.logWarn("Couldn't find any valid mining spots for " .. spotType.name)
        API.Write_LoopyLoop(false)
        return false
    end
end

---@param rockType table -- The rock type entry from Mining.ROCKS table
---@return boolean -- returns true if we successfully start mining a rock
function Mining.mine(rockType)
    local rocks = API.ReadAllObjectsArray({0,12},{-1},{rockType.name})

    if #rocks == nil or #rocks == 0 then
        API.logWarn("Couldn't find any: "..rockType.name.."s")
        API.Write_LoopyLoop(false)
        return false  
    end

    for _, rock in ipairs(rocks) do
        if API.DoAction_Object_string1(0x3a, API.OFF_ACT_GeneralObject_route0, rock.Name, 30, true) then
            API.RandomSleep2(800, 0, 250)
            while API.ReadPlayerMovin2() do
                API.RandomSleep2(50, 0, 50)
            end
            return true
        end
    end
    return false
end

---@return boxType key -- returns the key name of ore box found in inv or nil if none
function Mining.findOreBox()
    for boxKey, boxInfo in pairs(Mining.ORE_BOXES) do
        if API.InvItemcount_1(boxInfo.id) > 0 then
            return boxKey
        end
    end
    return nil
end

---@param boxType table -- The ore box entry from Mining.ORE_BOXES table
---@param oreType table -- The ore type entry from Mining.ORES table
---@return number -- returns the # of ores of the specified type within the Ore Box
function Mining.oreBoxCount(boxType, oreType) 
    local container = API.Container_Get_all(boxType.id)
    for _, item in pairs(container) do
        if item.item_id ~= -1 and item.item_id == oreType.id then
            return item.item_stack
        end
    end
    return 0 
end

---@param oreType table -- The ore type entry from Mining.ORES table
---@return number -- returns the max capacity for the specified ore type
function Mining.oreBoxCapacity(oreType)
    local oreBoxLevelRequirements = {
        copper = 7,
        tin = 7,
        iron = 18,
        coal = 28,
        mithril = 38,
        adamantite = 48,
        runite = 58,
        orichalcite = 68,
        drakolith = 78,
        necrite = 88,
        phasmatite = 98,
        banite = 108,
        light_animica = 118,
        dark_animica = 118
    }

    local miningLevel = API.XPLevelTable(API.GetSkillXP("MINING"))
    local baseCapacity = 100
    local requiredLevel = oreBoxLevelRequirements[oreType.name] or 0

    if miningLevel >= requiredLevel then
        return 120
    else
        return baseCapacity
    end
end

---@return boolean -- returns true if the Ore Box gets filled with an # of items
function Mining.fillOreBox()
    -- Implementation needed
end

---@param boxType table -- The ore box entry from Mining.ORE_BOXES table
---@param oreType table -- The ore type entry from Mining.ORES table
---@return boolean -- returns true if the Ore Box is full
function Mining.oreBoxFull(boxType, oreType)
    if Mining.oreBoxCount(boxType, oreType) == Mining.oreBoxCapacity(boxType) then
        return true
    end
    return false
end

---@param rockType table -- The rock type entry from Mining.ROCKS table
---@param oreType table -- The ore type entry from Mining.ORES table
---@return boolean -- returns true when inv is full. fills the ore box along the way if we have one
function Mining.gather(rockType, oreType)
    while not API.InvFull() do
        local boxKey = Mining.findOreBox()
        if boxKey then
            local boxType = Mining.ORE_BOXES[boxKey]
            if API.InvFreeCount() < math.random(2,8) then
                if not Mining.oreBoxFull(boxType, oreType) then
                    API.LogDebug("Filling "..boxType.name.." with "..oreType.name.."s.")
                    Mining.fillOreBox()
                end
            end
        end
        if not Mining.mine(rockType) then
            API.logWarn("Unable to mine rock: "..rockType.name)
            API.Write_LoopyLoop(false)
            return false
        else
            while API.checkAnim(50) do
                API.DoRandomEvents()
                API.RandomSleep2(600, 0, 250)
            end
        end
    end
    return true
end

return Mining