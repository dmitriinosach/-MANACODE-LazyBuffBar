local _, ns = ...
local S = {
    lShield   = 49281,
    wShield   = 57960,
    eShield   = 49284,
    wrathT    = 57722,
    airT      = 3738,
    windT     = 8512,
    soeT      = 58643,
    soeAura   = 58646,
    springT   = 58774,
    springAur = 58777,
    lust      = 2825,
    hero      = 32182,
    fireEle   = 2894,
    earthEle  = 2062,
    shear     = 57994,
    lvb       = 60043,
    cl        = 49271,
    em        = 16166,
    storm     = 59159,
    fs        = 49233,
    cc        = 16246,
    eFocus    = 16164,
    ss        = 17364,
    ll        = 60103,
    sr        = 30823,
    wolves    = 51533,
    nova      = 61657,
    mw        = 53817,
    mwTal     = 51528,
    flurry    = 16280,
    flurryTal = 16256,
    riptide   = 61301,
    ns        = 16188,
    tForce    = 55198,
    tide      = 16190,
    tWaves    = 53390,
    tWavesTal = 51562,
    berserk   = 59620,
    mongoose  = 28093,
    blackMag  = 59626,
}
local FLASK_SP   = { item = 46376, aura = 53755 }
local FLASK_RAGE = { item = 46377, aura = 53760 }
local FOOD_FEAST = { item = 43015, aura = 57399 }
local FOOD_SP    = { item = 34767, aura = 57327 }
local POT_WILD   = 40212
local POT_SPEED  = 40211
local POT_MANA   = 33448
local LUST = { id = S.lust, note = "Рейд на 40 сек. быстрее на 30%: по команде РЛа, обычно на пуле или в фазу добивания." }
local HERO = { id = S.hero, note = "Рейд на 40 сек. быстрее на 30%: по команде РЛа, обычно на пуле или в фазу добивания." }
local SOE    = { id = S.soeT, alt = { S.soeAura }, soft = true }
local SPRING = { id = S.springT, alt = { S.springAur }, soft = true }
local ENH_TRACK = {
    procs = {
        {
            id = S.mw,
            needs = S.mwTal,
            note = "На 5 зарядах {s:49238} или {s:49271} мгновенные: тратить сразу, лишний заряд сгорает впустую.",
        },
        {
            id = S.flurry,
            needs = S.flurryTal,
            note = "Скорость атаки с крита на три удара. Держится сам, пока бьёшь, слетает — значит, стоял без атаки.",
        },
        {
            id = S.berserk,
            needs = true,
            off = true,
            note = "Прок зачарования оружия: сила атаки на 15 сек. Включи, если носишь Берсерка.",
        },
        {
            id = S.mongoose,
            needs = true,
            off = true,
            note = "Прок зачарования оружия: ловкость и скорость на 15 сек. Включи, если носишь Мангуста.",
        },
        {
            id = S.blackMag,
            needs = true,
            off = true,
            note = "Прок Чёрной магии: скорость на 10 сек. Включи, если носишь это зачарование на оружии.",
        },
    },
    cds = {
        { id = S.ss, note = "По откату: цель получает больше урона от твоих заклинаний природы." },
        { id = S.ll, note = "По откату, с огненным оружием в левой руке урон заметно выше." },
        { id = S.wolves, note = "Волки на 45 сек.: под Жажду крови и зелье, урон их растёт от твоей силы атаки." },
        { id = S.sr, note = "Мана и меньше урона по тебе: жать на половине маны, не ждать дна." },
        LUST,
        HERO,
        { id = S.fireEle, off = true, note = "Элементаль огня на 2 минуты, если тотем огня не нужен рейду." },
        { id = S.nova, off = true, note = "Урон по площади от огненного тотема, когда целей много." },
        { id = S.shear, off = true, note = "Прерывание, откат 6 сек." },
    },
    dots = {
        { id = S.fs, note = "Держать на цели: тикает весь бой, а {s:60043} с водоворота по ней критует наверняка." },
    },
}
ns.rotation = ns.rotation or {}
ns.rotation.SHAMAN = {
    ele = {
        buffs     = { S.wShield, { id = S.lShield, off = true } },
        raidBuffs = {
            { id = S.wrathT, soft = true },
            { id = S.airT, soft = true },
            SPRING,
        },
        flask     = FLASK_SP,
        food      = { FOOD_FEAST, FOOD_SP },
        potions   = { POT_WILD, POT_SPEED },
        track = {
            procs = {
                {
                    id = S.cc,
                    needs = S.eFocus,
                    note = "После крита два заклинания дешевле и сильнее. Держится сам, пока криты идут.",
                },
                {
                    id = S.blackMag,
                    needs = true,
                    off = true,
                    note = "Прок Чёрной магии: скорость на 10 сек. Включи, если носишь это зачарование на оружии.",
                },
            },
            cds = {
                { id = S.lvb, note = "По откату, когда на цели висит {s:49233}: тогда крит гарантирован." },
                { id = S.em, note = "Скорость заклинаний на 15 сек.: под Жажду крови, зелье и тринкеты." },
                { id = S.fireEle, note = "Элементаль огня на 2 минуты под бурст: встаёт на место тотема огня." },
                LUST,
                HERO,
                { id = S.cl, off = true, note = "Между {s:60043}, когда целей больше одной или нужно бить на ходу." },
                { id = S.storm, off = true, note = "Мана, когда её не хватает; отбрасывает всё рядом, на боссах осторожно." },
                { id = S.earthEle, off = true, note = "Временный танк на крайний случай, когда танк лёг." },
                { id = S.shear, off = true, note = "Прерывание, откат 6 сек." },
            },
            dots = {
                { id = S.fs, note = "Должен висеть: без него {s:60043} не критует наверняка." },
            },
        },
    },
    enh_phys = {
        buffs     = { S.lShield },
        raidBuffs = {
            { id = S.windT, soft = true },
            SOE,
            SPRING,
        },
        flask     = FLASK_RAGE,
        food      = { FOOD_FEAST },
        potions   = { POT_SPEED },
        track     = ENH_TRACK,
    },
    enh_spell = {
        buffs     = { S.lShield },
        raidBuffs = {
            { id = S.windT, soft = true },
            SOE,
            SPRING,
        },
        flask     = FLASK_SP,
        food      = { FOOD_FEAST, FOOD_SP },
        potions   = { POT_SPEED, POT_WILD },
        track     = ENH_TRACK,
    },
    resto = {
        buffs     = { S.wShield },
        raidBuffs = {
            { id = S.eShield, single = true, note = "Держать на танке, который сейчас держит босса. Заряды кончаются — обновить." },
            SPRING,
            { id = S.airT, alt = { S.windT }, soft = true },
        },
        flask     = FLASK_SP,
        food      = { FOOD_FEAST, FOOD_SP },
        potions   = { POT_MANA, POT_SPEED },
        track = {
            procs = {
                {
                    id = S.tWaves,
                    needs = S.tWavesTal,
                    note = "После {s:61301} или {s:55459}: две Волны исцеления быстрее. Не давай сгорать без каста.",
                },
            },
            cds = {
                { id = S.riptide, note = "По откату на того, кого лечишь: даёт Приливные волны и усиливает {s:55459}." },
                { id = S.ns, note = "Мгновенное исцеление, когда танк проседает быстрее каста." },
                { id = S.tForce, note = "Три гарантированных крита: под залп по рейду или в связке с {s:16188}." },
                { id = S.tide, note = "Мана группе: ставить на половине маны, не ждать дна." },
                LUST,
                HERO,
                { id = S.shear, off = true, note = "Прерывание, откат 6 сек." },
            },
            dots = {},
        },
    },
}
