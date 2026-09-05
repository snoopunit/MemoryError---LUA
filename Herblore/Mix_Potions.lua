local API = require("api")
local HERB = require("lib/HERBLORE")

local initialized = false

local function init()
    
    if not initialized then
        HERB.drawGUI()
        initialized = true
    end
end

local function main()

    if not initialized then
        init()
    end
    startHerbloreRoutine()
    
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    main()
    API.RandomSleep2(800, 0, 400)
end----------------------------------------------------------------------------------