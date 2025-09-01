print("Run Lua script Whales_Maw_Fish_Oil.")

local API = require("api")
local FISH = require("lib/FISHING")
local MISC = require("lib/MISC")

function cook()
    print("Making Fish Oil")
    Interact:Object("Camp fire", "Cook at", 50)
    MISC.doCrafting() 
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    
    if Inventory:IsFull() then
        cook()
    else
        FISH.gather(SPOTS.WALES_MAW)
    end 
end----------------------------------------------------------------------------------
