local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.threat = {
    classes = {
        ROGUE   = { { id = 48659 }, { id = 57934, on = "tank" }, { id = 26889 } },
        HUNTER  = { { id = 5384 }, { id = 34477, on = "tank" } },
        MAGE    = { { id = 66 } },
        PRIEST  = { { id = 586 } },
        WARLOCK = { { id = 29858, reagent = 6265 } },
        PALADIN = { { id = 1038, on = "player" } },
        DRUID   = { { id = 48575 } },
    },
    races = {
        NightElf = { { id = 58984 } },
    },
    covers = { 48659, 26889, 5384, 66, 586, 29858, 1038, 48575 },
    at    = 80,
    ats   = { 70, 80, 90 },
    bad   = 95,
    gcd   = 1.5,
    tick  = 1,
    dim   = 0.4,
    under = 0.6,
    icons = { tank = 71, none = 586 },
    bar   = {
        ok   = { 0.3, 0.85, 0.3, 1 },
        soon = { 1, 0.8, 0.1, 1 },
        bad  = { 0.9, 0.2, 0.2, 1 },
        off  = { 0.5, 0.5, 0.5, 1 },
    },
}
ns.threatDataLoaded = true
