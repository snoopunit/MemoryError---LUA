print("Run Lua script <NAME>.")

local API = require("api")
local UTILS = require("utils")
local WC = require("SKILLS.WOODCUTTING")

local do_stuff = true
local do_debug = true

local Max_AFK = 5

--main loop
API.Write_LoopyLoop(true)
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(Max_AFK)

while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------

    if do_debug then
        --API.DeBuffbar_GetAllIDs(true)
        --API.Buffbar_GetAllIDs(true)
        
       
    end

    if do_stuff then
       
        if not API.InvFull_() then
            WC.gather(1,1)
        end
    end

    
end----------------------------------------------------------------------------------