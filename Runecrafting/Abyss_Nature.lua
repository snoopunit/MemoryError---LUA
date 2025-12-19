--MAKE SURE TO HAVE POUCH PROTECTOR/NEXUS MOD RELICS ACTIVE

local API = require("api")
local UTILS = require("UTILS")

local startTime = API.SystemTime()
local startXP = API.GetSkillXP("RUNECRAFTING")
local totalRunes = 0
local gainedXP = 0
local totalThreads = 0

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

local AREA           = {
    EDGEVILLE_LODESTONE     = { x = 3067, y = 3505,  z = 0 },
    EDGEVILLE_BANK          = { x = 3094, y = 3493,  z = 0 },
    EDGEVILLE               = { x = 3087, y = 3503,  z = 0 },
    WILDY                   = { x = 3099, y = 3523,  z = 0 },
    MAGE                    = { x = 3108, y = 3559,  z = 0 },
    ABBY                    = { x = 3040, y = 4843,  z = 0 },
    NATURE_ALTAR            = { x = 2400, y = 4843,  z = 0 },
    WARETREAT               = { x = 3294, y = 10127, z = 0 },
    SMALL_OBELISK           = { x = 3128, y = 3515,  z = 0 },
    DEATHS_OFFICE           = { x = 414,  y = 674,   z = 0 },
}

local function comma_value(n)
    local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

local function hasItem(item)
    return Inventory:Contains(item)    
end

local function canSeeMage()
    local Mage = API.ReadAllObjectsArray({1},{2257},"Mage of Zamorak")
    if #Mage > 0 then 
        return true
    else 
        return false
    end
end

local function loadLastPreset()

    local bankTimer = API.SystemTime()

    local function checkTimer()
        return (API.SystemTime() - bankTimer) < 10000
    end

    while not Inventory:IsFull() and checkTimer() and API.Read_LoopyLoop() do
    
        API.logDebug("Loading last preset.")

        if not Interact:Object("Counter", "Load Last Preset from", 30) then
            if not Interact:NPC("Banker", "Load Last Preset from", 30) then
                API.logWarn("Unable to bank!!")
                API.Write_LoopyLoop(false)
                return false
            end
        end

        API.RandomSleep2(1200,0,600)

        if Inventory:IsFull() then
            return true
        end

    end

    API.logWarn("Didn't get a full inventory after banking!")
    API.Write_LoopyLoop(false)
    return false

end

local function loadPresetNum(num)

    API.logDebug("Loading preset: ("..tostring(num)..").")

    if not Interact:Object("Counter", "Bank", 30) then
        if not Interact:NPC("Banker", "Bank", 30) then
            API.logWarn("Unable to bank!!")
            API.Write_LoopyLoop(false)
            return false
        end
    end

    API.RandomSleep2(1200,0,600)
    API.WaitUntilMovingEnds()

    if not API.BankOpen2() then
        API.logWarn("Bank not open!")
        return false
    end

    API.DoAction_Interface(0x24,0xffffffff,1,517,119,num,API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(1200,0,600)

    if API.BankOpen2() then
        API.logWarn("Bank still open after clicking preset!")
        return false
    end

end

local function isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

local function crossWildyWall()

    local crossAnim = 6703
  
    API.logDebug("Interacting: Wilderness wall.")

    Interact:Object("Wilderness wall", "Cross", 40) 
    

    while API.ReadPlayerAnim() ~= crossAnim and API.Read_LoopyLoop() do 
        API.RandomSleep2(50,0,50)
    end

end

local function clickTileNearMage()
    API.logDebug("Clicking tile near mage.")
    API.DoAction_Tile(WPOINT.new(3107 + math.random(-4, 4), 3559 + math.random(-4, 4), 0))
end

local function mageTeleport()
    Interact:NPC("Mage of Zamorak", "Teleport", 30)
end

local function wallToAbyss()

    local surgeAbility = API.GetABs_name("Surge")

    while not isAtLocation(AREA.MAGE, 20) and API.Read_LoopyLoop() do
        clickTileNearMage()
        API.RandomSleep2(500,0,500)
        if surgeAbility and surgeAbility.cooldown_timer == 0 then
            API.logDebug("Using surge ability.")
            API.DoAction_Ability_Direct(surgeAbility, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(250,0,250)
        end
    end

    while canSeeMage() and not isAtLocation(AREA.ABBY) and API.Read_LoopyLoop() do
        API.logDebug("Using mage teleport.")
        mageTeleport()
        API.RandomSleep2(600,0,600)
    end

end

local function natureRift()
    
    while not isAtLocation(AREA.NATURE_ALTAR) and API.Read_LoopyLoop() do
        Interact:Object("Nature rift", "Exit-through", 20)
        API.logDebug("Exiting nature rift.")
        API.RandomSleep2(250,0,250)
    end

end

local function natureAltar()
    local failTimer = API.SystemTime()
    while Inventory:IsFull() and API.Read_LoopyLoop() and (API.SystemTime() - failTimer < 10000) do
        if Interact:Object("Nature altar", "Use", 10) then
            API.logDebug("Using nature altar.")
            API.RandomSleep2(500,0,500)
        end
    end
    if Inventory:IsFull() and (API.SystemTime() - failTimer < 10000) then
        API.logWarn("Failed to craft at nature altar!")
        API.Write_LoopyLoop(false)
    end
    local runesMade = Inventory:GetItemAmount(561)
    if runesMade == 0 then
        API.logWarn("Failed to update rune count!")
    else
        totalRunes = totalRunes + runesMade
        totalThreads = totalThreads + Inventory:GetItemAmount(47661)
        gainedXP = API.GetSkillXP("RUNECRAFTING") - startXP
    end    
end

local function wildySwordTeleport()
    local ws = API.GetABs_name1("Wilderness sword")
    if ws.enabled and ws.action == "Edgeville" then
        API.logDebug("Use wilderness sword teleport.")
        API.DoAction_Ability_Direct(ws, 1, API.OFF_ACT_GeneralInterface_route)
    else
        API.logWarn("Wildy sword not found!")
        API.Write_LoopyLoop(false)
    end
    API.RandomSleep2(2400,0,600)
end

local function checkFamiliar()
    API.logDebug("Checking familiar.")

    local function usePouch()
        local pouch = API.GetABs_name1("Abyssal lurker pouch")
        if pouch.enabled and pouch.action == "Summon" then
            API.logDebug("Summoning Abyssal Lurker.")
            API.DoAction_Ability_Direct(pouch, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(2400,0,600)
            return true
        else
            API.logWarn("Abyssal lurker pouch not found on actionbar!")
            return false
        end
        
    end

    if Familiars:HasFamiliar() and (Familiars:GetTimeRemaining() >= 60) then 
        return true
    end

    if (not Familiars:HasFamiliar()) or (Familiars:GetTimeRemaining() < 60) then 
        local failTimer = API.SystemTime()

        while (API.GetSummoningPoints_() < 20) and (API.SystemTime() - failTimer < 10000) and API.Read_LoopyLoop() do
            if Interact:Object("Small obelisk", "Renew points", 60) then
                API.RandomSleep2(1000,0,1000)
                API.WaitUntilMovingEnds()
            else
                API.logDebug("Unable to renew summoning points!")
                API.Write_LoopyLoop(false)
                return false
            end    
        end

        if not isAtLocation(AREA.EDGEVILLE, 20) then 
            wildySwordTeleport() 
            while API.CheckAnim(50) and API.Read_LoopyLoop() do
                API.RandomSleep2(500,0,500)
            end
        end

        loadPresetNum(2)

        if usePouch() then
            if Familiars:HasFamiliar() and (Familiars:GetTimeRemaining() >= 60) then 
                API.logDebug("Familiar renewed!")
                return true
            end
        else
            API.logWarn("Unable to use abyssal lurker pouch!")
            API.Write_LoopyLoop(false)
            return false
        end
        
        loadPresetNum(1)

    end

end

local function runesPerHour()   
    return math.floor((totalRunes*60)/((API.SystemTime() - startTime)/60000))
end

local function xpPerHour()   
    return math.floor((gainedXP*60)/((API.SystemTime() - startTime)/60000))
end

local function profitPerHour()   
    local runeProfit = totalRunes * API.GetExchangePrice(561)
    local threadProfit = totalThreads * API.GetExchangePrice(47661)
    return math.floor(((runeProfit + threadProfit) * 60) / ((API.SystemTime() - startTime) / 60000))
end

local function threadsPerHour()   
    return math.floor((totalThreads*60)/((API.SystemTime() - startTime)/60000))
end

local function mainLoop()    

    API.logDebug("Starting main loop.")

    if isAtLocation(AREA.EDGEVILLE, 10) then
        if API.CheckAnim(50) then
            return
        end
        --checkFamiliar()
        if Inventory:IsFull() then
            crossWildyWall()
        else
            loadLastPreset()
            return
        end
    end

    if isAtLocation(AREA.EDGEVILLE_BANK, 10) then
        if Inventory:IsFull() then
            crossWildyWall()
        else
            --checkFamiliar()
        end
    end

    if isAtLocation(AREA.WILDY, 15) then
        wallToAbyss()
    end

    if isAtLocation(AREA.ABBY,10) then
        natureRift()
    end

    if isAtLocation(AREA.NATURE_ALTAR) and Inventory:IsFull() then
        natureAltar()
        wildySwordTeleport()
        ----METRICS----
        local metrics = {
            {"Script","Abyss: Nature Runes - by Klamor"},
            {"Runes:", comma_value(totalRunes)},
            {"Runes/H:", comma_value(runesPerHour())},
            {"Magical Threads:", totalThreads},
            {"Threads/H:", threadsPerHour()},
            {"Est. Profit: ", comma_value((totalRunes * API.GetExchangePrice(561))+(totalThreads * API.GetExchangePrice(47661))).."gp"},
            {"Profit/H: ", comma_value(profitPerHour()).."gp"},
            {"XP Gained:", comma_value(gainedXP)},
            {"XP/H:", comma_value(xpPerHour())},
        }
        API.DrawTable(metrics)
        ----METRICS----
        if API.SystemTime() - startTime > (45*60000) then
            startTime = API.SystemTime()
        end
    end

end

while API.Read_LoopyLoop() do

    mainLoop()
    --API.logInfo("Mage: " .. tostring(canSeeMage()))
    --API.RandomSleep2(500,0,500)

end