local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.shaman_reach = {
    slots = {
        {
            { spell = 58656, aura = 58655, alt = { 57663, 48090 } },
            { spell = 57722, aura = 57663, alt = { 48090 } },
            { spell = 58739, aura = 58740, alt = { 48947 } },
        },
        {
            { spell = 58643, aura = 58646, alt = { 57623 } },
            { spell = 58753, aura = 58752, alt = { 48942 } },
        },
        {
            { spell = 58774, aura = 58777, alt = { 48936, 48938 } },
            { spell = 58745, aura = 58744, alt = { 48945 } },
        },
        {
            { spell = 8512,  aura = 8515, alt = { 55610 } },
            { spell = 3738,  aura = 2895 },
            { spell = 58749, aura = 58750, alt = { 49071 } },
        },
    },
    calls  = { 66842, 66843, 66844 },
    recall = 36936,
    grace  = 2,
    tick   = 1,
    dim    = 0.4,
}
ns.shamanReachDataLoaded = true
