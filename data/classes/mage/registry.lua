local ADDON, ns = ...
local S = {
    fireball    = 133,
    lb          = 55360,
    pyro        = 11366,
    scorch      = 2948,
    impScorch   = 22959,
    fireblast   = 2136,
    combust     = 11129,
    hotstreak   = 48108,
    hotTalent   = 44448,
    molten      = 43046,
    mageArmor   = 43024,
    focus       = 54646,
    mirror      = 55342,
    evocation   = 12051,
    blizzard    = 10,
    flamestrike = 2120,
    ap          = 12042,
    pom         = 12043,
    barrage     = 44401,
    barrageTal  = 44404,
    clearcast   = 12536,
    arcConc     = 12577,
    potency     = 57531,
    potencyTal  = 31572,
    ab          = 42897,
    am          = 42846,
    veins       = 12472,
    snap        = 11958,
    elemental   = 31687,
    dfreeze     = 44572,
    fof         = 44544,
    fofTal      = 44545,
    brainProc   = 57761,
    brainTal    = 44549,
    ffb         = 47610,
    lance       = 42914,
    barrier     = 43039,
    block       = 45438,
    brilliance  = 43002,
    brillDala   = 61316,
    intellect   = 42995,
    intDala     = 61024,
}
local FLASK_SP    = { item = 46376, aura = 53755 }
local FOOD_FEAST  = { item = 43015, aura = 57399 }
local FOOD_SP     = { item = 34767, aura = 57327 }
local POT_WILD    = 40212
local POT_SPEED   = 40211
local POT_MANA    = 33448
local RAID_INT   = { id = S.brilliance, alt = { S.brillDala, S.intellect, S.intDala } }
local RAID_FOCUS = { id = S.focus, single = true,
                     note = "повесить на союзника-кастера с высоким критом: его криты дают ТЕБЕ +3% крита." }
ns.rotation = ns.rotation or {}
ns.rotation.MAGE = {
    arcane = {
        buffs     = { { id = S.molten, alt = { S.mageArmor } } },
        raidBuffs = { RAID_INT, RAID_FOCUS },
        flask     = FLASK_SP,
        food      = { FOOD_FEAST, FOOD_SP },
        potions   = { POT_SPEED, POT_WILD, POT_MANA },
        track = {
            procs = {
                {
                    id = S.barrage, needs = S.barrageTal,
                    note = "{s:42846} бесплатны и быстрее. Выпускать на 3-4 стаках {s:42897}, пока прок не сгорел: стрелы снимают стаки.",
                },
                {
                    id = S.clearcast, needs = S.arcConc, off = true,
                    note = "Следующее заклинание бесплатно: отдать его {s:42897} на полном стаке, а не стрелам.",
                },
                {
                    id = S.potency, needs = S.potencyTal, off = true,
                    note = "Следующее заклинание критует на 30% чаще. Висит после ясности мысли и {s:12043}: пустить в {s:42897}.",
                },
            },
            cds = {
                { id = S.ap, note = "Урон выше на 20%, расход маны тоже: в опенер вместе с {s:12472}, зельем и тринкетами, дальше по откату." },
                { id = S.pom, note = "Следующее заклинание мгновенно: в окно {s:12042} или на перебежке, чтобы не терять каст." },
                { id = S.veins, note = "Скорость выше на 20%: в одно окно с {s:12042}." },
                { id = S.mirror, note = "Копии бьют по твоей силе заклинаний и снимают часть угрозы: в опенер под бурст." },
                { id = S.evocation, note = "Мана почти до полной: на дне маны после окна {s:12042}, а не посреди бурста." },
                { id = S.block, off = true, note = "Сейв от смертельной механики, заодно сброс угрозы." },
            },
        },
    },
    fire = {
        buffs = { S.molten },
        raidBuffs = { RAID_INT, RAID_FOCUS },
        flask   = FLASK_SP,
        food    = { FOOD_FEAST, FOOD_SP },
        potions = { POT_WILD, POT_SPEED },
        track = {
            procs = {
                { id = S.hotstreak, needs = S.hotTalent, note = "два крита подряд — мгновенная Огненная глыба. Жать СРАЗУ, окно 10 сек: это главный источник урона." },
            },
            cds = {
                { id = S.combust, note = "жать, когда на цели максимум дотов (Живая бомба, дот Огненной глыбы, Воспламенение) — снимает их одним усиленным критом." },
                { id = S.mirror, note = "сброс агро и немного дпс — под бурст/геру." },
                { id = S.evocation, note = "на мане, на перебежках или когда босса не бьёшь." },
            },
            dots = {
                { id = S.lb, note = "держать всегда: финальный тик часто прокает Путь огня. Перевешивать в окно БЕЗ прока." },
                { id = S.impScorch, note = "держит на цели дебаф +5% крита по магии всему рейду." },
            },
        },
    },
    frost = {
        buffs     = { { id = S.molten, alt = { S.mageArmor } } },
        raidBuffs = { RAID_INT, RAID_FOCUS },
        flask     = FLASK_SP,
        food      = { FOOD_FEAST, FOOD_SP },
        potions   = { POT_SPEED, POT_WILD },
        track = {
            procs = {
                {
                    id = S.fof, needs = S.fofTal,
                    note = "Два заряда, цель считается замороженной: сразу {s:44572}, второй заряд — в {s:42914} или {s:47610}.",
                },
                {
                    id = S.brainProc, needs = S.brainTal,
                    note = "Мгновенная и бесплатная {s:47610}: выпустить до спада прока, лучше на заряде Ледяных пальцев.",
                },
                {
                    id = S.clearcast, needs = S.arcConc, off = true,
                    note = "Следующее заклинание бесплатно: экономит ману на длинном бою.",
                },
            },
            cds = {
                { id = S.veins, note = "Скорость выше на 20%: в опенер вместе с зельем и тринкетами, дальше по откату." },
                { id = S.dfreeze, note = "Только по замороженной цели: жать под Ледяные пальцы, по откату." },
                { id = S.elemental, note = "Вызвать до пула и перевызвать, если погиб: без него уходит заметная доля урона." },
                { id = S.snap, note = "Сбрасывает откаты ледяной ветки: вторая {s:12472} подряд или новый элементаль." },
                { id = S.mirror, note = "Копии бьют по твоей силе заклинаний и снимают часть угрозы: в опенер под бурст." },
                { id = S.evocation, off = true, note = "Мана почти до полной: на дне маны, лёд просит её редко." },
                { id = S.barrier, off = true, note = "Щит под АоЕ и на перебежке: пока висит, каст не сбивается уроном." },
                { id = S.block, off = true, note = "Сейв от смертельной механики, заодно сброс угрозы." },
            },
        },
    },
}
