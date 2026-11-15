local _, ns = ...
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
    chimera   = 53209,
    aimed     = 49050,
    explosive = 60053,
    kill      = 61006,
    scatter   = 19503,
    wyvern    = 49012,
    disengage = 781,
    tranqShot = 19801,
    masters   = 53271,
    freeze    = 14311,
    arcane    = 49045,
    multi     = 49048,
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
local POT_SPEED  = 40211
local PROC_QUICK = {
    id = S.quick, off = true, needs = T.impHawk,
    note = "Прок {s:61847} с талантом: скорость стрельбы выше на 15% на 12 секунд. Слетел аспект — проков не будет.",
    noteEn = "Proc of {s:61847} with the talent: ranged haste is 15% higher for 12 seconds. If the aspect drops, there will be no procs.",
}
local CD_RAPID  = { id = S.rapid, note = "Главный кд: стрельба быстрее на 40% на 15 секунд. В опенер вместе с зельем и тринкетами.",
  noteEn = "Main cooldown: 40% faster shooting for 15 seconds. Use it in the opener with a potion and trinkets." }
local CD_KCMD   = { id = S.kcmd, note = "Вне ГКД: усиливает следующие особые удары питомца. Жать по откату, не копить.",
  noteEn = "Off the global cooldown: it strengthens your pet's next special attacks. Press it on cooldown, do not hoard it." }
local CD_MISDIR = { id = S.misdir, note = "На танка до пула и в начале каждой волны аддов: угроза уходит ему.",
  noteEn = "On the tank before the pull and at the start of each wave of adds: the threat goes to him." }
local CD_FEIGN  = { id = S.feign, off = true, note = "Сбросить угрозу, если сорвал цель. Не ждать, пока босс развернётся.",
  noteEn = "Drop your threat if you pulled the target. Do not wait for the boss to turn around." }
local CD_DETER  = { id = S.deter, off = true, note = "Сейв на 5 секунд: отражает удары и заклинания в лицо.",
  noteEn = "A 5-second lifesaver: it deflects melee hits and spells back at the attacker." }
local CD_TRAP   = { id = S.trap, off = true, note = "АоЕ по пачке аддов, у траппера — по откату и в ротации на боссе.",
  noteEn = "AoE on a pack of adds; for a trapper, on cooldown and in the boss rotation." }
local CD_KILL   = { id = S.kill, off = true, note = "Цель ниже 20% здоровья: самый сильный выстрел добивания, жать по откату.",
  noteEn = "Target below 20% health: the strongest finishing shot, press it on cooldown." }
local CD_ARCANE = { id = S.arcane, off = true, note = "Мгновенный выстрел в свободный ГКД, пока хватает маны.",
  noteEn = "An instant shot for a free GCD, while mana allows." }
local CD_MULTI  = { id = S.multi, off = true, note = "По откату в окна, когда остальное в откате; на пачке — первым.",
  noteEn = "On cooldown in windows when everything else is on cooldown; on a pack, first." }
local CD_TRANQSHOT = { id = S.tranqShot, off = true, note = "Снять с цели исступление и магию: босс или адд в ярости, по команде.",
  noteEn = "Remove an enrage and magic effects from the target: a boss or an add in a frenzy, on call." }
local CD_FREEZE = { id = S.freeze, off = true, note = "Контроль адда ловушкой: откат общий с ледяной ловушкой и замораживающей стрелой.",
  noteEn = "Control an add with a trap: the cooldown is shared with Frost Trap and Freezing Arrow." }
local CD_MASTERS = { id = S.masters, off = true, note = "Питомец снимает замедление и обездвиживание с тебя или союзника.",
  noteEn = "Your pet removes slows and roots from you or an ally." }
local CD_DISENGAGE = { id = S.disengage, off = true, note = "Отпрыгнуть назад: выйти из лужи или из ближнего боя.",
  noteEn = "Leap backwards: get out of a puddle or out of melee range." }
local DOT_MARK  = {
    id = S.mark,
    note = "Плюс к силе атаки дальнего боя всего рейда по цели. Видна только своя метка: если цель метит другой охотник, строка останется пустой — договоритесь, кто метит.",
    noteEn = "Adds ranged attack power for the whole raid against the target. Only your own mark is visible: if another hunter marks the target, the row stays empty, so agree on who marks.",
}
local DOT_SERPENT = {
    id = S.serpent,
    note = "Держать на боссе без перерыва: свой урон плюс бонусы талантов и символов, завязанные на укус.",
    noteEn = "Keep it on the boss without a break: its own damage plus the talent and glyph bonuses tied to the sting.",
}
ns.rotation = ns.rotation or {}
ns.rotation.HUNTER = ns.rotation.HUNTER or {}
ns.rotation.HUNTER.bm = {
    buffs     = { ASPECT },
    raidBuffs = {
        {
            id = S.ferInsp, needs = T.ferInsp, noAction = true, soft = true, off = true,
            note = "Рейд получает на 3% больше урона, пока питомец жив и рядом. Пропало у всех — значит питомец мёртв или отозван.",
            noteEn = "The raid deals 3% more damage while your pet is alive and nearby. If it vanished for everyone, your pet is dead or dismissed.",
        },
    },
    flask     = FLASK_RAGE,
    food      = { FOOD_FEAST },
    potions   = { POT_SPEED },
    track = {
        procs = {
            PROC_QUICK,
            {
                id = S.beast, off = true, needs = T.beast,
                note = "Висит вместе с {s:19574}: ты бьёшь на 10% сильнее, мана дешевле вдвое. Окно для тринкетов и Быстрой стрельбы.",
                noteEn = "Up together with {s:19574}: you hit 10% harder and mana costs are halved. A window for trinkets and Rapid Fire.",
            },
        },
        cds = {
            { id = S.wrath, note = "Главный кд БМ: питомец звереет на 10 секунд, ты получаешь Зверя внутри. Совмещать с Быстрой стрельбой.",
              noteEn = "Main Beast Mastery cooldown: your pet goes into a frenzy for 10 seconds and you gain The Beast Within. Combine it with Rapid Fire." },
            CD_RAPID,
            CD_KCMD,
            CD_MISDIR,
            { id = S.intim, off = true, note = "Оглушение цели питомцем: сбить каст адда или поймать бегущего.",
              noteEn = "Your pet stuns the target: interrupt an add's cast or catch a runner." },
            CD_KILL,
            CD_ARCANE,
            CD_MULTI,
            CD_TRAP,
            CD_TRANQSHOT,
            CD_FREEZE,
            CD_MASTERS,
            CD_DISENGAGE,
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
        { id = S.tsa, soft = true, note = "Аура: сила атаки всего рейда выше на 10%. Пассивная, но работает только в радиусе — отставшие видны по счёту.",
          noteEn = "An aura: attack power of the whole raid is 10% higher. It is passive but works only in range; stragglers show up in the count." },
    },
    flask     = FLASK_RAGE,
    food      = { FOOD_FEAST },
    potions   = { POT_SPEED },
    track = {
        procs = {
            PROC_QUICK,
            {
                id = S.iss, needs = T.iss,
                note = "После {s:56641}: следующий {s:49050}, {s:3044} или {s:53209} сильнее на 15% и дешевле. Не держать прок до спада.",
                noteEn = "After {s:56641}: your next {s:49050}, {s:3044} or {s:53209} is 15% stronger and cheaper. Do not sit on the proc until it fades.",
            },
        },
        cds = {
            { id = S.chimera, note = "Главный выстрел ветки: по откату, обновляет {s:49001} на цели и сразу наносит часть урона укуса.",
              noteEn = "The tree's main shot: on cooldown, it refreshes {s:49001} on the target and at once deals part of the sting's damage." },
            { id = S.aimed, note = "По откату между {s:53209}: сильный выстрел и снижение лечения цели.",
              noteEn = "On cooldown between {s:53209}: a strong shot that also reduces the target's healing received." },
            CD_RAPID,
            { id = S.ready, note = "Сбрасывает откаты охотника: кончилась Быстрая стрельба — Готовность и сразу вторая.",
              noteEn = "Resets the hunter's cooldowns: when Rapid Fire ends, use Readiness and then a second Rapid Fire." },
            CD_KCMD,
            CD_MISDIR,
            { id = S.silence, off = true, note = "Прерывание и немота на 3 секунды, вне ГКД.",
              noteEn = "Interrupt and a 3-second silence, off the global cooldown." },
            CD_KILL,
            CD_TRAP,
            { id = S.scatter, off = true, note = "Дезориентировать цель на 4 секунды: сбить каст или выиграть время под ловушку.",
              noteEn = "Disorient the target for 4 seconds: stop a cast or buy time for a trap." },
            CD_TRANQSHOT,
            CD_FREEZE,
            CD_MASTERS,
            CD_DISENGAGE,
            CD_FEIGN,
            CD_DETER,
        },
        dots = {
            DOT_SERPENT,
            DOT_MARK,
            { id = S.piercing, off = true, note = "Кровотечение от критов {s:49050}, {s:56641} и {s:53209}. Само держится, смотреть только при разборе логов.",
              noteEn = "A bleed from crits of {s:49050}, {s:56641} and {s:53209}. It maintains itself; only look at it when reviewing logs." },
        },
    },
}
ns.rotation.HUNTER.surv = {
    buffs     = { ASPECT },
    raidBuffs = {
        {
            id = S.replen, needs = T.hunting, soft = true, noAction = true, off = true,
            note = "От {s:53292}: криты {s:60053}, {s:3044} и {s:56641} дают ману десяти игрокам. Висит не на всех, поэтому без красной рамки.",
            noteEn = "From {s:53292}: crits of {s:60053}, {s:3044} and {s:56641} give mana to ten players. It is not up on everyone, so there is no red border.",
        },
    },
    flask     = FLASK_RAGE,
    food      = { FOOD_FEAST },
    potions   = { POT_SPEED },
    track = {
        procs = {
            {
                id = S.lnl, needs = T.lnl,
                note = "Два {s:60053} без отката и без маны. Тратить сразу, вперёд всего остального.",
                noteEn = "Two free {s:60053} with no cooldown and no mana cost. Spend them at once, ahead of everything else.",
            },
            {
                id = S.sniper, off = true, needs = T.sniper,
                note = "6 секунд на месте — и {s:56641}, {s:49050}, {s:63672} и {s:60053} сильнее на 6%. Двигался — заработай заново.",
                noteEn = "After 6 seconds standing still, {s:56641}, {s:49050}, {s:63672} and {s:60053} deal 6% more. If you moved, earn it again.",
            },
            {
                id = S.expose, off = true, needs = T.expose,
                note = "С крита дальнего боя: к силе атаки четверть ловкости на 7 секунд.",
                noteEn = "From a ranged crit: a quarter of your Agility is added to attack power for 7 seconds.",
            },
            PROC_QUICK,
            {
                id = S.tactician, needs = T.tactician, off = true,
                note = "С попаданий: шанс крита выше на 10% на 8 секунд. Держится сам, смотреть при разборе.",
                noteEn = "From hits: crit chance is 10% higher for 8 seconds. It maintains itself; look at it when reviewing.",
            },
        },
        cds = {
            { id = S.explosive, note = "Главный выстрел ветки: по откату, не перебивать тики. С проком {s:56453} — два подряд.",
              noteEn = "The tree's main shot: on cooldown, do not interrupt its ticks. With a {s:56453} proc, cast two in a row." },
            CD_RAPID,
            CD_KCMD,
            CD_MISDIR,
            CD_KILL,
            CD_ARCANE,
            CD_MULTI,
            CD_TRAP,
            { id = S.wyvern, off = true, note = "Усыпить адда на 30 секунд, потом яд: любой урон будит.",
              noteEn = "Put an add to sleep for 30 seconds, then poison it: any damage wakes it up." },
            CD_TRANQSHOT,
            CD_FREEZE,
            CD_MASTERS,
            CD_DISENGAGE,
            CD_FEIGN,
            CD_DETER,
        },
        dots = {
            DOT_SERPENT,
            {
                id = S.blackArr,
                note = "Цель получает на 6% больше твоего урона, а тики дают шанс на {s:56453}. Обновлять по откату.",
                noteEn = "The target takes 6% more of your damage, and the ticks give a chance of {s:56453}. Refresh it on cooldown.",
            },
            DOT_MARK,
        },
    },
}
