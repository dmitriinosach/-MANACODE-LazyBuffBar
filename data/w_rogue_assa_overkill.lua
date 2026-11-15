local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.rogue_assa_overkill = {
    vanish  = 26889,
    windows = {
        { talent = 58426, aura = 58427, win = 20 },
    },
    energy  = { 30, 50, 70 },
    low     = 50,
    gcd     = 1.5,
    tick    = 1,
    dim     = 0.4,
    auraMax = 40,
    bar     = { 1, 0.85, 0.15, 1 },
    win     = { 0.3, 0.85, 0.3, 1 },
}
ns.rogueAssaOverkillDataLoaded = true
