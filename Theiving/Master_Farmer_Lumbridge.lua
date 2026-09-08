print("Lumbridge Master Farmer Thieving script initiated.")

local API = require("api")

local levelToStop = 50 -- thieving level to stop the script at

local idleTimer = API.SystemTime()

local function pickpocket()
  if Interact:NPC("Master farmer", "Pickpocket", 30) then
    --API.logInfo("Pickpocketing: Master farmer")
    API.RandomSleep2(600,0,600)
    API.WaitUntilMovingEnds()
  end
end

local function loadLastPreset()

    local failCount = 0

    while Inventory:IsFull() and API.Read_LoopyLoop() do

        if not API.ReadPlayerMovin2() then
            if Interact:Object("Bank chest", "Load Last Preset from", 30) then
                API.logDebug("Loading last preset...")
                API.RandomSleep2(600,0,600)
                API.WaitUntilMovingEnds()
            else
                API.logDebug("Unable to interact with Bank chest!")
                failCount = failCount + 1
            end    
        end

        API.RandomSleep2(1200,0,600)

        if not Inventory:IsFull() then
            failCount = failCount + 1
        end
        
        if failCount > 10 then
            API.logWarn("loadLastPreset() failCount = "..tostring(failCount).."!")
            API.Write_LoopyLoop(false)
            return
        end

        
    end

end

local function invCheck()
  if Inventory:IsFull() then
    loadLastPreset()
  end
end

local function lvlCheck() 
    local thievingSkillXP = API.GetSkillXP("THIEVING")
    if thievingSkillXP >= API.XPForLevel(levelToStop) then
      API.logInfo("Thieving level "..tostring(levelToStop).." reached, stopping script.")
      API.Write_LoopyLoop(false)
      return
    end  
end

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

API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)
API.Write_LoopyLoop(true)

while API.Read_LoopyLoop()
do
  
  lvlCheck()
  invCheck()
  idleCheck()
  API.RandomSleep2(600,0,600)
  
end
