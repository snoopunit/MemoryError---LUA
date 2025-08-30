print("FISHING KARAMJA LOBSTER")

local API = require("api")
local FISH = require("lib/FISHING")
local BANK = require("lib/BANKING")

function Fishing_and_Banking(spotType)

    if API.InvFull_() then

        BANK.goTo(BANK.BANKERS.STILES)

        local bankTimer = API.SystemTime()

        while API.Read_LoopyLoop() and (API.SystemTime() - bankTimer) < 30000 do
            
            Interact:NPC("Stiles", "Exchange", 40)

            while API.ReadPlayerMovin() and API.Read_LoopyLoop() do 
                bankTimer = API.SystemTime()
                API.RandomSleep2(2400, 0 ,600)
            end

            if not Inventory:Contains("Raw tuna") and not Inventory:Contains("Raw swordfish") then
                break
            end

        end

        if API.SystemTime() - bankTimer > 30000 then
            API.logWarn("bankTimer exceeded 30s!")
            API.Write_LoopyLoop(false)
            return
        end

    else

        if not FISH.findFishingSpots(spotType) then
            FISH.goTo(spotType)
        end
        FISH.gather(spotType)

    end

    API.RandomSleep2(2400, 0 ,600)

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    Fishing_and_Banking(SPOTS.TUNA_SWORDFISH)
end----------------------------------------------------------------------------------
