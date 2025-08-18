print("TESTING TEMPLATE")

local API = require("api")
local UTILS = require("UTILS")
local WC = require("lib/WOODCUTTING")
local COOK = require("lib/COOKING")
local BANK = require("lib/BANKING")
local FIRE = require("lib/FIREMAKING")
local FISH = require("lib/FISHING")
local HERB = require("lib/HERBLORE")
local MINE = require("lib/MINING")
local MISC = require("lib/MISC")
local TASK = require("lib/TASK")

local Max_AFK = 5

function Fishing_and_Banking(spotType, bankType)

    if API.InvFull_() then

        API.logInfo("Noting...")

        BANK.doBank(bankType, "note")

    else

        FISH.gather(spotType)

    end

    API.RandomSleep2(2400, 0 ,600)

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

HERB.drawGUI()

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    startHerbloreRoutine()
end----------------------------------------------------------------------------------

