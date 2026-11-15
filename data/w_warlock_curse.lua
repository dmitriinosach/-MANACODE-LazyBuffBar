local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.warlock_curse = {
    el    = 47865,
    agony = 47864,
    doom  = 47867,
    spec  = { affli = "agony", demo = "doom", destro = "doom" },
    soon  = { el = 10, agony = 2, doom = 1.5 },
    gcd   = 1.5,
    tick  = 0.5,
    dim   = 0.35,
}
ns.warlockCurseDataLoaded = true
