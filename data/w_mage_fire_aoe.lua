local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.mage_fire_aoe = {
    ranks   = { 42926, 42925 },
    last    = 8,
    fs      = 54741,
    talent  = 44442,
    wave    = 42945,
    breath  = 42950,
    gcd     = 1.5,
    warns   = { 1, 2 },
    tick    = 0.5,
    dim     = 0.45,
    debuffs = 40,
    left    = { 1, 0.5, 0.1, 0.9 },
    gone    = { 0, 0, 0, 0.75 },
}
ns.mageFireAoeDataLoaded = true
