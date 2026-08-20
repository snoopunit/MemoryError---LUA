print("Crayfish Lumbridge")

local API = require("api")
local FISH = require("lib/FISHING")
local BANK = require("lib/BANKING")

function Fishing_and_Banking(spotType)

    if Inventory:IsFull() then

        BANK.goTo(BANK.BANKERS.LUMBRIDGE_BANK_CHEST)

        local bankTimer = API.SystemTime()

        while API.Read_LoopyLoop() and (API.SystemTime() - bankTimer) < 30000 do
            
            Interact:Object("Bank chest", "Load Last Preset from", 60)

            while API.ReadPlayerMovin() and API.Read_LoopyLoop() do 
                bankTimer = API.SystemTime()
                API.RandomSleep2(2400, 0 ,600)
            end

            --Check we don't have any more items in inventory
            if Inventory:IsEmpty() then
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
    Fishing_and_Banking(SPOTS.CRAYFISH)
end----------------------------------------------------------------------------------
