print("Seer's Village Magic Shortbow(u)'s")

local API = require("api")
local MISC = require("lib/MISC")
local WC = require("lib/WOODCUTTING")

local AREA = {
    BANK = {x = 2675, y = 3405, z = 3},
    TREES = {x = 2691 , y = 3426, z = 2}
}

local function isAtLocation(location, distance)
    local distance = distance or 20
    return API.PInArea(location.x, distance, location.y, distance, location.z)
end

local function goToLocation(location)
    --try to walk to the location if we're not already there
    if not isAtLocation(location) then

        API.logDebug("goToLocation()")

        if not API.DoAction_Tile(WPOINT.new(location.x + math.random(-4, 4), location.y + math.random(-4, 4), location.z)) then

            API.logWarn("DoAction_Tile(): {"..tostring(location.x)..", "..tostring(location.y).."} failed!")
            API.Write_LoopyLoop(false)
            return 

        end


        while not isAtLocation(location) and API.Read_LoopyLoop() do

            API.RandomSleep2(50,0,50)

        end

    end
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

    --[[while not Inventory:IsEmpty() do
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
    end]]

end

function doProcessing()

    WC.useLogs(1)
    API.RandomSleep2(1200,0,600)

    if MISC.isChooseToolOpen() then
        MISC.chooseToolOption("Fletch")
        API.RandomSleep2(1200,0,600)
    end

    if MISC.isCraftingInterfaceOpen() then
        API.logDebug("Choosing shortbows(u)...")
        MISC.chooseCraftingItem(3)
    end

    API.RandomSleep2(1200,0,600)
    MISC.doCrafting()
    
end

function mainRoutine()

    if API.InvFull_() then
        doProcessing()
        --goToLocation(AREA.BANK)
        doBanking()    
        --goToLocation(AREA.TREES)
    else
        WC.gather()
    end

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)
WC.GLOBALS.treeType = TREES.MAGIC

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    mainRoutine()
end----------------------------------------------------------------------------------