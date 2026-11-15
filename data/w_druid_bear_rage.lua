local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.druid_bear_rage = {
    maul     = 48480,
    maulCost = 10,
    clarity  = 16870,
    marks    = { { id = 48564, cost = 15 }, { id = 48568, cost = 13 } },
    dump     = 40,
    steps    = { 30, 40, 50, 60 },
    variants = { bear = true, cat = true },
    demoRage = { solo = 8, party = 35, raid = 55 },
}
ns.druidBearRageDataLoaded = true
