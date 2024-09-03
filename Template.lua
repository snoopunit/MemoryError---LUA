print("Run Lua script <NAME>.")

local API = require("api")
local UTILS = require("utils")

local do_stuff = false
local do_debug = true

local Min_AFK = 30000
local Max_AFK = 180000

local AFK_Timer = API.SystemTime()

function Check_Timer(int)
    return (API.SystemTime() - int)
end
function antiban()
    local elapsedTime = Check_Timer(AFK_Timer)
    local afkThreshold = math.random(Min_AFK, Max_AFK)
    if elapsedTime > afkThreshold then
        local eTime = tostring(math.floor(Check_Timer(AFK_Timer)/1000).."s")       
        local action = math.random(1, 7)
        if action == 1 then API.PIdle1()
        elseif action == 2 then API.PIdle2()
        elseif action == 3 then API.PIdle22()
        elseif action == 4 then API.KeyboardPress('w', 50, 250)
        elseif action == 5 then API.KeyboardPress('a', 50, 250)
        elseif action == 6 then API.KeyboardPress('s', 50, 250)
        elseif action == 7 then API.KeyboardPress('d', 50, 250)
        end
        AFK_Timer = API.SystemTime()
    end
end

--main loop
API.Write_LoopyLoop(true)
API.SetDrawTrackedSkills(true)
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if do_debug then
        API.Buffbar_GetAllIDs(true)
        --API.DeBuffbar_GetAllIDs(true)
        
    end

    if do_stuff then
           
       
    end
    
    

    antiban()
    API.RandomSleep2(5000, 0, 250)

end----------------------------------------------------------------------------------