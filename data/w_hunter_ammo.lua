local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.hunter_ammo = {
    slot     = 0,
    ranged   = 18,
    locs     = { INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true },
    low      = 2000,
    lows     = { 1000, 2000, 4000 },
    part     = 0.25,
    tick     = 1,
    minFight = 20,
    icon     = "Interface\\Icons\\INV_Ammo_Arrow_02",
    numFont  = 0.42,
    subFont  = 0.28,
}
ns.hunterAmmoDataLoaded = true
