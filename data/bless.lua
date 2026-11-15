local _, ns = ...
ns.blessData = {
    classes = {
        "WARRIOR", "DEATHKNIGHT", "PALADIN", "ROGUE", "HUNTER",
        "SHAMAN", "DRUID", "PRIEST", "MAGE", "WARLOCK",
    },
    classTex = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes",
    classCoords = {
        WARRIOR     = { 0, 0.25, 0, 0.25 },
        MAGE        = { 0.25, 0.49609375, 0, 0.25 },
        ROGUE       = { 0.49609375, 0.7421875, 0, 0.25 },
        DRUID       = { 0.7421875, 0.98828125, 0, 0.25 },
        HUNTER      = { 0, 0.25, 0.25, 0.5 },
        SHAMAN      = { 0.25, 0.49609375, 0.25, 0.5 },
        PRIEST      = { 0.49609375, 0.7421875, 0.25, 0.5 },
        WARLOCK     = { 0.7421875, 0.98828125, 0.25, 0.5 },
        PALADIN     = { 0, 0.25, 0.5, 0.75 },
        DEATHKNIGHT = { 0.25, 0.49609375, 0.5, 0.75 },
    },
    skip = {
        wisdom = { WARRIOR = true, ROGUE = true, DEATHKNIGHT = true },
        might  = { MAGE = true, WARLOCK = true, PRIEST = true },
    },
    names = 4,
}
