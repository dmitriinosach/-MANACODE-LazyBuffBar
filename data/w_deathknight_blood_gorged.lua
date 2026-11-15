local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.dk_gorged = {
    talent   = 61154,
    tab      = 1,
    ranks    = 5,
    per      = 2,
    line     = 75,
    hysteria = 49016,
    drain    = 1,
    clicks   = {
        { id = 48982, heal = 0.10, talent = 48985, per = 1 / 3 },
        { id = 55233, heal = 0.15, grow = 0.15 },
    },
    gcd      = 1.5,
    warns    = { 3, 5, 10 },
    warn     = 5,
    dim      = 0.35,
}
ns.dkGorgedDataLoaded = true
