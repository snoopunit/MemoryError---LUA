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
---@param item number
---@return number
function Miscellaneous.itemsPerHour(item)
    if item == 0 then
        return 0
    end
    local elapsedTime = API.ScriptRuntime() / 3600 
    return math.floor(item / elapsedTime)
end

---@param ID number
---@param Num number
---@return number
function Miscellaneous.EstimatedProfit(ID, Num) 
    local profitPerItem = API.GetExchangePrice(ID)
    return Num * profitPerItem
end

---@param ID number
---@param Num number
---@return number
function Miscellaneous.EstimatedProfitPerHour(ID, Num)
    local elapsedTime = API.ScriptRuntime() / 3600
    return math.floor(Miscellaneous.EstimatedProfit(ID, Num) / elapsedTime)    
end

function Miscellaneous.getLevel(skill)

    return API.XPLevelTable(API.GetSkillXP(skill))

end

function Miscellaneous.isChooseToolOpen()

    if API.VB_FindPSettinOrder(2874, 0).state == 1277970 then
        return true
    else
        return false
    end

end

function Miscellaneous.waitForCraftingInterface()

    local failTimer = API.SystemTime()

    while not UTILS.isCraftingInterfaceOpen() do

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

    while not Miscellaneous.isChooseToolOpen() do

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

    while Miscellaneous.isChooseToolOpen() do

        API.RandomSleep2(250,0,250)

        if API.SystemTime() - failTimer > 30000 then

            API.logWarn("Failed to close Choose Tool Menu!")

            API.Write_LoopyLoop(false)

            return false

        end

    end

    return true

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

function Miscellaneous.clickStart()

    API.logInfo("Starting production...")

    if not UTILS.isCraftingInterfaceOpen() then

        API.logWarn("Failed to detect Crafting Interface...")

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

            if API.SystemTime() - craftingTimer > 10000 then
                API.logWarn("Crafting process took too long to start!")
                API.Write_LoopyLoop(false)
                return false
            end
            
        end

        while API.isProcessing() do
            API.RandomSleep2(600,0,500)
        end

        return true
        
    end

end

return Miscellaneous