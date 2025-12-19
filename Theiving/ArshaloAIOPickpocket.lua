--[[

@Title: AIO Thieving
@Description: Pick Pocketing for Money
@Author Arshalo
@Date  27/11/25
@Version 1.1



Details

--]]

local API = require("api")
local UTILS = require("utils")
local LODE = require("lodestones")
local Bank = require("bank")


local DEBUG = true   -- set to false to silence all debug logs
local firstRun = true


local startTime, afk = os.time(), os.time()
local MAX_IDLE_TIME_MINUTES = 15
local scriptPaused = true
local selectedLabel, selectedOne, selectedTarget, selectedLevel, selectedPathing

API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)


local potionCD = os.clock()
local debugCD = os.clock()
local restores = {3030, 3028, 3026, 3024}  
local prayerRenewal = {33176, 33178, 33180, 33182, 33184, 33186 --PrayerRenewals
}

local ID = {
    EXCALIBUR = 14632,
    EXCALIBUR_AUGMENTED = 36619,
    ELVEN_SHARD = 43358,    
    SAND_SEED = 54004,
    WICKED_HOOD = 22332,
}

local BANKING = 2


--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ END OF INTRO @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

local function dbg(...)
    if DEBUG then
        local msg = table.concat({...}, " ")
        print("[DEBUG] " .. msg)
    end
end

--[[ EXAMPLE
local hotspot = findObjTile()
dbg("Hotspot found:", hotspot and hotspot.CalcX, hotspot and hotspot.CalcY)

if not aminexttoahotspot() then
    dbg("Hotspot moved — clicking new location")
    clickHotspot()
end]]

local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end


local function activate_dive(x, y, z)
    local tile = WPOINT.new(x, y, z)
    API.DoAction_Dive_Tile(tile)
    API.RandomSleep2(45, 60, 60)
end

----------------------------------------------------------------------
--                              GUI
----------------------------------------------------------------------

local aioSelectC = API.CreateIG_answer()

local mainVariable = {{
    label = "Crux Eqal Knight (83)",
    printVariable = "Target = Crux Eqal Knight",
    targetsLevel = 83,
    pickPocketTarget = {29639, 29640},
    walkBack = function ()
        if API.PInArea(3294, 10, 10127, 10, 0) then
            API.DoAction_Inventory1(54004,0,1,API.OFF_ACT_GeneralInterface_route)
            UTILS.SleepUntil(function() return API.PInArea(3320, 2, 3307, 2, 0) end, 10, "Arrived at Magical Garden")
            UTILS.countTicks(1)
        elseif API.PInArea(3320, 1, 3307, 1, 0) then
            activate_dive(3320,3297,0)
            UTILS.surge()
            BANKING = 0
        end
    end
}, {
    label = "Goebie Scavenger (102)",
    printVariable = "Target = Goebie Scavenger",
    targetsLevel = 102,
    pickPocketTarget = {17501},
    walkBack = function () --To do : Add pathing to return to goebie
    end
}, {
    label = "Wizards' Tower master mage (106)",
    printVariable = "Target = Wizards' Tower master mage",
    targetsLevel = 106,
    pickPocketTarget = {17504},
    walkBack = function ()
        if API.PInArea(3294, 10, 10127, 10, 0) then
            API.DoAction_Inventory1(22332,0,3,API.OFF_ACT_GeneralInterface_route)
            UTILS.SleepUntil(function() return API.PInArea(3109, 2, 3156, 2, 3) end, 10, "Arrived at Wizards Tower")
            UTILS.countTicks(1)
        elseif API.PInArea(3109, 2, 3156, 2, 3) then
            UTILS.countTicks(1)
            API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,{ 79776 },50) --decend
            UTILS.SleepUntil(function() return API.PInArea(3103, 5, 3156, 5, 2) end, 10, "Arrived on second floor")
            UTILS.countTicks(1)
        elseif API.PInArea(3103, 5, 3156, 5, 2) and API.GetFloorLv_2() == 2 then
            BANKING = 0
        end
    end
}, {
    label = "Archaeology Professor (108)",
    printVariable = "Target = Archaeology Professor",
    targetsLevel = 108,
    pickPocketTarget = {17505},
    walkBack = function ()
        if API.PInArea(3294, 10, 10127, 10, 0) then
            API.DoAction_Inventory1(49429,0,7,API.OFF_ACT_GeneralInterface_route2)
            UTILS.SleepUntil(function() return API.PInArea(3336, 1, 3378, 1, 0) end, 10, "Arrived at Archaeology Campus")
            UTILS.countTicks(1)
        elseif API.PInArea(3336, 1, 3378, 1, 0) then
            API.DoAction_Tile(WPOINT.new(3337,3377,0))
            UTILS.countTicks(1)
            UTILS.surge()
            activate_dive(3348,3361,0)
            API.DoAction_Tile(WPOINT.new(3350,3360,0))
            UTILS.countTicks(1)
            UTILS.surge()
            API.DoAction_Tile(WPOINT.new(3363,3351,0))
        elseif API.PInArea(3363, 10, 3351, 10, 0) then
            BANKING = 0
        end
    end
},
}

btnStart = API.CreateIG_answer()
btnStart.box_start = FFPOINT.new(20, 149, 0)
btnStart.box_name = " START "
btnStart.box_size = FFPOINT.new(90, 50, 0)
btnStart.colour = ImColor.new(0, 255, 0)
btnStart.string_value = "START"

IG_Text = API.CreateIG_answer()
IG_Text.box_name = "TEXT"
IG_Text.box_start = FFPOINT.new(16, 79, 0)
IG_Text.colour = ImColor.new(196, 141, 59);
IG_Text.string_value = "Thieving - Pickpocket AIO" --What is it example - Primal Ore AIO

IG_Back = API.CreateIG_answer()
IG_Back.box_name = "back"
IG_Back.box_start = FFPOINT.new(5, 64, 0)
IG_Back.box_size = FFPOINT.new(226, 200, 0)
IG_Back.colour = ImColor.new(15, 13, 18, 255)
IG_Back.string_value = ""

aioSelectC.box_name = "###Thieving"                 --3x #Blanks out the text for the Gui. The box needs to be labelled
aioSelectC.box_start = FFPOINT.new(32, 94, 0)
aioSelectC.box_size = FFPOINT.new(240, 0, 0)
aioSelectC.stringsArr = {}
aioSelectC.tooltip_text = "Target to Steal from" --Mouses over the drop down and populates whats in here

table.insert(aioSelectC.stringsArr, "Select which targets' pocket you wish to empty") --Top of the drop down menu
for i, v in ipairs(mainVariable) do
    table.insert(aioSelectC.stringsArr, v.label)
end

API.DrawSquareFilled(IG_Back)
API.DrawTextAt(IG_Text)
API.DrawBox(btnStart)
API.DrawComboBox(aioSelectC, false)

----------------------------------------------------------------------
--                              GUI
----------------------------------------------------------------------

local function handleElidinisEvents()
    local lostSoul = 17720
    local unstableSoul = 17739
    local mimickingSoul = 18222
    local vengefulSoul = 17802
    local eventIDs = { lostSoul, unstableSoul, mimickingSoul, vengefulSoul }

    local found = false
    local eventObjs = API.GetAllObjArray1(eventIDs, 50, { 1 })
    if #eventObjs > 0 then
        print("Elidinis soul detected!")
        found = true
    end

    local originTile = API.PlayerCoordfloat()
    while #eventObjs > 0 and API.Read_LoopyLoop() do
        if eventObjs[1].Id == mimickingSoul then
           -- API.DoAction_Dive_Tile(eventObjs[1].Tile_XYZ) 
            API.DoAction_TileF(eventObjs[1].Tile_XYZ)
        elseif eventObjs[1].Id == unstableSoul or eventObjs[1].Id == lostSoul then
            -- API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, { eventObjs[1].Id }, 50)
            API.DoAction_NPC__Direct(0x29, API.OFF_ACT_InteractNPC_route, eventObjs[1])
        end

        API.RandomSleep2(1000, 250, 500)
        eventObjs = API.GetAllObjArray1(eventIDs, 50, { 1 })
    end

    if found then API.DoAction_TileF(originTile) end
end

local function isTeleportOptionsUp()
    local vb2874 = API.VB_FindPSettinOrder(2874, -1)
    return (vb2874.state == 13) or (vb2874.stateAlt == 13)
end

----------------------------------------------------------------------
--                              BUFFS
----------------------------------------------------------------------
local function elven()
    return API.DeBuffbar_GetIDstatus(43358).id > 0
end

local function CheckLightForm()
    return API.Buffbar_GetIDstatus(26048).id > 0
end

local function CheckRenewal()
    return API.Buffbar_GetIDstatus(14695).id > 0
end

local function CheckCMask()
    return API.Buffbar_GetIDstatus(25938).id > 0
end

local function healthCheck()
    local prayer = API.GetPrayPrecent()
    local excalCD = API.DeBuffbar_GetIDstatus(ID.EXCALIBUR, false)
    local excalFound = Inventory:InvItemcount(ID.EXCALIBUR_AUGMENTED)
    local elvenCD = API.DeBuffbar_GetIDstatus(ID.ELVEN_SHARD, false)

    local crystalMask = API.Buffbar_GetIDstatus(25938)
    local lightForm = API.Buffbar_GetIDstatus(26048)
    local fiveFingers = API.Buffbar_GetIDstatus(26098)

    local elvenFound = Inventory:InvItemcount(ID.ELVEN_SHARD)
    
    if not excalCD.found and excalFound > 0 then
        API.DoAction_Inventory1(ID.EXCALIBUR_AUGMENTED, 0, 1, API.OFF_ACT_GeneralInterface_route)
        dbg("Excalibrah")
        API.RandomSleep2(800, 500, 500)
    end

    if not elvenCD.found and elvenFound > 0 then
        API.DoAction_Inventory1(ID.ELVEN_SHARD, 43358, 1, API.OFF_ACT_GeneralInterface_route)
        dbg("Elven Shard")
        API.RandomSleep2(800, 500, 500)
    end

    if not crystalMask.found then
        --API.DoAction_Ability("Crystal Mask", 1, API.OFF_ACT_GeneralInterface_route)
        API.DoAction_Interface(0xffffffff,0xffffffff,1,1461,1,182,API.OFF_ACT_GeneralInterface_route)
        dbg("Crystal Mask")
        API.RandomSleep2(800, 500, 500)
    end

    if prayer > 10 and not lightForm.found then
        --API.DoAction_Ability("Light Form", 1, API.OFF_ACT_GeneralInterface_route)
        API.DoAction_Interface(0xffffffff,0xffffffff,1,1458,40,23,API.OFF_ACT_GeneralInterface_route)
        dbg("Light Form")
        API.RandomSleep2(800, 500, 500)
    end
end

local failSafe = 0

local function warsBank()
    local lightForm = API.Buffbar_GetIDstatus(26048)
    if lightForm.found then
        API.DoAction_Interface(0xffffffff,0xffffffff,1,1458,40,23,API.OFF_ACT_GeneralInterface_route)
        dbg("Deactivating Light Form")
        API.RandomSleep2(800, 500, 500)
    end
    if not API.PInArea(3294, 10, 10127, 10, 0) then
        API.DoAction_Ability("War's Retreat Teleport", 1, API.OFF_ACT_GeneralInterface_route)
        UTILS.SleepUntil(function() return API.PInArea(3294, 10, 10127, 10, 0) end, 10, "Arrived Wars Retreat")
    elseif API.PInArea(3294, 10, 10127, 10, 0) then
        Bank:LoadLastPreset()
        UTILS.countTicks(3)
        failSafe = failSafe + 1
        dbg(failSafe)
        if failSafe >= 5 then
            API.Write_LoopyLoop(false)
        end
        if Inventory:InvItemFounds(restores) == true then
            failSafe = 0
            BANKING = 2
        end
    end
end

local function verifyPrayer()
    if API.GetPrayPrecent() < 20 and os.clock() - potionCD >= 5 then
        for _, P in ipairs(restores) do
            if Inventory:InvItemcount(P) > 0 then
                dbg("Drinking Restores!")
                API.DoAction_Inventory1(P, 0, 1, API.OFF_ACT_GeneralInterface_route)
                potionCD = os.clock()
                break
            else 
                warsBank()
                BANKING = 1
            end
        end
    end
end

local function verifyRenewal()
    if not API.Buffbar_GetIDstatus(14695).found and os.clock() - potionCD >= 5 then
        for _, renewals in ipairs(prayerRenewal) do
            if Inventory:InvItemcount(renewals) > 0 then
                dbg("Drinking Renewal!")
                API.DoAction_Inventory1(renewals, 0, 1, API.OFF_ACT_GeneralInterface_route)
                potionCD = os.clock()
                break
            end
        end
    end
end

----------------------------------------------------------------------
--                           MAIN BODY
----------------------------------------------------------------------
local function debuggingSelection()
    if os.clock() - debugCD >= 5 then
        dbg(selectedOne)
        debugCD = os.clock()
    end
end

local function walk()
    selectedPathing()
end

local function stealingFromRich()
    if API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, selectedTarget, 20) then
        API.RandomSleep2(1200, 100, 100)
    end
end

local function check(condition, errorMessage)
    local result = condition
    if type(condition) == "function" then
        result = condition()
    end
    if not result then
        table.insert(errors, errorMessage)
    end
end

local function invCheck()
    errors = {}

    -- Inventory checks
    local wickedHoodCheck = Inventory:GetItemAmount(ID.WICKED_HOOD) > 0
    local seedCheck       = Inventory:GetItemAmount(ID.SAND_SEED) > 0

    if selectedLabel == "Wizards' Tower master mage (106)" then
        check(wickedHoodCheck, "You need a Wicked Hood in your inventory!")
    end

    if selectedLabel == "Crux Eqal Knight (83)" then
        check(seedCheck, "You need a Mysterious Seed in your inventory!")
    end

    -- Level check (Thieving)
    local hasRequiredLevel =
        API.XPLevelTable(API.GetSkillXP("THIEVING")) >= selectedLevel
    check(hasRequiredLevel,
        "You need at least Level " .. selectedLevel .. " Thieving")

    -- Not Required template for possible future use
    --[[if not isTeleportOptionsUp() and selectedLabel == "Wizards' Tower master mage (106)" then
        local hoodAB = API.GetABs_name1("Wicked hood")
        local whCheck = hoodAB and hoodAB.enabled
        check(whCheck, "You need to have Wicked Hood on your action bar")
    end]]

    -- API check
    local apiCheck = API.OFF_ACT_InteractNPC_route2 ~= nil
    check(apiCheck, "Please ensure you have the latest api.lua file from the ME release")

    firstRun = false
    return #errors == 0
end



--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ LOOPY LOOPY @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

API.Write_LoopyLoop(true)
while (API.Read_LoopyLoop()) do

----------------------------------------------------------------------
--                              GUI
----------------------------------------------------------------------
    if scriptPaused and aioSelectC.return_click then
        aioSelectC.return_click = false
        for i, v in ipairs(mainVariable) do
            if aioSelectC.string_value == v.label then
                selectedLabel   = v.label
                selectedOne     = v.printVariable
                selectedTarget  = v.pickPocketTarget
                selectedLevel   = v.targetsLevel
                selectedPathing = v.walkBack
            end
        end
    end

    local elapsedMinutes = (os.time() - startTime)


    if not scriptPaused then
        if btnStart.return_click then
            btnStart.return_click = false
            btnStart.box_name = " START "
            scriptPaused = true
        end
    end

    if scriptPaused then
        if btnStart.return_click then
            btnStart.return_click = false

            -- make sure a target was chosen
            if not selectedLabel or not selectedLevel then
                print("Please select a target from the dropdown menu!")
                API.logError("Please select a target from the dropdown menu!")
                goto continue
            end

            if not invCheck() then
                print("!!! Startup Check Failed !!!")
                if #errors > 0 then
                    print("Errors:")
                    for _, msg in ipairs(errors) do
                        print("- " .. msg)
                        API.logError(msg)
                    end
                end
                goto continue
            end

            btnStart.box_name = " PAUSE "
            IG_Back.remove = true
            btnStart.remove = true
            IG_Text.remove = true
            aioSelectC.remove = true
            MAX_IDLE_TIME_MINUTES = 15
            scriptPaused = false
            print("Script started!")
            API.logDebug("Info: Script started!")
            if firstRun then
                startTime = os.time()
                firstRun = false
            end
        end
        goto continue
    end

----------------------------------------------------------------------
--                              GUI
----------------------------------------------------------------------
    --debuggingSelection()


    if API.GetHPrecent() < 18 then 
        dbg("Emergency teleport")
        warsBank()
        BANKING = 1
    elseif BANKING == 1 then
        warsBank()    
    end

    if Inventory:IsFull() then
        dbg("Inventory full, proceed to banking")
        warsBank()
        BANKING = 1
    end

    if BANKING == 0 then
        healthCheck()
        verifyPrayer()
        verifyRenewal()
    end

    if API.CheckAnim(60) or API.ReadPlayerMovin2() then
        API.RandomSleep2(50, 100, 100)
        goto continue
    end

    if BANKING == 2 then
        selectedPathing()
    elseif BANKING == 0 then
        stealingFromRich()
    end

    ::continue::
    idleCheck()
    API.DoRandomEvents()
    API.RandomSleep2(200, 200, 200)
end