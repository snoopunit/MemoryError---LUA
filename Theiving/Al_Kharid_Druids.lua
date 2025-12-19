print("Al-Kharid Druid Thieving script initiated.")

local API = require("api")
local UTILS = require("utils")

local idleTimer = API.SystemTime()

local function pickpocket()
  if Interact:NPC("Druid", "Pickpocket", 30) then
    --API.logInfo("Pickpocketing: Druid ")
    API.RandomSleep2(600,0,600)
    API.WaitUntilMovingEnds()
  end
end

local function excalibur()

  local debuff = API.DeBuffbar_GetIDstatus(14632, false) 
    
  if debuff and debuff.found then
    --API.logDebug("Excalibur still on cooldown!")
    return
  end

  if (API.GetHPrecent() <= 60) then
    return
  end
  
  if UTILS.canUseSkill("Enhanced Excalibur") then
    
    API.logInfo("Activating Enhanced Excalibur Ability")
    API.DoAction_Ability("Enhanced Excalibur", 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 50, 300)
    
  end
  
end

API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)
API.Write_LoopyLoop(true)

local function idleCheck()
  if API.CheckAnim(30) then
    idleTimer = API.SystemTime()
    return
  end
  if (API.SystemTime() - idleTimer) > math.random(1600,2400) then
    pickpocket()  
    idleTimer = API.SystemTime()
  end  
end

while API.Read_LoopyLoop()
do
  
  idleCheck()
  excalibur()
  API.RandomSleep2(600,0,600)
  
end
