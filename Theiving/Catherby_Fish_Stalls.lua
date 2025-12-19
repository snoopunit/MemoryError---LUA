print("Run Lua script Catherby Fish Stalls.")

local API = require("api")

function dropFish()

    local salmon = Inventory:GetItemAmount("Raw salmon")
    local tuna = Inventory:GetItemAmount("Raw tuna")
    local lobster = Inventory:GetItemAmount("Raw lobster")

    if salmon > 0 then
        Inventory:Drop("Raw salmon")
        API.RandomSleep2(800, 0, 250)
    end
    if tuna > 0 then
        Inventory:Drop("Raw tuna")
        API.RandomSleep2(800, 0, 250)
    end
    if lobster > 0 then
        Inventory:Drop("Raw lobster")
        API.RandomSleep2(800, 0, 250)
    end

end

function stealFish() 
    Interact:Object("Fish Stall", "Steal from", 5)
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

    dropFish()
    stealFish()

    API.DoRandomEvents()
    API.RandomSleep2(600, 0, 250)

end----------------------------------------------------------------------------------
