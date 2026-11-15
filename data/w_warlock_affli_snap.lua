local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.warlock_affli_snap = {
    corr   = 47813,
    base   = 1080,
    coef   = 1.2,
    crit   = 1.0,
    school = 6,
    mods   = {
        { id = 70840, pct = 10 },
        { id = 57933, pct = 15 },
        { id = 70867, pct = 100 },
    },
    thr    = 5,
    thrs   = { 3, 5, 10 },
    keep   = 8,
    grace  = 1,
    dim    = 0.35,
}
ns.warlockAffliSnapDataLoaded = true
