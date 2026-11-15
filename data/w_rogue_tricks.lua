local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.rogue_tricks = {
    classes = {
        ROGUE = { spell = 57934, armed = 57934, transfer = 59628 },
    },
    gcd     = 1.5,
    tick    = 1,
    dim     = 0.4,
    auraMax = 40,
    bar     = { 0.3, 0.85, 0.3, 1 },
    dur     = 6,
}
ns.rogueTricksDataLoaded = true
