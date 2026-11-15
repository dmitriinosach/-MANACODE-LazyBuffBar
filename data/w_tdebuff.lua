local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.tdebuff = {
    cats = {
        armor = { label = "widget.td_armor", full = 20, list = {
            { id = 7386, per = 4, max = 5 },
            { id = 8647, pct = 20 },
            { id = 55749, per = 10, max = 2 },
        } },
        armor5 = { label = "widget.td_armor5", full = 5, list = {
            { id = 770, pct = 5 }, { id = 16857, pct = 5 }, { id = 702, pct = 5 }, { id = 56626, pct = 5 },
        } },
        phys = { label = "widget.td_phys", full = 4, list = {
            { id = 30070, pct = 4 }, { id = 58683, pct = 4 },
        } },
        crit = { label = "widget.td_crit", full = 3, list = {
            { id = 54499, pct = 3 }, { id = 30708, pct = 3 }, { id = 58410, pct = 3 },
        } },
        spell = { label = "widget.td_spell", full = 13, list = {
            { id = 1490, pct = 13 }, { id = 51735, pct = 13 }, { id = 60433, pct = 13 },
        } },
        spellcrit = { label = "widget.td_spellcrit", full = 5, list = {
            { id = 22959, pct = 5 }, { id = 12579, per = 1, max = 5 }, { id = 17800, pct = 5 },
        } },
        spellhit = { label = "widget.td_spellhit", full = 3, list = {
            { id = 33198, pct = 3 }, { id = 770, pct = 3 },
        } },
    },
    sets = {
        phys   = { "armor", "armor5", "phys", "crit" },
        caster = { "spell", "spellcrit", "crit", "spellhit" },
    },
    icon     = "Interface\\Icons\\Ability_Warrior_Sunder",
    tick     = 0.5,
    numFont  = 0.5,
    leftFont = 0.26,
    wideFont = 0.42,
    dim      = 0.35,
}
ns.tdebuffDataLoaded = true
