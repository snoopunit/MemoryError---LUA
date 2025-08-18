print("Woodcutting & Firemaking")

local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")
local WC = require("lib/WOODCUTTING")
local FIRE = require("lib/FIREMAKING")

print("Required modules loaded")

local Max_AFK = 5
local makeIncense = true

function Woodcutting_and_Firemaking()

    if API.InvFull_() then
        if makeIncense then
            if not FIRE.makeIncense() then
                return
            end
        else
            if not FIRE.addToBonfire() then
                if not FIRE.useLogs(2) then
                    return
                end
            end
        end
        API.RandomSleep2(800, 0, 600)
    else
        WC.gather()
    end

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)
WC.setTreeAndLogType()
FIRE.GLOBALS.logType = WC.GLOBALS.logType

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    WC.metrics()
    API.RandomSleep2(50,0,50)
    --Woodcutting_and_Firemaking()
end----------------------------------------------------------------------------------