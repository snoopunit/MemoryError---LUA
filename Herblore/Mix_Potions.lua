local API = require("api")
local HERB = require("lib/HERBLORE")
local MISC = require("lib/MISC")



local function main()

    
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    startHerbloreRoutine()

    API.RandomSleep2(800, 0, 400)
end----------------------------------------------------------------------------------