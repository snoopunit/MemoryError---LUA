print("FISHING KARAMJA LOBSTER")

local API = require("api")
local FISH = require("lib/FISHING")
local BANK = require("lib/BANKING")

function Fishing_and_Banking(spotType)

    if API.InvFull_() then

        BANK.goTo(BANKERS.STILES)

        Interact:NPC("Stiles", "Exchange", 30)

        local bankTimer = API.SystemTime()

        while API.Read_LoopyLoop and (API.SystemTime() - bankTimer) < 30000 do
            
            if API.ReadPlayerMovin() then 
                bankTimer = API.SystemTime()
            end

            --Check we don't have any more (un-noted Raw Lobster) ID: 377
            if not Inventory:Contains(377) then
                break
            end

        end

        if API.SystemTime() - bankTimer > 30000 then
            API.logWarn("Unable to deposit at the deposit box!")
            API.Write_LoopyLoop(false)
            return
        end

    else

        if not FISH.findFishingSpots(SPOTS.LOBSTER) then
            FISH.goTo(SPOTS.LOBSTER)
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
    Fishing_and_Banking(SPOTS.LOBSTER)
end----------------------------------------------------------------------------------
