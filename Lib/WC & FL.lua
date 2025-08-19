print("Woodcutting & Fletching")

local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")
local WC = require("lib/WOODCUTTING")

local Max_AFK = 5

function Woodcutting_and_Fletching()

    if API.InvFull_() then
        WC.useLogs(1)
        API.RandomSleep2(1200,0,600)
        if MISC.isChooseToolOpen() then
            MISC.chooseToolOption("Fletch")
        end
        MISC.doCrafting()
    else
        WC.gather()
    end

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)
WC.GLOBALS.treeType = TREES.OAK
WC.GLOBALS.logType = LOGS.OAK

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    Woodcutting_and_Fletching()
end----------------------------------------------------------------------------------