local API = require("api")

API.SetMaxIdleTime(4)
API.SetDrawTrackedSkills(true)
API.Write_LoopyLoop(true)

while API.Read_LoopyLoop()
do
    Interact:Object("Oak", "Chop down", 30)
    API.RandomSleep2(600,0,0)
end
