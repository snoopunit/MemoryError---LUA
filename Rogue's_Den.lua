print("Rogue's Den cooking")

local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")

function loadLastPreset()
    API.logDebug("Resupplying...")
    local banktimer = API.SystemTime()
    --API.DoAction_NPC(0x33,API.OFF_ACT_InteractNPC_route4,{ banker },50)
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
    MISC.doCrafting()
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(5)

while API.Read_LoopyLoop()
do-----------------------------------------------------------------------------------
    if Inventory:Contains("Raw lobster") then
        cookAtFire()
    else
        loadLastPreset()
    end
end----------------------------------------------------------------------------------