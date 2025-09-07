print("Adamant Darts.")

local API = require("api")
local MISC = require("lib/MISC")

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

TIPS = {
    ADAMANT = "Adamant dart tip",
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
            if not Interact:Object("Portable fletcher", "Ammo", 10) then
                Inventory:DoAction(type, 1, API.OFF_ACT_GeneralInterface_route)
            end
            MISC.doCrafting()
        end
    end

end----------------------------------------------------------------------------------