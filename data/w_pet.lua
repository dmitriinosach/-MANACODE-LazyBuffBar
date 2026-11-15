local _, ns = ...
ns.widgetData.pet = {
    low  = 40,
    lows = { 60, 40, 20 },
    gcd  = 1.5,
    classes = {
        HUNTER = {
            summon = 883, revive = 982, heal = 48990, happy = true,
            row = { { key = "summon", id = 883 }, { key = "revive", id = 982 }, { key = "heal", id = 48990 } },
        },
        WARLOCK = {
            demons = true,
            row = { { key = "summon" }, { key = "fel", id = 18708 }, { key = "heal", id = 47856 } },
        },
        DEATHKNIGHT = {
            summon = 46584, heal = 63560, talent = 52143, base = "unholy",
            row = { { key = "summon", id = 46584 }, { key = "heal", id = 63560 } },
        },
    },
    demons = {
        { key = "imp",       summon = 688,   sig = { 3110, 6307, 2947, 4511 } },
        { key = "void",      summon = 697,   sig = { 3716, 7812, 17767, 17735 } },
        { key = "succ",      summon = 712,   sig = { 7814, 6358, 6360, 7870 } },
        { key = "felhunter", summon = 691,   sig = { 19505, 19244, 54049 } },
        { key = "felguard",  summon = 30146, sig = { 30213, 30151, 33698 } },
    },
    spec = { affli = "felhunter", demo = "felguard", destro = "imp" },
}
