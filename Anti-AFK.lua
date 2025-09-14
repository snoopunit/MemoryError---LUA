local API = require("api")

API.SetMaxIdleTime(4)
API.Write_LoopyLoop(true)

while API.Read_LoopyLoop()
do
    API.RandomSleep2(600,0,0)
end