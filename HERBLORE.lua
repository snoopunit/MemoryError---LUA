local API = require("api")
local UTILS = require("UTILS")

local Herblore = {}

OBJECTS = {
    Portable_Well = 89770
}

POTIONS = {
    Water_Vial = 227,
    Spirit_Weed_Potion_Unf = 12181
}

GRIMY_HERBS = {

}

CLEAN_HERBS = {
    Clean_Spirit_Weed = 12172
}

function Herblore.makeVials()
    API.logDebug("Inventory:DoAction 'Make Vials' on water vials...")
    return Inventory:DoAction(POTIONS.Water_Vial,1,API.OFF_ACT_GeneralInterface_route)
end

function Herblore.mixPotionsAtPortableWell()
    API.logDebug("API.DoAction 'Mix Potions' on 'Portable Well'")
    return API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,{ OBJECTS.Portable_Well },50)
end

function Herblore.mixPotionsInventory(potionID)
    API.logDebug("Inventory:DoAction 'Mix' on ",tostring(potionID))
    return Inventory:DoAction(potionID, 1, API.OFF_ACT_GeneralInterface_route)
end

function Herblore.cleanHerbs(herbID)
    API.logDebug("Inventory:DoAction 'clean' on ", tostring(herbID))
    returnInventory:DoAction(herbID,1,API.OFF_ACT_GeneralInterface_route)
end

function Herblore.skillCape()
    if not Equipment:Contains("herblore cape") then
        API.logDebug("Couldn't find the herblore skillcape!")
        return false
    end
    API.logDebug("Using Skill Cape")
    local cape = Equipment:getCape()
    if cape then
        Equipment:DoAction(cape,2)
    else
        API.logDebug("Something went wrong. no cape data found!")
        return false
    end
end

return Herblore