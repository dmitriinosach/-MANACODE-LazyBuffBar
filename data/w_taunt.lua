local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.taunt = {
    classes = {
        WARRIOR     = { 355 },
        PALADIN     = { 62124 },
        DEATHKNIGHT = { 56222, 49576 },
        DRUID       = { 6795 },
    },
    gcd  = 1.5,
    tick = 1,
    dim  = 0.4,
    tint = { 0.5, 0.5, 1, 1 },
}
ns.tauntDataLoaded = true
