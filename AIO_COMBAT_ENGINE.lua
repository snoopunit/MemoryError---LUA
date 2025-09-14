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
local CombatEngine = require("lib/COMBAT")
local engine = CombatEngine.new()

------------------------SCRIPT SETUP------------------------
local Min_Eat_Percent = 60                                  --min HP% to start eating food
local Min_HP_Percent = 20                                   --min HP% to teleport out
local Use_Prayers_Percent = 20                              --min Pray% to activate prayers
local Loot_Types = {CUSTOM = 0, LIST = 1, BOTH = 2} 
local Loot_Type = Loot_Types.CUSTOM                         --Loot_Types.TYPE OR 0,1,2
------------------------END    SETUP------------------------

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
    ARMOR = {
        subj_hood = 24992,
        subj_garb = 24995,
        subj_gown = 24998,
        subj_ward = 25001,
        subj_boot = 25004,
        subj_glov = 25007
    },
    MISC = {
        feather = 314,
        blue_dhide = 1751,
        black_dhide = 1747,
        gold = 995,
        gs_shard1 = 11710,
        gs_shard2 = 11712,
        gs_shard3 = 11714
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
    Enh_Excalibur = 14632
}
local PROTECT_MAGIC = {
    names = {"Olivia the Chronicler", "Oyu the Quietest", "Frost dragon", "K'ril Tsutsaroth", "Black dragon", "Blue dragon"},
    BUFF_ID = 25959,
    SPELL_NAME = "Protect from Magic"
}
local PROTECT_MELEE = {
    names = {"Ahoeitu the Chef", "Xiang the Water-shaper", "Sarkhan the Serpentspeaker", "Fire giant"},
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
--table.insert(notelist, ITEMS.BONES.frost_dbones)

----Loot List----
local lootlist = {}
table.insert(lootlist, ITEMS.MISC.gold)
table.insert(lootlist, ITEMS.MISC.black_dhide)
--table.insert(lootlist, ITEMS.BONES.frost_dbones)
--table.insert(lootlist, ITEMS.ARMOR.subj_boot)
--table.insert(lootlist, ITEMS.ARMOR.subj_garb)
--table.insert(lootlist, ITEMS.ARMOR.subj_glov)
--table.insert(lootlist, ITEMS.ARMOR.subj_gown)
--table.insert(lootlist, ITEMS.ARMOR.subj_hood)
--table.insert(lootlist, ITEMS.ARMOR.subj_ward)
--table.insert(lootlist, ITEMS.MISC.gs_shard1)
--table.insert(lootlist, ITEMS.MISC.gs_shard2)
--table.insert(lootlist, ITEMS.MISC.gs_shard3)

local enemyToFight = nil
local lootDrops = true
local noteItems = true
local useSpecial = true
local waitForDeath = false
local useAoE = false
local runLoop = false

----GUI----
local imguiBackground = API.CreateIG_answer()
imguiBackground.box_name = "imguiBackground"
imguiBackground.box_start = FFPOINT.new(10, 10, 0)  
imguiBackground.box_size = FFPOINT.new(400, 130, 0)
imguiBackground.colour = ImColor.new(71, 71, 71)  

local fightBtn = API.CreateIG_answer()
fightBtn.box_name = "Fight"
fightBtn.box_start = FFPOINT.new(30, 10, 0)  
fightBtn.box_size = FFPOINT.new(100, 30, 0)
fightBtn.tooltip_text = "Click to start/stop fighting."

local getBtn = API.CreateIG_answer()
getBtn.box_name = "Get"
getBtn.box_start = FFPOINT.new(30, 35, 0)  
getBtn.box_size = FFPOINT.new(100, 30, 0)
getBtn.tooltip_text = "Click to populate enemy list."

local imguicombo = API.CreateIG_answer()
imguicombo.box_name = "Enemy List"
imguicombo.box_start = FFPOINT.new(130, 10, 0)  
imguicombo.stringsArr = { "Click 'Get' to update" }

local checkbox_width = 100
local checkbox_spacing = 20
local total_width = 3 * checkbox_width + 2 * checkbox_spacing
local start_x = (imguiBackground.box_size.x - total_width) / 2

local imguibox1 = API.CreateIG_answer()
imguibox1.box_name = "Loot Drops"
imguibox1.box_start = FFPOINT.new(start_x, 65, 0)  
imguibox1.box_size = FFPOINT.new(checkbox_width, 30, 0)
imguibox1.tooltip_text = ""
imguibox1.box_ticked = lootDrops

local imguibox2 = API.CreateIG_answer()
imguibox2.box_name = "Note Items"
imguibox2.box_start = FFPOINT.new(start_x + checkbox_width + checkbox_spacing, 65, 0)  
imguibox2.box_size = FFPOINT.new(checkbox_width, 30, 0)
imguibox2.tooltip_text = ""
imguibox2.box_ticked = noteItems

local imguibox3 = API.CreateIG_answer()
imguibox3.box_name = "SP Attack"
imguibox3.box_start = FFPOINT.new(start_x + 2 * (checkbox_width + checkbox_spacing), 65, 0)  
imguibox3.box_size = FFPOINT.new(checkbox_width, 30, 0)
imguibox3.tooltip_text = ""
imguibox3.box_ticked = useSpecial

local imguibox4 = API.CreateIG_answer()
imguibox4.box_name = "Wait"
imguibox4.box_start = FFPOINT.new(start_x + checkbox_width + checkbox_spacing, 85, 0)  
imguibox4.box_size = FFPOINT.new(checkbox_width, 30, 0)
imguibox4.tooltip_text = "Wait for enemies to die and drop loot"
imguibox4.box_ticked = waitForDeath

local imguibox5 = API.CreateIG_answer()
imguibox5.box_name = "Use AoE"
imguibox5.box_start = FFPOINT.new(start_x + 2 * (checkbox_width + checkbox_spacing), 85, 0)  
imguibox5.box_size = FFPOINT.new(checkbox_width, 30, 0)
imguibox5.tooltip_text = "Toggle AoE abilities (Death Skulls, Bloat, Soul Strike, Scythe)"
imguibox5.box_ticked = useAoE

local imguiTargetLabel = API.CreateIG_answer()
imguiTargetLabel.box_name = "CurrentTarget"
imguiTargetLabel.box_start = FFPOINT.new(140, 46, 0)  
imguiTargetLabel.string_value = "Current Target:" 
imguiTargetLabel.colour = ImColor.new(255, 255, 255)

local imguiTarget = API.CreateIG_answer()
imguiTarget.box_name = "Target"
imguiTarget.box_start = FFPOINT.new(250, 46, 0)  
imguiTarget.string_value = "None" 
imguiTarget.colour = ImColor.new(255, 255, 255)

local COLORS = {
    NO_TARGET = ImColor.new(78, 245, 66),
    HAS_TARGET = ImColor.new(13, 255, 0)
}
----GUI----

local function invContainsString(string)
    local inv = API.ReadInvArrays33()
    for index, value in ipairs(inv) do
        if string.find(value.textitem, string) then
            return true
        end
    end
    return false
end

local function terminate()
    API.logDebug("Shutting down...")
    runLoop = false
    API.Write_LoopyLoop(false)
end

local function hasBuff(buff)
    return API.Buffbar_GetIDstatus(buff, false).found
end

local function hasDeBuff(debuff)
    return API.DeBuffbar_GetIDstatus(debuff, false).found
end

local function hasItem(item)
    local invitems = API.InvItemcount_String(item)
    if invitems > 0 then
        return true
    end
    return false    
end

local function getEnemies(names, size)
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

local function uniqueEnemies()
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

local function checkGroundItems()
    local items = API.ReadAllObjectsArray({3}, lootlist, {})

    return #items
end

local function openLoot()

    if not lootDrops or (STATS.kills == 0) or (checkGroundItems() < 1) then
        return
    end

    API.DoAction_Interface(0x24,0xffffffff,1,1622,30,-1,API.OFF_ACT_GeneralInterface_route)

    --[[local data = API.LootWindow_GetData()
    local hasWindowItems = false
    
    if #data then
        for i = 1, #data, 1 do
            for j = 1, #notelist, 1 do
                if data[i].itemid1 == notelist[j] then
                    hasWindowItems = true
                    break
                end
            end
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
    end]]

end

local function clearGUI()
    imguiBackground.remove = true
    fightBtn.remove = true
    getBtn.remove = true
    imguicombo.remove = true
    imguibox1.remove = true
    imguibox2.remove = true
    imguibox3.remove = true
    imguibox4.remove = true
    imguibox5.remove = true
    imguiTargetLabel.remove = true
    imguiTarget.remove = true
end

local function drawGUI()

    if fightBtn.return_click then
        fightBtn.return_click = false
        if not engine.running then
            if imguicombo.string_value and imguicombo.string_value ~= "None" then
                engine.priorityList = { [imguicombo.string_value] = 1 }
            end
            engine:start()
            runLoop = true
            clearGUI()
            API.logDebug("Combat Engine: STARTED")
        else
            engine:stop()
            API.logDebug("Combat Engine: STOPPED")
        end
    end

    if imguicombo.return_click then
        imguicombo.return_click = false
        local chosen = imguicombo.string_value
        if chosen and chosen ~= "Select an enemy" then
            enemyToFight = chosen
            engine.priorityList = { [chosen] = 1 }
            imguiTarget.string_value = chosen
            API.logDebug("Selected Target: " .. chosen)
        end
    end

    --API.logDebug("Enemy to fight: "..tostring(enemyToFight))

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

    if imguibox4.return_click then
        imguibox4.return_click = false
        waitForDeath = not waitForDeath
        API.logDebug("Wait for Death: "..tostring(waitForDeath))
    end

    if imguibox5.return_click then
        imguibox5.return_click = false
        useAoE = not useAoE
        engine.useAoE = useAoE 
        API.logDebug("Use AoE abilities: " .. tostring(useAoE))
    end

    API.DrawSquareFilled(imguiBackground)
    API.DrawBox(fightBtn)
    API.DrawBox(getBtn)
    API.DrawComboBox(imguicombo, false)
    API.DrawCheckbox(imguibox1)
    API.DrawCheckbox(imguibox2)
    API.DrawCheckbox(imguibox3)
    API.DrawCheckbox(imguibox4)
    API.DrawCheckbox(imguibox5)
end

local function activateAbility(name)

    ---MUST BE ON ACTIONBARS

    API.DoAction_Ability(name, 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 50, 300)
end

local function emergencyTele()
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

local function healthCheck()
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
    --[[if not API.IsTargeting() and (API.GetAddreline_() > 55) and (API.GetHPrecent() < 80) then
        while API.GetAddreline_() > 0 do
            openLoot()
            antiban()
            API.RandomSleep2(600, 50, 300)
        end

    end]]
    if API.GetHPrecent() < Min_HP_Percent then
        emergencyTele()
        terminate()
    end
end

local function buffCheck()
       
    if Inventory:GetItemAmount("Ancient elven ritual shard") > 0 then
        if not hasDeBuff(DEBUFFS.Elven_Shard) and (API.GetPrayPrecent() <= 63) then
            --API.DoAction_Interface(0x2e,0xa95e,1,1670,110,-1,API.OFF_ACT_GeneralInterface_route)
            activateAbility("Ancient elven ritual shard")
            API.RandomSleep2(600, 50, 300)
        end 
    end

    if Inventory:GetItemAmount("Enhanced Excalibur") > 0 then
        if not hasDeBuff(DEBUFFS.Enh_Excalibur) and (API.GetHPrecent() <= 80) then
            activateAbility("Enhanced Excalibur")
            API.RandomSleep2(600, 50, 300)
        end 
    end
    
    if Inventory:GetItemAmount("Super antifire") > 0 then
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

    if Inventory:GetItemAmount("Overload") > 0 then
        if not hasBuff(BUFFS.Overload) then
            API.logDebug("Using Overloads")
            activateAbility("Overload potion")
            API.RandomSleep2(600, 50, 300)
        end
    end
    
    --[[if (API.InvItemcount_String("Aggression flask") > 0) or (API.InvItemcount_String("Aggression potion") > 0) then
        API.logDebug("Using Aggression potion")
        activateAbility("Aggression potion")
        API.RandomSleep2(600, 50, 300)    
    end]]
    
end

local function porterCheck()
    local porterBuff = 51490

    local porterAB = API.GetABs_name("Sign of the porter", false)

    if not hasBuff(porterBuff) and porterAB.enabled then
        API.logDebug("Activating: "..tostring(porterAB.name))
        API.DoAction_Interface(0xffffffff,0x7261,2,1670,97,-1,API.OFF_ACT_GeneralInterface_route)
    end 
    
end

local function setupPrayers()

    if enemyToFight == nil then
        return false
    else
        if UTILS.canUseSkill(PROTECT_MAGIC.SPELL_NAME) then
            for _, name in ipairs(PROTECT_MAGIC.names) do
                if name == enemyToFight then
                    PRAYER_TO_USE = PROTECT_MAGIC
                    return true
                end
            end
        else 
            --API.logDebug(PROTECT_MAGIC.SPELL_NAME.." unavailable!")
        end
        if UTILS.canUseSkill(PROTECT_MELEE.SPELL_NAME) then
            for _, name in ipairs(PROTECT_MELEE.names) do
                if name == enemyToFight then
                    PRAYER_TO_USE = PROTECT_MELEE
                    return true
                end
            end
        else
            --API.logDebug(PROTECT_MELEE.SPELL_NAME.." unavailable!")    
        end
        if UTILS.canUseSkill(PROTECT_RANGED.SPELL_NAME) then
            for _, name in ipairs(PROTECT_RANGED.names) do
                if name == enemyToFight then
                    PRAYER_TO_USE = PROTECT_RANGED
                    return true
                end
            end
        else
            --API.logDebug(PROTECT_RANGED.SPELL_NAME.." unavailable!")
        end
        if UTILS.canUseSkill(PROTECT_NECRO.SPELL_NAME) then
            for _, name in ipairs(PROTECT_NECRO.names) do
                if name == enemyToFight then
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

local function prayerCheck()

    if PRAYER_TO_USE == nil then
        API.logDebug(" PRAYER_TO_USE == nil !")
        return
    end

    if API.IsTargeting() and not hasBuff(PRAYER_TO_USE.BUFF_ID) and (API.GetPrayPrecent() > Use_Prayers_Percent) then
        API.logDebug("In combat! Enabling protection prayers")
        activateAbility(PRAYER_TO_USE.SPELL_NAME)
        API.RandomSleep2(800, 50, 300)
        return
    elseif (API.LocalPlayer_IsInCombat_() and  not API.IsTargeting()) and hasBuff(PRAYER_TO_USE.BUFF_ID) then
        API.logDebug("In combat w/o target! Disabling protection prayers")
        activateAbility(PRAYER_TO_USE.SPELL_NAME)
        API.RandomSleep2(800, 50, 300)
        return
    elseif not API.LocalPlayer_IsInCombat_() and hasBuff(PRAYER_TO_USE.BUFF_ID) then
        API.logDebug("Out of Combat! Disabling protection prayers")
        activateAbility(PRAYER_TO_USE.SPELL_NAME)
        API.RandomSleep2(800, 50, 300)    
    end
end

local function noteStuff()
    if not noteItems then
        return
    end
    if API.Invfreecount_() < math.random(1,8) then
        if not Inventory:Contains(30372) and not Inventory:Contains(43045) then
            API.logWarn("[Note] No notepaper.")
            return false
        end

        if not Inventory:Contains(18832) then
            return false
        else
            API.DoAction_DontResetSelection()
            if Inventory:Contains(30372) then
                Inventory:UseItemOnItem(18832, 30372)
            elseif Inventory:Contains(43045) then
                Inventory:UseItemOnItem(18832, 43045)
            else
                API.logWarn("[Note] No notepaper.")
                return false
            end
        end
    end
end

local function specialAttack()
    if not useSpecial then
        return
    end

    if UTILS.canUseSkill("Weapon Special Attack") then
        activateAbility("Weapon Special Attack")
        API.RandomSleep2(600, 0, 600)    
    end
end

local function chargePackCheck()
    --[[local chatTexts = API.GatherEvents_chat_check()
    for _, v in ipairs(chatTexts) do
        if (string.find(v.text, "Your charge pack has run out of power")) then
            API.logDebug("Charge pack is empty!")
            emergencyTele()
            terminate()
            return false
        end
    end]]
    return true
end

local function aggressionCheck()
    local aggPotAB = API.GetABs_name("Aggression potion")

    if not hasBuff(37969) then
        if aggPotAB.action == "Drink" and aggPotAB.enabled then
            API.DoAction_Ability_Direct(aggPotAB, 1, API.OFF_ACT_GeneralInterface_route)
        end
    end
end

local function essenceOfFinality()
        if not useSpecial then
            return
        end
    
        if UTILS.canUseSkill("Essence of Finality") then
            activateAbility("Essence of Finality")
            API.RandomSleep2(600, 0, 600)    
        end
end

local function rejuvenate()
    if not hasItem("shield") then
        return
    end

    if  (API.GetAddreline_() < 94) or (API.GetHPrecent() > 80) or hasDeBuff(DEBUFFS.Enh_Excalibur) then
        return
    end

    local startHP = API.GetHPrecent()

    API.KeyboardPress('1', 50, 250)
    API.RandomSleep2(600, 0, 600)  

    if UTILS.canUseSkill("Rejuvenate") then
        activateAbility("Rejuvenate")
        API.RandomSleep2(600, 0, 600)
    end

    local skillTimer = API.SystemTime()

    while Check_Timer(skillTimer) < 10000 do
        API.RandomSleep2(600, 0, 600)
    end

    API.KeyboardPress('2', 50, 250)
    API.RandomSleep2(600, 0, 600)
    
end

local function fd_reflection_check()
    local function projectile()
        return #API.ReadAllObjectsArray({5},{2875},{})
    end
    local function cease()
        local ceaseAB = API.GetABs_name("Cease")
        if ceaseAB and ceaseAB.enabled then
            API.DoAction_Ability_Direct(ceaseAB, 1, API.OFF_ACT_GeneralInterface_route)
        end
    end
    if projectile() >= 1 then
        API.logWarn("Detected Frost Dragon reflection ability projectile!")
        cease()
        API.RandomSleep2(6000,0,600)
    end
end


--main loop
API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    ----METRICS----
    local metrics = {
        {"Script","All-In-One Combat - by Klamor"},
        {"Kills:", engine.kills},
        {"Kills/H:", tostring(engine:KillsPerHour())},
    }
    API.DrawTable(metrics)
    ----METRICS----

    if runLoop then 

        if engine.running then

            if API.IsTargeting() then

                buffCheck()
                API.RandomSleep2(600, 0, 600)
                healthCheck()
                API.RandomSleep2(600, 0, 600)
                fd_reflection_check()
                API.RandomSleep2(600, 0, 600)
                noteStuff()
                API.RandomSleep2(600, 0, 600)

            end     

        end
    else
        drawGUI()
    end

    API.RandomSleep2(600, 0, 600)

end----------------------------------------------------------------------------------