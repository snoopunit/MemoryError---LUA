local API = require("api")

-- ========= Helpers =========
local function safeErr(e)
    if type(e) == "string" then return e end
    if type(e) == "table" and e.message then return tostring(e.message) end
    return tostring(e)
end

local function parseDuration(text)
    if not text then return 0 end
    local m, s = text:match("(%d+):(%d+)")
    if m and s then return tonumber(m) * 60 + tonumber(s) end
    local n = text:match("(%d+)%s*s")
    if n then return tonumber(n) end
    return 0
end

local function nowMs()
    return API.SystemTime()
end

local function areWefighting()
    return API.IsTargeting() and API.CheckAnim(25)
end

local function noteFrostDragonBones()
    if not noteItems then
        return
    end
    if API.Invfreecount_() < math.random(1,8) then
        if not Inventory:Contains(30372) and not Inventory:Contains(43045) then
            API.logWarn("[Note] No notepaper.")
            return false
        end

        if not Inventory:Contains(18832) then
            return false
        else
            API.DoAction_DontResetSelection()
            if Inventory:Contains(30372) then
                Inventory:UseItemOnItem(18832, 30372)
            elseif Inventory:Contains(43045) then
                Inventory:UseItemOnItem(18832, 43045)
            else
                API.logWarn("[Note] No notepaper.")
                return false
            end
        end
    end
end

-- ========= State =========
local running = true
local lastStep = "init"
local lastGcdEnd = 0
local scheduler = {}
local startTime = API.SystemTime()
local kills = 0
local primaryTargetName = nil
local scanInterval = 1800
local lastScanTime = 0
local useAoE = true
local isFirstTarget = true
local priorityList = {["Frost Dragon"] = 1}
local priosSorted = false
local _targetSettledAt = 0
local _settleDelayMs = 120
local _postTargetSleepUntil = 1800
local pendingCast = false
local pendingUntil = 600
local gcd = 1.8

local trackedBuffIDs = {
    necrosis        = 30101,
    residualSouls   = 30123,
    skeletonWarrior = 34177,
    vengefulGhost   = 34178,
    putridZombie    = 34179,
    phantomGuardian = 34180,
}
local enemyDebuffIDs = {
    immune_poison = 30094,
    immune_stun = 26104,
    haunted = 30212,
    bloated = 30098
}

local abilities = {
    --[["Touch of Death"]] = {
        adrenaline = 9,
        cd = 14400,
        lastUsed = -1e12,
        expectedValue = function()
            if API.GetAddreline_() == 100 then return 0.0 end
            local nec = getBuff("necrosis")
            local stacks = (nec and nec.stacks) or 0
            if stacks < 6 then
                API.logDebug("ToD #Stacks: "..tostring(stacks))
                return 7.5
            else
                return 0.5
            end
        end
    },
    --[["Soul Sap"]] = {
        adrenaline = 9,
        cd = 5400,
        lastUsed = -1e12,
        expectedValue = function()
            if API.GetAddreline_() == 100 then return 0.0 end
            local rs = getBuff("residualSouls")
            local stacks = (rs and rs.stacks) or 0
            if stacks < 3 then
                API.logDebug("Soul Sap #Stacks: "..tostring(stacks))
                return 6.0
            else
                return 0.0
            end
        end
    },
    ["Finger of Death"] = {
        adrenaline = -60,
        lastUsed   = -1e12,
        expectedValue = function()
            local nec = getBuff("necrosis")
            local stacks = (nec and nec.stacks) or 0
            if stacks >= 6 then return 10.0 else return 0.0 end
        end
    },
    ["Volley of Souls"] = {
        adrenaline = 0,
        lastUsed = -1e12,
        expectedValue = function()
            local rs = getBuff("residualSouls")
            local stacks = (rs and rs.stacks) or 0
            if stacks == 3 then return 9.0 else return 0.0 end
        end
    },
    ["Bloat"] = {
        adrenaline = -20,
        cd = 60000,
        lastUsed = -1e12,
        expectedValue = function()
            if not useAoE then return 0.0 end
            if targetHasDebuff(enemyDebuffIDs.bloated) then return 0.0 else return 9.5 end
        end
    },
    ["Soul Strike"] = {
        adrenaline = 0,
        lastUsed = -1e12,
        expectedValue = function()
            if targetHasDebuff(enemyDebuffIDs.immune_stun) then return 0.0 end
            if not useAoE then return 0.0 end
            local rs = getBuff("residualSouls")
            local stacks = (rs and rs.stacks) or 0
            if stacks < 1 then return 0.0 end
            return 2.5
        end
    },
    ["Death Skulls"] = {
        adrenaline = -100,
        cd = 60000,
        lastUsed = -1e12,
        expectedValue = function()
            if not useAoE then return 0.0 end
            if API.GetAddreline_() < 100 then return 0.0 end
            local t = nowMs()
            local desc = abilities["Death Skulls"]
            if desc and (t - desc.lastUsed < (desc.cd or 0)) then return 0.0 end
            return 10.0
        end
    },
    ["Living Death"] = {
        adrenaline = -100,
        cd = 90000,
        lastUsed = -1e12,
        expectedValue = function()
            if API.GetAddreline_() < 100 then return 0.0 end
            local t = nowMs()
            local desc = abilities["Living Death"]
            if desc and (t - desc.lastUsed < (desc.cd or 0)) then return 0.0 end
            if isAbilityReady("Death Skulls") and useAoE then return 0.0 end
            return 9.0
        end,
        onCast = function()
            local t = nowMs()
            if abilities["Death Skulls"] then
                abilities["Death Skulls"].lastUsed = -1e12
                abilities["Death Skulls"].cd = 12000
            end
            if abilities["Touch of Death"] then
                abilities["Touch of Death"].lastUsed = -1e12
            end
            schedule(30000, function()
                if abilities["Death Skulls"] then
                    abilities["Death Skulls"].cd = 60000
                end
            end)
            API.logDebug("Living Death cast: DS/ToD reset, DS cd reduced to 12s for 30s")
        end
    },
    --[["Conjure Skeleton Warrior"]] = {
        adrenaline = 0,
        lastUsed = -1e12,
        expectedValue = function()
            return hasConjure("skeletonWarrior") and 0.0 or 1.8
        end
    },
    ["Command Skeleton Warrior"] = {
        adrenaline = 0,
        cd = 15000,
        lastUsed = -1e12,
        expectedValue = function()
            if isAbilityReady("Command Skeleton Warrior") then return 3.5 end
            return 0.0
        end
    },
    --[["Conjure Putrid Zombie"]] = {
        adrenaline = 0,
        lastUsed = -1e12,
        expectedValue = function()
            return hasConjure("putridZombie") and 0.0 or 1.8
        end
    },
    --[["Command Putrid Zombie"]] = {
        adrenaline = 0,
        cd = 15000,
        lastUsed = -1e12,
        expectedValue = function()
            if hasConjure("putridZombie") and isAbilityReady("Command Putrid Zombie") then return 1.5 end
            return 0.0
        end
    },
    --[["Conjure Vengeful Ghost"]] = {
        adrenaline = 0,
        lastUsed = -1e12,
        expectedValue = function()
            return hasConjure("vengefulGhost") and 0.0 or 1.8
        end
    },
    ["Command Vengeful Ghost"] = {
        adrenaline = 0,
        cd = 15000,
        lastUsed = -1e12,
        expectedValue = function()
            if isAbilityReady("Command Vengeful Ghost") then return 4.0 else return 0.0 end
        end
    },
    --[["Conjure Phantom Guardian"]] = {
        adrenaline = 0,
        lastUsed = -1e12,
        expectedValue = function()
            return hasConjure("phantomGuardian") and 0.0 or 1.8
        end
    },
    --[["Command Phantom Guardian"]] = {
        adrenaline = 0,
        cd = 15000,
        lastUsed = -1e12,
        expectedValue = function()
            if hasConjure("phantomGuardian") and isAbilityReady("Command Phantom Guardian") then return 3.0 end
            return 0.0
        end
    },
    ["Spectral Scythe"] = {
        adrenaline = -10,
        cd = 15000,
        lastUsed = -1e12,
        stage = 0,
        stageExpire = 0,
        expectedValue = function()
            local desc = abilities["Spectral Scythe"]
            if not useAoE then return 0.0 end
            local rs = getBuff("residualSouls")
            local stacks = (rs and rs.stacks) or 0
            if stacks >= 3 then return 0.0 end
            if nowMs() > desc.stageExpire then desc.stage = 0 end
            if desc.stage == 0 then return 2.5 elseif desc.stage == 1 then return 3.0 elseif desc.stage == 2 then return 3.5 end
            return 0.0
        end,
        onCast = function()
            local desc = abilities["Spectral Scythe"]
            local t = nowMs()
            if t > desc.stageExpire then desc.stage = 0 end
            if desc.stage < 2 then
                desc.stage = desc.stage + 1
                desc.stageExpire = t + 15000
            else
                desc.stage = 0
                desc.lastUsed = t
                desc.stageExpire = 0
            end
        end
    },
    ["Conjure Undead Army"] = {
        adrenaline = 0,
        cd = 60000,
        lastUsed = -1e12,
        expectedValue = function()
            if isSkillQueued("Conjure Undead Army") then return 0.0 end
            if hasAnyConjure() then return 0.0 else return 11.0 end
        end
    },
    ["Blood Siphon"] = {
        adrenaline = 0,
        cd = 45000,
        lastUsed = -1e12,
        expectedValue = function()
            local hp = API.GetHPrecent()
            if hp >= 70 then return 0.0 else return 7.5 end
        end,
        onCast = function()
            local t = nowMs()
            pendingCast  = "Blood Siphon"
            pendingUntil = t + 6000
            API.logDebug("[Blood Siphon] Channeling for 6000ms")
        end
    },
    ["Death Grasp"] = {
        adrenaline = -25,
        cd = 30000,
        lastUsed = -1e12,
        expectedValue = function()
            if targetHasDebuff(enemyDebuffIDs.immune_stun) then return 0.0 end
            local nec = getBuff("necrosis")
            local stacks = (nec and nec.stacks) or 0
            if stacks >= 2 and stacks <= 5 then return 9.0 elseif stacks >= 6 then return 0.0 end
            return 0.0
        end
    },
    ["Eat Food"] = {
        adrenaline = 0,
        lastUsed = -1e12,
        expectedValue = function()
            local hp = API.GetHPrecent()
            if hp >= 40 then return 0.0 else return 11.0 end
        end
    },
}

-- ========= Priority Sorting =========
local function rebuildPriosIfNeeded()
    if priosSorted then return end
    local prios = {}
    for name, weight in pairs(priorityList) do
        if type(weight) == "number" then
            prios[#prios+1] = { name = name, weight = weight }
        else
            API.logWarn("[rebuildPriosIfNeeded] Priority for '"..tostring(name).."' is not a number! ("..type(weight)..")")
        end
    end
    table.sort(prios, function(a,b) return a.weight < b.weight end)
    priosSorted = prios
end

-- ========= Buffs =========
function parseBbar(bbar)
    if not bbar or not bbar.found then return { found=false, stacks=0, raw=nil, duration=0 } end
    local raw = (type(bbar.text) == "string") and bbar.text or ""
    local duration = parseDuration(raw)
    local n = raw:match("x%s*(%d+)") or raw:match("(%d+)%s*st") or raw:match("(%d+)")
    local stacks = n and tonumber(n) or 0
    return { found=true, stacks=stacks, raw=raw, duration=duration }
end

function getBuff(name)
    local id = trackedBuffIDs[name]
    if not id then return nil end
    local ok, b = pcall(function() return API.Buffbar_GetIDstatus(id, false) end)
    if ok and b then return parseBbar(b) else return nil end
end

function hasAnyConjure()
    return (getBuff("skeletonWarrior").found)
        or (getBuff("vengefulGhost").found)
        or (getBuff("putridZombie").found)
        or (getBuff("phantomGuardian").found)
end

function hasConjure(name)
    local b = getBuff(name)
    return b and b.found or false
end

function targetHasDebuff(id)
    if not API.IsTargeting() then return false end
    local tInfo = API.ReadTargetInfo(true)
    if not tInfo or type(tInfo.Buff_stack) ~= "table" then return false end
    for _, buffId in ipairs(tInfo.Buff_stack) do
        if buffId == id then return true end
    end
    return false
end

-- ========= Scheduler =========
function schedule(delayMs, job)
    table.insert(scheduler, { time = nowMs() + (delayMs or 0), job = job })
end

function processScheduler()
    local t = nowMs()
    for i = #scheduler, 1, -1 do
        local item = scheduler[i]
        if t >= item.time then
            local ok, err = pcall(item.job)
            if not ok then API.logWarn("[Scheduler] Job error: " .. safeErr(err)) end
            table.remove(scheduler, i)
        end
    end
end

-- ========= Targeting =========
function acquireTargetIfNeeded()
    lastStep = "targeting_or_planning"
    if API.IsTargeting() then return end
    if not priosSorted or #priosSorted == 0 then
        API.logWarn("[Targeting] Priority list is empty! No targets will be acquired.")
        return
    end
    local t = nowMs()
    if t - (lastScanTime or 0) < (scanInterval) then return end
    if t < (_targetSettledAt or 0) then return end
    lastScanTime = t
    local startTime = t
    local bestNpc, bestName, bestDist = nil, nil, 1e9
    for _, entry in ipairs(priosSorted) do
        local npcs = API.ReadAllObjectsArray({1}, {-1}, {entry.name})
        if npcs and #npcs > 0 then
            for i = 1, math.min(#npcs, 50) do
                local npc = npcs[i]
                if npc and npc.Life and npc.Life > 0 then
                    local d = npc.Distance
                    if d < 50 and d < bestDist then
                        bestNpc, bestName, bestDist = npc, entry.name, d
                        if d < 6 then break end
                    end
                end
            end
            if bestNpc then break end
        end
    end
    if not bestNpc then
        API.logDebug("[Targeting] No valid NPCs found. Check priority list and NPC names.")
        return
    end
    local ok, attacked = pcall(function()
        return API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, bestNpc)
    end)
    local elapsed = nowMs() - startTime
    if ok and attacked then
        API.logInfo(("[ENGINE] Engaging: %s @%.1fm took %dms"):format(bestName, bestDist, elapsed))
        primaryTargetName = bestName
        if isFirstTarget then isFirstTarget = false else kills = kills + 1 end
        _targetSettledAt = nowMs() + _settleDelayMs
        _postTargetSleepUntil = nowMs() + 2000
    elseif not ok then
        API.logWarn("[Targeting ERROR] C++ crash during targeting of: " .. tostring(bestName))
    else
        API.logDebug("Attack failed on: " .. tostring(bestName) .. " | time " .. elapsed .. "ms")
    end
end

-- ========= Ability Casting =========
function getAbilityBar(name)
    local ab = API.GetABs_name(name, true)
    if not ab then API.logWarn("[getAbilityBar] No bar data for '" .. tostring(name) .. "'") return nil end
    local abType = type(ab)
    if abType ~= "table" and abType ~= "userdata" then API.logWarn("[getAbilityBar] For ability '" .. tostring(name) .. "', got invalid type: " .. abType .. ", value: " .. tostring(ab)) return nil end
    local hasSlot = ab.slot ~= nil
    local hasId = ab.id ~= nil
    local hasName = ab.name ~= nil
    if not (hasSlot and hasId and hasName) then API.logWarn("[getAbilityBar] For ability '" .. tostring(name) .. "', got type '" .. abType .. "' but missing Abilitybar fields") return nil end
    return ab
end

function isAbilityReady(name)
    local ab = getAbilityBar(name)
    local desc = abilities[name]
    if not ab or not desc then return false end
    local abType = type(ab)
    if abType ~= "table" and abType ~= "userdata" then API.logWarn("[isAbilityReady] For ability '" .. tostring(name) .. "', got invalid type: " .. abType) return false end
    local hasSlot = ab.slot ~= nil
    local hasId = ab.id ~= nil
    local hasName = ab.name ~= nil
    if not (hasSlot and hasId and hasName) then API.logWarn("[isAbilityReady] For ability '" .. tostring(name) .. "', got type '" .. abType .. "' but missing Abilitybar fields") return false end
    if ab.enabled == false then return false end
    if ab.cooldown_timer and ab.cooldown_timer > 0 then return false end
    local t = nowMs()
    if t - desc.lastUsed < (desc.cd or 0) then return false end
    if t < lastGcdEnd then return false end
    return true
end

function castAbility(name)
    if not name then API.logWarn("[castAbility] Ability name is nil") return end
    local ab = getAbilityBar(name)
    local desc = abilities[name]
    if not ab or not desc then API.logWarn("[castAbility] Missing data for ability: " .. tostring(name)) return end
    local abType = type(ab)
    if abType ~= "table" and abType ~= "userdata" then API.logWarn("[castAbility] For ability '" .. tostring(name) .. "', got invalid type: " .. abType) return end
    local hasSlot = ab.slot ~= nil
    local hasId = ab.id ~= nil
    local hasName = ab.name ~= nil
    if not (hasSlot and hasId and hasName) then API.logWarn("[castAbility] For ability '" .. tostring(name) .. "', got type '" .. abType .. "' but missing Abilitybar fields") return end
    local t = nowMs()
    if pendingCast == name and t < pendingUntil then return end
    if not isAbilityReady(name) then return end
    local success, result = pcall(function() return API.DoAction_Ability_Direct(ab, 1, API.OFF_ACT_GeneralInterface_route) end)
    if not success then API.logWarn("[castAbility] C++ crash in DoAction for: " .. name) return end
    if result then
        pendingCast = name
        pendingUntil = t + 600
        desc.lastUsed = t
        lastGcdEnd = t + math.floor(gcd * 1000)
        if desc.onCast then
            local ok, err = pcall(function() desc.onCast() end)
            if not ok then API.logWarn("[castAbility] onCast error for " .. name .. ": " .. safeErr(err)) end
        end
    else
        API.logWarn("[ENGINE] DoAction failed for: " .. name)
    end
end

function planAndQueue()
    if not API.IsTargeting() then return end
    if pendingCast and nowMs() < pendingUntil then return end
    local bestName, bestScore = nil, -math.huge
    for name, desc in pairs(abilities) do
        local ab = getAbilityBar(name)
        if ab and isAbilityReady(name) then
            local score = (desc.expectedValue and desc.expectedValue()) or 0
            if score > bestScore then bestScore, bestName = score, name end
        end
    end
    if bestName and bestScore > 0 then
        API.logInfo("[ENGINE] Scheduling cast: " .. bestName .. " | score: " .. tostring(bestScore))
        schedule(0, function() castAbility(bestName) end)
    else
        API.logDebug("[ENGINE] No positive-EV ability to cast this tick.")
    end
end

-- ========= Main Loop =========
local tickCount = 0
local maxTicks = 1000 -- or set to desired number of iterations
while running and tickCount < maxTicks do
    tickCount = tickCount + 1
    -- Reset pending if ability shows cooldown now
    lastStep = "check_pending_cast"
    if pendingCast then
        local ab = getAbilityBar(pendingCast)
        if ab and ab.cooldown_timer and ab.cooldown_timer > 0 then
            pendingCast = nil
            pendingUntil = 0
        elseif nowMs() > pendingUntil then
            pendingCast = nil
            pendingUntil = 0
        end
    end
    if _postTargetSleepUntil and nowMs() < _postTargetSleepUntil then goto continue end
    lastStep = "targeting_or_planning"
    if areWefighting() then
        local ok, err = pcall(function() planAndQueue() end)
        if not ok then API.logWarn(err) running = false end
    else
        local ok, err = pcall(function() acquireTargetIfNeeded() end)
        if not ok then API.logWarn(err) running = false end
    end
    local ok, err = pcall(function() processScheduler() end)
    if not ok then API.logWarn("[update] Scheduler error: " .. safeErr(err)) running = false end
    noteFrostDragonBones()
    ::continue::
end

API.logInfo("[ENGINE] Stopped.")
