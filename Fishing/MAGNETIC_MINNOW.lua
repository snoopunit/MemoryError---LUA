print("FISHING MAGNETIC MINNOWS")

local API = require("api")

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    if API.CheckAnim(50) then
        API.RandomSleep2(600, 0 ,600)
        API.doRandomEvents()
    else
        Interact:NPC("Minnow Shoal", "Catch", 20)
    end
end----------------------------------------------------------------------------------
