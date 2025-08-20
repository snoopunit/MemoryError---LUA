print("Rogue's Den cooking")

local API = require("api")

RAW_FISH = {
    RAW_SHRIMPS           = { name = "Raw Shrimps",             id = 317 },
    RAW_CRAYFISH          = { name = "Raw Crayfish",            id = 13435 },
    RAW_SARDINE           = { name = "Raw Sardine",             id = 327 },
    RAW_ANCHOVIES         = { name = "Raw Anchovies",           id = 321 },
    RAW_KARAMBWANJI       = { name = "Raw Karambwanji",         id = 3150 },
    RAW_HERRING           = { name = "Raw Herring",             id = 345 },
    RAW_MACKEREL          = { name = "Raw Mackerel",            id = 353 },
    RAW_TROUT             = { name = "Raw Trout",               id = 335 },
    RAW_COD               = { name = "Raw Cod",                 id = 341 },
    RAW_PIKE              = { name = "Raw Pike",                id = 349 },
    RAW_SALMON            = { name = "Raw Salmon",              id = 331 },
    RAW_SLIMY_EEL         = { name = "Slimy Eel",               id = 3379}, 
    RAW_TUNA              = { name = "Raw Tuna",                id = 359 },
    RAW_KARAMBWAN         = { name = "Raw Karambwan",           id = 3142 },
    RAW_RAINBOW_FISH      = { name = "Raw Rainbow Fish",        id = 10138 },
    RAW_CAVE_EEL          = { name = "Raw Cave Eel",            id = 5001 }, 
    RAW_LOBSTER           = { name = "Raw Lobster",             id = 377 },
    RAW_BASS              = { name = "Raw Bass",                id = 363 },
    RAW_SWORDFISH         = { name = "Raw Swordfish",           id = 371 },
    RAW_DESERT_SOLE       = { name = "Raw Desert Sole",         id = 40287 },  
    RAW_CATFISH           = { name = "Raw Catfish",             id = 40289 }, 
    RAW_MONKFISH          = { name = "Raw Monkfish",            id = 7944 },
    RAW_BELTFISH          = { name = "Raw Beltfish",            id = 40291 }, 
    RAW_SHARK             = { name = "Raw Shark",               id = 383 },
    RAW_SEA_TURTLE        = { name = "Raw Sea Turtle",          id = 395 },
    RAW_GREAT_WHITE_SHARK = { name = "Raw Great White Shark",   id = 34727 }, 
    RAW_CAVEFISH          = { name = "Raw Cavefish",            id = 15264 }, 
    RAW_MANTA_RAY         = { name = "Raw Manta Ray",           id = 389 },
    RAW_ROCKTAIL          = { name = "Raw Rocktail",            id = 15270 },
    RAW_TIGER_SHARK       = { name = "Raw Tiger Shark",         id = 21520 }  
}

function getAllFishNames()
    local names = {"None"}
    for _, fish in pairs(RAW_FISH) do
        table.insert(names, fish.name)
    end
    return names
end

GLOBALS = {
    fishToCook = nil,
    fishCooked = 0,
    currentState = "Idle"
}

---@param amount number
---@return string
function comma_value(amount)
    local formatted = tostring(amount) -- Convert the number to a string
    while true do
        -- Replace a sequence of digits followed by three digits with the same sequence, a comma, and the three digits
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        -- If no more replacements were made (k == 0), break the loop
        if (k == 0) then
            break
        end
    end
    return formatted
end

function fmt(value)
    if value > 999 then
        return comma_value(value)
    end
    return tostring(value)
end

---@param item number
---@return number
function itemsPerHour(item)
    if item == 0 then
        return 0
    end
    local elapsedTime = API.ScriptRuntime() / 3600 
    return math.floor(item / elapsedTime)
end

---@param itemID number
---@param itemNum number
---@return number
function EstimatedProfit(itemID, itemNum) 
    local profitPerItem = API.GetExchangePrice(itemID)
    return itemNum * profitPerItem
end

---@param itemID number
---@param itemNum number
---@return number
function EstimatedProfitPerHour(itemID, itemNum)
    local elapsedTime = API.ScriptRuntime() / 3600
    return math.floor(EstimatedProfit(itemID, itemNum) / elapsedTime)    
end

----METRICS----
function metrics()
    local METRICS = {
        {"Current State: ", GLOBALS.currentState},
        {"Fish Type: ", GLOBALS.fishToCook.name},
        {"GE Value: ", fmt(API.GetExchangePrice(GLOBALS.fishToCook.id))},
        {"# of fish: ", fmt(GLOBALS.fishCooked)},
        {"# of fish/hr: ", fmt(itemsPerHour(GLOBALS.fishCooked))},
        {"Est. profit: ", fmt(EstimatedProfit(GLOBALS.fishToCook.id, GLOBALS.fishCooked))},
        {"Est. profit/hr: ", fmt(EstimatedProfitPerHour(GLOBALS.fishToCook.id, GLOBALS.fishCooked))}
    }
    API.DrawTable(METRICS)
end

function updateFishNum(fishCooked)

    GLOBALS.fishCooked = (GLOBALS.fishCooked + fishCooked)

    metrics()

end

function updateCurrentState(state)
    GLOBALS.currentState = state
    API.logDebug("Current State: "..GLOBALS.currentState)
    metrics()
end
----METRICS----

function drawGUI()

    imguiBackground = API.CreateIG_answer()
    imguiBackground.box_name = "imguiBackground"
    imguiBackground.box_start = FFPOINT.new(50, 30, 0)
    imguiBackground.box_size = FFPOINT.new(400, 150, 0)
    imguiBackground.colour = ImColor.new(99, 99, 99, 225)

    local gui_center_x = imguiBackground.box_start.x + (imguiBackground.box_size.x / 2)

    local dropdown_width = 300
    local dropdown_height = 20
    local dropdown_x = gui_center_x - (dropdown_width / 2) - 20
    local dropdown_y = 40 

    local fishTypes = getAllFishNames()

    fishTypeCombo = API.CreateIG_answer()
    fishTypeCombo.box_name = "Fish Type"
    fishTypeCombo.box_start = FFPOINT.new(dropdown_x, dropdown_y, 0)
    fishTypeCombo.stringsArr = fishTypes
    fishTypeCombo.string_value = fishTypes[1]
    fishTypeCombo.tooltip_text = "Choose the fish type to cook."

    local button_y = dropdown_y + dropdown_height + 30  
    local button_width = 80
    local button_height = 30
    local button_spacing = 20
    local total_button_width = button_width * 2 + button_spacing
    local buttons_start_x = gui_center_x - (total_button_width / 2)

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
    API.DrawComboBox(fishTypeCombo)
    API.DrawBox(startButton)
    API.DrawBox(quitButton)

end

function clearGUI()
    imguiBackground.remove = true
    fishTypeCombo.remove = true
    startButton.remove = true
    quitButton.remove = true
end

---CREDIT---DEAD.UTILS
--- Is the Crafting interface open
---@return boolean
function isCraftingInterfaceOpen()
  return API.VB_FindPSett(2874, 1, 0).state == 1310738
end

function waitForCraftingInterface()
    local failTimer = API.SystemTime()
    while not isCraftingInterfaceOpen() do
        API.RandomSleep2(600,0,250)
        if API.SystemTime() - failTimer > 30000 then
            API.logWarn("Failed to open Crafting Interface!")
            API.Write_LoopyLoop(false)
            return false
        end
    end
    return true
end

function clickStart()
    API.logInfo("Starting production...")
    if not isCraftingInterfaceOpen() then
        API.logWarn("Failed to detect Crafting Interface...")
        API.Write_LoopyLoop(false)
        return false
    end
    return API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,API.OFF_ACT_GeneralInterface_Choose_option)  
end

function doCrafting()
    waitForCraftingInterface()
    if clickStart() then
        local craftingTimer = API.SystemTime()
        while not API.isProcessing() do
            API.RandomSleep2(600,0,500)
            if API.SystemTime() - craftingTimer > 10000 then
                API.logWarn("Crafting process took too long to start!")
                API.Write_LoopyLoop(false)
                return false
            end
        end
        while API.isProcessing() do
            API.RandomSleep2(600,0,500)
        end
        return true
    end
end

function loadLastPreset()
    API.logDebug("Resupplying...")
    local banktimer = API.SystemTime()
    Interact:NPC("Emerald Benedict", "Load Last Preset from", 20)
    API.RandomSleep2(600, 0, 250)
    while API.Invfreecount_() > 0 do
        if (API.SystemTime() - banktimer) > 30000 then
            API.logDebug("Out of supplies!")
            API.Write_LoopyLoop(false)
            return
        end
        API.RandomSleep2(50, 0, 50)
    end
end

function cookAtFire()
    API.logDebug("Cooking food...")
    Interact:Object("Fire", "Cook at", 10)
    doCrafting()
end

function startCookingRoutine()

    while GLOBALS.currentState == "Idle" do

        if fishTypeCombo.return_click then
            fishTypeCombo.return_click = false
            local selectedFishType = fishTypeCombo.string_value
            for key, value in pairs(RAW_FISH) do
                if value.Name == selectedFishType then
                    GLOBALS.fishToCook = value
                    break
                end
            end
            if GLOBALS.fishToCook ~= nil then
                API.logDebug("Selected Fish Type: "..GLOBALS.fishToCook.Name)
            else
                API.logWarn("Something went wrong! Selected fish type still NIL!")
                API.Write_LoopyLoop(false)
                return
            end
        end

        if startButton.return_click then
            startButton.return_click = false
            if GLOBALS.fishToCook == nil then
                API.logWarn("Fish Type not selected!")
            else
                clearGUI()
                updateCurrentState("Starting...")
            end

        end

        if quitButton.return_click then
            API.logWarn("Stopping script!")
            API.Write_LoopyLoop(false)
            return
        end

        API.RandomSleep2(250,0,250)

    end

    while GLOBALS.currentState ~= "Idle" do
        if Inventory:Contains(GLOBALS.fishToCook.name) then
            cookAtFire()
        else
            loadLastPreset()
        end
    end

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(5)
drawGUI()

while API.Read_LoopyLoop()
do-----------------------------------------------------------------------------------
    startCookingRoutine()
end----------------------------------------------------------------------------------