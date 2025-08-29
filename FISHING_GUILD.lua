print("TESTING TEMPLATE")

local API = require("api")
local UTILS = require("UTILS")
local COOK = require("lib/COOKING")
local FISH = require("lib/FISHING")
local MISC = require("lib/MISC")

local Max_AFK = 5

function Fishing_and_Banking(spotType)

    if API.InvFull_() then

        Interact:Object("Bank deposit box", "Deposit-All", 20)

        local bankTimer = API.SystemTime()

        while API.Read_LoopyLoop and (API.SystemTime() - bankTimer) < 30000 do
            
            if API.ReadPlayerMovin() then 
                bankTimer = API.SystemTime()
            end

            if Inventory:IsEmpty() then
                break
            end

        end

        if API.SystemTime() - bankTimer > 30000 then
            API.logWarn("Unable to deposit at the deposit box!")
            API.Write_LoopyLoop(false)
            return
        end

    else

        FISH.gather(spotType)

    end

    API.RandomSleep2(2400, 0 ,600)

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

while(API.Read_LoopyLoop())

do-----------------------------------------------------------------------------------
    Fishing_and_Banking(SPOTS.SHARK)
end----------------------------------------------------------------------------------
