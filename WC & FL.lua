print("Woodcutting & Fletching")

local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")
local WC = require("lib/WOODCUTTING")
local BANK = require("lib/BANKING")

local Max_AFK = 5
local fletchType = "None"
local scriptState = "Idle"
local fletchSelection = 2
local isBanking = false

function drawGUI()

    imguiBackground = API.CreateIG_answer()
    imguiBackground.box_name = "imguiBackground"
    imguiBackground.box_start = FFPOINT.new(50, 30, 0)
    imguiBackground.box_size = FFPOINT.new(350, 150, 0)
    imguiBackground.colour = ImColor.new(99, 99, 99, 225)

    local gui_center_x = imguiBackground.box_start.x + (imguiBackground.box_size.x / 2)

    local dropdown_width = 300
    local dropdown_height = 20
    local dropdown_x = gui_center_x - (dropdown_width / 2) + 10
    local dropdown_y = 40 

    fletchTypes = {"Wood Box", "Arrow Shafts", "Shortbows (U)", "Stocks", "Shieldbows (U)"}

    fletchTypeCombo = API.CreateIG_answer()
    fletchTypeCombo.box_name = "Fletch Type"
    fletchTypeCombo.box_start = FFPOINT.new(dropdown_x, dropdown_y, 0)
    fletchTypeCombo.stringsArr = fletchTypes
    fletchTypeCombo.string_value = fletchTypes[2]
    fletchTypeCombo.tooltip_text = "Choose the type of item to fletch."

    treeTypes = {"Tree", "Oak", "Willow", "Maple", "Yew", "Magic", "Elder"}

    treeTypeCombo = API.CreateIG_answer()
    treeTypeCombo.box_name = "Tree Type"
    treeTypeCombo.box_start = FFPOINT.new(dropdown_x, dropdown_y, 0)
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
    startButton.box_start = FFPOINT.new(buttons_start_x, button_y, 0)
    startButton.box_size = FFPOINT.new(button_width, button_height, 0)
    startButton.tooltip_text = "Start the script."

    quitButton = API.CreateIG_answer()
    quitButton.box_name = "QUIT"
    quitButton.box_start = FFPOINT.new(buttons_start_x + button_width + button_spacing, button_y, 0)
    quitButton.box_size = FFPOINT.new(button_width, button_height, 0)
    quitButton.tooltip_text = "Close the script."

    API.DrawSquareFilled(imguiBackground)
    API.DrawComboBox(fletchTypeCombo)
    API.DrawBox(startButton)
    API.DrawBox(quitButton)

end

function clearGUI()
    imguiBackground.remove = true
    fletchTypeCombo.remove = true
    startButton.remove = true
    quitButton.remove = true
end

function Woodcutting_and_Fletching()

    if API.InvFull_() then
        WC.useLogs(1)
        API.RandomSleep2(1200,0,600)
        if MISC.isChooseToolOpen() then
            MISC.chooseToolOption("Fletch")
            MISC.waitForCraftingInterface()
        end
        MISC.chooseCraftingItem(fletchSelection)
        MISC.doCrafting()
        if isBanking then
            Interact:NPC("Banker", "Load Last Preset from", 20)
            API.waitUntilMovingEnds(1,2)
        end
    else
        WC.gather()
    end

end

function mainRoutine()
    if scriptState == "Idle" then
        if fletchTypeCombo.return_click then
            fletchTypeCombo.return_click = false
            fletchType = fletchTypeCombo.string_value
            for i, v in ipairs(fletchTypes) do
                if v == fletchType then
                    fletchSelection = i
                    break
                end
            end
            if fletchType ~= "None" then
                API.logDebug("Selected Fletch Type: "..fletchType)
                if fletchType ~= "Arrow Shafts" then
                    isBanking = true
                end
            else
                API.logWarn("Something went wrong! Selected fish type still None!")
                API.Write_LoopyLoop(false)
                return
            end
        end
        if startButton.return_click then
            startButton.return_click = false
            if fletchType == "None" then
                API.logWarn("Fletch Type not selected!")
            else
                clearGUI()
                scriptState = "Running"
            end
        end
        if quitButton.return_click then
            API.logWarn("Stopping script!")
            API.Write_LoopyLoop(false)
            return
        end
        if not API.Read_LoopyLoop() then return end
        API.RandomSleep2(250,0,250)
    else
        Woodcutting_and_Fletching()   
    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)
WC.GLOBALS.treeType = TREES.MAPLE
WC.GLOBALS.logType = LOGS.MAPLE
drawGUI()

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    mainRoutine()
end----------------------------------------------------------------------------------