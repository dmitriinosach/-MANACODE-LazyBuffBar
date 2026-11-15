local _, ns = ...
ns.encRaids = {
    { key = "icc", map = "IcecrownCitadel", bosses = { "marrowgar", "deathwhisper", "gunship", "saurfang", "festergut",
        "rotface", "putricide", "council", "lanathel", "valithria", "sindragosa", "lichking" } },
    { key = "rs", map = "TheRubySanctum", bosses = { "baltharus", "saviana", "zarithrian", "halion" } },
}
ns.encBosses = {
    marrowgar    = { raid = "icc", npc = { 36612 }, spells = { 69065, 69076 } },
    deathwhisper = { raid = "icc", npc = { 36855 }, spells = { 71289, 71237, 71204, 70674, 70842 } },
    gunship      = { raid = "icc", npc = { 36939, 36948 }, spells = { 69638, 69651, 69652 } },
    saurfang     = { raid = "icc", npc = { 37813 }, spells = { 72293, 72410, 72441, 72371, 72737 } },
    festergut    = { raid = "icc", npc = { 36626 }, spells = { 69279, 69240, 72219, 69166, 69291 } },
    rotface      = { raid = "icc", npc = { 36627 }, spells = { 69674, 72272 } },
    putricide    = { raid = "icc", npc = { 36678 },
                     spells = { 70911, 70447, 70672, 72451, 72550, 72620, 70539, 70542, 70352, 70353 } },
    council      = { raid = "icc", npc = { 37970, 37972, 37973 }, spells = { 72999, 71807, 70952 } },
    lanathel     = { raid = "icc", npc = { 37955 }, spells = { 71340, 71277, 70838, 70923, 70877, 70867, 70879, 73070 } },
    valithria    = { raid = "icc", npc = { 36789 }, spells = { 70633, 70751, 70873, 71941, 72966 } },
    sindragosa   = { raid = "icc", npc = { 36853 }, spells = { 70157, 70126, 69762, 69766, 70106, 70127 } },
    lichking     = { raid = "icc", npc = { 36597 }, spells = { 70337, 69409, 70541, 68980, 69242, 72143 } },
    baltharus    = { raid = "rs", npc = { 39751, 39899 }, spells = { 74505, 75125 } },
    saviana      = { raid = "rs", npc = { 39747 }, spells = { 74453, 74456, 78722 } },
    zarithrian   = { raid = "rs", npc = { 39746 }, spells = { 74367, 74384 } },
    halion       = { raid = "rs", npc = { 39863, 40142, 40146 }, spells = { 74562, 74792, 74567, 74795, 74807, 74826 } },
}
