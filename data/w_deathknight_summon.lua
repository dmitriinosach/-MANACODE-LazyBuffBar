local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.dk_summon = {
    spells = {
        { id = 49206, last = 30 },
        { id = 49028, last = 12 },
    },
    cost  = 60,
    hero  = { 2825, 32182 },
    buffs = { 2825, 32182, 53365, 49016, 53908 },
    slots = { 13, 14 },
    needs = { 1, 2, 0 },
    need  = 1,
    gcd   = 1.5,
    tick  = 1,
    dim   = 0.6,
    tint  = { 0.5, 0.5, 1, 1 },
}
ns.dkSummonDataLoaded = true
