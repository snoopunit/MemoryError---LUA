print("Run Lua script Catherby Fish Stalls.")

local API = require("api")

function dropOres()

    local salmon = Inventory:GetItemAmount("Runite ore")
    local tuna = Inventory:GetItemAmount("Luminite")

    if salmon > 0 then
        Inventory:Drop("Runite ore")
        API.RandomSleep2(800, 0, 250)
    end
    if tuna > 0 then
        Inventory:Drop("Luminite")
        API.RandomSleep2(800, 0, 250)
    end

end

function pickLock() 
   return Interact:Object("Chest", "Pick lock", 15)
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

--main loop
API.Write_LoopyLoop(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if not (API.PlayerLoggedIn()) then
        print("Player is not logged in. Terminating Script.")
        return      
    end

    API.logDebug("Player anim: " .. tostring(API.ReadPlayerAnim()))

    if API.ReadPlayerAnim() == 0 then
        if not pickLock() then
            print("Failed to pick lock. Terminating Script.")
            return
        end
        API.RandomSleep2(1200, 0, 250)
        API.WaitUntilMovingEnds(3,10)
    end

    dropOres()

    API.DoRandomEvents()
    API.RandomSleep2(600, 0, 250)

end----------------------------------------------------------------------------------
