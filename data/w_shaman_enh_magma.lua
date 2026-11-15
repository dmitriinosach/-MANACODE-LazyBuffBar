local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.shaman_enh_magma = {
    place  = { 58734, 58704 },
    totems = { 58734, 58704 },
    summons = {
        [8190] = true, [10585] = true, [10586] = true, [10587] = true, [25552] = true, [58731] = true, [58734] = true,
        [3599] = true, [6363] = true, [6364] = true, [6365] = true, [10437] = true, [10438] = true, [25533] = true,
        [58699] = true, [58703] = true, [58704] = true,
    },
    hits = {
        [8187] = true, [10579] = true, [10580] = true, [10581] = true, [25550] = true, [58732] = true, [58735] = true,
        [3606] = true, [6350] = true, [6351] = true, [6352] = true, [10435] = true, [10436] = true, [25530] = true,
        [58700] = true, [58701] = true, [58702] = true,
        [8349] = true, [8502] = true, [8503] = true, [11306] = true, [11307] = true, [25535] = true, [25537] = true,
        [61650] = true, [61654] = true,
    },
    nova   = 61657,
    gcd    = 1.5,
    miss   = 5,
    soon   = 3,
    tick   = 1,
    dim    = 0.4,
}
ns.shamanEnhMagmaDataLoaded = true
