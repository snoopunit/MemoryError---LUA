print("Run Lua script Fighter.")

local API = require("api")
local UTILS = require("utils")

API.SetDrawTrackedSkills(true)
API.SetDrawLogs(true)

local menu = API.CreateIG_answer()

local Min_AFK = 30000
local Max_AFK = 180000
local Min_Eat_Percent = 50
local Min_HP_Percent = 20 --Min HP% to GTFO
local Eat_Food = false
local Loot_Drops = false
local Note_Items = false
local Weapon_Special_Attack = false
local Weapon_Special_Percent = 50 --Adrenaline% for Special Attack
local Grace_Of_The_Elves = false
local Powder_Of_Burials = false
local Elven_Ritual_Shard = false
local Super_Antifire = false
local Ring_of_Fortune = false

----Lootlist----
local blue_dhide = 1751
local black_dhide = 1747
local dbones = 536
local frost_dbones = 18832
local dragon_bolts = 9341
local royal_bolts = 24336
local baby_dbones
local bones
local big_bones
local blue_charm = 12163
local gold = 995
local gold_charm = 12158
local crimson_charm = 12160
local green_charm = 12159
local hard_clue_scroll = 42008
local fire_rune = 554
local law_rune = 563
local air_rune = 556
local death_rune = 560
local blood_rune = 565
local pure_ess = 7936
local dhelm = 1149
local dlongsword = 1305
local doffhandsword = 25740
local mithril_stone_Spirit = 44805
local adamant_stone_Spirit = 44807

----items to note----
local notelist = {}
table.insert(notelist, frost_dbones)
--table.insert(notelist, black_dhide)
--table.insert(notelist, dbones)
--table.insert()

----Lootlist table----
local lootlist = {}
--table.insert(lootlist, blue_dhide)
--table.insert(lootlist, black_dhide)
--table.insert(lootlist, dbones)
table.insert(lootlist, frost_dbones)
--table.insert(lootlist, dragon_bolts)
--table.insert(lootlist, royal_bolts)
table.insert(lootlist, gold)
table.insert(lootlist, blue_charm)
table.insert(lootlist, gold_charm)
table.insert(lootlist, crimson_charm)
table.insert(lootlist, green_charm)
--table.insert(lootlist, hard_clue_scroll)
--table.insert(lootlist, fire_rune)
table.insert(lootlist, pure_ess)
table.insert(lootlist, death_rune)
table.insert(lootlist, law_rune)
--table.insert(lootlist, air_rune)
table.insert(lootlist, blood_rune)
--table.insert(lootlist, dhelm)
--table.insert(lootlist, dlongsword)
--table.insert(lootlist, doffhandsword)
table.insert(lootlist, mithril_stone_Spirit)
table.insert(lootlist, adamant_stone_Spirit)

local lootsearch

--if Cselect == "Baby blue dragon" then
--    lootsearch = baby_dbones
--elseif Cselect == "Blue dragon" then
--    lootsearch = blue_dhide 
--elseif Cselect == "Black dragon" then
--    lootsearch = gold
--elseif Cselect == "Frost dragon" then
    lootsearch = frost_dbones
--elseif Cselect == "Cow" then
--    lootsearch = bones
--elseif Cselect == "Troll brute" then
--    lootsearch = bones
--elseif Cselect == "Ice warrior" then
--    lootsearch = bones
--elseif Cselect == "Hill Giant" then
--    lootsearch = big_bones
--elseif Cselect == "Fire giant" then
--    lootsearch = gold    
--end

----Enemy IDs----
local currentEnemy = {
    {
        name = nil,
        ids = { nil }
    }
}

local enemyOptions = {
    {
        name = "Blue Dragon",
        ids = { 55, 4682, 4683 }
    },
    {
        name = "Black Dragon",
        ids = { 54, 4673 }
    },
    {
        name = "Frost Dragon",
        ids = { 14405 }
    },
    {
        name = "Fire Giant",
        ids = { 110, 1585, 1586 }
    },
    {
        name = "Abyssal Creature",
        ids = { 2263, 2264, 2265 }
    },
    {
        name = "Cow",
        ids = { 12362, 12363, 12364, 12365}
    },
    {
        name = "Troll Chucker",
        ids = {14981}
    },
    {
        name = "Flesh Crawler",
        ids = { 4391 }
    },
    {
        name = "Hill Giant",
        ids = { 4690, 4691, 4692 }
    },
    {
        name = "Moss Giant",
        ids = { 112, 1588, 4688 }
    },
    {
        name = "Cockroach Soldier",
        ids = { 7160 }
    }
}

----Buff IDs----
local Powder_Of_Burials_Buff = 52805
local Grace_Of_The_Elves_Buff = 51490
local Super_Antifire_Buff = 30093

----DEbuff IDs----
local Poison = 14691
local Elven_Ritual_Shard_Debuff

----Script Timers----
local Script_Timer = API.SystemTime()
local AFK_Timer = API.SystemTime()
local Attack_Timer = API.SystemTime()
local Combat_Timer
local Loot_Timer = API.SystemTime()

----Script Stats----
local antibans = 0
local kills = 0

function  setupMenu()
    menu.box_name = " "
    menu.box_start = FFPOINT.new(1, 580, 0)
    menu.box_size = FFPOINT.new(440, 0, 0)
    menu.stringsArr = {}

    table.insert(menu.stringsArr, "Enemy List")
    for _, v in ipairs(enemyOptions) do
        table.insert(menu.stringsArr, v.name)
    end
    
    --API.DrawCheckbox(boolMenu)
    API.DrawComboBox(menu, false)
end
setupMenu()

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

function Check_Timer(int)
    return (API.SystemTime() - int)
end

---MUST BE ON ACTIONBARS
function activate(name)
    API.DoAction_Ability(name, 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 50, 300)
end

function emergencyTele()
    if Ring_of_Fortune then
        API.DoAction_Interface(0xffffffff,0x9b80,2,1670,84,-1,API.OFF_ACT_GeneralInterface_route)
    end    
end

function healthcheck()
    if API.GetHPrecent() < Min_Eat_Percent then
        print("Low HP! Eating Food!")
        activate("Eat Food")
        API.RandomSleep2(600, 50, 300)
        if API.GetHPrecent() > Min_Eat_Percent then
            return true
        end
    end
    if API.GetHPrecent() < Min_HP_Percent then
        print("HP Critical! Teleporting out!")
        
            API.Write_LoopyLoop(false)
    end
end

function buffCheck()
    if Powder_Of_Burials then
        if not hasBuff(Powder_Of_Burials_Buff) then
            activate("Powder of burials")
            API.RandomSleep2(1200, 50, 300)
            if not hasBuff(Powder_Of_Burials_Buff) then
                print("We're out of Powder of burials!")
            end
        end
    end
    if Elven_Ritual_Shard then
        if API.GetPrayPrecent() < 65 then
            activate("Ancient elven ritual shard")
            API.RandomSleep2(1200, 50, 300)
            --if not hasDeBuff(Elven_Ritual_Shard_Debuff) then
                --print("Something went wrong!")
            --end
        end
    end
    if Super_Antifire then
        if not hasBuff(Super_Antifire_Buff) then
            activate("Super antifire potion")
            API.RandomSleep2(1200, 50, 300)
            if not hasBuff(Super_Antifire_Buff) then
                print("We're out of Super Antifires!")
                emergencyTele()
                API.Write_LoopyLoop(false)
            end
        end
    end
end

local function getTotalRuntime(timer)
    local currentTime = API.SystemTime()
    local elapsed = currentTime - timer
    local hours = math.floor(elapsed / 3600000)
    local minutes = math.floor((elapsed % 3600000) / 60000)
    local seconds = math.floor((elapsed % 60000) / 1000)
    return string.format("%dh,%dm,%ds", hours, minutes, seconds)
end

function antiban()
        
    -- Calculate the time since the last afkTimer reset
    local elapsedTime = Check_Timer(AFK_Timer)
    
    -- Generate a random threshold between minAFK and maxAFK
    local afkThreshold = math.random(Min_AFK, Max_AFK)
    
    -- Check if the elapsed time exceeds the threshold
    if elapsedTime > afkThreshold then
        -- Print the scriptTimer, current elapsedTime, and separators
        antibans = antibans + 1

        local eTime = tostring(math.floor(Check_Timer(AFK_Timer)/1000).."s")

        print("============")        
        print("AFK Timer:", eTime)
        print("Antibans:", antibans)
        print("============")           

        -- Perform a random antiban action
        local action = math.random(1, 7)
        if action == 1 then API.PIdle1()
        elseif action == 2 then API.PIdle2()
        elseif action == 3 then API.PIdle22()
        elseif action == 4 then API.KeyboardPress('w', 50, 250)
        elseif action == 5 then API.KeyboardPress('a', 50, 250)
        elseif action == 6 then API.KeyboardPress('s', 50, 250)
        elseif action == 7 then API.KeyboardPress('d', 50, 250)
        end
    
        -- Reset the afkTimer
        AFK_Timer = API.SystemTime()
    end
end

function FindEnemyInRangeOfPlayer(enemy, distance, Username)
    local allPlayers = API.ReadAllObjectsArray(true, 2)
    local player
    for i = 1, #allPlayers do
        if (allPlayers[i].Name == Username) then
            player = allPlayers[i]
        end    
    end
    if not (player == nil) then
        local NPCs = API.ReadAllObjectsArray(true, 1)
        local enemylist = {}
        for i = 1, #NPCs do
            local dist = math.sqrt(((NPCs[i].TileX / 512) - (player.TileX / 512))^2 + ((NPCs[i].TileY / 512) - (player.TileY / 512))^2)
            if math.floor(dist) <= distance then
                if NPCs[i].Id == enemy then
                    table.insert(enemylist, NPCs[i])
                end
            end     
        end
        if #enemylist == nil then
            return 0
        else
            return #enemylist
        end
    end  
end

--loot while window is open
function openLoot(quick)
    local dist = 5
    local radius = 5

    if kills == 0 then
        return
    end

    if not API.LootWindowOpen_2() then
        print("Opening Loot Window")
        API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1678, 8, -1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 0, 200)
    end    
    
    if currentEnemy.name == "Frost Dragon" then
        API.DoAction_Interface(0x24,0xffffffff,1,1622,30,-1,API.OFF_ACT_GeneralInterface_route)
    else
        API.DoAction_Loot_w(lootlist, dist, API.PlayerCoordfloat(), radius)
        print("Looting lootlist")
    end    

end

function attack()

    if API.IsTargeting() then
        return true
    end
    
    Attack_Timer = API.SystemTime()

    while (Check_Timer(Attack_Timer) < 45000) do

        --add function to find second closest enemy to avoid trying to fight dead ones

        API.DoAction_NPC(0x2a,API.OFF_ACT_AttackNPC_route,currentEnemy.ids,50)
        API.RandomSleep2(1800, 50, 600)

        if API.IsTargeting() or API.LocalPlayer_IsInCombat_() then
            Combat_Timer = API.SystemTime()
            API.WaitUntilMovingEnds()       
            return true
        end

    end 

    print("Unable to locate monster:", tostring(currentEnemy.name))
    return false
end

function KillsPerHour()   
    return ((kills*60)/((API.SystemTime() - Script_Timer)/60000))
end

function noteStuff()
    for i = 0, #notelist do
    UTILS.NoteItem(notelist[i])
    end
end

function progress()
    local kph = math.floor(KillsPerHour())
    print("============")
    print("Kills:", kills)
    print("Kills/H:", kph)
    print("============")
end

--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    if (menu.return_click) then
        menu.return_click = false
        for _, v in ipairs(enemyOptions) do
            if (menu.string_value == v.name) then
                currentEnemy = v
                print("Enemy Selected:", currentEnemy.name)
            end
        end
    end
    
    if currentEnemy.name then
        if attack() then
            
            buffCheck()
            
            if Loot_Drops then
                if API.LootWindowOpen_2() then
                    openLoot()
                end
            end

            if API.Invfreecount_() < math.random(1,4) then
                if Note_Items then
                    noteStuff()
                end
            end    
            while API.IsTargeting() or API.LocalPlayer_IsInCombat_() do  
                if API.GetTargetHealth() == 0 then
                    kills = kills + 1
                    progress()
                    if Loot_Drops then
                        API.RandomSleep2(3000, 0, 600)
                        openLoot()
                    end
                    break
                end   
                if Weapon_Special_Attack then
                    if API.GetAddreline_() >= Weapon_Special_Percent then
                        activate("Weapon Special Attack")
                        API.RandomSleep2(600, 0, 600)    
                    end            
                end   
                healthcheck()    
                antiban()
                API.RandomSleep2(600, 0, 600)   
            end     
        else  
            API.Write_LoopyLoop(false)
            print("Shutting down.")
            break   
        end        
    else
        print("Please select an enemy from the Enemy List")
        API.RandomSleep2(2400, 0, 600)
    end
    antiban()
    API.RandomSleep2(600, 0, 600)
end-----------------------------------------------------------------------
