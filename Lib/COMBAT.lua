--[[

    All-In-One Combat Module
    by Klamor

    COMBAT = require("lib/COMBAT")
    COMBAT.moduleStart()
    
]]

local API = require("api")
local UTILS = require("utils")

local Combat = {}

------------------------SCRIPT SETUP------------------------
local Min_Eat_Percent = 60                                  --min HP% to start eating food
local Min_HP_Percent = 20                                   --min HP% to teleport out
local Use_Prayers_Percent = 20                              --min Pray% needed to activate prayers
---------------------------END SETUP------------------------

GLOBALS = {

    --SCRIPT--
    guiToggle = false,
    enemyToFight = nil,
    currentTarget = nil,
    currentTargetInfo = nil,
    closestNPC = nil,
    hasMoved = false,
    runLoop = false,
    prayerToUse = nil,
    --SCRIPT--

    --STATS--
    kills = 0,
    --STATS--

    --CONFIG--
    lootDrops = false,
    noteItems = false,
    useSpecial = false,
    waitForDeathAnim = false,
    moveToTarget = false
    --CONFIG--

}

ITEMS = {
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

BUFFS = {
    Powder_Of_Burials = 52805,
    Grace_Of_The_Elves = 51490,
    Super_Antifire = 30093,
    Overload = 26093
}

DEBUFFS = {
    Poison = 14691,
    Elven_Shard = 43358,
    Enh_Excalibur = 14632
}

PRAYERS = {
    PROTECT_MAGIC = {
        names = {"Olivia the Chronicler", "Oyu the Quietest"},
        BUFF_ID = 25959,
        SPELL_NAME = "Protect from Magic"
    },
    PROTECT_MELEE = {
        names = {"Ahoeitu the Chef", "Xiang the Water-shaper", "Sarkhan the Serpentspeaker"},
        BUFF_ID = 25961,
        SPELL_NAME = "Protect from Melee"
    },
    PROTECT_RANGED = {
        names = {},
        BUFF_ID = 25960,
        SPELL_NAME = "Protect from Ranged"
    },
    PROTECT_NECRO = {
        names = {},
        BUFF_ID = nil, -- add this ID or it wont work
        SPELL_NAME = "Protect from Necromancy"
    },
    SOUL_SPLIT = {
        names = {},
        BUFF_ID = nil, -- add this ID or it wont work
        SPELL_NAME = "Soul split"
    }
}

----Note List----
notelist = {}

----Loot List----
lootlist = {}

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
        API.RandomSleep2(800, 0, 600)

    if API.IsTargeting() then
        return true
    else
        return false
    end
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
    if not moveToTarget then return end

    local player = API.PlayerCoord()
    local enemyX, enemyY, enemyZ = currentTarget.Tile_XYZ.x, currentTarget.Tile_XYZ.y, currentTarget.Tile_XYZ.z

    local direction = {
        x = player.x - enemyX,
        y = player.y - enemyY,
        z = player.z - enemyZ
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
    
    local target_tile = WPOINT:new(
        math.floor(enemyX + 3 * unit_vector.x),
        math.floor(enemyY + 3 * unit_vector.y),
        math.floor(enemyZ + 3 * unit_vector.z)
    )
    
    
    API.DoAction_WalkerW(target_tile)
    API.RandomSleep2(1600, 0, 250)

    if length > 14 then
        if UTILS.canUseSkill("Surge") then
            activateAbility("Surge")
            API.RandomSleep2(600, 0, 250)
        end
    elseif length >= 7 then
        if UTILS.canUseSkill("Barge") then
            activateAbility("Barge")
            API.RandomSleep2(600, 0, 250)
        end
    end
  
    while API.ReadPlayerMovin2() do
        API.RandomSleep2(600, 0, 250)
        attack()
    end

end

function findClosestEnemy()

    local coords = API.PlayerCoord()
    local playerX, playerY = coords.x, coords.y

    local NPCs = getEnemies({enemyToFight})

    if #NPCs == 0 then
        return false
    end

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
    imguiTarget.string_value = currentTarget.Name
    API.DrawTextAt(imguiTarget)
    return true
end

function KillsPerHour()   
    local elapsedTime = API.ScriptRuntime() / 3600
    return math.floor((GLOBALS.kills*60)/elapsedTime)
end

function activateAbility(name)

    ---MUST BE ON ACTIONBARS

    API.DoAction_Ability(name, 1, API.OFF_ACT_GeneralInterface_route)
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
    if not API.IsTargeting() and (API.GetAddreline_() > 55) and (API.GetHPrecent() < 80) then
        while API.GetAddreline_() > 0 do
            openLoot()
            antiban()
            API.RandomSleep2(600, 50, 300)
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

    if GLOBALS.currentTarget == nil then
        return false
    else
        if UTILS.canUseSkill(PRAYERS.PROTECT_MAGIC.SPELL_NAME) then
            for _, name in ipairs(PRAYERS.PROTECT_MAGIC.names) do
                if name == GLOBALS.currentTarget then
                    GLOBALS.prayerToUse = PRAYERS.PROTECT_MAGIC
                    return true
                end
            end
        else 
            --API.logDebug(PROTECT_MAGIC.SPELL_NAME.." unavailable!")
        end
        if UTILS.canUseSkill(PRAYERS.PROTECT_MELEE.SPELL_NAME) then
            for _, name in ipairs(PRAYERS.PROTECT_MELEE.names) do
                if name == GLOBALS.currentTarget then
                    GLOBALS.prayerToUse = PRAYERS.PROTECT_MELEE
                    return true
                end
            end
        else
            --API.logDebug(PROTECT_MELEE.SPELL_NAME.." unavailable!")    
        end
        if UTILS.canUseSkill(PRAYERS.PROTECT_RANGED.SPELL_NAME) then
            for _, name in ipairs(PRAYERS.PROTECT_RANGED.names) do
                if name == GLOBALS.currentTarget then
                    GLOBALS.prayerToUse = PRAYERS.PROTECT_RANGED
                    return true
                end
            end
        else
            --API.logDebug(PROTECT_RANGED.SPELL_NAME.." unavailable!")
        end
        if UTILS.canUseSkill(PRAYERS.PROTECT_NECRO.SPELL_NAME) then
            for _, name in ipairs(PRAYERS.PROTECT_NECRO.names) do
                if name == GLOBALS.currentTarget then
                    GLOBALS.prayerToUse = PRAYERS.PROTECT_NECRO
                    return true
                end
            end
        else
            --API.logDebug(PROTECT_NECRO.SPELL_NAME.." unavailable!")    
        end
        if UTILS.canUseSkill(PRAYERS.SOUL_SPLIT.SPELL_NAME) then
            GLOBALS.prayerToUse = PRAYERS.SOUL_SPLIT
            return true
        else
            --API.logDebug(SOUL_SPLIT.SPELL_NAME.." unavailable!")
        end
    end
    return false
end

function prayerCheck()

    if GLOBALS.prayerToUse == nil then
        return
    end

    if API.IsTargeting() and not hasBuff(GLOBALS.prayerToUse.BUFF_ID) and (API.GetPrayPrecent() > Use_Prayers_Percent) then
        API.logDebug("In combat! Enabling protection prayers")
        activateAbility(GLOBALS.prayerToUse.SPELL_NAME)
        API.RandomSleep2(800, 50, 300)
    elseif (API.LocalPlayer_IsInCombat_() and  not API.IsTargeting()) and hasBuff(GLOBALS.prayerToUse.BUFF_ID) then
        API.logDebug("In combat w/o target! Disabling protection prayers")
        activateAbility(GLOBALS.prayerToUse.SPELL_NAME)
        API.RandomSleep2(800, 50, 300)
    elseif not API.LocalPlayer_IsInCombat_() and hasBuff(GLOBALS.prayerToUse.BUFF_ID) then
        API.logDebug("Out of Combat! Disabling protection prayers")
        activateAbility(GLOBALS.prayerToUse.SPELL_NAME)
        API.RandomSleep2(800, 50, 300)    
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
            API.logDebug("Charge pack is empty!")
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

function rejuvenate()
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

function doCombat()

    hasMoved = false

    if runLoop and enemyToFight ~= nil and enemyToFight ~= "None" then

        setupPrayers()
        chargePackCheck()
        healthCheck()
   
        if not currentTarget then 
            local noTarget = API.SystemTime()
            if not findClosestEnemy() then
                while currentTarget == nil do
                    if API.IsTargeting() then
                        break
                    end
                    if Check_Timer(noTarget) > 60000 then
                        terminate()    
                        return
                    end
                    antiban()
                    API.RandomSleep2(600, 0, 250)
                end
            end
        end

        
        if not API.IsTargeting() then
            attack()
            API.RandomSleep2(600, 0, 600)
        end

        

        while API.IsTargeting() do

            currentTargetInfo = API.ReadTargetInfo(false)
            
            if not currentTargetInfo.Target_Name == enemyToFight then
                attack()
                API.RandomSleep2(600, 0, 600)
            end

            openLoot()
            foodDump()
            if not hasMoved then noteStuff() end
            buffCheck()
            prayerCheck()
            healthCheck()
            rejuvenate()
            specialAttack()  
            essenceOfFinality()
            if not hasMoved then moveToEnemy() end
            hasMoved = true
            antiban()
            API.RandomSleep2(600, 0, 600)  

        end     
  
        currentTarget = nil
        imguiTarget.string_value = ""
        API.DrawTextAt(imguiTarget)
        STATS.kills = STATS.kills + 1  
        if waitForDeath then 
            API.RandomSleep2(3600, 0, 1200)
            noteStuff()
            openLoot()
        end

    else

        if enemyToFight == nil or enemyToFight == "None" then 
            API.logDebug("Please select an enemy") 
        end
        API.RandomSleep2(2400, 0, 600)

    end
    
    API.RandomSleep2(600, 0, 250)

end

function Combat.drawGuiToggle()
    toggleButton = API.CreateIG_answer()
    toggleButton.box_name = ">>>"
    toggleButton.box_start = FFPOINT.new(0, 60, 0)
    toggleButton.box_size = FFPOINT.new(45, 30, 0)
    toggleButton.tooltip_text = "Click to toggle combat GUI"
    API.DrawBox(toggleButton)
end

function Combat.initGui()

    imguiBackground = API.CreateIG_answer()
    imguiBackground.box_name = "imguiBackground"
    imguiBackground.box_start = FFPOINT.new(40, 20, 0)  
    imguiBackground.box_size = FFPOINT.new(420, 145, 0)
    imguiBackground.colour = ImColor.new(71, 71, 71)  

    fightBtn = API.CreateIG_answer()
    fightBtn.box_name = "Fight"
    fightBtn.box_start = FFPOINT.new(50, 30, 0)  
    fightBtn.box_size = FFPOINT.new(100, 30, 0)
    fightBtn.tooltip_text = "Click to start/stop fighting."

    getBtn = API.CreateIG_answer()
    getBtn.box_name = "Get"
    getBtn.box_start = FFPOINT.new(50, 55, 0)  
    getBtn.box_size = FFPOINT.new(100, 30, 0)
    getBtn.tooltip_text = "Click to populate enemy list."

    imguicombo = API.CreateIG_answer()
    imguicombo.box_name = "Enemy List"
    imguicombo.box_start = FFPOINT.new(150, 30, 0)  
    imguicombo.stringsArr = { "Click 'Get' to update" }

    local checkbox_width = 100
    local checkbox_spacing = 20
    local total_width = 3 * checkbox_width + 2 * checkbox_spacing
    local start_x = ((imguiBackground.box_size.x - total_width) / 2) + 20  -- offset center X by 20

    imguibox1 = API.CreateIG_answer()
    imguibox1.box_name = "Loot Drops"
    imguibox1.box_start = FFPOINT.new(start_x, 85, 0)  
    imguibox1.box_size = FFPOINT.new(checkbox_width, 30, 0)
    imguibox1.tooltip_text = ""
    imguibox1.box_ticked = lootDrops

    imguibox2 = API.CreateIG_answer()
    imguibox2.box_name = "Note Items"
    imguibox2.box_start = FFPOINT.new(start_x + checkbox_width + checkbox_spacing, 85, 0)  
    imguibox2.box_size = FFPOINT.new(checkbox_width, 30, 0)
    imguibox2.tooltip_text = ""
    imguibox2.box_ticked = noteItems

    imguibox3 = API.CreateIG_answer()
    imguibox3.box_name = "SP Attack"
    imguibox3.box_start = FFPOINT.new(start_x + 2 * (checkbox_width + checkbox_spacing), 85, 0)  
    imguibox3.box_size = FFPOINT.new(checkbox_width, 30, 0)
    imguibox3.tooltip_text = ""
    imguibox3.box_ticked = useSpecial

    imguibox4 = API.CreateIG_answer()
    imguibox4.box_name = "Wait"
    imguibox4.box_start = FFPOINT.new(start_x + checkbox_width + checkbox_spacing, 105, 0)  
    imguibox4.box_size = FFPOINT.new(checkbox_width, 30, 0)
    imguibox4.tooltip_text = "Wait for enemies to die and drop loot"
    imguibox4.box_ticked = waitForDeath

    imguibox5 = API.CreateIG_answer()
    imguibox5.box_name = "Move"
    imguibox5.box_start = FFPOINT.new(start_x + 2 * (checkbox_width + checkbox_spacing), 105, 0)  
    imguibox5.box_size = FFPOINT.new(checkbox_width, 30, 0)
    imguibox5.tooltip_text = "Move closer to enemies for area loot"
    imguibox5.box_ticked = moveToTarget

    imguiTargetLabel = API.CreateIG_answer()
    imguiTargetLabel.box_name = "CurrentTarget"
    imguiTargetLabel.box_start = FFPOINT.new(160, 66, 0)  
    imguiTargetLabel.string_value = "Current Target:" 
    imguiTargetLabel.colour = ImColor.new(255, 255, 255)

    imguiTarget = API.CreateIG_answer()
    imguiTarget.box_name = "Target"
    imguiTarget.box_start = FFPOINT.new(270, 66, 0)  
    imguiTarget.string_value = "None" 
    imguiTarget.colour = ImColor.new(255, 255, 255)

    COLORS = {
        NO_TARGET = ImColor.new(78, 245, 66),
        HAS_TARGET = ImColor.new(13, 255, 0)
    }

end

function Combat.drawGUI()

    API.DrawSquareFilled(imguiBackground)
    API.DrawBox(fightBtn)
    API.DrawBox(getBtn)
    API.DrawComboBox(imguicombo, false)
    API.DrawCheckbox(imguibox1)
    API.DrawCheckbox(imguibox2)
    API.DrawCheckbox(imguibox3)
    API.DrawCheckbox(imguibox4)
    API.DrawCheckbox(imguibox5)
    API.DrawTextAt(imguiTargetLabel)
    API.DrawTextAt(imguiTarget)
end

function Combat.clearGui()
    imguiTarget.remove = true
    imguiTargetLabel.remove = true 
    imguicombo.remove = true
    imguibox1.remove = true 
    imguibox2.remove = true
    imguibox3.remove = true 
    imguibox4.remove = true
    imguibox5.remove = true
    imguiBackground.remove = true
    fightBtn.remove = true
    getBtn.remove = true
end

function Combat.moduleStart()

    Combat.initGui()
    Combat.drawGuiToggle()

    while not runLoop do

        if API.Read_LoopyLoop() == false then
            return
        end

        if toggleButton.return_click then
            GLOBALS.guiToggle = not GLOBALS.guiToggle
            if GLOBALS.guiToggle then
                Combat.drawGUI()
            else
                Combat.clearGui()
            end
        end

        if fightBtn.return_click then
        runLoop = not runLoop
        API.logDebug("Fighting: "..tostring(runLoop))
        fightBtn.return_click = false
        end

        if imguicombo.return_click then
            imguicombo.return_click = false
            enemyToFight = imguicombo.string_value
            API.logDebug("Selected Target: "..imguicombo.string_value)    
            API.RandomSleep2(250, 0, 50)
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

        if imguibox4.return_click then
            imguibox4.return_click = false
            waitForDeath = not waitForDeath
            API.logDebug("Wait for Death: "..tostring(waitForDeath))
        end

        if imguibox5.return_click then
            imguibox5.return_click = false
            moveToTarget = not moveToTarget
            API.logDebug("Move to target: "..tostring(moveToTarget))
        end
    end

end

function Combat.Metrics()

    return {
        {"Script","All-In-One Combat - by Klamor"},
        {"Fighting:", GLOBALS.currentTarget},
        {"Kills:", GLOBALS.kills},
        {"Kills/H:", tostring(KillsPerHour())},
    }

end

function Combat.updateMetrics()
    API.DrawTable(Combat.Metrics())
end

return Combat