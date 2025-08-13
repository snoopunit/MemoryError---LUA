local API = require("api")

local Cooking = {}

FOOD = {
    SHRIMP = {
        raw = "Raw shrimps",
        cooked = "Shrimps",
        rawId = nil,
        cookedId = nil
    },
    SARDINE = {
        raw = "Raw sardine",
        cooked = "Sardine",
        rawId = nil,
        cookedId = nil
    },
    ANCHOVIES = {
        raw = "Raw anchovies",
        cooked = "Anchovies",
        rawId = nil,
        cookedId = nil
    },
    HERRING = {
        raw = "Raw herring",
        cooked = "Herring",
        rawId = nil,
        cookedId = nil
    },
    MACKEREL = {
        raw = "Raw mackerel",
        cooked = "Mackerel",
        rawId = nil,
        cookedId = nil
    },
    TROUT = {
        raw = "Raw trout",
        cooked = "Trout",
        rawId = nil,
        cookedId = nil
    },
    COD = {
        raw = "Raw cod",
        cooked = "Cod",
        rawId = nil,
        cookedId = nil
    },
    PIKE = {
        raw = "Raw pike",
        cooked = "Pike",
        rawId = nil,
        cookedId = nil
    },
    SALMON = {
        raw = "Raw salmon",
        cooked = "Salmon",
        rawId = nil,
        cookedId = nil
    },
    TUNA = {
        raw = "Raw tuna",
        cooked = "Tuna",
        rawId = nil,
        cookedId = nil
    },
    RAINBOW_FISH = {
        raw = "Raw rainbow fish",
        cooked = "Rainbow fish",
        rawId = nil,
        cookedId = nil
    },
    CAVE_EEL = {
        raw = "Raw cave eel",
        cooked = "Cave eel",
        rawId = nil,
        cookedId = nil
    },
    LOBSTER = {
        raw = "Raw lobster",
        cooked = "Lobster",
        rawId = nil,
        cookedId = nil
    },
    BASS = {
        raw = "Raw bass",
        cooked = "Bass",
        rawId = nil,
        cookedId = nil
    },
    SWORDFISH = {
        raw = "Raw swordfish",
        cooked = "Swordfish",
        rawId = nil,
        cookedId = nil
    },
    LAVA_EEL = {
        raw = "Raw lava eel",
        cooked = "Lava eel",
        rawId = nil,
        cookedId = nil
    },
    MONKFISH = {
        raw = "Raw monkfish",
        cooked = "Monkfish",
        rawId = nil,
        cookedId = nil
    },
    SHARK = {
        raw = "Raw shark",
        cooked = "Shark",
        rawId = nil,
        cookedId = nil
    },
    SEA_TURTLE = {
        raw = "Raw sea turtle",
        cooked = "Sea turtle",
        rawId = nil,
        cookedId = nil
    },
    CAVEFISH = {
        raw = "Raw cavefish",
        cooked = "Cavefish",
        rawId = nil,
        cookedId = nil
    },
    MANTA_RAY = {
        raw = "Raw manta ray",
        cooked = "Manta ray",
        rawId = nil,
        cookedId = nil
    },
    ROCKTAIL = {
        raw = "Raw rocktail",
        cooked = "Rocktail",
        rawId = nil,
        cookedId = nil
    },
    BEEF = {
        raw = "Raw beef",
        cooked = "Cooked meat",
        rawId = nil,
        cookedId = nil
    },
    RAT_MEAT = {
        raw = "Raw rat meat",
        cooked = "Cooked meat",
        rawId = nil,
        cookedId = nil
    },
    BEAR_MEAT = {
        raw = "Raw bear meat",
        cooked = "Cooked meat",
        rawId = nil,
        cookedId = nil
    },
    CHICKEN = {
        raw = "Raw chicken",
        cooked = "Cooked chicken",
        rawId = nil,
        cookedId = nil
    },
    RABBIT = {
        raw = "Raw rabbit",
        cooked = "Cooked rabbit",
        rawId = nil,
        cookedId = nil
    },
    BIRD_MEAT = {
        raw = "Raw bird meat",
        cooked = "Cooked bird meat",
        rawId = nil,
        cookedId = nil
    },
    CRAB_MEAT = {
        raw = "Raw crab meat",
        cooked = "Cooked crab meat",
        rawId = nil,
        cookedId = nil
    },
    BEAST_MEAT = {
        raw = "Raw beast meat",
        cooked = "Cooked beast meat",
        rawId = nil,
        cookedId = nil
    },
    CHOMPY = {
        raw = "Raw chompy",
        cooked = "Cooked chompy",
        rawId = nil,
        cookedId = nil
    },
    JUBBLY = {
        raw = "Raw jubbly",
        cooked = "Cooked jubbly",
        rawId = nil,
        cookedId = nil
    },
    OOMLIE = {
        raw = "Raw oomlie",
        cooked = "Cooked oomlie wrap",
        rawId = nil,
        cookedId = nil
    },
    SWEETCORN = {
        raw = "Sweetcorn",
        cooked = "Cooked sweetcorn",
        rawId = nil,
        cookedId = nil
    },
    GIANT_CARP = {
        raw = "Raw giant carp",
        cooked = "Giant carp",
        rawId = nil,
        cookedId = nil
    },
    KARAMBWAN = {
        raw = "Raw karambwan",
        cooked = "Cooked karambwan",
        rawId = nil,
        cookedId = nil
    },
    KARAMBWANJI = {
        raw = "Raw karambwanji",
        cooked = "Cooked karambwanji",
        rawId = nil,
        cookedId = nil
    },
    BARON_SHARK = {
        raw = "Raw baron shark",
        cooked = "Baron shark",
        rawId = nil,
        cookedId = nil
    },
    SLIMY_EEL = {
        raw = "Raw slimy eel",
        cooked = "Cooked slimy eel",
        rawId = nil,
        cookedId = nil
    },
    SACRED_EEL = {
        raw = "Raw sacred eel",
        cooked = "Sacred eel",
        rawId = nil,
        cookedId = nil
    },
    POTATO = {
        raw = "Potato",
        cooked = "Baked potato",
        rawId = nil,
        cookedId = nil
    },
    UGTHANKI_MEAT = {
        raw = "Raw ugthanki meat",
        cooked = "Cooked ugthanki meat",
        rawId = nil,
        cookedId = nil
    },
    SAILFISH = {
        raw = "Raw sailfish",
        cooked = "Sailfish",
        rawId = nil,
        cookedId = nil
    },
    GREAT_WHITE_SHARK = {
        raw = "Raw great white shark",
        cooked = "Great white shark",
        rawId = nil,
        cookedId = nil
    },
    BLUE_BLUBBER_JELLYFISH = {
        raw = "Raw blue blubber jellyfish",
        cooked = "Blue blubber jellyfish",
        rawId = nil,
        cookedId = nil
    },
    CATFISH = {
        raw = "Raw catfish",
        cooked = "Catfish",
        rawId = nil,
        cookedId = nil
    },
    BELTFISH = {
        raw = "Raw beltfish",
        cooked = "Beltfish",
        rawId = nil,
        cookedId = nil
    },
    DESERT_SOLE = {
        raw = "Raw desert sole",
        cooked = "Desert sole",
        rawId = nil,
        cookedId = nil
    },
    GOLDEN_KARAMBIT = {
        raw = "Raw golden karambit",
        cooked = "Golden karambit",
        rawId = nil,
        cookedId = nil
    },
    CROCODILE = {
        raw = "Raw crocodile",
        cooked = "Cooked crocodile",
        rawId = nil,
        cookedId = nil
    },
    TARPON = {
        raw = "Raw tarpon",
        cooked = "Tarpon",
        rawId = nil,
        cookedId = nil
    },
    SEERFISH = {
        raw = "Raw seerfish",
        cooked = "Seerfish",
        rawId = nil,
        cookedId = nil
    },
    FRUIT_KEBAB = {
        raw = "Uncooked fruit kebab",
        cooked = "Fruit kebab",
        rawId = nil,
        cookedId = nil
    },
    MEAT_KEBAB = {
        raw = "Uncooked meat kebab",
        cooked = "Meat kebab",
        rawId = nil,
        cookedId = nil
    },
    PITTA_BREAD = {
        raw = "Uncooked pitta bread",
        cooked = "Pitta bread",
        rawId = nil,
        cookedId = nil
    },
    CAKE = {
        raw = "Uncooked cake",
        cooked = "Cake",
        rawId = nil,
        cookedId = nil
    },
    BREAD = {
        raw = "Bread dough",
        cooked = "Bread",
        rawId = nil,
        cookedId = nil
    },
    PIZZA_BASE = {
        raw = "Pizza base",
        cooked = "Plain pizza",
        rawId = nil,
        cookedId = nil
    },
    INCOMPLETE_PIZZA = {
        raw = "Incomplete pizza",
        cooked = "Uncooked pizza",
        rawId = nil,
        cookedId = nil
    },
    APPLE_PIE = {
        raw = "Uncooked apple pie",
        cooked = "Apple pie",
        rawId = nil,
        cookedId = nil
    },
    MEAT_PIE = {
        raw = "Uncooked meat pie",
        cooked = "Meat pie",
        rawId = nil,
        cookedId = nil
    },
    REDBERRY_PIE = {
        raw = "Uncooked redberry pie",
        cooked = "Redberry pie",
        rawId = nil,
        cookedId = nil
    },
    GARDEN_PIE = {
        raw = "Uncooked garden pie",
        cooked = "Garden pie",
        rawId = nil,
        cookedId = nil
    },
    FISH_PIE = {
        raw = "Uncooked fish pie",
        cooked = "Fish pie",
        rawId = nil,
        cookedId = nil
    },
    ADMIRAL_PIE = {
        raw = "Uncooked admiral pie",
        cooked = "Admiral pie",
        rawId = nil,
        cookedId = nil
    },
    WILD_PIE = {
        raw = "Uncooked wild pie",
        cooked = "Wild pie",
        rawId = nil,
        cookedId = nil
    },
    SUMMER_PIE = {
        raw = "Uncooked summer pie",
        cooked = "Summer pie",
        rawId = nil,
        cookedId = nil
    },
    MUSHROOM_AND_ONION = {
        raw = "Uncooked mushroom and onion",
        cooked = "Mushroom and onion",
        rawId = nil,
        cookedId = nil
    },
    MUSHROOM_AND_ONION_POTATO = {
        raw = "Uncooked mushroom and onion potato",
        cooked = "Mushroom and onion potato",
        rawId = nil,
        cookedId = nil
    },
    TUNA_AND_CORN = {
        raw = "Uncooked tuna and corn",
        cooked = "Tuna and corn",
        rawId = nil,
        cookedId = nil
    },
    TUNA_AND_CORN_POTATO = {
        raw = "Uncooked tuna and corn potato",
        cooked = "Tuna and corn potato",
        rawId = nil,
        cookedId = nil
    },
    CHILLI_CON_CARNE = {
        raw = "Uncooked chilli con carne",
        cooked = "Chilli con carne",
        rawId = nil,
        cookedId = nil
    },
    EGG_AND_TOMATO = {
        raw = "Uncooked egg and tomato",
        cooked = "Egg and tomato",
        rawId = nil,
        cookedId = nil
    },
    EGG_AND_TOMATO_POTATO = {
        raw = "Uncooked egg and tomato potato",
        cooked = "Egg and tomato potato",
        rawId = nil,
        cookedId = nil
    },
    CHEESE_AND_TOMATO_POTATO = {
        raw = "Uncooked cheese and tomato potato",
        cooked = "Cheese and tomato potato",
        rawId = nil,
        cookedId = nil
    },
    CURRY = {
        raw = "Uncooked curry",
        cooked = "Curry",
        rawId = nil,
        cookedId = nil
    },
    STEW = {
        raw = "Uncooked stew",
        cooked = "Stew",
        rawId = nil,
        cookedId = nil
    },
    FISHCAKE = {
        raw = "Uncooked fishcake",
        cooked = "Fishcake",
        rawId = nil,
        cookedId = nil
    },
    POTATO_WITH_BUTTER = {
        raw = "Potato with butter",
        cooked = "Potato with butter",
        rawId = nil,
        cookedId = nil
    },
    POTATO_WITH_CHEESE = {
        raw = "Potato with cheese",
        cooked = "Potato with cheese",
        rawId = nil,
        cookedId = nil
    },
    SPICY_SAUCE = {
        raw = "Uncooked spicy sauce",
        cooked = "Spicy sauce",
        rawId = nil,
        cookedId = nil
    },
    SCRAMBLED_EGG = {
        raw = "Uncooked egg",
        cooked = "Scrambled egg",
        rawId = nil,
        cookedId = nil
    },
    FRIED_ONIONS = {
        raw = "Onion",
        cooked = "Fried onions",
        rawId = nil,
        cookedId = nil
    },
    FRIED_MUSHROOMS = {
        raw = "Mushroom",
        cooked = "Fried mushrooms",
        rawId = nil,
        cookedId = nil
    },
    BANANA = {
        raw = "Raw banana",
        cooked = "Cooked banana",
        rawId = nil,
        cookedId = nil
    }
}

RANGES = {
    LUMBRIDGE_CASTLE = {
        name = "Cook-o-matic 25",
        id = nil,
        location = {}
    },
    FORT_FORINTHRY = {
        name = "Range",
        id = nil,
        location = {}
    },
    COOKS_GUILD = {
        name = "Range",
        id = nil,
        location = {}
    },
    CATHERBY = {
        name = "Range",
        id = nil,
        location = {}
    },
    NARDAH = {
        name = "Clay oven",
        id = nil,
        location = {}
    },
    NEITIZNOT = {
        name = "Clay oven",
        id = nil,
        location = {}
    },
    PORT_PHASMATYS = {
        name = "Range",
        id = nil,
        location = {}
    },
    ZANARIS = {
        name = "Range",
        id = nil,
        location = {}
    },
    PORTABLE_RANGE = {
        name = "Portable range",
        id = nil,
        location = {}
    },
    CATHERBY_HOUSE = {
        name = "Range",
        id = nil,
        location = {}
    },
    LUNAR_ISLE = {
        name = "Range",
        id = nil,
        location = {}
    },
    SEERS_VILLAGE = {
        name = "Range",
        id = nil,
        location = {}
    },
    SINCLAIR_MANSION = {
        name = "Range",
        id = nil,
        location = {}
    },
    MENAPHOS = {
        name = "Range",
        id = nil,
        location = {}
    }
}

function Cooking.findRanges(rangeType)
    local spots = API.ReadAllObjectsArray({1},{-1},{rangeType.name})

    if spots == nil or #spots == 0 then
        API.logWarn("Couldn't find any: " .. rangeType.name)
        return false  
    end

    local validSpots = {}
    local newCoords = {}

    for _, spot in pairs(spots) do
        if spot.Distance < 40 and spot.Action == rangeType.action then
            local x, y, z = math.floor(spot.Tile_XYZ.x), math.floor(spot.Tile_XYZ.y), math.floor(spot.Tile_XYZ.z)
            local isNew = true
            
            -- Check if this coordinate is already in rangeType.Location
            for _, existingCoord in ipairs(rangeType.Location) do
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
            for _, spot in pairs(validSpots) do
                API.logDebug("ID: "..tostring(spot.Id))
            end
        else
            API.logDebug("No new coordinates found.")
        end
        return validSpots
    else
        API.logWarn("Couldn't find any valid cooking ranges for " .. rangeType.name)
        API.Write_LoopyLoop(false)
        return false
    end
end


function Cooking.useRange(rangeType)

end

function Cooking.makeX_Cook()

end


function Cooking.makeX_Select()

end

function Cooking.makeCampfire()
    local WC = require("WOODCUTTING")

end


function Cooking.cookOnCampfire()

end

---@return string|nil -- returns the key of fish type found in inv or nil if none
function Cooking.findRawFood()
    local invItems = API.ReadInvArrays33()

    API.logDebug("Found " .. #invItems .. " items in inventory")

    for foodKey, foodInfo in pairs(FOOD) do
        for _, item in ipairs(invItems) do
            if item.textitem == "<col=ff9040>" .. foodInfo.raw then
                API.logDebug("Found: " .. foodInfo.raw)
                if foodInfo.id ~= item.itemid1 then
                    API.logDebug("Updating " .. foodInfo.raw .. " ID from " .. (foodInfo.id or "nil") .. " to " .. item.itemid1)
                    LOGS[foodKey].id = item.itemid1
                end
                API.logDebug("Log type found: " .. foodKey)
                return foodKey  -- This returns the actual key from the LOGS table
            end
        end
    end

    API.logDebug("No logs found in inventory")
    return nil
end

function Cooking.rawFoodCount()
    local foodType = Cooking.findRawFood()
    return API.InvItemcount_String(FOOD.foodType.raw)
end

return Cooking