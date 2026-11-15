local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.war_rage = {
    hero      = 47450,
    cleave    = 47520,
    queueCost = { hero = 15, cleave = 20 },
    marks = {
        arms = { { id = 47486, cost = 30 }, { id = 47475, cost = 15 } },
        fury = { { id = 23881, cost = 20 }, { id = 1680, cost = 25 } },
        prot = { { id = 47488, cost = 20 }, { id = 47498, cost = 15 } },
    },
    dump    = { arms = 60, fury = 50, prot = 50 },
    steps   = { 40, 50, 60, 70, 80 },
    color   = { 0.78, 0.18, 0.18, 1 },
    numFont = 0.5,
}
ns.warRageDataLoaded = true
