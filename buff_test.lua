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

-- Dumps all debuff IDs from the current target's Buff_stack, skipping any -1 entries
function dumpTargetDebuffs()
    local tInfo = API.ReadTargetInfo(true)
    if not tInfo or not tInfo.Buff_stack then
        API.logDebug("No target debuffs found (no target or Buff_stack missing)")
        return
    end

    API.logDebug("=== Target Debuffs Dump ===")

    for i, buff in ipairs(tInfo.Buff_stack) do
        if type(buff) == "number" then
            -- skip numeric -1 sentinels
            if buff ~= -1 then
                API.logDebug(string.format("[%d] ID=%d", i, buff))
            end

        elseif type(buff) == "table" then
            -- read possible id fields
            local raw_id = buff.id or buff.ID
            local num_id = tonumber(raw_id)

            -- skip when id is exactly -1
            if num_id ~= -1 then
                local text = buff.text or buff.conv_text or "?"
                API.logDebug(string.format("[%d] ID=%s | Text=%s", i, tostring(raw_id or "?"), tostring(text)))
            end

        else
            API.logDebug(string.format("[%d] Unexpected buff type: %s", i, type(buff)))
        end
    end
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)

while API.Read_LoopyLoop() do

    dumpTargetDebuffs()
    --DumpAllBuffs()
    API.RandomSleep2(600, 0, 0)

end