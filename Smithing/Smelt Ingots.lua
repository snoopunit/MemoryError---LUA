print("CRAFT ONCE BEFORE STARTING")

local API = require("api")
local MISC = require("lib/MISC")

local function useFurnace()
    if not Interact:Object("Furnace", "Smelt") then
        API.logWarn("Unable to interact with Furnace!")
        API.Write_LoopyLoop(false)
    end
end

local function isSmeltingInterfaceOpen()
  return API.VB_FindPSett(2874, 1, 0).state == 85
end

local function doCrafting()
    local smeltTimer = API.SystemTime()

    while not isSmeltingInterfaceOpen() and API.Read_LoopyLoop() do
        if API.SystemTime() - smeltTimer > 30000 then
            API.logWarn("Smelting interface not found after 30s!")
            API.Write_LoopyLoop(false)
            return
        end
        API.RandomSleep2(50,0,50)
    end

    API.RandomSleep2(1200,0,600)

    API.DoAction_Interface(0x24,0xffffffff,1,37,163,-1,API.OFF_ACT_GeneralInterface_route)

    local craftingTimer = API.SystemTime()

    while not API.isProcessing() and API.Read_LoopyLoop() do

        API.RandomSleep2(600,0,500)

        if API.SystemTime() - craftingTimer > 10000 then
            API.logWarn("Didn't find API.isProcessing() after 10s!")
            API.Write_LoopyLoop(false)
            return
        end
            
    end

    while API.isProcessing() and API.Read_LoopyLoop() do
        API.RandomSleep2(600,0,500)
    end

end

local function doBanking()
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

API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)
API.Write_LoopyLoop(true)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    useFurnace()
    doCrafting()
    doBanking()
end----------------------------------------------------------------------------------
