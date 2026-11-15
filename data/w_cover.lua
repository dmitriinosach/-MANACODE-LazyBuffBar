local _, ns = ...
ns.widgetData.cover = {
    classes = {
        PRIEST = {
            { key = "fort",   group = 48162, single = 48161, alt = { 72590, 69377 }, reagent = { 44615, 17029 } },
            { key = "spirit", group = 48074, single = 48073, alt = { 54424 }, reagent = { 44615, 17029 }, need = "spirit" },
            { key = "shadow", group = 48170, single = 48169, alt = { 48943 }, reagent = { 44615, 17029 }, watch = false },
        },
        MAGE = {
            { key = "int", group = 43002, single = 42995, alt = { 61316, 61024, 54424 }, reagent = 17020, need = "mana" },
        },
        DRUID = {
            { key = "wild", group = 48470, single = 48469, alt = { 72588, 69381 }, reagent = 44605 },
        },
    },
    needs = {
        mana   = { PALADIN = true, HUNTER = true, PRIEST = true, SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true },
        spirit = { PALADIN = true, PRIEST = true, SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true },
    },
    soon     = 300,
    lines    = 3,
    group    = 2,
}
ns.coverDataLoaded = true
