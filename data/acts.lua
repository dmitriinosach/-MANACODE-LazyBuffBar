local _, ns = ...
local MAGIC = { Magic = true }
local DISEASE = { Disease = true }
local POISON = { Poison = true }
local CURSE = { Curse = true }
ns.actCauses = {
    [527]   = { kind = "dispel", types = MAGIC },
    [988]   = { kind = "dispel", types = MAGIC },
    [528]   = { kind = "dispel", types = DISEASE },
    [552]   = { kind = "dispel", types = DISEASE },
    [4987]  = { kind = "dispel", types = { Magic = true, Disease = true, Poison = true } },
    [1152]  = { kind = "dispel", types = { Disease = true, Poison = true } },
    [526]   = { kind = "dispel", types = { Disease = true, Poison = true } },
    [51886] = { kind = "dispel", types = { Curse = true, Disease = true, Poison = true } },
    [475]   = { kind = "dispel", types = CURSE },
    [2782]  = { kind = "dispel", types = CURSE },
    [8946]  = { kind = "dispel", types = POISON },
    [2893]  = { kind = "dispel", types = POISON },
    [370]   = { kind = "dispel", types = MAGIC },
    [8012]  = { kind = "dispel", types = MAGIC },
    [30449] = { kind = "dispel", types = MAGIC },
    [8129]  = { kind = "mana" },
    [10326] = { kind = "evil" },
    [9484]  = { kind = "undead" },
    [9485]  = { kind = "undead" },
    [10955] = { kind = "undead" },
}
ns.creatureKinds = {
    ["Undead"] = "undead", ["Нежить"] = "undead", ["No-muerto"] = "undead", ["Untoter"] = "undead",
    ["Mort-vivant"] = "undead",
    ["Demon"] = "demon", ["Демон"] = "demon", ["Demonio"] = "demon", ["Dämon"] = "demon", ["Démon"] = "demon",
}
