local API = require("api")

local Mining_Guild_Door = WPOINT:new(3046, 9756, 1)
local Mining_Guild_Door_ID = 2112

local function isInsideMiningGuild()

    local door = API.ReadAllObjectsArray({12}, {Mining_Guild_Door_ID}, {"Door"})

    if not door or #door ~= 1 then
        API.logDebug("Unable to locate Mining Guild Door <object>")
        return false
    end

    local playerCoords = API.PlayerCoord()

    if math.floor(playerCoords.y) > Mining_Guild_Door.y then 
        return false
    else
        return true
    end

end

API.SetMaxIdleTime(4)
API.SetDrawTrackedSkills(true)
API.SetDrawLogs(true)
API.Write_LoopyLoop(true)

while API.Read_LoopyLoop()
do
    print(isInsideMiningGuild())
    API.RandomSleep2(600,0,0)
end