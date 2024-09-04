print("Run Lua script <NAME>.")

local API = require("api")
local UTILS = require("utils")

local do_stuff = false
local do_debug = true

local Min_AFK = 30000
local Max_AFK = 180000

----vars
local AFK_Timer = API.SystemTime()

local antibans = 0

function Check_Timer(int)
    return (API.SystemTime() - int)
end

function antiban()
        
    -- Calculate the time since the last afkTimer reset
    local elapsedTime = Check_Timer(AFK_Timer)
    
    -- Generate a random threshold between minAFK and maxAFK
    local afkThreshold = math.random(Min_AFK, Max_AFK)
    
    -- Check if the elapsed time exceeds the threshold
    if elapsedTime > afkThreshold then
        -- Print the scriptTimer, current elapsedTime, and separators
        antibans = antibans + 1

        -- Perform a random antiban action
        local action = math.random(1, 7)
        if action == 1 then API.PIdle1()
        elseif action == 2 then API.PIdle2()
        elseif action == 3 then API.PIdle22()
        elseif action == 4 then API.KeyboardPress('w', 50, 250)
        elseif action == 5 then API.KeyboardPress('a', 50, 250)
        elseif action == 6 then API.KeyboardPress('s', 50, 250)
        elseif action == 7 then API.KeyboardPress('d', 50, 250)
        end
    
        -- Reset the afkTimer
        AFK_Timer = API.SystemTime()
    end
end

function getEnemies(names)
    local NPCs = {}
    if names then
        NPCs = API.ReadAllObjectsArray({1}, {-1}, names)
    else
        NPCs = API.ReadAllObjectsArray({1}, {-1}, {})
    end
    return NPCs
end

function miniBossCount()
    local miniBoss_Names = {
        "Ahoeitu the Chef",
        "Olivia the Chronicler",
        "Xiang the Water-shaper",
        "Sarkhan the Serpentspeaker",
        "Oyu the Quietest"
    }
    local miniBosses = getEnemies(miniBoss_Names)
    if #miniBosses > 0 then
        print("Mini Bosses:"..tostring(#miniBosses))
        for k, v in pairs(miniBosses) do
            print("Name:"..v.Name.." ID:"..v.Id)
            end
        return #miniBosses
    end
end

function enemyCount(enemy_names)
    local enemies = getEnemies(enemy_names)
    if #enemies > 0 then
        print("Enemies:"..tostring(#enemies))
        return #enemies
    end
end



--main loop
API.Write_LoopyLoop(true)
API.SetDrawTrackedSkills(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if do_debug then
        --API.Dialog_Read_NPC()
        --API.DeBuffbar_GetAllIDs(true)
        --API.Buffbar_GetAllIDs(true)
        local result = inOrOut()
        print(result)
        
       
    end

    if do_stuff then
       
       
    end

    

    antiban()
    API.RandomSleep2(2000, 0, 250)

end----------------------------------------------------------------------------------