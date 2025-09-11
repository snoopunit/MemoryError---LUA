local API = require("api")

local BUFFS = {
    PROT_MAGIC = 25959,
    PROT_RANGE = 25960,
    PROT_MELEE = 25961
}

function DumpAllBuffs()
    local buffs = API.Buffbar_GetAllIDs(false)
    if not buffs or #buffs == 0 then
        API.logDebug("No buffs found.")
        return
    end
    
    API.logInfo("-------------------------------------")
    for _, buff in ipairs(buffs) do
        if buff and buff.found then
            API.logDebug(string.format("Buff: %s | ID: %d | conv_text: %s",
                tostring(buff.text),
                tonumber(buff.id) or -1,
                tostring(buff.conv_text)))
        end
    end
    API.logInfo("-------------------------------------")
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)

while API.Read_LoopyLoop() do

    DumpAllBuffs()
    API.RandomSleep2(2400, 0, 0)

end