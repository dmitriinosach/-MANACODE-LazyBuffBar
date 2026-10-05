local ADDON, ns = ...
local S = {
    vt = 48160,
    dp = 48300,
    mb = 48127,
    mf = 48156,
    swp = 48125,
    sear = 53023,
    fiend = 34433,
    disp = 47585,
    hymn = 64901,
    swd = 48158,
    weave = 15258,
    form = 15473,
    fire = 48168,
    ve = 15286,
    pFort   = 48162,
    fort    = 48161,
    pSpirit = 48074,
    dSpirit = 48073,
    pShadow = 48170,
    shadow  = 48169,
    penance  = 53007,
    painSup  = 33206,
    pi       = 10060,
    focus    = 14751,
    pom      = 48113,
    divHymn  = 64843,
    fearWard = 6346,
    borrowed = 59891,
    hope     = 63944,
    gs       = 47788,
    coh      = 48089,
    well     = 48087,
    desp     = 48173,
    surge    = 33151,
    seren    = 63734,
    holyConc = 63725,
    holyConcT = 34860,
}
local FLASK_SP  = { item = 46376, aura = 53755 }
local POT_WILD  = 40212
local POT_SPEED = 40211
local POT_MANA  = 33448
local FOOD_FEAST = { item = 43015, aura = 57399 }
local FOOD_SP    = { item = 34767, aura = 57327 }
local FOOD_HASTE = { item = 34769, aura = 57332 }
local RAID = {
    { id = S.pFort,   alt = { S.fort } },
    { id = S.pSpirit, alt = { S.dSpirit } },
    { id = S.pShadow, alt = { S.shadow } },
}
ns.rotation = ns.rotation or {}
ns.rotation.PRIEST = {
    shadow = {
        buffs = { S.fire, S.ve },
        raidBuffs = RAID,
        flask     = FLASK_SP,
        food      = { FOOD_FEAST, FOOD_SP },
        potions   = { POT_WILD, POT_SPEED },
        track = {
            procs = {
                { id = S.weave, note = "5 стаков = +10% теневого урона. Доты снапшотят его в момент наложения — вешать на пяти." },
            },
            cds = {
                { id = S.mb,    note = "по кд: это он кормит рейд Восполнением." },
                { id = S.fiend, note = "мана, а не дпс." },
                { id = S.disp,  note = "на мане, а не когда страшно." },
                { id = S.hymn,  off = true, note = "когда рейд просел по мане." },
            },
            dots = {
                { id = S.vt,  note = "обновлять по ОКОНЧАНИИ: перекаст срезает последний тик." },
                { id = S.swp, note = "держится сам через Пытку разума — перекаст это потеря." },
                { id = S.dp,  note = "вернуть, как только слетела." },
            },
        },
    },
    disc = {
        buffs     = { S.fire },
        raidBuffs = RAID,
        flask     = FLASK_SP,
        food      = { FOOD_FEAST, FOOD_HASTE, FOOD_SP },
        potions   = { POT_MANA, POT_SPEED },
        track = {
            procs = {
                { id = S.borrowed, note = "После {s:48066} следующий каст на 25% быстрее: тратить на длинный {s:48063} или {s:48072}, а не на второй щит." },
                { id = S.hope, off = true, note = "Рейд получает на 3% меньше урона минуту после щита. Слетело — значит щитов давно не было." },
            },
            cds = {
                { id = S.penance,  note = "По кд в того, кто проседает: самое сильное лечение в одну цель и заряды Милости." },
                { id = S.pom,      note = "По кд на того, кого бьют: прыгает сама и лечит без каста." },
                { id = S.painSup,  note = "Танку под сильный удар или под рывок угрозы с него: 40% меньше урона 8 секунд." },
                { id = S.pi,       note = "Под тяжёлую фазу: себе на ману и скорость или кастеру под бурст." },
                { id = S.fiend,    note = "С половины маны, в окно без движения." },
                { id = S.focus,    off = true, note = "Перед {s:53007} или {s:48072}: бесплатно и с шансом крита выше." },
                { id = S.divHymn,  off = true, note = "Рейдовый сейв под известный залп, если рейд ждёт его от тебя." },
                { id = S.hymn,     off = true, note = "Когда хилы просели по мане, а не для себя одного." },
                { id = S.fearWard, off = true, note = "На танка заранее, если босс пугает." },
            },
        },
    },
    holy = {
        buffs     = { S.fire },
        raidBuffs = RAID,
        flask     = FLASK_SP,
        food      = { FOOD_FEAST, FOOD_HASTE, FOOD_SP },
        potions   = { POT_MANA, POT_SPEED },
        track = {
            procs = {
                { id = S.surge, note = "Крит дал мгновенное бесплатное {s:48071}: потратить, пока не сгорело за 10 секунд." },
                { id = S.seren, note = "Каждое {s:48071} или {s:48120} ускоряет {s:48063} и {s:48072}: на трёх стаках жать длинное лечение." },
                { id = S.holyConc, needs = S.holyConcT, off = true, note = "Крит лечения ускорил реген маны на 8 секунд: окно, чтобы не жать дорогое." },
            },
            cds = {
                { id = S.coh,     note = "По кд на пачку под уроном: мгновенное лечение до 6 целей." },
                { id = S.pom,     note = "По кд на того, кого бьют: прыгает сама и лечит без каста." },
                { id = S.gs,      note = "Танку, который умрёт следующим ударом: лечение по нему сильнее на 40%, а смерть дух заберёт на себя." },
                { id = S.divHymn, note = "Под известный рейдовый залп: лечит трёх самых раненых и усиливает лечение по ним." },
                { id = S.fiend,   note = "С половины маны, в окно без движения." },
                { id = S.hymn,    off = true, note = "Когда хилы просели по мане, а не для себя одного." },
                { id = S.well,    off = true, note = "Ставить до залпа там, где стоит рейд: пьют сами, когда просели." },
                { id = S.desp,    off = true, note = "Себе, когда до тебя не дотягиваются другие хилы." },
                { id = S.focus,   off = true, note = "Перед {s:48072} или {s:64843}: бесплатно и с шансом крита выше." },
                { id = S.fearWard, off = true, note = "На танка заранее, если босс пугает." },
            },
        },
    },
}
