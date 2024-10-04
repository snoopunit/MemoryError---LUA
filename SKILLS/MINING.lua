local API = require("api")

local Mining = {}

Mining.ROCKS = {
    copper =            { name = "Copper rock", min_lvl = 1, max_lvl = 15 },
    tin =               { name = "Tin rock", min_lvl = 1, max_lvl = 15 },
    iron =              { name = "Iron rock", min_lvl = 10, max_lvl = 85 },
    coal =              { name = "Coal rock", min_lvl = 20, max_lvl = 85 },
    mithril =           { name = "Mithril rock", min_lvl = 30, max_lvl = 85 },
    adamantite =        { name = "Adamantite rock", min_lvl = 40, max_lvl = 85 },
    luminite =          { name = "Luminite rock", min_lvl = 40, max_lvl = 85 },
    runite =            { name = "Runite rock", min_lvl = 50, max_lvl = 85 },
    orichalcite =       { name = "Orichalcite rock", min_lvl = 60, max_lvl = 90 },
    drakolith =         { name = "Drakolith rock", min_lvl = 60, max_lvl = 90 },
    necrite =           { name = "Necrite rock", min_lvl = 70, max_lvl = 90 },
    phasmatite =        { name = "Phasmatite rock", min_lvl = 70, max_lvl = 90 },
    banite =            { name = "Banite rock", min_lvl = 80, max_lvl = 90 },
    light_animica =     { name = "Light animica rock", min_lvl = 90, max_lvl = 99 },
    dark_animica =      { name = "Dark animica rock", min_lvl = 90, max_lvl = 99 },
    primal =            { name = "Primal rock", min_lvl = 100, max_lvl = 120 },
}

Mining.ORES = {
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

Mining.ORE_BOXES = {
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