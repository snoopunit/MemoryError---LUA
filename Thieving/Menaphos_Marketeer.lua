local API = require("api")
local UTILS = require("utils")

local function pickpocket()
  if Interact:Object("Menaphos Marketeer", "Pickpocket", 30) then
    API.logInfo("Pickpocketing: Menaphos Marketeer")
    API.RandomSleep2(600,0,600)
    API.WaitUntilMovingEnds()
  end
end

local function excalibur()
  if UTILS.canUseSkill("Enhanced Excalibur") then
    if not API.DeBuffbar_GetIDstatus(14632, false).found then
      if (API.GetHPrecent() <= 80) then
        API.logInfo("Activating: Enhanced Excalibur")
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

while API.Read_LoopyLoop()
do
  if API.ReadPlayerAnim() == 0 then
    pickpocket()
  else
    API.RandomSleep2(600,0,600)
  end
end
