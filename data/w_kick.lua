local _, ns = ...
local S = ns.STATE
ns.widgetData = ns.widgetData or {}
ns.widgetData.kick = {
    classes = {
        ROGUE       = { { id = 1766 } },
        WARRIOR     = { { id = 6552, stance = 2458 }, { id = 72 } },
        SHAMAN      = { { id = 57994 } },
        DEATHKNIGHT = { { id = 47528 }, { id = 47476 } },
        MAGE        = { { id = 2139 } },
        PRIEST      = { { id = 15487 } },
        HUNTER      = { { id = 34490 } },
        PALADIN     = { { id = 48827, alt = { 48826, 32700, 32699, 31935 }, talent = 53711, noBoss = true },
                        { id = 10308, alt = { 5589, 5588, 853 }, noBoss = true } },
        DRUID       = { { id = 8983, alt = { 6798, 5211 } }, { id = 16979 } },
        WARLOCK     = { { id = 19647, alt = { 19244 }, pet = true } },
    },
    spec = {
        DRUID = { bear = true },
    },
    gcd      = 1.5,
    frame    = 0.05,
    slow     = 1,
    petSlots = 10,
    fill     = { S.full[1], S.full[2], S.full[3], 0.35 },
    glow     = S.full,
    edge     = { ok = S.ok, soon = S.soon, off = S.off, lock = S.off },
    bar      = { ok = S.full, soon = S.soon, off = S.mute, lock = S.off },
    dimIdle  = 0.3,
    dimWait  = 0.4,
}
ns.kickDataLoaded = true
