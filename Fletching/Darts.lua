print("Adamant Darts.")

local API = require("api")
local MISC = require("lib/MISC")

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

TIPS = {
    ADAMANT = "Adamant dart tip"
    RUNE = "Rune dart tip"
}

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    
    if not Inventory:Contains("Feather") then
        API.logWarn("Can't detect any feathers in inventory!")
        API.Write_LoopyLoop(false)
        return
    end

    for _, type in pairs(TIPS) do
        if Inventory:Contains(type) then
            Interact:Object("Portable fletcher", "Ammo", 10)
            MISC.doCrafting()
        end
    end

end----------------------------------------------------------------------------------