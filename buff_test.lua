print("-----BUFF_TESTING-----")

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
        return #API.ReadAllObjectsArray({5},{2875},{})
    end
    local function cease()
        local ceaseAB = API.GetABs_name("Cease")
        if ceaseAB and ceaseAB.enabled then
            API.DoAction_Ability_Direct(ceaseAB, 1, API.OFF_ACT_GeneralInterface_route)
        end
    end
    if projectile() >= 1 then
        API.logWarn("Detected Frost Dragon reflection ability projectile!")
        while projectile() >= 1 and API.Read_LoopyLoop() do
            API.logDebug("CEASING until the projectile is gone!")
            buffCheck()
            healthCheck()
            cease()
            API.RandomSleep2(6000,0,600)
        end
    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)

while API.Read_LoopyLoop() do

    DumpAllBuffs()
    API.RandomSleep2(2400, 0, 0)

end