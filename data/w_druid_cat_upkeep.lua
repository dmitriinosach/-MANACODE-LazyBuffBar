local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.druid_cat_upkeep = {
    cells = {
        roar   = { id = 52610, auras = { 52610 }, unit = "player", soon = 3, combo = 1 },
        rip    = { id = 49800, auras = { 49800 }, unit = "target", soon = 2, combo = 5 },
        rake   = { id = 48574, auras = { 48574 }, unit = "target", soon = 0 },
        mangle = { id = 48566, auras = { 48566, 48564, 46857 }, unit = "target", soon = 3, any = true },
    },
    order   = { "roar", "rip", "rake", "mangle" },
    form    = 768,
    desync  = 5,
    desyncs = { 0, 3, 5, 8 },
    roarBase = 9,
    roarPer = 5,
    tick    = 0.5,
    dim     = 0.4,
}
ns.druidCatUpkeepDataLoaded = true
