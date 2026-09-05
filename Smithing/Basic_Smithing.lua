local API = require("api")

local smithingAnim = 32622

local lastReHeat = API.SystemTime()

local function hasUnfinished()
    return Inventory:Contains("Unfinished smithing item")
end

local function heatForge()
    return Interact:Object("Forge", "Heat", 10)
end

local function smithAnvil()
    return Interact:Object("Anvil", "Smith", 10)
end

local function isSmithing()
    return API.ReadPlayerAnim() == smithingAnim
end

local function readChat()
    local chats = API.GatherEvents_chat_check()

    for index, value in ipairs(chats) do
        if value.text then
            return value.text
        end
    end   
    return nil
end

local function lostHeatCheck()
    local check = readChat()
    if check  == "<col=FF0000>Your item has cooled down slightly. It will be slightly harder to work.</col>" then
        return true
    else
        return false
    end
end

API.SetMaxIdleTime(4)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.Write_LoopyLoop(true)

while API.Read_LoopyLoop()  do
    
    if isSmithing() then
        if lostHeatCheck() then
            API.logDebug("Smithing item cooled down. Reheating...")
            heatForge()
            API.RandomSleep2(2400,0,600)
        end
    end

    if not isSmithing() and hasUnfinished() then
        API.logDebug("Smithing unfinished items...")
        smithAnvil()
        API.RandomSleep2(2400,0,600)
    end

    if not isSmithing() and not hasUnfinished() then
        print("We're all out of unfinished smithing items!")
        API.Write_LoopyLoop(false)
        return
    end

    API.RandomSleep2(600,0,0)

end