local API = require("api")
local UTILS = require("utils")

local Combat = {}

local MELEE = {
    BASICS = {
        SLICE = {
            --  95 - 115% DMG
            --  +40% if enemy stunned or bound
            --  generates 8% adrenaline
            name = "Slice",
            cd = 3
        },
            --  65 - 75% DMG
            --  STUN/BIND target for 1.2s
            --  generates 8% adrenaline
        BACKHAND = {
            name = "Backhand",
            cd = 15
        }
    },
    THRESHOLDS = {
        SLAUGHTER = {
            --  30 - 40% DMG x5 hits
            --  3x DMG if target moves
            --  consumes 15% adrenaline
            name = "Slaughter"
            cd = 30
            cost = 50
        }
    },
    ULTIMATES = {}
}

return Combat