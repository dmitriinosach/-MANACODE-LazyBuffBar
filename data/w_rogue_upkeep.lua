local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.rogue_upkeep = {
    cells = {
        snd  = { id = 6774,  aura = 6774,  unit = "player", soon = 3,  finisher = true },
        rup  = { id = 48672, aura = 48672, unit = "target", soon = 2,  finisher = true },
        hfb  = { id = 51662, aura = 63848, unit = "player", soon = 10, bleed = true, keep = true },
        env  = { id = 57993, aura = 57993, unit = "player", soon = 0,  finisher = true, optional = true },
        hemo = { id = 48660, aura = 48660, unit = "target", soon = 3 },
    },
    sets = {
        assassination = { "snd", "rup", "hfb", "env" },
        combat        = { "snd", "rup" },
        subtlety      = { "snd", "rup", "hemo" },
    },
    bleeds = { 48672, 48676, 12721, 47465, 49800, 48574, 48568, 49804, 63468 },
    mine   = { 48672, 48676 },
    soons  = { 2, 3, 5 },
    tick   = 0.5,
    dim    = 0.4,
}
ns.rogueUpkeepDataLoaded = true
