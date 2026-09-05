--MAKE SURE TO HAVE POUCH PROTECTOR/NEXUS MOD RELICS ACTIVE

local API = require("api")
local UTILS = require("UTILS")

local startTime = API.SystemTime()
local startXP = API.GetSkillXP("RUNECRAFTING")
local totalRunes = 0
local gainedXP = 0
local totalThreads = 0

local AREA          = {
    EDGEVILLE_BANK          = { x = 3094, y = 3493,  z = 0 },
    EDGEVILLE               = { x = 3087, y = 3503,  z = 0 },
    WILDY                   = { x = 3099, y = 3527,  z = 0 },
    MAGE                    = { x = 3108, y = 3559,  z = 0 },
    ABBY                    = { x = 3040, y = 4843,  z = 0 },
    NATURE_ALTAR            = { x = 2400, y = 4843,  z = 0 },
    SMALL_OBELISK           = { x = 3128, y = 3515,  z = 0 },
    WATER_ALTAR             = { x = 3484, y = 4836,  z = 0 }, -- Placeholder for Water Altar coordinates  -- Replace with actual coordinates
    LAW_ALTAR               = { x = 3108, y = 3559,  z = 0 }, -- Placeholder for Law Altar coordinates
    COSMIC_ALTAR            = { x = 3108, y = 3559,  z = 0 }, -- Placeholder for Cosmic Altar coordinates
}

local  ALTAR     = {
    NATURE                  = "Nature",
    WATER                   = "Water",
    LAW                     = "Law",
    COSMIC                  = "Cosmic",
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
        return (API.SystemTime() - bankTimer) < 15000
    end

    while not Inventory:IsFull() and checkTimer() do
    
        API.logDebug("Loading last preset.")
        if not API.ReadPlayerMovin() then
            if not Interact:Object("Counter", "Load Last Preset from", 30) then
                if not Interact:NPC("Banker", "Load Last Preset from", 30) then
                    API.logWarn("Unable to bank!!")
                end
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

    while not API.BankOpen2() and API.Read_LoopyLoop() do

        if not Interact:Object("Counter", "Bank", 30) then
            if not Interact:NPC("Banker", "Bank", 30) then
                API.logWarn("Unable to bank!!")
                API.Write_LoopyLoop(false)
                return false
            end
        end

        API.RandomSleep2(1200,0,600)

    end

    API.DoAction_Interface(0x24,0xffffffff,1,517,119,num,API.OFF_ACT_GeneralInterface_route)
    
    local failTimer = API.SystemTime()

    while API.BankOpen2() and API.Read_LoopyLoop() do
        if API.SystemTime() - failTimer > 10000 then
            API.logWarn("Failed to close bank after 10s!")
            API.Write_LoopyLoop(false)
            return false
        end
        API.RandomSleep2(1200,0,600)
    end
    
    return true

end

local function isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

local function crossWildyWall()

    local crossAnim = 6703
  
    while not isAtLocation(AREA.WILDY, 10) and API.Read_LoopyLoop() do
        Interact:Object("Wilderness wall", "Cross", 40)
        API.RandomSleep2(500,0,500)
    end

    while API.ReadPlayerAnim() ~= crossAnim and API.Read_LoopyLoop() do 
        API.RandomSleep2(50,0,50)
    end

end

local function clickTileNearMage()
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
            API.DoAction_Ability_Direct(surgeAbility, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(250,0,250)
        end
    end

    while canSeeMage() and not isAtLocation(AREA.ABBY) and API.Read_LoopyLoop() do
        mageTeleport()
        API.RandomSleep2(600,0,600)
    end

end

local function useRift(area, type)
    
    while not isAtLocation(area) and API.Read_LoopyLoop() do
        Interact:Object(type, "Exit-through", 20)
        API.logDebug("Exiting "..tostring(type)..".")
        API.RandomSleep2(600,0,600)
        API.WaitUntilMovingEnds()
    end

end

local function useAltar(type)
    while Inventory:IsFull() and API.Read_LoopyLoop() do
        if Interact:Object(type, "Use", 10) then
            API.logDebug("Using "..tostring(type)..".")
            API.RandomSleep2(1800,0,600)
        end
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

local function natureRift()
    
    while not isAtLocation(AREA.WATER_ALTAR) and API.Read_LoopyLoop() do
        Interact:Object("Water rift", "Exit-through", 30)
        API.RandomSleep2(600,0,600)
        API.WaitUntilMovingEnds()
    end

end

local function natureAltar()
    while Inventory:IsFull() and API.Read_LoopyLoop() do
        if Interact:Object("Water altar", "Use", 10) then
            API.RandomSleep2(600,0,600)
        end
    end
    local runesMade = Inventory:GetItemAmount(555)
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
    API.RandomSleep2(1800,0,600)
end

local function usePouch()
        
    local pouch = API.GetABs_name1("Abyssal lurker pouch")
    if pouch.enabled and pouch.action == "Summon" then
        API.logDebug("Summoning Abyssal Lurker.")
        API.DoAction_Ability_Direct(pouch, 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(1800,0,600)
        return true
    else
        API.logWarn("Abyssal lurker pouch not found on actionbar!")
        return false
    end
        
end

local function checkFamiliar()
    API.logDebug("Checking familiar.")

    local hasFam = Familiars:HasFamiliar()
    local timeLeft = Familiars:GetTimeRemaining()
    local sumPoints = API.GetSummoningPoints_()

    if hasFam and (timeLeft > 1) then 
        API.logDebug("Familiar time: "..tostring(timeLeft))
        return true
    end

    if not hasFam or (timeLeft <= 1) then
        API.logDebug("hasFamiliar: "..tostring(hasFam))
        API.logDebug("timeLeft: "..tostring(timeLeft)) 

        if (sumPoints < 100) then
            while not isAtLocation(AREA.SMALL_OBELISK, 20) and API.Read_LoopyLoop() do
                API.logDebug("Clicking tile near obelisk.")
                API.DoAction_Tile(WPOINT.new(3128 + math.random(-4, 4), 3515 + math.random(-4, 4), 0))  
                API.RandomSleep2(1200,0,1200)
            end

            while (sumPoints < 100) and API.Read_LoopyLoop() do
                API.logDebug("Summoning points: "..tostring(sumPoints))

                if Interact:Object("Small obelisk", "Renew points", 30) then
                    API.RandomSleep2(1200,0,1200)
                    API.WaitUntilMovingandAnimEnds()
                    sumPoints = API.GetSummoningPoints_()
                else
                    API.logDebug("Unable to renew summoning points!")
                    return false
                end  

            end    
        end

        if not isAtLocation(AREA.EDGEVILLE, 20) then 
            
            while not isAtLocation(AREA.EDGEVILLE, 20) and API.Read_LoopyLoop() do
                if API.ReadPlayerAnim() ~= 0 then
                    API.RandomSleep2(600,0,600)
                else
                    wildySwordTeleport()
                    API.RandomSleep2(1800,0,600)
                end
            end

        end

        if not loadPresetNum(2) then return end

        if usePouch() then
            API.RandomSleep2(600,0,600)
            hasFam = Familiars:HasFamiliar()
            timeLeft = Familiars:GetTimeRemaining()
            if hasFam and (timeLeft >= 1) then 
                API.logDebug("Familiar renewed!")
            else
                API.logDebug("hasFamiliar: "..tostring(hasFam))
                API.logDebug("timeLeft: "..tostring(timeLeft))
                API.logWarn("Familiar not renewed! Shutting down!")
                return false
            end
        end
        
        if not loadPresetNum(1) then return end

        return true

    end

end

local function reUp()

    if not checkFamiliar() then
        API.logDebug("checkFamiliar: false")
        API.logWarn("Shutting Down!")
        API.Write_LoopyLoop(false)
        return
    end
    
    if Inventory:IsFull() then
        crossWildyWall()
    else
        loadLastPreset()
        return
    end
    
end

local function runesPerHour()   
    return math.floor((totalRunes*60)/((API.SystemTime() - startTime)/60000))
end

local function xpPerHour()   
    return math.floor((gainedXP*60)/((API.SystemTime() - startTime)/60000))
end

local function profitPerHour()   
    local runeProfit = totalRunes * API.GetExchangePrice(555)
    local threadProfit = totalThreads * API.GetExchangePrice(47661)
    return math.floor(((runeProfit + threadProfit) * 60) / ((API.SystemTime() - startTime) / 60000))
end

local function threadsPerHour()   
    return math.floor((totalThreads*60)/((API.SystemTime() - startTime)/60000))
end

local function finitto()
    --API.logDebug("Time left: "..tostring((60*60000) - (API.SystemTime() - startTime)))
    --return (API.SystemTime() - startTime) >= (60*60000) 
    
    local xp = API.GetSkillXP("RUNECRAFTING")
    if xp >= 5902831 then
        API.logInfo("Level 91 reached, stopping script.")
        API.Write_LoopyLoop(false)
        return
    end
end 

local function mainLoop(area, type)    

    if API.ReadPlayerAnim() ~= 0 then
        API.RandomSleep2(250,0,250)
        return
    end

    if isAtLocation(AREA.EDGEVILLE, 10) then
        API.RandomSleep2(250,0,250)
        reUp()
    end

    if isAtLocation(AREA.EDGEVILLE_BANK, 10) then
        reUp()
    end

    if isAtLocation(AREA.SMALL_OBELISK, 10) then
        checkFamiliar()
    end

    if isAtLocation(AREA.WILDY, 20) then
        wallToAbyss()
    end

    if isAtLocation(AREA.ABBY,10) then
        natureRift()
        --useRift(area, type)
    end

    if isAtLocation(area, 10) then
        
        if Inventory:IsFull() then
            natureAltar()
            --useAltar(type)
        else
            wildySwordTeleport()
            ----METRICS----
            local metrics = {
                {"Script","Abyss: Nature Runes - by Klamor"},
                {"Runes:", comma_value(totalRunes)},
                {"Runes/H:", comma_value(runesPerHour())},
                {"Magical Threads:", totalThreads},
                {"Threads/H:", threadsPerHour()},
                {"Est. Profit: ", comma_value((totalRunes * API.GetExchangePrice(555))+(totalThreads * API.GetExchangePrice(47661))).."gp"},
                {"Profit/H: ", comma_value(profitPerHour()).."gp"},
                {"XP Gained:", comma_value(gainedXP)},
                {"XP/H:", comma_value(xpPerHour())},
            }
            API.DrawTable(metrics)
            ----METRICS----
            if finitto() then
                API.Write_LoopyLoop(false)
            end
        end
        
    end
    
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while API.Read_LoopyLoop() do

    
    
    mainLoop(AREA.WATER_ALTAR, ALTAR.WATER)
    API.RandomSleep2(600,0,250)

end
