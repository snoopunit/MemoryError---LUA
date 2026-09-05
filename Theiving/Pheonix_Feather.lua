print("Desert Phoenix Thieving script initiated.")

local API = require("api")
local UTILS = require("utils")

local idleTimer = API.SystemTime()
local porterBuffID =  51490

local function pickpocket()
  if Interact:NPC("Desert Phoenix", "Grab-feather", 30) then
    --API.logInfo("Pickpocketing: Druid ")
    API.RandomSleep2(600,0,600)
    API.WaitUntilMovingEnds()
  end
end

local function emergencyTele()
    if UTILS.canUseSkill("War's Retreat Teleport") then
        API.logDebug("Teleport: War's Retreat")
        API.DoAction_Ability("War's Retreat Teleport", 1, API.OFF_ACT_GeneralInterface_route) 
    end  
end

local function hasPorters()
    local porterBuff = API.Buffbar_GetIDstatus(porterBuffID, false)
    if porterBuff and porterBuff.found then
      --API.logDebug("Porters buff found!")
      return true
    else
      --API.logDebug("Porters buff not found!")
      emergencyTele()
      API.Write_LoopyLoop(false)
      return false
    end 
end

local function excalibur()

  local debuff = API.DeBuffbar_GetIDstatus(14632, false) 
    
  if debuff and debuff.found then
    --API.logDebug("Excalibur still on cooldown!")
    return
  end

  if (API.GetHPrecent() > 60) then
    return
  end
  
  if UTILS.canUseSkill("Enhanced Excalibur") then
    
    API.logInfo("Activating Enhanced Excalibur Ability")
    API.DoAction_Ability("Enhanced Excalibur", 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 50, 300)
    
  end
  
end

local function idleCheck()
  if API.CheckAnim(10) then
    idleTimer = API.SystemTime()
    return
  end
  if (API.SystemTime() - idleTimer) > math.random(600,1200) then
    pickpocket()  
    idleTimer = API.SystemTime()
  end  
end

local function healthCheck()
  if API.GetHPrecent() < 10 then
    emergencyTele()
    API.Write_LoopyLoop(false)
  end
end

API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)
API.Write_LoopyLoop(true)

while API.Read_LoopyLoop()
do
  
    healthCheck()
    idleCheck()
    excalibur()
    API.RandomSleep2(600,0,600)
  
end
