local API = require("api")
local WC = require("WOODCUTTING")

local Firemaking = {}

local ANIM = {
    CHOPPING = 36456,
    LIGHTING = 16783
}

--@return table/boolean -- returns table of obj if we find a fire or false if we dont
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
    
        return newFires
    else
        return false
    end
end

--@return boolean -- returns true if the Cook/Add to Fire interface is present
function Firemaking.findBonfireInterface()
   
    --Full IDs: { { 1179,0,-1,-1,0 }, { 1179,99,-1,0,0 }, { 1179,99,14,99,0 } }
    return #API.ScanForInterfaceTest2Get(true, { { 1179,0,-1,-1,0 }}) > 0
end

--@return boolean -- returns true if we Use action on a fire
function useFire()
    local fires = Firemaking.findFires()
    
    if not fires then
        print("No fires found")
        return false
    end

    for _, fire in pairs(fires) do

        API.DoAction_Object1(0x2e,API.GeneralObject_route_useon,{ fire.Id },50)
        

        if API.DoAction_Object1(0x2e,API.GeneralObject_route_useon,{  },50) then
            API.RandomSleep2(800, 0, 600)
            while API.ReadPlayerMovin2() do
                API.RandomSleep2(50, 0, 50)
            end
            return true
        end
    end

    return false

end

function Firemaking.useLogOnFire(logType)
    print("Clicking log: "..logType.name)
    API.DoAction_Inventory1(1513,0,1,API.OFF_ACT_GeneralInterface_route)    
    API.RandomSleep2(1200,0,600)

    local fires = Firemaking.findFires()
    if not fires then
        return false
    end
    
    for _, fire in pairs(fires) do
        print("Attempting to add to fire...")
        API.DoAction_Interface(0xffffffff,0xffffffff,0,1179,27,-1,API.OFF_ACT_GeneralInterface_Choose_option)
        API.RandomSleep2(1200,0,600)
    end

    if API.CheckAnim(60) then
        API.logInfo("Successfully added "..logType.name.." to the fire.")
        return true
    else
        API.logWarn("Failed to add "..logType.name.." to the fire.")
        return false
    end
end

--@return boolean -- returns true if we successfully 'add to bonfire' action on a fire
function Firemaking.addToBonfire()

    if not Firemaking.findBonfireInterface() then
        API.logWarn("Couldn't find bonfire interface!")
        return false
    end
    API.LogInfo("Adding "..logType.name.."s to the bonfire.")
    return API.DoAction_Interface(0xffffffff,0xffffffff,0,1179,17,-1,API.OFF_ACT_GeneralInterface_Choose_option)

end

--@param logType -- keyValue from LOGS table -- requires WOODCUTTING.lua
--@return boolean -- returns true if we find a log in the inv and light action on it
function Firemaking.lightLog(logType)
    API.logInfo("Starting a "..logType.name.." fire.")
    return API.DoAction_Inventory1(logType.id,0,2,API.OFF_ACT_GeneralInterface_route)
end

--@return obj/nil -- returns the brazier obj or nil if none foudn
function Firemaking.findBrazier()
    API.logWarn("updateTrees() function has not been implemented yet!")
    return false
end

--@return boolean -- returns true if we successfully action on the brazier
function Firemaking.useBrazier()
    API.logWarn("updateTrees() function has not been implemented yet!")
    return false
end

function Firemaking.makeIncense(logType)
    API.logInfo("Making incense with "..logType.name..".")
    return Inventory:DoAction(logType.id, 1, API.OFF_ACT_GeneralInterface_route)
end

function Firemaking.craftIncense()
    API.logInfo("Crafting incense.")
    return API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,API.OFF_ACT_GeneralInterface_Choose_option)
end
return Firemaking