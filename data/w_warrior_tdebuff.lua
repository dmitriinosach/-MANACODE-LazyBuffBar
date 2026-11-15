local _, ns = ...
local td = ns.widgetData.tdebuff
td.cats.atkspd = { label = "widget.wtd_atkspd", full = 20, list = {
    { id = 47502, pct = 20 }, { id = 55095, pct = 20 }, { id = 68055, pct = 20 }, { id = 58181, pct = 20 },
} }
td.cats.ap = { label = "widget.wtd_ap", full = 0, list = {
    { id = 47437, pct = 0 }, { id = 48560, pct = 0 }, { id = 50511, pct = 0 }, { id = 26017, pct = 0 },
} }
ns.widgetData.war_tankdebuffs = {
    cats = { "atkspd", "ap", "armor" },
    icon = 47502,
}
ns.warTankDebuffDataLoaded = true
