print("WC & FL/FM")

local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")
local WC = require("lib/WOODCUTTING")
local FIRE = require("lib/FIREMAKING")

local Max_AFK = 5
local itemType = "None"
local treeType = "None"
local scriptState = "Idle"
local itemSelection = 2
local isBanking = false
local makeIncense = false


function drawGUI()

    imguiBackground = API.CreateIG_answer()
    imguiBackground.box_name = "imguiBackground"
    imguiBackground.box_start = FFPOINT.new(50, 30, 0)
    imguiBackground.box_size = FFPOINT.new(350, 140, 0)
    imguiBackground.colour = ImColor.new(99, 99, 99, 225)

    local gui_center_x = imguiBackground.box_start.x + (imguiBackground.box_size.x / 2)

    local dropdown_width = 300
    local dropdown_height = 20
    local dropdown_x = gui_center_x - (dropdown_width / 2)
    local dropdown_y = 40 

    itemTypes = {"None", "Wood Box", "Arrow Shafts", "Shortbows (U)", "Stocks", "Shieldbows (U)", "Incense", "Light Fires"}

    itemTypeCombo = API.CreateIG_answer()
    itemTypeCombo.box_name = "###ITEM"
    itemTypeCombo.box_start = FFPOINT.new(dropdown_x, dropdown_y, 0)
    itemTypeCombo.box_size = FFPOINT.new(200, 0, 0)
    itemTypeCombo.stringsArr = itemTypes
    itemTypeCombo.string_value = itemTypes[2]
    itemTypeCombo.tooltip_text = "Choose the type of item to make."
    
    treeTypes = {}
    for key, tree in pairs(TREES) do
        if tree.name then
            table.insert(treeTypes, tree.name)
        end
    end

    treeTypeCombo = API.CreateIG_answer()
    treeTypeCombo.box_name = "###TREETYPE"
    treeTypeCombo.box_start = FFPOINT.new(dropdown_x, dropdown_y + 20, 0)
    treeTypeCombo.box_size = FFPOINT.new(200, 0, 0)
    treeTypeCombo.stringsArr = treeTypes
    treeTypeCombo.string_value = treeTypes[4]
    treeTypeCombo.tooltip_text = "Choose the type of tree to cut."

    local button_y = dropdown_y + dropdown_height + 15  
    local button_width = 80
    local button_height = 30
    local button_spacing = 20
    local total_button_width = button_width * 2 + button_spacing
    local buttons_start_x = gui_center_x - (total_button_width / 2) - 25

    startButton = API.CreateIG_answer()
    startButton.box_name = "START"
    startButton.box_start = FFPOINT.new(buttons_start_x, button_y + 20, 0)
    startButton.box_size = FFPOINT.new(button_width, button_height, 0)
    startButton.tooltip_text = "Start the script."

    quitButton = API.CreateIG_answer()
    quitButton.box_name = "QUIT"
    quitButton.box_start = FFPOINT.new(buttons_start_x + button_width + button_spacing, button_y + 20, 0)
    quitButton.box_size = FFPOINT.new(button_width, button_height, 0)
    quitButton.tooltip_text = "Close the script."

    API.DrawSquareFilled(imguiBackground)
    API.DrawComboBox(itemTypeCombo)
    API.DrawComboBox(treeTypeCombo)
    API.DrawBox(startButton)
    API.DrawBox(quitButton)
    
end

function clearGUI()
    imguiBackground.remove = true
    itemTypeCombo.remove = true
    treeTypeCombo.remove = true
    startButton.remove = true
    quitButton.remove = true
end

function doBanking()
    local bankTimer = API.SystemTime()
    local hasBanked = false
    local bankNPCs = {"Banker"}
    local bankOBJs = {"Bank chest", "Counter"}

    for i, NPC in ipairs(bankNPCs) do
        if Interact:NPC(NPC, "Load Last Preset from", 50) then
            hasBanked = true
            break
        end
    end

    if not hasBanked then
        for i, OBJ in ipairs(bankOBJs) do
            if Interact:Object(OBJ, "Load Last Preset from", 50) then
                hasBanked = true
                break
            end
        end
    end
    
    if not hasBanked then
        API.logWarn("Couldn't interact with any banks!")
        API.Write_LoopyLoop(false)
        return false
    end

    while not Inventory:IsEmpty() do
        if not API.Read_LoopyLoop() then return false end
        API.RandomSleep2(600,0,500)
        if API.ReadPlayerMovin() then
            bankTimer = API.SystemTime()
        end
        if API.SystemTime() - bankTimer > 15000 then
            API.logWarn("Didn't clean out our inventory after 30s!")
            API.Write_LoopyLoop(false)
            return false
        end
    end

end

function doFiremaking()

    if FIRE.findFires() == 0 then

        API.logInfo("Starting a new fire...")
        WC.useLogs(2)
        API.RandomSleep2(1200,0,600)

        while API.CheckAnim(75) and API.Read_LoopyLoop() do
            API.RandomSleep2(1200,0,600)    
        end

    end

    API.logInfo("Adding logs...")
    WC.useLogs(1)
    API.RandomSleep2(1200,0,600)

    if MISC.isChooseToolOpen() then
        MISC.chooseToolOption("Bonfire")
        API.RandomSleep2(1200,0,600)
    end

    while API.CheckAnim(75) and API.Read_LoopyLoop() do
        API.RandomSleep2(1200,0,600)    
    end

end

function doProcessing(typeString)

    WC.useLogs(1)
    API.RandomSleep2(1200,0,600)

    if MISC.isChooseToolOpen() then
        MISC.chooseToolOption(typeString)
        API.RandomSleep2(1800,0,600)
    end

    if typeString ~= "Incense" then
        MISC.chooseCraftingItem(itemSelection)
    end

    API.RandomSleep2(1200,0,600)
    MISC.doCrafting()
    
end

function fillWoodBox()
    local boxAB = API.GetABs_name("box", false)

    if boxAB.action == "Fill" and boxAB.enabled then
        API.DoAction_Ability_Direct(boxAB, 1, API.OFF_ACT_GeneralInterface_route)
    end
    
end

function mainRoutine()
    if scriptState == "Idle" then

        if itemTypeCombo.return_click then
            itemTypeCombo.return_click = false
            itemType = itemTypeCombo.string_value
            if itemType ~= "None" and itemType ~= "Incense" then
                for i, v in ipairs(itemTypes) do
                    if v == itemType then
                        itemSelection = i - 1
                        break
                    end
                end
            end
            if itemType == "Arrow Shafts" or itemType == "Incense" or itemType == "Light Fires" then
                isBanking = false
            else
                isBanking = true
            end
            API.logDebug("Selected item type: " .. itemType)
        end

        if treeTypeCombo.return_click then
            treeTypeCombo.return_click = false
            treeType = treeTypeCombo.string_value
            for key, tree in pairs(TREES) do
                if tree.name == treeType then
                    WC.GLOBALS.treeType = tree
                    API.logDebug("Selected tree type: " .. tree.name)
                    local logKey = TREE_TO_LOG_MAP[key]
                    if logKey and LOGS[logKey] then
                        WC.GLOBALS.logType = LOGS[logKey]
                        API.logDebug("Assigned Log Type: " .. WC.GLOBALS.logType.name)
                    else
                        API.logWarn("No matching log type found for tree: " .. key)
                    end
                    break
                end
            end
        end

        if startButton.return_click then
            startButton.return_click = false
            clearGUI()
            scriptState = "Running"
        end

        if quitButton.return_click then
            API.logWarn("Stopping script!")
            API.Write_LoopyLoop(false)
            return
        end

        if not API.Read_LoopyLoop() then return end

        API.RandomSleep2(250,0,250)

    else

        if API.InvFull_() then

            API.logDebug("Inv_Full()")
            API.logDebug("itemType: "..tostring(itemType))

            while (Inventory:GetItemAmount(WC.GLOBALS.logType.id) > 2) and API.Read_LoopyLoop() do
                if not API.Read_LoopyLoop then return end
                if itemType == "Incense" then
                    doProcessing("Incense")
                elseif itemType == "Light Fires" then
                    doFiremaking()
                elseif itemType ~= "None" then
                    doProcessing("Fletch")
                else break
                end
            end
        
            if isBanking then
                doBanking()    
            end    

        else
            WC.gather()
            if Inventory:FreeSpaces() < math.random(2,8) then
                fillWoodBox()
            end
        end

    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)
drawGUI()

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    mainRoutine()
end----------------------------------------------------------------------------------