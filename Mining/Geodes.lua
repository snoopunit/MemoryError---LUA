local API = require("api")

local function hasGeodes()

    return Inventory:Contains("Sedimentary geode")

end

local function openGeodes()

  local geodeAB = API.GetABs_name("geode", false)

  if geodeAB.action == "Open" and geodeAB.enabled then
    return API.DoAction_Ability_Direct(geodeAB, 1, API.OFF_ACT_GeneralInterface_route)
  end

  return false

end

local function loadLastPreset()
  return Interact:NPC("Banker", "Load Last Preset from", 10)
end


--Exported function list is in API
--main loop
API.Write_LoopyLoop(true)
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(4)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    if not (API.PlayerLoggedIn()) then
        print("Player is not logged in. Terminating Script.")
        API.Write_LoopyLoop(false)
        return     
    end
    
    if Inventory:IsFull() then
        loadLastPreset()
        API.RandomSleep2(600, 0, 600)
    else
        if not hasGeodes() then
            print("Ran out of geodes!")
            API.Write_LoopyLoop(false)
        end
        openGeodes()
    end

    API.RandomSleep2(100, 0, 50)

end----------------------------------------------------------------------------------
