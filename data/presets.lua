local _, ns = ...
local COMBO = { block = "track", k = "widget:combo", view = "a" }
local POISONS = { block = "buffs", k = "widget:poisons", view = "a" }
local TOTEMS = { block = "track", k = "widget:totems", view = "a" }
local MODE = { block = "buffs", k = "widget:mode", view = "one" }
local REMIND = { block = "remind", k = "widget:mode", view = "one", opt = { when = "none", glow = true, label = true } }
local RUNES = { block = "track", k = "widget:runes", view = "pairs" }
local BURST = { block = "track", k = "widget:cds_burst", view = "row" }
local DEFS = { block = "track", k = "widget:cds_defs", view = "row" }
local MINE = { block = "track", k = "widget:mine", view = "row" }
local KICK = { block = "track", k = "widget:kick", view = "one" }
local PET = { block = "buffs", k = "widget:pet", view = "one" }
local COVER = { block = "buffs", k = "widget:cover", view = "row" }
local RAIDBUFFS = { block = "buffs", k = "widget:raidbuffs", view = "buffs", opt = { watch = { "fort", "spirit", "shadow" } } }
local function retCd(id, extra)
    local p = { block = "cds", k = "spell:" .. id, role = "cd" }
    for k, v in pairs(extra or {}) do p[k] = v end
    return p
end
local RET = {
    MODE,
    retCd(31884), retCd(53385), retCd(53408), retCd(35395), retCd(48819), retCd(48801),
    retCd(48806, { rules = { { u = "target", t = "hp", op = "<", v = 20 } } }),
    retCd(10278), retCd(642), retCd(498), retCd(10308), retCd(20066),
}
ns.presetRecipe = {
    rev = 12,
    blocks = {
        { key = "buffs", groups = { "personal", "flask", "food", "raid", "potion" },
          point = { "CENTER", "CENTER", 0, -160 } },
        { key = "track", groups = { "proc", "cd", "gear", "dot" },
          point = { "TOP", "CENTER", 0, -201 } },
        { key = "remind", groups = {}, spare = true,
          point = { "CENTER", "CENTER", 0, -33 }, scale = 1.2, idle = 0.3, fight = 0.5 },
        { key = "cds", groups = {}, spare = true,
          point = { "TOP", "CENTER", 0, -245 }, cols = 7 },
        { key = "expect", groups = { "expect" }, spare = true, beside = "buffs",
          point = { "TOP", "CENTER", 0, -292 } },
    },
    spec = {
        ["ROGUE/assassination"]   = { put = { COMBO, MINE, KICK, POISONS } },
        ["ROGUE/combat"]          = { put = { COMBO, BURST, KICK, POISONS } },
        ["ROGUE/subtlety"]        = { put = { COMBO, BURST, KICK } },
        ["DRUID/balance"]         = { put = { MODE, COVER, REMIND, BURST, MINE } },
        ["DRUID/cat"]             = { put = { COMBO, MODE, COVER, REMIND, BURST, MINE } },
        ["DRUID/bear"]            = { put = { MODE, COVER, REMIND, DEFS, KICK } },
        ["DRUID/resto"]           = { put = { MODE, COVER, REMIND, BURST, MINE } },
        ["SHAMAN/ele"]            = { put = { TOTEMS, MODE, BURST, KICK } },
        ["SHAMAN/enh_phys"]       = { put = { TOTEMS, MODE, BURST, KICK } },
        ["SHAMAN/enh_spell"]      = { put = { TOTEMS, MODE, BURST, KICK } },
        ["SHAMAN/resto"]          = { put = { TOTEMS, MODE, BURST, MINE, KICK } },
        ["WARRIOR/arms"]          = { put = { MODE, BURST, KICK } },
        ["WARRIOR/fury"]          = { put = { MODE, BURST, KICK } },
        ["WARRIOR/prot"]          = { put = { MODE, DEFS, KICK } },
        ["PALADIN/holy"]          = { put = { MODE, BURST, MINE } },
        ["PALADIN/prot_tank"]     = { put = { MODE, DEFS } },
        ["PALADIN/prot_dps"]      = { put = { MODE, BURST } },
        ["PALADIN/ret_agi"]       = { put = RET },
        ["HUNTER/bm"]             = { put = { MODE, PET, BURST, MINE } },
        ["HUNTER/mm"]             = { put = { MODE, PET, BURST, MINE, KICK } },
        ["HUNTER/surv"]           = { put = { MODE, PET, BURST, MINE } },
        ["PRIEST/disc"]           = { put = { RAIDBUFFS, DEFS, MINE } },
        ["PRIEST/holy"]           = { put = { RAIDBUFFS, DEFS, MINE } },
        ["PRIEST/shadow"]         = { put = { MODE, RAIDBUFFS, REMIND, MINE, KICK } },
        ["DEATHKNIGHT/blood_tank"] = { put = { RUNES, MODE, DEFS, MINE, KICK } },
        ["DEATHKNIGHT/blood_str"] = { put = { RUNES, MODE, BURST, MINE, KICK } },
        ["DEATHKNIGHT/blood_agi"] = { put = { RUNES, MODE, BURST, MINE, KICK } },
        ["DEATHKNIGHT/frost"]     = { put = { RUNES, MODE, BURST, MINE, KICK } },
        ["DEATHKNIGHT/unholy"]    = { put = { RUNES, MODE, PET, BURST, MINE, KICK } },
        ["MAGE/arcane"]           = { put = { MODE, COVER, BURST, KICK } },
        ["MAGE/fire"]             = { put = { MODE, COVER, BURST, KICK } },
        ["MAGE/frost"]            = { put = { MODE, COVER, BURST, KICK } },
        ["WARLOCK/affli"]         = { put = { MODE, PET, MINE } },
        ["WARLOCK/demo"]          = { put = { MODE, PET, BURST, MINE } },
        ["WARLOCK/destro"]        = { put = { MODE, PET, MINE } },
    },
}
ns.presetsDataLoaded = true
