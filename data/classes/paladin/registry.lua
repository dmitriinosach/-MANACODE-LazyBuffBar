local ADDON, ns = ...
local S = {
    sealVeng = 31801,
    sealCorr = 53736,
    hvStack  = 31803,
    bloodCorr = 53742,
    sealCmd  = 20375,
    judge    = 20186,
    cs       = 35395,
    ds       = 53385,
    cons     = 26573,
    exo      = 879,
    how      = 24275,
    hw       = 2812,
    wings    = 31884,
    aow      = 59578,
    glKings  = 25898,
    glMight  = 48934,
    glWisdom = 48938,
    hl       = 48782,
    fol      = 48785,
    hs       = 48825,
    beacon   = 53563,
    shield   = 53601,
    sealWis  = 20166,
    jol      = 20271,
    jow      = 53408,
    plea     = 54428,
    illum    = 31842,
    favor    = 20216,
    loh      = 48788,
    auraConc = 19746,
    auraMast = 31821,
    cleanse  = 4987,
    bop      = 10278,
    sacr     = 6940,
    dsac     = 64205,
    bubble   = 642,
    di       = 19752,
    lightsGrace = 31834,
    infusion    = 54149,
    jotp        = 54153,
    hotr     = 53595,
    sor      = 61411,
    holyShld = 48952,
    consT    = 48819,
    avShield = 48827,
    hwT      = 48817,
    rf       = 25780,
    sanct    = 25899,
    taunt    = 62124,
    rd       = 31789,
    dprot    = 498,
    ardent   = 31852,
    berserk  = 59620,
}
local FLASK_STONE = { item = 46379, aura = 53758 }
local POT_ARMOR   = 40093
local POT_HEALTH  = 33447
local FLASK_SP = { item = 46376, aura = 53755 }
local POT_MANA = 33448
local FLASK_FURY = { item = 46377, aura = 53760 }
local POT_SPEED  = 40211
local FOOD_FEAST = { item = 43015, aura = 57399 }
local FOOD_ARP   = { item = 42995, aura = 57358 }
ns.rotation = ns.rotation or {}
ns.rotation.PALADIN = {
    prot_tank = {
        buffs = { S.sealVeng, S.rf },
        raidBuffs = { S.sanct, S.glKings, S.glMight, S.glWisdom },
        raidReagents = { { item = 21177, min = 100 } },
        flask   = FLASK_STONE,
        food    = { { item = 43015, aura = 57399 } },
        potions = { POT_ARMOR, POT_HEALTH },
        track = {
            procs = {
                { id = S.plea, note = "висит всегда: обновляется автоатакой, даёт ману и с символом 3% снижения урона. Слетела, значит стоишь без автоатаки." },
            },
            cds = {
                { id = S.holyShld, note = "по кд: блок и угроза, держать без пауз." },
                { id = S.avShield, note = "по кд в слот девятки: рывок угрозы и оглушение." },
                { id = S.dprot,    note = "главный сейв: 50% меньше урона 12 секунд." },
                { id = S.taunt,    note = "таунт с уроном, если цель ещё не на тебе." },
                { id = S.rd,       off = true, note = "второй таунт: снять до трёх целей с союзника." },
                { id = S.dsac,     off = true, note = "рейд получает на 20% меньше урона; перенаправление снять макросом." },
                { id = S.wings,    off = true, note = "только на пуле: после крыльев 30 секунд нет Божественной защиты." },
                { id = S.loh,      off = true, note = "себе или второму танку, когда сейвы кончились." },
            },
            dots = {
                { id = S.hvStack, needs = S.sealVeng, note = "стак печати на боссе: держать на 5, каждый стак растит урон печати и Правосудия." },
                { id = S.bloodCorr, needs = S.sealCorr, note = "Стак {s:53736} на боссе у Орды: держать на 5, как и у Альянса." },
                { id = S.jol,     note = "должно висеть на боссе: бьющие лечатся, Клятва обновляется." },
            },
        },
    },
    holy = {
        buffs = { S.sealWis, { id = S.rf, off = true } },
        raidBuffs = { S.glKings, S.glMight, S.glWisdom },
        raidReagents = { { item = 21177, min = 100 } },
        flask   = FLASK_SP,
        food    = { { item = 43015, aura = 57399 }, { item = 34767, aura = 57327 } },
        potions = { POT_MANA, POT_SPEED },
        track = {
            procs = {
                { id = S.lightsGrace, note = "после Света небес следующий Свет небес на полсекунды быстрее, 15 сек: не давать ему кончаться." },
                { id = S.infusion, note = "крит Шока небес: следующая Вспышка Света мгновенная, а Свет небес критует на 20% чаще." },
                { id = S.jotp, note = "15% скорости с любого Правосудия на минуту: слетело, значит джагу забыл." },
            },
            cds = {
                { id = S.hs,       note = "по кд: мгновенное исцеление и заряд Прилива Света." },
                { id = S.favor,    note = "перед Шоком, когда нужна гарантированная мгновенная Вспышка." },
                { id = S.plea,     note = "с половины маны, в спокойное окно." },
                { id = S.illum,    note = "самое сильное окно: 15 секунд лечишь за полцены." },
                { id = S.wings,    note = "исцеление на 20% сильнее 20 секунд: под залп, вместе с тринкетами." },
                { id = S.auraMast, off = true, note = "под известный магический залп, с аурой нужной школы." },
                { id = S.dsac,     off = true, note = "рейд получает на 20% меньше урона, перенаправление снять с себя макросом." },
                { id = S.loh,      off = true, note = "танк, который умрёт на следующем ударе." },
            },
            dots = {
                { id = S.jol, note = "висит на боссе всегда: бьющие лечатся, ты получаешь скорость." },
            },
        },
    },
    prot_dps = {
        buffs = {
            { id = S.sealVeng, alt = { S.sealCmd } },
            { id = S.sealCorr, alt = { S.sealCmd } },
            { id = S.rf, off = true },
        },
        raidBuffs = { S.sanct, S.glKings, S.glMight, S.glWisdom },
        raidReagents = { { item = 21177, min = 100 } },
        flask   = FLASK_FURY,
        food    = { FOOD_FEAST, FOOD_ARP },
        potions = { POT_SPEED },
        track = {
            procs = {
                { id = S.plea, note = "Мана дд-защиты: лечения по тебе нет, и Духовное созвучие молчит. С талантом Под охраной света обновляется автоатакой и висит весь бой." },
                { id = S.berserk, needs = true, off = true, note = "Прок зачарования Берсерк: 400 силы атаки на 15 секунд. Включи, если оружие зачаровано им." },
            },
            cds = {
                { id = S.wings,    note = "По кд, вместе с зельем скорости и тринкетами: весь бурст в одно окно." },
                { id = S.avShield, note = "Самый сильный удар круга: по кд, на пачке бьёт три цели." },
                { id = S.hwT,      off = true, note = "По нежити: урон по площади и оглушение, в Цитадели жать по кд." },
                { id = S.holyShld, off = true, note = "Урон идёт только с блоков: жать, когда по тебе бьют, иначе это пустая девятка." },
                { id = S.dsac,     off = true, note = "Рейд получает на 20% меньше урона 6 секунд: под известный залп, перенаправление снять макросом." },
                { id = S.loh,      off = true, note = "Танку или лекарю, который умрёт на следующем ударе." },
            },
            dots = {
                { id = S.hvStack,   needs = S.sealVeng, note = "Стак печати на цели: держать на 5, каждый стак растит урон печати и Правосудия." },
                { id = S.bloodCorr, needs = S.sealCorr, note = "То же у Орды: стак {s:53736} держать на 5." },
                { id = S.judge,     off = true, note = "Правосудие мудрости на боссе: мана рейду. Кто из паладинов держит какое Правосудие, договориться до пула." },
                { id = S.jol,       off = true, note = "Правосудие Света на боссе, если мудрость держит другой паладин." },
            },
        },
    },
    ret_agi = {
        buffs = { S.sealVeng, S.sealCmd, { id = S.rf, off = true } },
        raidBuffs = { S.glKings, S.glMight, S.glWisdom },
        raidReagents = { { item = 21177, min = 100 } },
        flask   = FLASK_FURY,
        food    = { { item = 43015, aura = 57399 } },
        potions = { POT_SPEED },
        track = {
            procs = {
                { id = S.aow, note = "критами в ближнем бою заряжает мгновенный Экзорцизм — не давать прокам сгорать." },
            },
            cds = {
                { id = S.wings, note = "по кд, вместе с зельем и тринкетами — весь бурст в одно окно." },
            },
            dots = {
                { id = S.hvStack, needs = S.sealVeng, note = "стак печати: держать на 5, каждый стак растит урон печати. Орда видит его как Порча крови." },
                { id = S.bloodCorr, needs = S.sealCorr, note = "Стак {s:53736} у Орды: держать на 5, каждый стак растит урон печати." },
            },
        },
    },
}
