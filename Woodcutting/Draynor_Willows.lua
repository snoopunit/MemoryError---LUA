print("Draynor Willows.")

local API = require("api")
local WC = require("lib/WOODCUTTING")

local Willow_Logs_ID = 1519
local canFillBox = true
local init = false
local startTime = API.SystemTime()
local timeToQuit = math.random(3600000, 7200000) -- Random time between 1 and 2 hours in milliseconds


local function useBank()
    return Interact:NPC("Banker", "Bank", 30)
end

local function doBanking()
  
    while not Bank:IsOpen() and API.Read_LoopyLoop() do
        if not API.ReadPlayerMovin2() then
            if not useBank() then
                API.logWarn("Unable to interact with banker!")
                API.Write_LoopyLoop(false)
                return
            end
        else
            API.RandomSleep2(600,0,600)
        end    
    end
    API.RandomSleep2(1200,0,1200)
  
    if not Bank:DepositAll(Willow_Logs_ID) then
      API.logWarn("Unable to deposit logs!")
      API.Write_LoopyLoop(false)
      return
    end
    API.RandomSleep2(1200,0,1200)
  
    if not Bank:WoodBoxDepositLogs() then
      API.logWarn("Unable to deposit woodbox logs!")
      API.Write_LoopyLoop(false)
      return
    end
    API.RandomSleep2(1200,0,1200)
    
end

local function chopWillows()
  return WC.chop()
end

local function fillWoodBox()
    
  local ability = API.GetABs_name("ood box", false)
    
  if ability.action == "Fill" and ability.enabled then
        
    API.DoAction_Ability_Direct(ability, 1, API.OFF_ACT_GeneralInterface_route)
        
  end
    
  API.RandomSleep2(1200,0,400)
    
  if Inventory:GetItemAmount("Willow logs") > 0 then
        
    return false
        
  end
    
  return true
    
end

local function initialize()
    WC.GLOBALS.treeType = TREES.WILLOW
    WC.GLOBALS.logType = LOGS.WILLOW
end

function timeToStop()
    local elapsedTime = (API.SystemTime() - startTime)

    if elapsedTime > timeToQuit then
        print(tostring(math.floor(timeToQuit / 3600000)) .. " hours have passed. Terminating Script.")
        API.Write_LoopyLoop(false)
        return true
    end

    return false
end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if not init then
        initialize()
    end

    if Inventory:IsFull() then

        doBanking()
        timeToStop()
        canFillBox = true

    else
  
        if not API.CheckAnim(15) then
            if not chopWillows() then
              API.logWarn("Unable to interact with Willow Trees!")
              API.Write_LoopyLoop(false)
              return
            end
        end
  
        if Inventory:FreeSpaces() <= math.random(1,16) and canFillBox then
            if not fillWoodBox() then
                canFillBox = false
            end
        end
    
    end 

    API.RandomSleep2(600,0,2400)

end----------------------------------------------------------------------------------
