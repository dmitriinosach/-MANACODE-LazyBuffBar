local _, ns = ...
ns.widgetData = ns.widgetData or {}
local SPELL = { spell = true }
local MELEE = { melee = true }
local ALL = { spell = true, melee = true, ranged = true }
ns.widgetData.hit = {
    caps = { spell = 17, melee = 8, ranged = 8 },
    cr   = { spell = 8, melee = 6, ranged = 7 },
    per  = { spell = 26.232, melee = 32.79, ranged = 32.79 },
    over = 1,
    eps  = 0.005,
    icon = "Interface\\Icons\\Ability_Marksmanship",
    presence    = { 6562, 28878 },
    presencePct = 1,
    race        = "Draenei",
    faction     = "Alliance",
    talents = {
        DEATHKNIGHT = {
            { id = 50138, tab = 2, per = 1, max = 3, kinds = MELEE, cond = "dual" },
            { id = 49568, tab = 3, per = 1, max = 3, kinds = SPELL },
        },
        DRUID   = { { id = 33596, tab = 1, per = 2, max = 2, kinds = SPELL } },
        HUNTER  = { { id = 53622, tab = 2, per = 1, max = 3, kinds = ALL } },
        MAGE    = {
            { id = 12840, tab = 1, per = 1, max = 3, kinds = SPELL, cond = "tree" },
            { id = 29440, tab = 3, per = 1, max = 3, kinds = SPELL },
        },
        PRIEST  = { { id = 15328, tab = 3, per = 1, max = 3, kinds = SPELL, cond = "tree" } },
        ROGUE   = { { id = 13845, tab = 2, per = 1, max = 5, kinds = ALL } },
        SHAMAN  = {
            { id = 30674, tab = 1, per = 1, max = 3, kinds = SPELL },
            { id = 30819, tab = 2, per = 2, max = 3, kinds = MELEE, cond = "dual" },
        },
        WARLOCK = { { id = 18176, tab = 1, per = 1, max = 3, kinds = SPELL } },
        WARRIOR = { { id = 29592, tab = 2, per = 1, max = 3, kinds = MELEE } },
    },
    numFont  = 0.4,
    subFont  = 0.27,
    wideFont = 0.42,
}
ns.hitDataLoaded = true
