local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.rogue_sub_prep = {
    classes = {
        ROGUE = {
            spell   = 14185,
            main    = { 26889, 36554 },
            minor   = { 26669, 11305, 14177 },
            glyph   = 56819,
            glyphed = { 1766, 51722, 13877 },
            row     = { 26889, 36554 },
        },
    },
    big    = 30,
    gcd    = 1.5,
    tick   = 1,
    dim    = 0.4,
    glyphs = 6,
}
ns.rogueSubPrepDataLoaded = true
