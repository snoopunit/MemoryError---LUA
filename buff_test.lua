local API = require("api")

local BUFFS = {
    PROT_MAGIC = 25959,
    PROT_RANGE = 25960,
    PROT_MELEE = 25961
}

local function getBuff(buffId)
    local buff = API.Buffbar_GetIDstatus(buffId, false)
    remaining = ((buff.found and API.Bbar_ConvToSeconds(buff)) or -1)
    API.logInfo(tostring(buffId.." time remaining: "..tostring(remaining)))
    return remaining
end

local function hasBuff(buff)
    if API.Buffbar_GetIDstatus(buff, false).found then
        API.logInfo("Found buff: "..tostring(buff))
        return true
    else
        return false
    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)

while API.Read_LoopyLoop() do

    hasBuff(BUFFS.PROT_MAGIC)
    hasBuff(BUFFS.PROT_MELEE)
    hasBuff(BUFFS.PROT_RANGE)

    API.logInfo("Prayer%: "..tostring(API.GetPrayPrecent()))
    API.logInfo("Prayer: "..tostring(API.GetPray_()))

    API.RandomSleep2(1200, 0, 0)

end