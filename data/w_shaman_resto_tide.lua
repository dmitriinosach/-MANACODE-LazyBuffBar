local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.shaman_resto_tide = {
    id       = 61301,
    alt      = { 61300, 61299, 61295 },
    waves    = 53390,
    talent   = 51566,
    wave     = 49273,
    lesser   = 49276,
    chain    = 55459,
    t10      = 70806,
    relic    = { item = 50464, slot = 18, aura = 71220, max = 3 },
    charges  = 2,
    burn     = 3,
    burns    = { 2, 3, 4 },
    gcd      = 1.5,
    cd       = 6,
    tick     = 1,
    dim      = 0.45,
    calm     = 0.6,
    ring     = { 0.55, 0.8, 1, 0.95 },
    ringOff  = { 0, 0, 0, 0.35 },
}
ns.shamanRestoDataLoaded = true
