--[[
    Author:      Klamor
    Version:     1.0
    Release      Date: 
    Script:      All-In-One Combat

    Release Notes:
    - Version 1.0   :   Initial Release

    SUPPORTED FEATURES:
    --HEALING--
        :   Food
        :   Enhanced Excalibur 
    --PRAYERS--
        :   Elven Ritual Shard
        :   Protection Prayers
        :   Soul Split
    --LOOTING--
        :   'Loot Custom'
        :   Lootlist -- add ITEM IDs to ITEMS and table.insert(lootlist, ITEMS.CATEGORY.ITEM)
                        Example: table.insert(lootlist, ITEMS.RARES.hard_clue_scroll) 
        :   Notelist -- add ITEM IDs to ITEMS and table.insert(notelist, ITEMS.NAME)
                        Example: table.insert(notelist, ITEMS.BONES.frost_dbones)
    --Teleports--
        :   Wilderness Sword
        :   Ring of Fortune
        :   War's Retreat

    UPCOMING FEATURES:
        :   Add support for familiars
        :   Add support for more potions
        :   Add support to check for Necro Ectoplasm

    REQUIREMENTS:
        :   UTILS.lua

    SCRIPT SETUP:
        :   Modify values in 'SCRIPT SETUP'
        :   Make sure all 'feature-supported' items/abilities are on your action bars

]]

local API = require("api")
local UTILS = require("utils")

------------------------SCRIPT SETUP------------------------
local Min_Eat_Percent = 60                                  --min HP% to start eating food
local Min_HP_Percent = 20                                   --min HP% to teleport out
local Use_Prayers_Percent = 20                              --min Pray% to activate prayers
local Loot_Types = {CUSTOM = 0, LIST = 1, BOTH = 2} 
local Loot_Type = Loot_Types.CUSTOM                         --Loot_Types.TYPE OR 0,1,2
local Min_AFK = 30000                                       --Minimum idle time in ms
local Max_AFK = 180000                                      --Maximum idle time in ms
------------------------END    SETUP------------------------

local TIMERS = {
    Script_Timer = API.SystemTime(),
    AFK_Timer = API.SystemTime()
}
local STATS = {
    antibans = 0,
    kills = 0
}
local ITEMS = {
    CHARMS = {
        blue_charm = 12163,
        gold_charm = 12158,
        crimson_charm = 12160,
        green_charm = 12159
    },
    BONES = {
        bones = 17670,
        big_bones = 17674,
        dbones = 17676,
        frost_dbones = 18832,
        hardened_dbones = 35008,
        reinforced_dbones = 35010,
    },
    RUNES = {
        fire_rune = 554,
        water_rune = 555,
        air_rune = 556,
        earth_rune = 557,
        mind_rune = 558,
        body_rune = 559,
        death_rune = 560,
        nature_rune = 561,
        chaos_rune = 562,
        law_rune = 563,
        cosmic_rune = 564,
        blood_rune = 565,
        soul_rune = 566,
        pure_ess = 7936
    },
    RARES = {
        hard_clue_scroll = 42008,
    },
    AMMUNITION = {
        dragon_bolts = 9341,
        royal_bolts = 24336
    },
    MISC = {
        feather = 314,
        blue_dhide = 1751,
        black_dhide = 1747,
        gold = 995
    }
}
local BUFFS = {
    Powder_Of_Burials = 52805,
    Grace_Of_The_Elves = 51490,
    Super_Antifire = 30093,
    Overload = 26093
}
local DEBUFFS = {
    Poison = 14691,
    Elven_Shard = 43358,
    Enh_Excalibur = nil -- add this ID or it wont work
}
local PROTECT_MAGIC = {
    names = {"Olivia the Chronicler", "Oyu the Quietest"},
    BUFF_ID = 25959,
    SPELL_NAME = "Protect from Magic"
}
local PROTECT_MELEE = {
    names = {"Ahoeitu the Chef", "Xiang the Water-shaper", "Sarkhan the Serpentspeaker"},
    BUFF_ID = 25961,
    SPELL_NAME = "Protect from Melee"
}
local PROTECT_RANGED = {
    names = {},
    BUFF_ID = 25960,
    SPELL_NAME = "Protect from Ranged"
}
local PROTECT_NECRO = {
    names = {},
    BUFF_ID = nil, -- add this ID or it wont work
    SPELL_NAME = "Protect from Necromancy"
}
local SOUL_SPLIT = {
    names = {},
    BUFF_ID = nil, -- add this ID or it wont work
    SPELL_NAME = "Soul split"
}   
local PRAYER_TO_USE = nil

----Note List----
local notelist = {}
table.insert(notelist, ITEMS.BONES.frost_dbones)

----Loot List----
local lootlist = {}
table.insert(lootlist, ITEMS.MISC.gold)

local enemyToFight = nil
local currentTarget = nil
local closestNPC = nil
local lootDrops = true
local noteItems = true
local useSpecial = true
local runLoop = false

----GUI----
local imguiBackground = API.CreateIG_answer()
imguiBackground.box_name = "imguiBackground"
imguiBackground.box_start = FFPOINT.new(16, 60, 0)  
imguiBackground.box_size = FFPOINT.new(400, 150, 0)
imguiBackground.colour = ImColor.new(71, 71, 71)  

local fightBtn = API.CreateIG_answer()
fightBtn.box_name = "Fight"
fightBtn.box_start = FFPOINT.new(30, 60, 0)  
fightBtn.box_size = FFPOINT.new(100, 30, 0)
fightBtn.tooltip_text = "Click to start/stop fighting."

local getBtn = API.CreateIG_answer()
getBtn.box_name = "Get"
getBtn.box_start = FFPOINT.new(30, 85, 0)  
getBtn.box_size = FFPOINT.new(100, 30, 0)
getBtn.tooltip_text = "Click to populate enemy list."

local imguicombo = API.CreateIG_answer()
imguicombo.box_name = "Enemy List"
imguicombo.box_start = FFPOINT.new(130, 60, 0)  
imguicombo.stringsArr = { "Click 'Get' to update" }

local checkbox_width = 100
local checkbox_spacing = 20
local total_width = 3 * checkbox_width + 2 * checkbox_spacing
local start_x = (imguiBackground.box_size.x - total_width) / 2

local imguibox1 = API.CreateIG_answer()
imguibox1.box_name = "Loot Drops"
imguibox1.box_start = FFPOINT.new(start_x, 115, 0)  
imguibox1.box_size = FFPOINT.new(checkbox_width, 30, 0)
imguibox1.tooltip_text = ""

local imguibox2 = API.CreateIG_answer()
imguibox2.box_name = "Note Items"
imguibox2.box_start = FFPOINT.new(start_x + checkbox_width + checkbox_spacing, 115, 0)  
imguibox2.box_size = FFPOINT.new(checkbox_width, 30, 0)
imguibox2.tooltip_text = ""

local imguibox3 = API.CreateIG_answer()
imguibox3.box_name = "SP Attack"
imguibox3.box_start = FFPOINT.new(start_x + 2 * (checkbox_width + checkbox_spacing), 115, 0)  
imguibox3.box_size = FFPOINT.new(checkbox_width, 30, 0)
imguibox3.tooltip_text = ""

local imguiTargetLabel = API.CreateIG_answer()
imguiTargetLabel.box_name = "CurrentTarget"
imguiTargetLabel.box_start = FFPOINT.new(140, 96, 0)  
imguiTargetLabel.string_value = "Current Target:" 
imguiTargetLabel.colour = ImColor.new(255, 255, 255)

local imguiTarget = API.CreateIG_answer()
imguiTarget.box_name = "Target"
imguiTarget.box_start = FFPOINT.new(250, 96, 0)  
imguiTarget.string_value = "None" 
imguiTarget.colour = ImColor.new(255, 255, 255)

local COLORS = {
    NO_TARGET = ImColor.new(78, 245, 66),
    HAS_TARGET = ImColor.new(13, 255, 0)
}
----GUI----

function terminate()
    API.logDebug("Shutting down...")
    runLoop = false
    API.Write_LoopyLoop(false)
end

function hasBuff(buff)
    if API.Buffbar_GetIDstatus(buff, false).id == 0 then
        return false
    else
        return true
    end
end

function hasDeBuff(debuff)
    if API.DeBuffbar_GetIDstatus(debuff, false).id == 0 then
        return false
    else
        return true
    end
end

function hasItem(item, count)
    invitems = API.InvItemcount_String()
    if count then return invitems end
    if invitems > 0 then
        return true
    else
        return false
    end
end

function getEnemies(names, size)
    local NPCs = {}
    if names then
        NPCs = API.ReadAllObjectsArray({1}, {-1}, names)
    else
        NPCs = API.ReadAllObjectsArray({1}, {-1}, {})
    end
    if size then
        return #NPCs    
    else
        return NPCs
    end
end

function attack()
    API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, closestNPC)
end

function uniqueEnemies()
    local uniqueEnemies = {}  
    local seenIDs = {}   

    local enemies = getEnemies() 

    for _, enemy in ipairs(enemies) do
        local name = enemy.Name
        local action = enemy.Action
            if name and (action == "Attack") and not seenIDs[name] and not (name == "") then
            table.insert(uniqueEnemies, enemy) 
            seenIDs[name] = true
        end
    end
    
    return uniqueEnemies
end

function moveToEnemy()
    local player = API.PlayerCoord()
    local enemy = currentTarget

    local direction = {
        x = player.x - enemy.Tile_XYZ.x,
        y = player.y - enemy.Tile_XYZ.y,
        z = player.z - enemy.Tile_XYZ.z
    }

    local length = math.sqrt(direction.x^2 + direction.y^2 + direction.z^2)

    if length <= 4 then
        return 
    end
    
    local unit_vector = {
        x = direction.x / length,
        y = direction.y / length,
        z = direction.z / length
    }
    
    local target_tile = FFPOINT:new{
        enemy.Tile_XYZ.x + 3 * unit_vector.x,
        enemy.Tile_XYZ.y + 3 * unit_vector.y,
        enemy.Tile_XYZ.z + 3 * unit_vector.z
    }
    
    
    API.DoAction_WalkerF(target_tile)
    API.RandomSleep2(1600, 0, 250)

    if length > 14 then
        if UTILS.canUseSkill("Barge") then
            activateAbility("Barge")
            API.RandomSleep2(600, 0, 250)
        end
        if UTILS.canUseSkill("Surge") then
            activateAbility("Surge")
            API.RandomSleep2(600, 0, 250)
        end
    end
  
    while API.ReadPlayerMovin2() do
        API.RandomSleep2(600, 0, 250)
        attack()
    end

end

function openLoot()

    if not lootDrops or (STATS.kills == 0) then
        return
    end

    local data = API.LootWindow_GetData()
    local hasWindowItems = false
    
    if #data then
        for i = 0, #data do
            for j = 0, #notelist do
                if data[i].itemid1 == notelist[j] then
                    hasWindowItems = true
                    break
                end
            end
        end
    end

    for j = 1, #data, 1 do
        if data[j].itemid1 == gItems[i].Id then
            itemPresent = true
        end
    end

    local dist = 10
    local radius = 10

    if not API.LootWindowOpen_2() then
        API.logDebug("Opening Loot Window")
        API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1678, 8, -1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 0, 0)
    end
    
    
    
    if Loot_Type == (Loot_Types.CUSTOM or Loot_Types.BOTH) and hasWindowItems then
        API.logDebug("Loot custom button")
        API.DoAction_Interface(0x24,0xffffffff,1,1622,30,-1,API.OFF_ACT_GeneralInterface_route)
    elseif Loot_Type == (Loot_Types.LIST or Loot_Types.BOTH) then
        if not API.LootWindowOpen_2() then API.logDebug("Searching for loot...")
        else API.logDebug("Looting lootlist") end
        API.DoAction_Loot_w(lootlist, dist, API.PlayerCoordfloat(), radius)
    end

end

function drawGUI()

    if fightBtn.return_click then
        runLoop = not runLoop
        API.logDebug("Fighting: "..tostring(runLoop))
        fightBtn.return_click = false
    end

    if imguicombo.return_click then
        imguicombo.return_click = false
        while enemyToFight == nil do
            if not imguicombo.string_value == ("Select an enemy" or "") then
                enemyToFight = imguicombo.string_value
                API.logDebug("Selected Target: "..imguicombo.string_value)    
            else
                enemyToFight = "None"
            end
            API.RandomSleep2(250, 0, 50)
        end
    end

    if getBtn.return_click then
        local availableTargets = uniqueEnemies()
        API.logDebug("Populating enemy list...")
        imguicombo.stringsArr = {"Select an enemy"}
        for _, target in ipairs(availableTargets) do
            table.insert(imguicombo.stringsArr, target.Name)
        end
        getBtn.return_click = false
    end

    if imguibox1.return_click then
        imguibox1.return_click = false
        lootDrops = not lootDrops
        API.logDebug("Looting: "..tostring(lootDrops))
    end

    if imguibox2.return_click then
        imguibox2.return_click = false
        noteItems = not noteItems
        API.logDebug("Noting drops: "..tostring(noteItems))
    end

    if imguibox3.return_click then
        imguibox3.return_click = false
        useSpecial = not useSpecial
        API.logDebug("Weapon Special Attack: "..tostring(useSpecial))
    end

    API.DrawSquareFilled(imguiBackground)
    API.DrawBox(fightBtn)
    API.DrawBox(getBtn)
    API.DrawComboBox(imguicombo, false)
    API.DrawCheckbox(imguibox1)
    API.DrawCheckbox(imguibox2)
    API.DrawCheckbox(imguibox3)
    API.DrawTextAt(imguiTargetLabel)
    API.DrawTextAt(imguiTarget)
end

function findClosestEnemy()

    local coords = API.PlayerCoord()
    local playerX, playerY = coords.x, coords.y

    local NPCs = getEnemies({enemyToFight})

    local minDistanceSquared = math.huge

    for i = 1, #NPCs do
        local npc = NPCs[i]
        if npc.Life > 0 then
            local dx = playerX - npc.Tile_XYZ.x
            local dy = playerY - npc.Tile_XYZ.y
            local distanceSquared = dx * dx + dy * dy

            if distanceSquared < minDistanceSquared then
                minDistanceSquared = distanceSquared
                closestNPC = npc
            end
        end
    end
    currentTarget = closestNPC
end

function Check_Timer(int)
    return (API.SystemTime() - int)
end

function getTotalRuntime(timer)
    local currentTime = API.SystemTime()
    local elapsed = currentTime - timer
    local hours = math.floor(elapsed / 3600000)
    local minutes = math.floor((elapsed % 3600000) / 60000)
    local seconds = math.floor((elapsed % 60000) / 1000)
    return string.format("%dh,%dm,%ds", hours, minutes, seconds)
end

function antiban()
    local elapsedTime = Check_Timer(TIMERS.AFK_Timer)
    local afkThreshold = math.random(Min_AFK, Max_AFK)
    if elapsedTime > afkThreshold then
        STATS.antibans = STATS.antibans + 1
        local eTime = tostring(math.floor(Check_Timer(TIMERS.AFK_Timer)/1000).."s")       
        local action = math.random(1, 7)
        if action == 1 then API.PIdle1()
        elseif action == 2 then API.PIdle2()
        elseif action == 3 then API.PIdle22()
        elseif action == 4 then API.KeyboardPress('w', 50, 250)
        elseif action == 5 then API.KeyboardPress('a', 50, 250)
        elseif action == 6 then API.KeyboardPress('s', 50, 250)
        elseif action == 7 then API.KeyboardPress('d', 50, 250)
        end
        TIMERS.AFK_Timer = API.SystemTime()
    end
end

function KillsPerHour()   
    return math.floor((STATS.kills*60)/((API.SystemTime() - TIMERS.Script_Timer)/60000))
end

function activateAbility(name, m_action)

    ---MUST BE ON ACTIONBARS
    --m_action is selection menu #choice --- default to 1

    local action = 1
    if not m_action == 1 then
        action = m_action
    end
    API.DoAction_Ability(name, action, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 50, 300)
end

function emergencyTele()
    if UTILS.canUseSkill("War's Retreat Teleport") then
        API.logDebug("Teleport: War's Retreat")
        activateAbility("War's Retreat Teleport")  
    elseif UTILS.canUseSkill("Ring of Fortune") then
        API.logDebug("Teleport: Ring of Fortune")
        activateAbility("Ring of Fortune", 2)
    elseif UTILS.canUseSkill("Wilderness Sword") then
        API.logDebug("Teleport: Wilderness Sword")
        API.DoAction_Interface(0xffffffff,0x9410,2,1670,136,-1,API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600, 50, 300)
            API.KeyboardPress('1', 50, 250)
            API.RandomSleep2(600, 50, 300)
            API.KeyboardPress('1', 50, 250) 
    end  
    terminate()
end

function healthCheck()
    if API.GetHPrecent() < Min_Eat_Percent then
        if UTILS.canUseSkill("Eat Food") then
            API.logDebug("Low HP! Eating Food!")
            activateAbility("Eat Food")
            API.RandomSleep2(600, 50, 300)
            if API.GetHPrecent() > Min_Eat_Percent then
                return true
            end
        else
            API.logDebug("Can't use 'Eat Food'. It's either not on the action bar or no food in inventory.")
        end
    end
    if API.GetHPrecent() < Min_HP_Percent then
        emergencyTele()
        terminate()
    end
end

function buffCheck()
       
    if API.InvItemcount_String("Ancient elven ritual shard") > 0 then
        if not hasDeBuff(DEBUFFS.Elven_Shard) and (API.GetPrayPrecent() <= 63) then
            --API.DoAction_Interface(0x2e,0xa95e,1,1670,110,-1,API.OFF_ACT_GeneralInterface_route)
            activateAbility("Ancient elven ritual shard")
            API.RandomSleep2(600, 50, 300)
        end 
    end

    if API.InvItemcount_String("Enhanced Excalibur") > 0 then
        if not hasDeBuff(DEBUFFS.Enh_Excalibur) and (API.GetHPrecent() <= 80) then
            activateAbility("Enhanced Excalibur")
            API.RandomSleep2(600, 50, 300)
        end 
    end
    
    if API.InvItemcount_String("Super antifire") > 0 then
        if not hasBuff(BUFFS.Super_Antifire) then
            API.logDebug("Using super antifire")
            activateAbility("Super antifire potion")
            API.RandomSleep2(600, 50, 300)
        end
    else
        if currentTarget == "Frost dragon" then
            emergencyTele()
            terminate()
        end
    end

    if API.InvItemcount_String("Overload") > 0 then
        if not hasBuff(BUFFS.Overload) then
            API.logDebug("Using Overloads")
            activateAbility("Overload potion")
            API.RandomSleep2(600, 50, 300)
        end
    end
    
    if (API.InvItemcount_String("Aggression flask") > 0) or (API.InvItemcount_String("Aggression potion") > 0) then
        API.logDebug("Using Aggression potion")
        activateAbility("Aggression potion")
        API.RandomSleep2(600, 50, 300)    
    end
    
end

function setupPrayers()

    if currentTarget == nil then
        return false
    else
        if UTILS.canUseSkill(PROTECT_MAGIC.SPELL_NAME) then
            for _, name in ipairs(PROTECT_MAGIC.names) do
                if name == currentTarget then
                    PRAYER_TO_USE = PROTECT_MAGIC
                    return true
                end
            end
        else 
            --API.logDebug(PROTECT_MAGIC.SPELL_NAME.." unavailable!")
        end
        if UTILS.canUseSkill(PROTECT_MELEE.SPELL_NAME) then
            for _, name in ipairs(PROTECT_MELEE.names) do
                if name == currentTarget then
                    PRAYER_TO_USE = PROTECT_MELEE
                    return true
                end
            end
        else
            --API.logDebug(PROTECT_MELEE.SPELL_NAME.." unavailable!")    
        end
        if UTILS.canUseSkill(PROTECT_RANGED.SPELL_NAME) then
            for _, name in ipairs(PROTECT_RANGED.names) do
                if name == currentTarget then
                    PRAYER_TO_USE = PROTECT_RANGED
                    return true
                end
            end
        else
            --API.logDebug(PROTECT_RANGED.SPELL_NAME.." unavailable!")
        end
        if UTILS.canUseSkill(PROTECT_NECRO.SPELL_NAME) then
            for _, name in ipairs(PROTECT_NECRO.names) do
                if name == currentTarget then
                    PRAYER_TO_USE = PROTECT_NECRO
                    return true
                end
            end
        else
            --API.logDebug(PROTECT_NECRO.SPELL_NAME.." unavailable!")    
        end
        if UTILS.canUseSkill(SOUL_SPLIT.SPELL_NAME) then
            PRAYER_TO_USE = SOUL_SPLIT
            return true
        else
            --API.logDebug(SOUL_SPLIT.SPELL_NAME.." unavailable!")
        end
    end
    return false
end

function prayerCheck()

    if PRAYER_TO_USE == nil then
        return
    end

    if API.IsTargeting() and not hasBuff(PRAYER_TO_USE.BUFF_ID) and (API.GetPrayPrecent() > Use_Prayers_Percent) then
        API.logDebug("In combat! Enabling protection prayers")
        activateAbility(PRAYER_TO_USE.SPELL_NAME)
        API.RandomSleep2(800, 50, 300)
    elseif (API.LocalPlayer_IsInCombat_() and  not API.IsTargeting()) and hasBuff(PRAYER_TO_USE.BUFF_ID) then
        API.logDebug("In combat w/o target! Disabling protection prayers")
        activateAbility(PRAYER_TO_USE.SPELL_NAME)
        API.RandomSleep2(800, 50, 300)
    elseif not API.LocalPlayer_IsInCombat_() and hasBuff(PRAYER_TO_USE.BUFF_ID) then
        API.logDebug("Out of Combat! Disabling protection prayers")
        activateAbility(PRAYER_TO_USE.SPELL_NAME)
        API.RandomSleep2(800, 50, 300)    
    end
end

function noteStuff()
    if not noteItems then
        return
    end
    for i = 1, #notelist do
        if not hasItem(notelist[i]) then
            return
        end
    end
    if API.Invfreecount_() < math.random(1,4) then
        for i = 1, #notelist do
            UTILS.NoteItem(notelist[i])
        end
    end
end

function specialAttack()
    if not useSpecial then
        return
    end

    if UTILS.canUseSkill("Weapon Special Attack") then
        activateAbility("Weapon Special Attack")
        API.RandomSleep2(600, 0, 600)    
    end
end

function chargePackCheck()
    local chatTexts = API.GatherEvents_chat_check()
    for _, v in ipairs(chatTexts) do
        if (string.find(v.text, "Your charge pack has run out of power")) then
            API.logWarn("Charge pack is empty!")
            emergencyTele()
            terminate()
            return false
        end
    end
    return true
end

function essenceOfFinality()
        if not useSpecial then
            return
        end
    
        if UTILS.canUseSkill("Essence of Finality") then
            activateAbility("Essence of Finality")
            API.RandomSleep2(600, 0, 600)    
        end
end
--main loop
API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    drawGUI()
    ----METRICS----
    local metrics = {
        {"Script","All-In-One Combat - by Klamor"},
        {"Fighting:", currentTarget},
        {"Antibans:", STATS.antibans},
        {"Kills:", STATS.kills},
        {"Kills/H:", tostring(KillsPerHour())},
        }
        API.DrawTable(metrics)
    ----METRICS----
    if runLoop and enemyToFight ~= (nil or "None") then

        setupPrayers()
        chargePackCheck()
        healthCheck()
   
        if not currentTarget then findClosestEnemy() end

        if not API.isTargeting() then
            attack()
        end

        imguiTarget.string_value = currentTarget.Name
        API.DrawTextAt(imguiTarget)

        while API.IsTargeting() do 

            openLoot()
            noteStuff()
            buffCheck()
            prayerCheck()
            healthCheck()
            specialAttack()  
            essenceOfFinality()
            moveToEnemy()
            antiban()
            API.RandomSleep2(1200, 0, 600)  

        end     
  
        currentTarget = nil
        imguiTarget.string_value = ""
        API.DrawTextAt(imguiTarget)
        STATS.kills = STATS.kills + 1  
        API.RandomSleep2(2400, 0, 600)
        openLoot()

    else

        if currentTarget == nil then API.logWarn("Please select an enemy") end
        API.RandomSleep2(2400, 0, 600)

    end
    
    antiban()
    API.RandomSleep2(600, 0, 250)
end----------------------------------------------------------------------------------