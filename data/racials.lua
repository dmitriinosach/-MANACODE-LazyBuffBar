local _, ns = ...
local FURY_AP = { WARRIOR = true, HUNTER = true, ROGUE = true, DEATHKNIGHT = true }
local TORRENT_MANA = { PALADIN = true, HUNTER = true, PRIEST = true, MAGE = true, WARLOCK = true }
ns.racials = {
    Human = {
        { id = 59752, off = true },
    },
    Orc = {
        { id = 20572, classes = FURY_AP },
        { id = 33697, classes = { SHAMAN = true } },
        { id = 33702, classes = { WARLOCK = true } },
    },
    Dwarf = {
        { id = 20594, off = true },
    },
    NightElf = {
        { id = 58984, off = true },
    },
    Scourge = {
        { id = 7744, off = true },
    },
    Tauren = {
        { id = 20549, off = true },
    },
    Gnome = {
        { id = 20589, off = true },
    },
    Troll = {
        { id = 26297 },
    },
    BloodElf = {
        { id = 28730, classes = TORRENT_MANA },
        { id = 25046, classes = { ROGUE = true } },
        { id = 50613, classes = { DEATHKNIGHT = true } },
    },
    Draenei = {
        { id = 28880, classes = { WARRIOR = true } },
        { id = 59542, classes = { PALADIN = true } },
        { id = 59543, classes = { HUNTER = true } },
        { id = 59544, classes = { PRIEST = true } },
        { id = 59545, classes = { DEATHKNIGHT = true } },
        { id = 59547, classes = { SHAMAN = true } },
        { id = 59548, classes = { MAGE = true } },
    },
}
