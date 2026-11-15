local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.druid_eclipse = {
    talent = 48525,
    solar  = { aura = 48517, cast = 48461, catch = 48465 },
    lunar  = { aura = 48518, cast = 48465, catch = 48461 },
    order  = { "solar", "lunar" },
    dur    = 15,
    icd    = 30,
    soon   = 3,
    tick   = 0.2,
    dim    = 0.6,
}
ns.widgetData.druid_bloom = {
    id   = 48451,
    alt  = { 48450, 33763 },
    max  = 3,
    need = 3,
    soon = 2,
    tick = 0.2,
    dim  = 0.45,
}
ns.widgetData.druid_brez = {
    classes = {
        DRUID = { id = 48477, alt = { 26994, 20748, 20747, 20742, 20739, 20484 }, reagent = 44614 },
    },
    soon  = 30,
    gcd   = 1.5,
    tick  = 1,
    lines = 10,
    dim   = 0.6,
}
ns.druidDataLoaded = true
