print("Menaphos Marketeer Thieving script initiated.")

local API = require("api")
local UTILS = require("utils")

local function pickpocket()
  if Interact:NPC("Menaphite marketeer", "Pickpocket", 30) then
    --API.logInfo("Pickpocketing: Menaphite marketeer")
    API.RandomSleep2(600,0,600)
    API.WaitUntilMovingEnds()
  end
end

local function excalibur()
  if UTILS.canUseSkill("Enhanced Excalibur") then
    --API.logDebug("Found Enhanced Excalibur Ability")
    if not API.DeBuffbar_GetIDstatus(14632, false).found then
      --API.logDebug("No debuff found!")
      if (API.GetHPrecent() <= 80) then
        API.logInfo("Activating Enhanced Excalibur Ability")
        API.DoAction_Ability("Enhanced Excalibur", 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 50, 300)
      end
    end
  end
end

API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)
API.Write_LoopyLoop(true)

local idleTimer = API.SystemTime()

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

  local thievingSkillXP = API.GetSkillXP("THIEVING")
  if thievingSkillXP >= 814445 then
    API.logInfo("Thieving level 71 reached, stopping script.")
    API.Write_LoopyLoop(false)
    return
  end
  
  idleCheck()
  excalibur()
  API.RandomSleep2(600,0,600)
  
end
