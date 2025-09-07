print("Run Lua script Whales_Maw_Fish_Oil.")

local API = require("api")
local FISH = require("lib/FISHING")
local MISC = require("lib/MISC")

function cook()
    print("Making Fish Oil")
    Interact:Object("Camp fire", "Cook at", 50)
    MISC.doCrafting() 
end

function clickYesDialog()
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1183,5,-1,API.OFF_ACT_GeneralInterface_Choose_option)
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    
    if Inventory:IsFull() then

        if (Inventory:GetItemAmount("Raw sillago") >= 3) then
            cook()
        end
        if (Inventory:GetItemAmount("Raw seerfish") >= 6) then 
            cook()
        end
        
        if Inventory:Drop("Burnt seerfish") then
            API.RandomSleep2(800,0,600)
            clickYesDialog()
            API.RandomSleep2(800,0,600)
        end
        if Inventory:Drop("Burnt sillago") then
            API.RandomSleep2(800,0,600)
            clickYesDialog()
            API.RandomSleep2(800,0,600)
        end

    else
        FISH.gather(SPOTS.WALES_MAW)
    end 
end----------------------------------------------------------------------------------