local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.mana = {
    classes = {
        PRIEST  = { { key = "fiend", id = 34433 }, { key = "hymn", id = 64901 }, { key = "disp", id = 47585 } },
        PALADIN = { { key = "plea", id = 54428 } },
        SHAMAN  = { { key = "tide", id = 16190 } },
        DRUID   = { { key = "innervate", id = 29166, self = true } },
        MAGE    = { { key = "evoc", id = 12051 }, { key = "gem", items = { 33312, 22044, 8008, 8007, 5513, 5514 } } },
        WARLOCK = { { key = "tap", id = 57946, alt = { 27222, 11689, 11688, 11687, 1456, 1455, 1454 } } },
    },
    potion  = { key = "potion", items = { 42545, 33448, 43570, 40067, 22832, 13444, 20520, 12662 } },
    low     = 0.35,
    crit    = 0.15,
    window  = 10,
    minSpan = 2,
    gcd     = 1.5,
    tick    = 1,
    tint    = { 0.5, 0.5, 1, 1 },
    dim     = 0.4,
}
ns.manaDataLoaded = true
