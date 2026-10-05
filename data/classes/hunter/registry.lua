local ADDON, ns = ...
local S = {
    mark      = 53338,
    hawk      = 27044,
    dhawk     = 61847,
    serpent   = 49001,
    blackArr  = 63672,
    piercing  = 63468,
    silence   = 34490,
    rapid     = 3045,
    ready     = 23989,
    wrath     = 19574,
    intim     = 19577,
    trap      = 49067,
    kcmd      = 34026,
    misdir    = 34477,
    feign     = 5384,
    deter     = 19263,
    tsa       = 19506,
    ferInsp   = 75447,
    replen    = 57669,
    quick     = 6150,
    beast     = 34471,
    iss       = 53220,
    lnl       = 56453,
    sniper    = 64420,
    expose    = 34501,
    tactician = 34837,
}
local T = {
    impHawk   = 19556,
    ferInsp   = 34460,
    beast     = 34692,
    iss       = 53224,
    lnl       = 56344,
    sniper    = 53304,
    expose    = 34503,
    tactician = 34839,
    hunting   = 53292,
}
local ASPECT     = { id = S.dhawk, alt = { S.hawk } }
local FLASK_RAGE = { item = 46377, aura = 53760 }
local FOOD_FEAST = { item = 43015, aura = 57399 }
local FOOD_AGI   = { item = 42999, aura = 57367 }
local POT_SPEED  = 40211
local PROC_QUICK = {
    id = S.quick, needs = T.impHawk,
    note = "Прок {s:61847} с талантом: скорость стрельбы выше на 15% на 12 секунд. Слетел аспект — проков не будет.",
}
local CD_RAPID  = { id = S.rapid, note = "Главный кд: стрельба быстрее на 40% на 15 секунд. В опенер вместе с зельем и тринкетами." }
local CD_KCMD   = { id = S.kcmd, note = "Вне ГКД: усиливает следующие особые удары питомца. Жать по откату, не копить." }
local CD_MISDIR = { id = S.misdir, note = "На танка до пула и в начале каждой волны аддов: угроза уходит ему." }
local CD_FEIGN  = { id = S.feign, off = true, note = "Сбросить угрозу, если сорвал цель. Не ждать, пока босс развернётся." }
local CD_DETER  = { id = S.deter, off = true, note = "Сейв на 5 секунд: отражает удары и заклинания в лицо." }
local CD_TRAP   = { id = S.trap, off = true, note = "АоЕ по пачке аддов, у траппера — по откату и в ротации на боссе." }
local DOT_MARK  = {
    id = S.mark,
    note = "Плюс к силе атаки дальнего боя всего рейда по цели. Видна только своя метка: если цель метит другой охотник, строка останется пустой — договоритесь, кто метит.",
}
local DOT_SERPENT = {
    id = S.serpent,
    note = "Держать на боссе без перерыва: свой урон плюс бонусы талантов и символов, завязанные на укус.",
}
ns.rotation = ns.rotation or {}
ns.rotation.HUNTER = ns.rotation.HUNTER or {}
ns.rotation.HUNTER.bm = {
    buffs     = { ASPECT },
    raidBuffs = {
        {
            id = S.ferInsp, needs = T.ferInsp,
            note = "Рейд получает на 3% больше урона, пока питомец жив и рядом. Пропало у всех — значит питомец мёртв или отозван.",
        },
    },
    flask     = FLASK_RAGE,
    food      = { FOOD_FEAST, FOOD_AGI },
    potions   = { POT_SPEED },
    track = {
        procs = {
            PROC_QUICK,
            {
                id = S.beast, needs = T.beast,
                note = "Висит вместе с {s:19574}: ты бьёшь на 10% сильнее, мана дешевле вдвое. Окно для тринкетов и Быстрой стрельбы.",
            },
        },
        cds = {
            { id = S.wrath, note = "Главный кд БМ: питомец звереет на 10 секунд, ты получаешь Зверя внутри. Совмещать с Быстрой стрельбой." },
            CD_RAPID,
            CD_KCMD,
            CD_MISDIR,
            { id = S.intim, off = true, note = "Оглушение цели питомцем: сбить каст адда или поймать бегущего." },
            CD_FEIGN,
            CD_DETER,
        },
        dots = {
            DOT_SERPENT,
            DOT_MARK,
        },
    },
}
ns.rotation.HUNTER.mm = {
    buffs     = { ASPECT },
    raidBuffs = {
        { id = S.tsa, note = "Аура: сила атаки всего рейда выше на 10%. Пассивная, но работает только в радиусе — отставшие видны по счёту." },
    },
    flask     = FLASK_RAGE,
    food      = { FOOD_FEAST, FOOD_AGI },
    potions   = { POT_SPEED },
    track = {
        procs = {
            PROC_QUICK,
            {
                id = S.iss, needs = T.iss,
                note = "После {s:56641}: следующий {s:49050}, {s:3044} или {s:53209} сильнее на 15% и дешевле. Не держать прок до спада.",
            },
        },
        cds = {
            CD_RAPID,
            { id = S.ready, note = "Сбрасывает откаты охотника: кончилась Быстрая стрельба — Готовность и сразу вторая." },
            CD_KCMD,
            CD_MISDIR,
            { id = S.silence, off = true, note = "Прерывание и немота на 3 секунды, вне ГКД." },
            CD_TRAP,
            CD_FEIGN,
            CD_DETER,
        },
        dots = {
            DOT_SERPENT,
            DOT_MARK,
            { id = S.piercing, off = true, note = "Кровотечение от критов {s:49050}, {s:56641} и {s:53209}. Само держится, смотреть только при разборе логов." },
        },
    },
}
ns.rotation.HUNTER.surv = {
    buffs     = { ASPECT },
    raidBuffs = {
        {
            id = S.replen, needs = T.hunting, soft = true,
            note = "От {s:53292}: криты {s:60053}, {s:3044} и {s:56641} дают ману десяти игрокам. Висит не на всех, поэтому без красной рамки.",
        },
    },
    flask     = FLASK_RAGE,
    food      = { FOOD_FEAST, FOOD_AGI },
    potions   = { POT_SPEED },
    track = {
        procs = {
            {
                id = S.lnl, needs = T.lnl,
                note = "Два {s:60053} без отката и без маны. Тратить сразу, вперёд всего остального.",
            },
            {
                id = S.sniper, needs = T.sniper,
                note = "6 секунд на месте — и {s:56641}, {s:49050}, {s:63672} и {s:60053} сильнее на 6%. Двигался — заработай заново.",
            },
            {
                id = S.expose, needs = T.expose,
                note = "С крита дальнего боя: к силе атаки четверть ловкости на 7 секунд.",
            },
            PROC_QUICK,
            {
                id = S.tactician, needs = T.tactician, off = true,
                note = "С попаданий: шанс крита выше на 10% на 8 секунд. Держится сам, смотреть при разборе.",
            },
        },
        cds = {
            CD_RAPID,
            CD_KCMD,
            CD_MISDIR,
            CD_TRAP,
            CD_FEIGN,
            CD_DETER,
        },
        dots = {
            DOT_SERPENT,
            {
                id = S.blackArr,
                note = "Цель получает на 6% больше твоего урона, а тики дают шанс на {s:56453}. Обновлять по откату.",
            },
            DOT_MARK,
        },
    },
}
