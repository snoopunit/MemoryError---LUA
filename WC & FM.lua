print("Woodcutting & Firemaking")

local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")
local WC = require("lib/WOODCUTTING")
local FIRE = require("lib/FIREMAKING")

local Max_AFK = 5

function Woodcutting_and_Firemaking()

    if API.InvFull_() then
        if makeIncense then
            if not FIRE.makeIncense(WC.GLOBALS.logType) then
                return
            end
        else
            if not FIRE.addToBonfire(WC.GLOBALS.logType) then
                if not FIRE.useLogs(WC.GLOBALS.logType, 2) then
                    return
                end
            end
        end
        API.RandomSleep2(800, 0, 600)
    else
        WC.gather(WC.GLOBALS.treeType, WC.GLOBALS.logType)
    end

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)
WC.setTreeAndLogType()

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    Woodcutting_and_Firemaking()
end----------------------------------------------------------------------------------