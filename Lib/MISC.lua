local API = require("api")
local UTILS = require("UTILS")
local Miscellaneous = {}

---@param amount number
---@return string
function Miscellaneous.comma_value(amount)
    local formatted = tostring(amount) -- Convert the number to a string
    while true do
        -- Replace a sequence of digits followed by three digits with the same sequence, a comma, and the three digits
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        -- If no more replacements were made (k == 0), break the loop
        if (k == 0) then
            break
        end
    end
    return formatted
end

function Miscellaneous.fmt(value)
    if value > 999 then
        return Miscellaneous.comma_value(value)
    end
    return tostring(value)
end

---@param item number
---@return number
function Miscellaneous.itemsPerHour(item)
    if item == 0 then
        return 0
    end
    local elapsedTime = API.ScriptRuntime() / 3600 
    return math.floor(item / elapsedTime)
end

---@param itemID number
---@param itemNum number
---@return number
function Miscellaneous.EstimatedProfit(itemID, itemNum) 
    local profitPerItem = API.GetExchangePrice(itemID)
    return itemNum * profitPerItem
end

---@param itemID number
---@param itemNum number
---@return number
function Miscellaneous.EstimatedProfitPerHour(itemID, itemNum)
    local elapsedTime = API.ScriptRuntime() / 3600
    return math.floor(Miscellaneous.EstimatedProfit(itemID, itemNum) / elapsedTime)    
end

function Miscellaneous.getLevel(skill)

    return API.XPLevelTable(API.GetSkillXP(skill))

end

function Miscellaneous.isCraftingInterfaceOpen()
  return API.VB_FindPSett(2874, 1, 0).state == 1310738
end

function Miscellaneous.isChooseToolOpen()
    return API.VB_FindPSettinOrder(2874, 0).state == 1277970 
end

function Miscellaneous.isSwitchToolMenuOpen()
    return API.VB_FindPSettinOrder(2874, 0).state == 1277992
end

function Miscellaneous.isSwitchedToolMenuOpen()
    return API.VB_FindPSettinOrder(2874, 0).state == 40
end

function Miscellaneous.waitForCraftingInterface()

    local failTimer = API.SystemTime()

    while not Miscellaneous.isCraftingInterfaceOpen() and API.Read_LoopyLoop() do

        API.RandomSleep2(600,0,250)

        if API.SystemTime() - failTimer > 30000 then

            API.logWarn("Failed to open Crafting Interface!")

            API.Write_LoopyLoop(false)

            return false

        end

    end

    return true

end

function Miscellaneous.waitForChooseToolToOpen()

    local failTimer = API.SystemTime()

    while not Miscellaneous.isChooseToolOpen() and API.Read_LoopyLoop() do

        API.RandomSleep2(250,0,250)

        if API.SystemTime() - failTimer > 30000 then

            API.logWarn("Failed to open Choose Tool Menu!")

            API.Write_LoopyLoop(false)

            return false

        end

    end

    return true

end

function Miscellaneous.waitForChooseToolToClose()

    local failTimer = API.SystemTime()

    while Miscellaneous.isChooseToolOpen() and API.Read_LoopyLoop() do

        API.RandomSleep2(250,0,250)

        if API.SystemTime() - failTimer > 30000 then

            API.logWarn("Failed to close Choose Tool Menu!")

            API.Write_LoopyLoop(false)

            return false

        end

    end

    return true

end

---@return boolean --- returns true if we click on the "Change Tool" button
function Miscellaneous.changeToolOption()
    return API.DoAction_Interface(0x2e,0xffffffff,1,1371,14,-1,API.OFF_ACT_GeneralInterface_route)
end

function Miscellaneous.chooseToolOption(option)

    if option == "Light" then

        option = 12

    elseif option == "Fletch" then

        option = 17

    elseif option == "Bonfire" then

        option = 27

    elseif option == "Incense" then

        option = 32

    end

    if option ~= 12 and option ~= 17 and option ~= 27 and option ~= 32 then

        API.logDebug("Crafting Interface option is not valid: ", option)

        return false

    end

    if not Miscellaneous.isChooseToolOpen() then

        API.logDebug("Choose Tool Interface not detected!")

        return false

    end

    API.DoAction_Interface(0xffffffff,0xffffffff,0,1179,option,-1,API.OFF_ACT_GeneralInterface_Choose_option)

    Miscellaneous.waitForChooseToolToClose()

    return true

end

---@param selectionBoxNum number --- Selection Box Number
---@return boolean --- Returns true if API.DoAction_Interface() returns true
function Miscellaneous.chooseCraftingItem(selectionBoxNum)
    API.logDebug("Selecting crafting item #: "..tostring(selectionBoxNum))
    if not Miscellaneous.isCraftingInterfaceOpen() then
        API.logWarn("Failed to detect Crafting Interface in chooseCraftingItem()")
        API.Write_LoopyLoop(false)
        return false
    end
    local iType = 1 + ((selectionBoxNum - 1)*4)
    return API.DoAction_Interface(0xffffffff,0xffffffff,1,1371,22,iType,API.OFF_ACT_GeneralInterface_route)
end

function Miscellaneous.clickStart()
    API.logInfo("Starting production...")
    if not Miscellaneous.isCraftingInterfaceOpen() then
        API.logWarn("Failed to detect Crafting Interface in clickStart()")
        API.Write_LoopyLoop(false)
        return false
    end
    return API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,API.OFF_ACT_GeneralInterface_Choose_option)  
end

function Miscellaneous.autoRetaliate(set)

    function toggleAutoRetaliate()

        if API.DoAction_Interface(0xffffffff,0xffffffff,1,1430,57,-1,API.OFF_ACT_GeneralInterface_route) then
            API.RandomSleep2(800,0,250)
            return true
        else
            API.logWarn("Failed to toggle Auto Retaliate!")
            return false
        end

    end

    local state = API.VB_FindPSettinOrder(462, 0).state

    if set == "on" then

        if state == 0 then
            API.logInfo("Auto Retaliate is already ON")
            return true
        elseif state == 1 then 
            if toggleAutoRetaliate() then
                API.logInfo("Auto Retaliate turned ON")
                return true
            end
        end

    elseif set == "off" then

        if state == 1 then
            API.logInfo("Auto Retaliate is already OFF")
            return true
        elseif state == 0 then 
            if toggleAutoRetaliate() then
                API.logInfo("Auto Retaliate turned OFF")
                return true
            end
        end

    end

end

function Miscellaneous.doCrafting()

    Miscellaneous.waitForCraftingInterface()

    if Miscellaneous.clickStart() then
        local craftingTimer = API.SystemTime()

        while not API.isProcessing() do

            API.RandomSleep2(600,0,500)

            if not API.Read_LoopyLoop() then return false end

            if API.SystemTime() - craftingTimer > 10000 then
                API.logWarn("Crafting process took too long to start!")
                API.Write_LoopyLoop(false)
                return false
            end
            
        end

        while API.isProcessing() and API.Read_LoopyLoop() do
            API.RandomSleep2(600,0,500)
        end

        return true
        
    end

end

return Miscellaneous