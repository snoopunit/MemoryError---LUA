print("Waiko Bamboo.")

local API = require("api")

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    
    if Inventory:IsFull() then

        Inventory:DoAction("Bamboo", 1, offset)

    else

        loadLastPreset()

    end 
end----------------------------------------------------------------------------------