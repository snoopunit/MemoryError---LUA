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

local function fd_reflection_check()
    local function projectile()
        return API.ReadAllObjectsArray({5},{2875},{})
    end
    if projectile() then
        API.logWarn("Detected Frost Dragon reflection ability projectile!")
        local cease = API.GetABs_name("Cease")
        if cease and cease.enabled then
            API.DoAction_Ability_Direct(cease, 1, API.OFF_ACT_GeneralInterface_route)
        end
        while projectile() and API.Read_LoopyLoop() do
            API.logDebug("Looping until the projectile is gone!")
            buffCheck()
            healthCheck()
            API.RandomSleep2(600,0,600)
        end
    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)

while API.Read_LoopyLoop() do

    fd_reflection_check()
    API.RandomSleep2(2400, 0, 0)

end