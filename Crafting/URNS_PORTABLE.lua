print("URNS_PORTABLES")

local API = require("api")
local UTILS = require("UTILS")
local BANK = require("lib/BANKING")
local MISC = require("lib/MISC")

function dialogOpen()
    return API.ScanForInterfaceTest2Get(false, { { 1188, 5, -1, -1, 0 }, { 1188, 3, -1, 5, 0 }, { 1188, 3, 14, 3, 0 } })
end

function waitForDialog()
    local dialogTimer = API.SystemTime()
    while not dialogOpen() and API.Read_LoopyLoop() do
        if (API.SystemTime() - dialogTimer) > 10000 then
            API.logWarn("Dialog Window took too long to open! Shutting down!")
            API.Write_LoopyLoop(false)
            return 
        end
        API.RandomSleep(50,0,50)
    end
end

function usePortableCrafter()
    Interact:Object("Portable crafter", "Clay Crafting", 10)
end

function formClay()
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1188,8,-1,API.OFF_ACT_GeneralInterface_Choose_option)
end

function fireClay()
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1188,13,-1,API.OFF_ACT_GeneralInterface_Choose_option)
end

function bank()
    local bankTimer = API.SystemTime()
    
    while (API.SystemTime() - bankTimer) < 15000 do

        Interact:NPC("Banker", "Load Last Preset from", 10)

        API.RandomSleep2(1200,0,0)

        while API.Read_LoopyLoop() and API.ReadPlayerMovin() do
            API.RandomSleep2(50,0,50)
        end

        if Inventory:IsFull() then
            return true
        end

    end

    API.logWarn("Banking took too long! Shutting Down!")
    API.Write_LoopyLoop(false)
    return false
    
end

local function hasUnfiredPots()
    local inv = API.ReadInvArrays33()
    for index, value in ipairs(inv) do
        if string.find(value.textitem, "unfired") then
            return true
        end
    end
    return false
end

function makeUrns()

    API.logDebug("makeUrns()")
    if Inventory:IsFull() then
        while (Inventory:GetItemAmount("Soft clay") >= 2) and API.Read_LoopyLoop() do
            usePortableCrafter()
            API.RandomSleep2(1200,0,0)
            waitForDialog()
            formClay()
            MISC.waitForCraftingInterface()
            MISC.doCrafting()
        end
        while hasUnfiredPots() and API.Read_LoopyLoop() do
            usePortableCrafter()
            API.RandomSleep2(1200,0,0)
            waitForDialog()
            fireClay()
            MISC.waitForCraftingInterface()
            MISC.doCrafting()
        end
    else
        Interact:NPC("Banker", "Load Last Preset from", 10)
        API.RandomSleep2(2400,0,600)
    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)


while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    makeUrns()  
end----------------------------------------------------------------------------------

