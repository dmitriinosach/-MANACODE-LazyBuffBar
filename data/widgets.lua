local _, ns = ...
ns.widgetData = {
    combo = {
        ticks = {
            ["ROGUE/assassination"] = { 25, 35 },
            ["ROGUE/combat"]        = { 25, 35 },
            ["ROGUE/subtlety"]      = { 25, 35 },
            ["DRUID/cat"]           = { 30, 35 },
        },
        cat    = 768,
        max    = 5,
        color  = ns.STATE.combo,
        full   = ns.STATE.full,
        none   = ns.STATE.mute,
        energy = ns.STATE.energy,
    },
    poison = {
        spells = {
            instant    = 57968,
            deadly     = 57973,
            wound      = 57978,
            crippling  = 3408,
            mind       = 5761,
            anesthetic = 57982,
        },
        debuff = 57970,
        stacks = 5,
        soon   = 300,
    },
    totem = {
        names     = { "fire", "earth", "water", "air" },
        icon      = { [1] = 3599, [2] = 8071, [3] = 5394, [4] = 8512 },
        multicast = { [1] = 134, [2] = 133, [3] = 135, [4] = 136 },
        page      = 4,
        soon      = 10,
    },
    mode = {
        dim  = 0.3,
        cols = 4,
        max  = 5,
        glow = {
            PRIEST = { 1, 0.3, 0.9, 1 },
            DRUID  = { 0.2, 0.85, 1, 1 },
        },
        classes = {
            WARRIOR = {
                bar = true,
                modes = {
                    { key = "battle", id = 2457 },
                    { key = "def",    id = 71 },
                    { key = "bers",   id = 2458 },
                },
                spec = { arms = "battle", fury = "bers", prot = "def" },
            },
            PALADIN = {
                bar = true,
                modes = {
                    { key = "dev",     id = 48942, alt = { 465 } },
                    { key = "ret",     id = 54043, alt = { 7294 } },
                    { key = "conc",    id = 19746 },
                    { key = "pshadow", id = 48943, alt = { 19876 } },
                    { key = "pfrost",  id = 48945, alt = { 19888 } },
                    { key = "pfire",   id = 48947, alt = { 19891 } },
                    { key = "crus",    id = 32223 },
                },
                spec = { holy = "conc", prot_tank = "dev", prot_dps = "ret", ret_agi = "ret" },
            },
            HUNTER = {
                bar = false,
                modes = {
                    { key = "dragon",  id = 61847, alt = { 27044 } },
                    { key = "viper",   id = 34074 },
                    { key = "monkey",  id = 13163 },
                    { key = "cheetah", id = 5118 },
                    { key = "pack",    id = 13159 },
                    { key = "beast",   id = 13161 },
                    { key = "wild",    id = 49071 },
                },
                spec = { bm = "dragon", mm = "dragon", surv = "dragon" },
            },
            PRIEST = {
                bar = true,
                modes = { { key = "sf", id = 15473 } },
                spec = { shadow = "sf" },
            },
            DEATHKNIGHT = {
                bar = true,
                modes = {
                    { key = "blood",  id = 48266 },
                    { key = "frostp", id = 48263 },
                    { key = "unholy", id = 48265 },
                },
                spec = { blood_tank = "frostp", blood_str = "blood", blood_agi = "blood", frost = "blood", unholy = "blood" },
            },
            SHAMAN = {
                bar = false,
                modes = {
                    { key = "ls", id = 49281, alt = { 324 } },
                    { key = "ws", id = 57960, alt = { 24398 } },
                },
                spec = { ele = "ws", enh_phys = "ls", enh_spell = "ls", resto = "ws" },
            },
            MAGE = {
                bar = false,
                modes = {
                    { key = "molten",     id = 43046, alt = { 30482 } },
                    { key = "mage",       id = 43024, alt = { 6117 } },
                    { key = "ice",        id = 43008, alt = { 7302 } },
                    { key = "frostarmor", id = 7301,  alt = { 168 } },
                },
                spec = { arcane = "molten", fire = "molten", frost = "molten" },
            },
            WARLOCK = {
                bar = false,
                fallback = { "fel", "demon", "skin" },
                modes = {
                    { key = "fel",   id = 47893, alt = { 47892, 28189, 28176 } },
                    { key = "demon", id = 47889, alt = { 47793, 27260, 11735, 11734, 11733, 1086, 706 } },
                    { key = "skin",  id = 696, alt = { 687 } },
                },
                spec = { affli = "fel", demo = "fel", destro = "fel" },
            },
            DRUID = {
                bar = true,
                modes = {
                    { key = "cat",    id = 768 },
                    { key = "bear",   id = 9634, alt = { 5487 } },
                    { key = "moon",   id = 24858 },
                    { key = "tree",   id = 33891 },
                    { key = "travel", id = 783 },
                    { key = "aqua",   id = 1066 },
                    { key = "bird",   id = 40120, alt = { 33943 } },
                },
                spec = { balance = "moon", cat = "cat", bear = "bear", resto = "tree" },
            },
        },
    },
}
ns.widgetsDataLoaded = true
