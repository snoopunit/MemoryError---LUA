local API = require("api")
local WC = require("WOODCUTTING")
local MISC = require("MISC")

local Firemaking = {}

local ANIM = {
    CHOPPING = 36456,
    LIGHTING = 16783
}

---@return num/boolean -- returns number of objs if we find a fire or false if we dont
function Firemaking.findFires()

    local fires = API.ReadAllObjectsArray({0},{-1},{"Fire"})

    if #fires > 0 then

        local newFires = {}

        for _, fire in pairs(fires) do

            if fire.Name ~= "Fireplace" and fire.Distance < 10 then

                table.insert(newFires, fire)

            end

        end

        API.logDebug("Found: "..tostring(#newFires).." fire(s).")

        return #newFires

    else

        return false

    end

end

---@return boolean -- returns true if the Cook/Add to Fire interface is present
function Firemaking.findBonfireInterface()

   

    --Full IDs: { { 1179,0,-1,-1,0 }, { 1179,99,-1,0,0 }, { 1179,99,14,99,0 } }

    return #API.ScanForInterfaceTest2Get(true, { { 1179,0,-1,-1,0 }}) > 0

end

---@return boolean -- returns true if we Use action on a fire
function Firemaking.useFire()

    if not Firemaking.findFires() then
        print("No fires found")
        return false
    end

    if Interact:Object("Fire", "Use", 30) then
        API.RandomSleep2(800, 0, 600)
        while API.CheckAnim(60) do
            API.RandomSleep2(800, 0, 600)
        end
        if MISC.isChooseToolOpen() then
            return true
        end
    end

    return false

end

---@return obj/nil -- returns the brazier obj or nil if none foudn
function Firemaking.findBrazier()

    API.logWarn("updateTrees() function has not been implemented yet!")

    return false

end

---@return boolean -- returns true if we successfully action on the brazier
function Firemaking.useBrazier()

    API.logWarn("updateTrees() function has not been implemented yet!")

    return false

end

---@return boolean -- logType -- keyValue from LOGS table -- action -- 1-Craft, 2-Light, 3-Use, 4-Drop
function Firemaking.useLogs(logType, action)

    if action ~= 1 and action ~= 2 and action ~= 3 and action ~= 4 then
        API.logDebug("Firemaking useLogs action is not valid: ", action)
        return false
    end
    return Inventory:DoAction(logType.id, action, API.OFF_ACT_GeneralInterface_route)

end

---@return boolean -- returns true if we successfully 'add to bonfire' on an existing fire
function Firemaking.addToBonfire(logType)

    if Firemaking.useFire() then
        MISC.chooseToolOption("Bonfire")
        MISC.waitForChooseToolToClose()
    end

    API.RandomSleep2(1200,0,600)

    if API.CheckAnim(60) then
        API.logInfo("Successfully added "..logType.name.." to the fire.")
        return true
    else
        API.logWarn("Failed to add "..logType.name.." to the fire.")
        return false
    end

end

function Firemaking.makeIncense(logType)

    if not Firemaking.useLogs(logType, 1) then
        API.logWarn("Failed to use logs: "..logType.name)
        return false
    else
        API.logInfo("Using logs: "..logType.name)
        API.RandomSleep2(1200, 0, 600)
        if MISC.isChooseToolOpen() then
            MISC.chooseToolOption("Incense")
            API.RandomSleep2(1200, 0, 600)
        end
        if not MISC.doCrafting() then
            API.logWarn("Failed to start crafting incense with "..logType.name)
            return false
        end
    end

    if API.CheckAnim(60) then
        API.logInfo("Successfully made incense with "..logType.name..".")
        return true
    else
        API.logWarn("Failed to make incense with "..logType.name..".")
        return false
    end

end

return Firemaking