local API = require("api")
local MISC = require("lib/MISC")

local function invContainsString(string)
    local inv = API.ReadInvArrays33()
    for index, value in ipairs(inv) do
        if string.find(value.textitem, string) then
            return true
        end
    end
    return false
end

local function loadLastPreset()

end

local function cutGems()

end

local function useForge()

end

local function craftNecklaces()

end

local function makePorters()

end

local function mainLoop()

    if invContainsString("Sign of the porter") then
        loadLastPreset()
    elseif invContainsString("Uncut") then
        cutGems()
    elseif invContainsString("Sapphire") 
        or invContainsString("Emerald") 
        or invContainsString("Ruby") 
        or invContainsString("Diamond") 
        or invContainsString("Dragonstone") then
            useForge()
            craftNecklaces()
    elseif invContainsString("necklace") then
        makePorters()

end

API.Write_LoopyLoop(true)
API.SetDrawLogs(true)

while API.Read_LoopyLoop() do

    

    API.RandomSleep2(1200, 0, 0)

end