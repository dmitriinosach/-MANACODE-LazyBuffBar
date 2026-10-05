local ADDON, ns = ...
ns.profiles = {
    WARRIOR = {
        arms = { phys = true, melee = true },
        fury = { phys = true, melee = true },
        prot = { phys = true, melee = true },
    },
    PALADIN = {
        holy      = { spell = true, mana = true },
        prot_tank = { phys = true, melee = true, mana = true },
        prot_dps  = { phys = true, melee = true, mana = true },
        ret_agi   = { phys = true, melee = true, mana = true },
    },
    HUNTER = {
        bm   = { phys = true, mana = true },
        mm   = { phys = true, mana = true },
        surv = { phys = true, mana = true },
    },
    ROGUE = {
        assassination = { phys = true, melee = true },
        combat        = { phys = true, melee = true },
    },
    PRIEST = {
        disc   = { spell = true, mana = true },
        holy   = { spell = true, mana = true },
        shadow = { spell = true, mana = true },
    },
    DEATHKNIGHT = {
        blood_tank = { phys = true, melee = true },
        blood_str  = { phys = true, melee = true },
        blood_agi  = { phys = true, melee = true },
        frost      = { phys = true, melee = true },
        unholy     = { phys = true, melee = true },
    },
    SHAMAN = {
        ele       = { spell = true, mana = true },
        enh_phys  = { phys = true, melee = true, mana = true },
        enh_spell = { phys = true, melee = true, spell = true, mana = true },
        resto     = { spell = true, mana = true },
    },
    MAGE = {
        arcane = { spell = true, mana = true },
        fire   = { spell = true, mana = true },
        frost  = { spell = true, mana = true },
    },
    WARLOCK = {
        affli  = { spell = true, mana = true },
        demo   = { spell = true, mana = true },
        destro = { spell = true, mana = true },
    },
    DRUID = {
        balance = { spell = true, mana = true },
        cat     = { phys = true, melee = true },
        bear    = { phys = true, melee = true },
        resto   = { spell = true, mana = true },
    },
}
ns.profilesLoaded = true
