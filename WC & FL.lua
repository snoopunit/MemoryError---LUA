print("Woodcutting & Fletching")

local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")
local WC = require("lib/WOODCUTTING")
local BANK = require("lib/BANKING")

local Max_AFK = 5

function drawGUI()

    imguiBackground = API.CreateIG_answer()
    imguiBackground.box_name = "imguiBackground"
    imguiBackground.box_start = FFPOINT.new(50, 30, 0)
    imguiBackground.box_size = FFPOINT.new(330, 115, 0)
    imguiBackground.colour = ImColor.new(99, 99, 99, 225)

    local gui_center_x = imguiBackground.box_start.x + (imguiBackground.box_size.x / 2)

    local dropdown_width = 300
    local dropdown_height = 20
    local dropdown_x = gui_center_x - (dropdown_width / 2) + 10
    local dropdown_y = 40 

    local fletchTypes = {"Arrow Shafts", "Shortbows (U)", "Stocks", "Shieldbows (U)"}

    fletchTypeCombo = API.CreateIG_answer()
    fletchTypeCombo.box_name = "Fletch Type"
    fletchTypeCombo.box_start = FFPOINT.new(dropdown_x, dropdown_y, 0)
    fletchTypeCombo.stringsArr = fletchTypes
    fletchTypeCombo.string_value = fletchTypes[1]
    fletchTypeCombo.tooltip_text = "Choose the type of item to fletch."

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
        end
        MISC.doCrafting()
        BANK.loadLastPreset()
    else
        WC.gather()
    end

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)
WC.GLOBALS.treeType = TREES.WILLOW
WC.GLOBALS.logType = LOGS.WILLOW

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    Woodcutting_and_Fletching()
end----------------------------------------------------------------------------------