local _, ns = ...
ns.specs = ns.specs or {}
ns.specs.WARRIOR = {
    ru = "Воин", en = "Warrior",
    order = { "arms", "fury", "prot" },
    variants = {
        arms = { ru = "Оружие",       en = "Arms",       tab = 1, role = "dd",   base = "arms", nature = "phys", default = true },
        fury = { ru = "Неистовство",  en = "Fury",       tab = 2, role = "dd",   base = "fury", nature = "phys", default = true },
        prot = { ru = "Защита",       en = "Protection", tab = 3, role = "tank", base = "prot", nature = "tank", default = true },
    },
}
ns.specs.PALADIN = {
    ru = "Паладин", en = "Paladin",
    order = { "holy", "prot_tank", "prot_dps", "ret_agi" },
    variants = {
        holy      = { ru = "Свет",                en = "Holy",              tab = 1, role = "heal", base = "holy", nature = "caster", default = true },
        prot_tank = { ru = "Защита (танк)",        en = "Protection (tank)", tab = 2, role = "tank", base = "prot", nature = "tank", default = true },
        prot_dps  = { ru = "Защита (дд)",          en = "Protection (dps)",  tab = 2, role = "dd",  base = "prot", nature = "phys" },
        ret_agi   = { ru = "Воздаяние",            en = "Retribution",       tab = 3, role = "dd",  base = "ret", nature = "phys",  default = true },
    },
}
ns.specs.HUNTER = {
    ru = "Охотник", en = "Hunter",
    order = { "bm", "mm", "surv" },
    variants = {
        bm   = { ru = "Повелитель зверей", en = "Beast Mastery", tab = 1, role = "dd", base = "bm", nature = "phys",   default = true },
        mm   = { ru = "Стрельба",          en = "Marksmanship",  tab = 2, role = "dd", base = "mm", nature = "phys",   default = true },
        surv = { ru = "Выживание",         en = "Survival",      tab = 3, role = "dd", base = "surv", nature = "phys", default = true },
    },
}
ns.specs.ROGUE = {
    ru = "Разбойник", en = "Rogue",
    order = { "assassination", "combat", "subtlety" },
    variants = {
        assassination = { ru = "Убийство",   en = "Assassination", tab = 1, role = "dd", base = "assassination", nature = "phys", default = true },
        combat        = { ru = "Бой",        en = "Combat",        tab = 2, role = "dd", base = "combat", nature = "phys",        default = true },
        subtlety      = { ru = "Скрытность", en = "Subtlety",      tab = 3, role = "dd", base = "subtlety", nature = "phys",      default = true },
    },
}
ns.specs.PRIEST = {
    ru = "Жрец", en = "Priest",
    order = { "disc", "holy", "shadow" },
    variants = {
        disc   = { ru = "Послушание", en = "Discipline", tab = 1, role = "heal", base = "disc", nature = "caster",   default = true },
        holy   = { ru = "Свет",       en = "Holy",       tab = 2, role = "heal", base = "holy", nature = "caster",   default = true },
        shadow = { ru = "Тьма",       en = "Shadow",     tab = 3, role = "dd",  base = "shadow", nature = "caster", default = true },
    },
}
ns.specs.DEATHKNIGHT = {
    ru = "Рыцарь смерти", en = "Death Knight",
    order = { "blood_tank", "blood_str", "blood_agi", "frost", "unholy" },
    variants = {
        blood_tank = { ru = "Кровь (танк)",          en = "Blood (tank)",      tab = 1, role = "tank", base = "blood", nature = "tank", default = true },
        blood_str  = { ru = "Кровь (дд, сила)",       en = "Blood (dps, str)",  tab = 1, role = "dd",  base = "blood", nature = "phys" },
        blood_agi  = { ru = "Кровь (дд, ловкость)",   en = "Blood (dps, agi)",  tab = 1, role = "dd",  base = "blood", nature = "phys" },
        frost      = { ru = "Лёд",                    en = "Frost",             tab = 2, role = "dd",  base = "frost", nature = "phys",  default = true },
        unholy     = { ru = "Нечестивость",           en = "Unholy",            tab = 3, role = "dd",  base = "unholy", nature = "phys", default = true },
    },
}
ns.specs.SHAMAN = {
    ru = "Шаман", en = "Shaman",
    order = { "ele", "enh_phys", "enh_spell", "resto" },
    variants = {
        ele       = { ru = "Стихии",                       en = "Elemental",             tab = 1, role = "dd",  base = "ele", nature = "caster",   default = true },
        enh_phys  = { ru = "Совершенствование (физ)",       en = "Enhancement (phys)",    tab = 2, role = "dd",  base = "enh", nature = "phys",   default = true },
        enh_spell = { ru = "Совершенствование (спеллхенс)", en = "Enhancement (spellh.)", tab = 2, role = "dd",  base = "enh", nature = "caster" },
        resto     = { ru = "Восстановление",               en = "Restoration",           tab = 3, role = "heal", base = "resto", nature = "caster", default = true },
    },
}
ns.specs.MAGE = {
    ru = "Маг", en = "Mage",
    order = { "arcane", "fire", "frost" },
    variants = {
        arcane = { ru = "Тайная магия", en = "Arcane", tab = 1, role = "dd", base = "arcane", nature = "caster", default = true },
        fire   = { ru = "Огонь",        en = "Fire",   tab = 2, role = "dd", base = "fire", nature = "caster",   default = true },
        frost  = { ru = "Лёд",          en = "Frost",  tab = 3, role = "dd", base = "frost", nature = "caster",  default = true },
    },
}
ns.specs.WARLOCK = {
    ru = "Чернокнижник", en = "Warlock",
    order = { "affli", "demo", "destro" },
    variants = {
        affli  = { ru = "Колдовство",   en = "Affliction",  tab = 1, role = "dd", base = "affli", nature = "caster",  default = true },
        demo   = { ru = "Демонология",  en = "Demonology",  tab = 2, role = "dd", base = "demo", nature = "caster",   default = true },
        destro = { ru = "Разрушение",   en = "Destruction", tab = 3, role = "dd", base = "destro", nature = "caster", default = true },
    },
}
ns.specs.DRUID = {
    ru = "Друид", en = "Druid",
    order = { "balance", "cat", "bear", "resto" },
    variants = {
        balance = { ru = "Баланс",               en = "Balance",      tab = 1, role = "dd",  base = "balance", nature = "caster", default = true },
        cat     = { ru = "Сила зверя — Кот",     en = "Feral (cat)",  tab = 2, role = "dd",  base = "feral", nature = "phys",   default = true },
        bear    = { ru = "Сила зверя — Медведь", en = "Feral (bear)", tab = 2, role = "tank", base = "feral", nature = "tank" },
        resto   = { ru = "Восстановление",       en = "Restoration",  tab = 3, role = "heal", base = "resto", nature = "caster",   default = true },
    },
}
function ns.DefaultVariant(class, tab)
    local c = ns.specs[class]
    if not c then return nil end
    for _, key in ipairs(c.order) do
        local v = c.variants[key]
        if v.tab == tab and v.default then return key end
    end
    for _, key in ipairs(c.order) do
        if c.variants[key].tab == tab then return key end
    end
    return nil
end
function ns.SpecInfo(class, variant)
    local c = ns.specs[class]
    return c and c.variants[variant] or nil
end
local NAME_FIELD = { ruRU = "ru", enUS = "en", esES = "es", ptBR = "pt" }
function ns.LocalName(info)
    if not info then return nil end
    local f = NAME_FIELD[(ns.CurrentLocale and ns.CurrentLocale()) or "ruRU"] or "ru"
    return info[f] or info.en or info.ru
end
ns.CLASS_NAME = ns.CLASS_NAME or {}
setmetatable(ns.CLASS_NAME, { __index = function(_, token)
    return ns.LocalName(ns.specs[token])
end })
function ns.ClassName(class)
    return ns.LocalName(ns.specs[class]) or class
end
