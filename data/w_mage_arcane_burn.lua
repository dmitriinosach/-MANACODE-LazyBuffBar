local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.mage_arcane_burn = {
    evoc     = 12051,
    blast    = 42897,
    missiles = 42846,
    barrage  = 44425,
    ap       = 12042,
    hero     = { 2825, 32182 },
    stack    = 36032,
    stackMin = 3,
    gems     = { 33312, 22044, 8008, 8007, 5513, 5514 },
    gemMana  = 3400,
    evokeAt  = 0.25,
    low      = { ["15"] = 0.15, ["35"] = 0.35 },
    margin   = 10,
    hold     = 2,
    step     = 1,
    samples  = 5,
    execute  = 0.10,
    gcd      = 1.5,
    dim      = 0.4,
    track    = { 0, 0, 0, 0.5 },
}
ns.mageArcaneBurnDataLoaded = true
