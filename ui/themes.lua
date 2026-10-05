local ADDON, ns = ...
ns.themes = {}
local ACH_CAT       = "Interface\\AchievementFrame\\UI-Achievement-Category-Background"
local ACH_BAR_COORD = { 0, 0.6640625, 0, 0.796875 }
local DLG_INSET     = { left = 11, right = 12, top = 12, bottom = 11 }
local ACCENT = { 0.22, 0.72, 0.32 }
ns.ACCENT = ACCENT
ns.LINK = { 0.4, 0.85, 1.0 }
ns.QMARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local COIN = "|TInterface\\MoneyFrame\\UI-%sIcon:12:12:2:0|t"
function ns.GoldString(copper)
    if not copper or copper <= 0 then return nil end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local out = {}
    if g > 0 then out[#out + 1] = g .. COIN:format("Gold") end
    if s > 0 then out[#out + 1] = s .. COIN:format("Silver") end
    if c > 0 or #out == 0 then out[#out + 1] = c .. COIN:format("Copper") end
    return table.concat(out, " ")
end
function ns.ClassColor(token)
    local pal = _G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS
    local c = token and pal and pal[token]
    if not c then return { 1, 1, 1 } end
    return { c.r, c.g, c.b }
end
local PRIMARY = { 1, 1, 1 }
local SECONDARY = { 1, 1, 1 }
ns.themes.parchment = {
    label = "Пергамент", labelKey = "settings.theme.parchment",
    window = {
        backdrop = {
            bgFile   = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = false, edgeSize = 32, insets = DLG_INSET,
        },
        bgColor     = { 0.72, 0.64, 0.5, 1 },
        borderColor = { 1, 1, 1, 1 },
    },
    bossPlate  = { tex = ACH_CAT, coord = ACH_BAR_COORD, color = { 1, 0.88, 0.62, 1 } },
    panel = {
        backdrop = {
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        },
        bgColor     = { 0, 0, 0, 0.6 },
        borderColor = { 1, 1, 1, 1 },
    },
    text = { primary = PRIMARY, secondary = SECONDARY, shadow = false },
    card = {
        bg    = { 1, 1, 1, 0.06 },
        frame = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                  edgeSize = 12, color = { 0.72, 0.60, 0.38, 0.7 }, over = 1 },
    },
    bossCard = {
        bg      = { 0.10, 0.11, 0.12, 0.75 },
        name    = { 1, 0.82, 0 },
        sub     = SECONDARY,
        avatarBg = { 0, 0, 0, 0.45 },
        frame   = {
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            color    = { 0.72, 0.60, 0.38, 1 },
            over     = 2,
        },
    },
    tabbar = {
        bar        = { 0.05, 0.06, 0.05, 0.85 },
        frame      = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                       edgeSize = 12, color = { 1.0, 0.675, 0.125, 1 }, over = 2 },
        navHover   = { 1, 1, 1, 0.06 },
        sep        = { 1, 1, 1, 0.15 },
        chipMark   = { tex = "Interface\\Buttons\\Arrow-Up-Up",
                       coord = { 0, 0.9375, 0.4375, 0.9375 }, w = 15, h = 8 },
        underline  = { 1.0, 0.82, 0.25, 1 },
        textActive = { 1, 1, 1 },
        textIdle   = SECONDARY,
        textHover  = { 1, 1, 1 },
    },
    button = {
        backdrop = {
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        },
        bg          = { 0, 0, 0, 0.7 },
        bgHover     = { 0, 0, 0, 0.45 },
        bgActive    = { ACCENT[1] * 0.4, ACCENT[2] * 0.4, ACCENT[3] * 0.4, 0.95 },
        bgOff       = { 0, 0, 0, 0.75 },
        border      = { 1, 0.82, 0, 0.65 },
        borderHover = { 1, 0.82, 0, 1 },
        borderActive = { 1, 0.82, 0, 1 },
        borderOff   = { 0.45, 0.45, 0.45, 0.6 },
        text        = SECONDARY,
        textHover   = { 1, 1, 1 },
        textActive  = { 1, 1, 1 },
        textOff     = { 0.45, 0.45, 0.45 },
    },
    check = {
        box       = { tex = "Interface\\Buttons\\UI-CheckBox-Up" },
        mark      = { tex = "Interface\\Buttons\\UI-CheckBox-Check" },
        boxColor      = { 1, 1, 1, 1 },
        boxColorHover = { 1, 1, 1, 1 },
        markColor     = { ACCENT[1] + 0.3, 1, ACCENT[3] + 0.3, 1 },
        label         = PRIMARY,
        labelHover    = { 1, 1, 1 },
    },
    bossRow = {
        tex       = ACH_CAT,
        coord     = ACH_BAR_COORD,
        bg        = { 0.10, 0.11, 0.12, 0.55 },
        bgHover   = { 0.14, 0.16, 0.15, 0.85 },
        marker    = { ACCENT[1], ACCENT[2], ACCENT[3], 1 },
        name      = { 1, 0.96, 0.88 },
        nameHover = { 1, 1, 1 },
        sub       = SECONDARY,
        frame     = {
            tex   = "Interface\\AchievementFrame\\UI-Achievement-IconFrame",
            coord = { 0, 0.5625, 0, 0.5625 },
            scale = 1.5,
            color      = { 1, 1, 1, 1 },
            colorHover = { ACCENT[1] + 0.3, 1, ACCENT[3] + 0.3, 1 },
            smallDesat = true,
            colorSmall      = { 0.72, 0.72, 0.72, 1 },
            colorSmallHover = { 0.95, 0.95, 0.95, 1 },
        },
    },
}
local DLG_BG    = "Interface\\DialogFrame\\UI-DialogBox-Background"
local DLG_DARK  = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark"
local DLG_EDGE  = "Interface\\DialogFrame\\UI-DialogBox-Border"
local DLG_GOLD  = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border"
local TIP_BG    = "Interface\\Tooltips\\UI-Tooltip-Background"
local TIP_EDGE  = "Interface\\Tooltips\\UI-Tooltip-Border"
local ACH_BG = "Interface\\AchievementFrame\\UI-Achievement-AchievementBackground"
local WHITE  = "Interface\\Buttons\\WHITE8X8"
local PVP_TEX     = "Interface\\PVPFrame\\UI-Character-PVP"
local PVP_STRIP   = { 0, 0.65625, 0.1875, 0.2305 }
local PVP_ENGRAVE = { 0, 0.65625, 0.2383, 0.7617 }
local LFG_FILIGREE       = "Interface\\LFGFrame\\UI-LFG-FILIGREE"
local LFG_FILIGREE_COORD = { 0, 0.5996094, 0.03125, 0.8984375 }
local LFG_WALL      = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-DUNGEONWALL"
local STONE_SLAB  = "Interface\\ItemTextFrame\\ItemText-Stone-TopLeft"
local SLAB_COORD  = { 0.03125, 1, 0.046875, 1 }
local LFG_BG_COORD  = { 0, 0.6367188, 0.14, 0.86 }
local WOOD_EDGE = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder"
local function panelOf(edgeFile, bg)
    return {
        backdrop = {
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = edgeFile,
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        },
        bgColor     = bg,
        borderColor = { 1, 1, 1, 1 },
    }
end
ns.themes.flat = {
    label = "Плоский", labelKey = "settings.theme.flat",
    window = {
        backdrop = {
            bgFile   = TIP_BG,
            edgeFile = TIP_EDGE,
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        },
        bgColor = { 0.03, 0.04, 0.05, 0.94 }, borderColor = { 0.42, 0.47, 0.54, 1 },
        decor = {
            { tex = WHITE, color = { 0.04, 0.05, 0.06 }, alpha = 0.96, inset = 5, sub = -1 },
        },
    },
    bossPlate = { color = { 0.52, 0.60, 0.72, 1 } },
    tabbar = {
        bar       = { 0.09, 0.10, 0.12, 0.9 },
        frame     = { edgeFile = TIP_EDGE, edgeSize = 12,
                      color = { 0.45, 0.52, 0.62, 1 }, over = 2 },
        underline = { 0.45, 0.78, 1.0, 1 },
        sep       = { 1, 1, 1, 0.12 },
    },
    bossRow = {
        bg = { 0.07, 0.08, 0.10, 0.7 }, bgHover = { 0.12, 0.14, 0.17, 0.9 },
        name = { 0.88, 0.92, 1.0 },
        frame = { color = { 0.55, 0.62, 0.72, 1 }, colorHover = { 0.78, 0.9, 1, 1 } },
    },
    bossCard = {
        bg = { 0.06, 0.07, 0.09, 0.8 }, name = { 0.72, 0.86, 1.0 },
        frame = { edgeFile = TIP_EDGE, color = { 0.45, 0.52, 0.62, 1 } },
    },
    card = { bg = { 1, 1, 1, 0.05 }, frame = { edgeFile = TIP_EDGE, edgeSize = 12,
             color = { 0.45, 0.52, 0.62, 0.8 }, over = 1 } },
    panel = panelOf(TIP_EDGE, { 0, 0, 0, 0.9 }),
}
ns.themes.pvp = {
    label = "Поле боя", labelKey = "settings.theme.pvp",
    window = {
        backdrop = {
            bgFile = DLG_BG, edgeFile = DLG_GOLD,
            tile = true, tileSize = 32, edgeSize = 32, insets = DLG_INSET,
        },
        bgColor     = { 1, 1, 1, 1 },
        borderColor = { 0.72, 0.78, 0.88, 1 },
        decor = {
            { tex = ACH_BG, color = { 0.40, 0.44, 0.50 }, inset = 10, sub = -1 },
        },
    },
    bossPlate = { color = { 0.80, 0.84, 0.92, 1 } },
    tabbar = {
        bar   = { 0.06, 0.07, 0.08, 0.85 },
        fill  = { tex = PVP_TEX, coord = PVP_STRIP, color = { 1, 1, 1, 0.7 } },
        frame = { edgeFile = TIP_EDGE, edgeSize = 12,
                  color = { 0.78, 0.81, 0.88, 1 }, over = 2 },
        sep       = { 1, 1, 1, 0.22 },
        underline = { 0.95, 0.86, 0.55, 1 },
    },
    bossRow = {
        bg = { 0.10, 0.11, 0.13, 0.6 }, bgHover = { 0.16, 0.17, 0.20, 0.88 },
        frame = { color = { 0.84, 0.87, 0.92, 1 } },
    },
    bossCard = { frame = { color = { 0.74, 0.78, 0.86, 1 } } },
    card = { bg = { 0, 0, 0, 0.35 }, frame = { edgeFile = TIP_EDGE, edgeSize = 12,
             color = { 0.78, 0.81, 0.88, 0.7 }, over = 1 } },
    panel = panelOf(DLG_EDGE, { 0.05, 0.06, 0.07, 0.72 }),
}
ns.themes.lfg = {
    label = "Подземелье", labelKey = "settings.theme.lfg",
    window = {
        backdrop = {
            bgFile = DLG_BG, edgeFile = DLG_EDGE,
            tile = true, tileSize = 32, edgeSize = 32, insets = DLG_INSET,
        },
        bgColor     = { 1, 1, 1, 1 },
        borderColor = { 1, 1, 1, 1 },
        decor = {
            { tex = WHITE,  color = { 0.62, 0.44, 0.26 }, inset = 10, sub = -3 },
            { tex = LFG_WALL, coord = LFG_BG_COORD, tileAspect = 0.564,
              inset = 10, sub = -2 },
            { tex = WHITE, h = 130, y = 10, inset = 10, sub = -1,
              grad = { dir = "VERTICAL",
                       from = { 0.10, 0.18, 0.34, 0 },
                       to   = { 0.10, 0.20, 0.40, 0.85 } } },
        },
    },
    bossPlate = { color = { 0.95, 0.86, 0.68, 1 } },
    tabbar = {
        bar       = { 0.07, 0.06, 0.05, 0.85 },
        frame     = { edgeFile = TIP_EDGE, edgeSize = 12,
                      color = { 0.92, 0.78, 0.45, 1 }, over = 2 },
        underline = { 0.55, 0.80, 1.0, 1 },
    },
    bossRow = {
        bg = { 0.12, 0.10, 0.08, 0.6 }, bgHover = { 0.18, 0.15, 0.11, 0.9 },
        frame = { color = { 0.95, 0.85, 0.6, 1 } },
    },
    card = { bg = { 0, 0, 0, 0.38 }, frame = { edgeFile = TIP_EDGE, edgeSize = 12,
             color = { 0.92, 0.78, 0.45, 0.6 }, over = 1 } },
    panel = panelOf(DLG_EDGE, { 0.07, 0.06, 0.04, 0.72 }),
}
ns.themes.gold = {
    label = "Тёмное золото", labelKey = "settings.theme.gold",
    window = {
        backdrop = {
            bgFile = DLG_DARK, edgeFile = WOOD_EDGE,
            tile = true, tileSize = 32, edgeSize = 32, insets = DLG_INSET,
        },
        bgColor = { 1, 1, 1, 1 }, borderColor = { 1, 1, 1, 1 },
        decor = {
            { tex = ACH_BG, color = { 0.26, 0.20, 0.12 }, inset = 10, sub = -1 },
        },
    },
    bossPlate = { color = { 1, 0.84, 0.5, 1 } },
    tabbar = {
        bar       = { 0.08, 0.06, 0.03, 0.88 },
        frame     = { edgeFile = TIP_EDGE, edgeSize = 12,
                      color = { 1, 0.78, 0.25, 1 }, over = 2 },
        underline = { 1, 0.86, 0.35, 1 },
    },
    bossRow = {
        bg = { 0.12, 0.09, 0.05, 0.65 }, bgHover = { 0.18, 0.14, 0.07, 0.9 },
        name = { 1, 0.93, 0.78 },
        frame = { color = { 1, 0.88, 0.55, 1 } },
    },
    bossCard = { frame = { color = { 0.9, 0.74, 0.38, 1 } } },
    card = { bg = { 0, 0, 0, 0.35 }, frame = { edgeFile = TIP_EDGE, edgeSize = 12,
             color = { 1, 0.84, 0.4, 0.55 }, over = 1 } },
    panel = panelOf(DLG_GOLD, { 0.08, 0.06, 0.02, 0.72 }),
}
ns.themes.stone = {
    label = "Камень", labelKey = "settings.theme.stone",
    window = {
        backdrop = {
            bgFile = DLG_BG, edgeFile = DLG_EDGE,
            tile = true, tileSize = 32, edgeSize = 32, insets = DLG_INSET,
        },
        bgColor = { 1, 1, 1, 1 }, borderColor = { 1, 1, 1, 1 },
        decor = {
            { tex = STONE_SLAB, coord = SLAB_COORD, tile = 244,
              inset = 10, sub = -1 },
        },
    },
    bossPlate = { color = { 0.78, 0.80, 0.86, 1 } },
    tabbar = {
        bar       = { 0.05, 0.05, 0.06, 0.85 },
        frame     = { edgeFile = TIP_EDGE, edgeSize = 12,
                      color = { 0.70, 0.72, 0.78, 1 }, over = 2 },
        underline = { 0.85, 0.88, 0.95, 1 },
    },
    bossRow = {
        bg = { 0.12, 0.12, 0.14, 0.6 }, bgHover = { 0.18, 0.18, 0.21, 0.9 },
        frame = { color = { 0.82, 0.84, 0.9, 1 } },
    },
    card = { bg = { 0, 0, 0, 0.38 }, frame = { edgeFile = TIP_EDGE, edgeSize = 12,
             color = { 0.65, 0.68, 0.74, 0.8 }, over = 1 } },
    panel = panelOf(DLG_EDGE, { 0.06, 0.06, 0.07, 0.72 }),
}
ns.themeOrder = { "parchment", "stone", "pvp", "lfg", "gold", "flat" }
local function deepCopy(src)
    if type(src) ~= "table" then return src end
    local out = {}
    for k, v in pairs(src) do out[k] = deepCopy(v) end
    return out
end
local function inherit(t, base)
    for k, v in pairs(base) do
        if t[k] == nil then
            t[k] = deepCopy(v)
        elseif type(t[k]) == "table" and type(v) == "table" and t[k][1] == nil then
            inherit(t[k], v)
        end
    end
end
local ETALON = ns.themes.parchment
for _, id in ipairs(ns.themeOrder) do
    local t = ns.themes[id]
    if t ~= ETALON then inherit(t, ETALON) end
end
ns.themesLoaded = true
