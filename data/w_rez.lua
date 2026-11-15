local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.rez = {
    classes = {
        PRIEST  = { id = 48171, alt = { 25435, 20770, 10881, 10880, 2010, 2006 } },
        PALADIN = { id = 48950, alt = { 48949, 20773, 20772, 10324, 10322, 7328 } },
        SHAMAN  = { id = 49277, alt = { 25590, 20777, 20776, 20610, 20609, 2008 } },
        DRUID   = { id = 50769, alt = { 50768, 50767, 50766, 50765, 50764, 50763 } },
    },
    tick  = 1,
    lines = 10,
    dim   = 0.45,
    tint  = { 0.5, 0.5, 1, 1 },
}
ns.rezDataLoaded = true
