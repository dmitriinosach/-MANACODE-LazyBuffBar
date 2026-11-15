local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.hunter_md = {
    classes = {
        HUNTER = { id = 34477, armed = 34477, xfer = 35079 },
    },
    order = {
        auto  = { "focus", "tank" },
        tank  = { "tank" },
        tank2 = { "tank2" },
        focus = { "focus" },
    },
    gcd     = 1.5,
    tick    = 1,
    fast    = 0.25,
    dim     = 0.35,
    letters = 4,
}
ns.hunterMdDataLoaded = true
