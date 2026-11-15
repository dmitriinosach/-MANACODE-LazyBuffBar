local _, ns = ...
ns.widgetData.runes = {
    cells    = { { 1, 2 }, { 5, 6 }, { 3, 4 } },
    base     = { 1, 3, 2 },
    slotType = { 1, 1, 2, 2, 3, 3 },
    death    = 4,
    color = {
        [1] = { 1, 0.25, 0.25, 1 },
        [2] = { 0.35, 0.9, 0.3, 1 },
        [3] = { 0.35, 0.75, 1, 1 },
        [4] = { 0.8, 0.4, 1, 1 },
    },
    dim = {
        [1] = { 0.5, 0.12, 0.12, 1 },
        [2] = { 0.17, 0.45, 0.15, 1 },
        [3] = { 0.17, 0.37, 0.5, 1 },
        [4] = { 0.4, 0.2, 0.5, 1 },
    },
    powerType    = 6,
    maxPower     = 100,
    power        = { 0, 0.82, 1, 1 },
    powerLow     = { 0, 0.35, 0.45, 1 },
    powerFull    = ns.STATE.full,
    spend = {
        ["DEATHKNIGHT/blood_tank"] = 20,
    },
    spendDefault = 40,
    mute = ns.STATE.mute,
    text = ns.STATE.text,
}
ns.runesDataLoaded = true
