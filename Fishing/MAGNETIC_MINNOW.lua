print("FISHING MAGNETIC MINNOWS")

local API = require("api")

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    if API.CheckAnim(50) then
        API.RandomSleep2(2400, 0 ,600)
        API.DoRandomEvents()
        API.logDebug("Magnetic minnows: "..tostring(Inventory:GetItemAmount("Magnetic minnow")))
    else
        Interact:NPC("Minnow shoal", "Catch", 20)
    end
end----------------------------------------------------------------------------------
