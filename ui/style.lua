local _, ns = ...
ns.Style = {}
local St = ns.Style
local function opts(list)
    local out = {}
    for i, o in ipairs(list) do out[i] = { key = o[1], code = o[2], item = o[3] or nil } end
    return out
end
St.KNOBS = {
    edge = { def = "square", all = true, bar = true, item = true, look = true, opts = opts({
        { "square", "V1" }, { "thin", "V2" }, { "thick", "V3" }, { "soft", "V4" }, { "round", "V5" },
        { "gold", "V6" }, { "goldflat", "V7" }, { "silver", "V8" }, { "bronze", "V9" }, { "brick", "V10" },
        { "quality", "V11" }, { "class", "V12" }, { "glass", "V13" }, { "blizz", "V14" }, { "state", "V15" },
        { "color", "V16" }, { "rounded", "V17" }, { "roundgold", "V18" }, { "talent", "V19" }, { "native", "V20" },
        { "socket", "V21" }, { "darkglow", "V22" }, { "action", "V23" }, { "roundcolor", "V24" },
    }) },
    edgeColor = { def = "gold", all = true, bar = true, item = true, opts = opts({
        { "gold", "V16" }, { "silver", "V16" }, { "bronze", "V16" }, { "red", "V16" }, { "green", "V16" },
        { "blue", "V16" }, { "purple", "V16" }, { "white", "V16" }, { "class", "V16" },
    }) },
    frame = { def = "auto", all = true, bar = true, item = false, opts = opts({
        { "auto", "P3" }, { "none", "P1" }, { "thin", "P2" }, { "plate", "P3" }, { "soft", "P4" }, { "titled", "P5" },
        { "corners", "P7" }, { "brackets", "P8" }, { "gold", "P9" }, { "silver", "P10" }, { "underline", "P11" },
        { "glow", "P12" }, { "dialog", "P13" },
    }) },
    title = { def = "off", all = true, bar = true, item = false, opts = opts({ { "off", "P6" }, { "on", "P6" } }) },
    cd = { def = "auto", all = true, bar = true, item = true, opts = opts({
        { "auto", "C1" }, { "spiral", "C1" }, { "edge", "C2" }, { "reverse", "C3" }, { "rocket", "C4" }, { "rocketBack", "C5" },
        { "strip", "C6" }, { "number", "C7" }, { "fillUp", "C8" }, { "fillDown", "C9" }, { "curtain", "C10" },
        { "ring", "C11" },
    }) },
    ready = { def = "auto", all = true, bar = true, item = false, opts = opts({
        { "auto", "C13" }, { "flash", "C12" }, { "nova", "S24" }, { "pulse", "S23" }, { "ants", "S22" },
        { "white", "S25" }, { "shine", "S26" }, { "none", "S27" },
    }) },
    soon = { def = "none", all = true, bar = true, item = false, opts = opts({
        { "none", "S27" }, { "red", "N13" }, { "pulse", "S28" }, { "edge", "S29" }, { "strip", "S30" }, { "ramp", "C14" },
    }) },
    mana = { def = "pic", all = true, bar = true, item = false, opts = opts({
        { "pic", "S2" }, { "all", "S1" }, { "edge", "S3" }, { "drop", "S4" }, { "cost", "S5" }, { "dim", "S6" },
        { "none", "S2" },
    }) },
    range = { def = "pic", all = true, bar = true, item = false, opts = opts({
        { "pic", "S9" }, { "all", "S8" }, { "edge", "S10" }, { "digit", "S7" }, { "under", "S11" }, { "arrow", "S12" },
        { "none", "S9" },
    }) },
    place = { def = "layout", all = false, bar = true, item = true, opts = opts({
        { "layout", "N2" }, { "center", "N2" }, { "bottom", "N3" }, { "top", "N4" },
        { "big", "N1" }, { "corner", "N5" }, { "above", "N6" }, { "none", "N11" },
    }) },
    fmt = { def = "now", all = true, bar = true, item = false, opts = opts({
        { "now", "N10" }, { "omni", "N8" }, { "mmss", "N7" }, { "int", "N9" },
    }) },
    ncolor = { def = "white", all = true, bar = true, item = true, opts = opts({
        { "white", "N14" }, { "remain", "N13" }, { "gold", "N15" }, { "class", "N16" },
    }) },
    stacks = { def = "normal", all = true, bar = true, item = false, opts = opts({
        { "normal", "N18" }, { "big", "N19" }, { "badge", "N21" },
    }) },
    bag = { def = "bottom", all = true, bar = true, item = true, opts = opts({
        { "bottom", "N22" }, { "top", "N18" }, { "none", "N11" },
    }) },
    font = { def = "own", all = true, bar = false, item = false, opts = opts({
        { "own", "N25" }, { "friz", "N24" }, { "skurri", "N26" }, { "morpheus", "N27" },
    }) },
    outline = { def = "soft", all = true, bar = true, item = false, opts = opts({
        { "outline", "N29" }, { "shadow", "N28" }, { "thick", "N30" }, { "soft", "N31" }, { "none", "N32" },
    }) },
    nscale = { def = 1, all = true, bar = true, item = true, opts = opts({
        { 0.75, "N33" }, { 0.9, "N33" }, { 1, "N33" }, { 1.15, "N33" }, { 1.3, "N33" }, { 1.5, "N33" },
    }) },
}
St.ORDER = { "edge", "edgeColor", "frame", "title", "cd", "ready", "soon", "mana", "range",
             "place", "fmt", "ncolor", "stacks", "bag", "nscale", "outline", "font" }
for key, k in pairs(St.KNOBS) do k.key = key end
St.THEMES = {
    T1 = { edge = "thin", frame = "none", cd = "strip", place = "top", ncolor = "remain", ready = "none",
           mana = "edge", range = "edge", soon = "red" },
    T2 = { edge = "gold", frame = "gold", title = "on", cd = "spiral", ncolor = "gold", ready = "ants",
           mana = "pic", range = "pic", soon = "red" },
    T3 = { edge = "blizz", frame = "plate", cd = "spiral", place = "bottom", ncolor = "white", ready = "ants",
           mana = "all", range = "all", soon = "none" },
    T4 = { edge = "state", frame = "soft", cd = "edge", place = "big", ncolor = "remain", ready = "pulse",
           soon = "pulse", mana = "pic", range = "pic" },
}
St.THEME_ORDER = { "T1", "T2", "T3", "T4" }
local function db()
    LazyBuffBarDB = LazyBuffBarDB or {}
    return LazyBuffBarDB
end
local function same(a, b)
    if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 0.001 end
    return a == b
end
function St.Knob(key)
    return St.KNOBS[key]
end
function St.Valid(key, v, level)
    local k = St.KNOBS[key]
    if not k or v == nil then return false end
    for _, o in ipairs(k.opts) do
        if same(o.key, v) then return level == "item" or not o.item end
    end
    return false
end
function St.Options(key, level)
    local out = {}
    local k = St.KNOBS[key]
    if not k then return out end
    for _, o in ipairs(k.opts) do
        if level == "item" or not o.item then out[#out + 1] = o end
    end
    return out
end
function St.Opt(key, v)
    local k = St.KNOBS[key]
    if not k then return nil end
    for _, o in ipairs(k.opts) do
        if same(o.key, v) then return o end
    end
    return nil
end
function St.Global(key)
    local k = St.KNOBS[key]
    if not k then return nil end
    local v
    if k.look then
        local look = db().look
        v = look and look[key]
    else
        local s = db().style
        v = s and s[key]
    end
    if v == nil or not St.Valid(key, v, "all") then return k.def end
    return v
end
function St.OwnGlobal(key)
    local k = St.KNOBS[key]
    return k ~= nil and not same(St.Global(key), k.def)
end
local function fighting()
    if not InCombatLockdown() then return false end
    if ns.say then ns.say(ns.T("bar.combat")) end
    return true
end
function St.SetGlobal(key, v)
    local k = St.KNOBS[key]
    if not (k and k.all) then return false end
    if v ~= nil and not St.Valid(key, v, "all") then return false end
    if fighting() then return false end
    if v ~= nil and same(v, k.def) then v = nil end
    if k.look then
        if ns.Look.ALL[key] then ns.Look.Set(key, v == nil and ns.Look.ALL[key].def or v) end
        return true
    end
    local d = db()
    d.style = d.style or {}
    d.style[key] = v
    if not next(d.style) then d.style = nil end
    ns.Look.Changed()
    return true
end
local function blockAt(i)
    return ns.Preset and ns.Preset.Blocks and ns.Preset.Blocks()[i] or nil
end
local function barOwn(b, key)
    local s = b and b.style
    local v = type(s) == "table" and s[key] or nil
    if v ~= nil and St.Valid(key, v, "bar") then return v end
    return nil
end
local function itemOwn(it, key)
    local s = it and it.style
    local v = type(s) == "table" and s[key] or nil
    if v ~= nil and St.Valid(key, v, "item") then return v end
    return nil
end
function St.Get(key, b, it)
    local k = St.KNOBS[key]
    if not k then return nil end
    local v
    if k.item then v = itemOwn(it, key) end
    if v ~= nil then return v end
    if k.bar then v = barOwn(b, key) end
    if v ~= nil then return v end
    if k.all then return St.Global(key) end
    return k.def
end
function St.Bar(i, key)
    return St.Get(key, blockAt(i), nil)
end
function St.OwnBar(i, key)
    return barOwn(blockAt(i), key) ~= nil
end
local function with(t, key, v)
    local out = {}
    if type(t) == "table" then
        for k, x in pairs(t) do out[k] = x end
    end
    out[key] = v
    if next(out) == nil then return nil end
    return out
end
function St.WriteBar(b, t)
    local ok = ns.Preset.SetBlock(b.key, "style", t) and true or false
    if ok and ns.buffbar and ns.buffbar.ApplyTheme then ns.buffbar:ApplyTheme() end
    return ok
end
function St.SetBar(i, key, v)
    local k = St.KNOBS[key]
    local b = blockAt(i)
    if not (k and k.bar and b) then return false end
    if v ~= nil and not St.Valid(key, v, "bar") then return false end
    if fighting() then return false end
    if v ~= nil and same(v, k.all and St.Global(key) or k.def) then v = nil end
    if v == nil and barOwn(b, key) == nil then return true end
    return St.WriteBar(b, with(b.style, key, v))
end
function St.ApplyTheme(i, name)
    local b = blockAt(i)
    if not b then return false end
    local t = name and St.THEMES[name]
    if name and not t then return false end
    if fighting() then return false end
    local out
    if t then
        out = {}
        for key, v in pairs(t) do
            if St.Valid(key, v, "bar") then out[key] = v end
        end
    end
    return St.WriteBar(b, out)
end
function St.ThemeOf(i)
    local b = blockAt(i)
    local s = b and b.style
    if type(s) ~= "table" then return nil end
    for _, name in ipairs(St.THEME_ORDER) do
        local t = St.THEMES[name]
        local ok = true
        for key, v in pairs(t) do
            if not same(s[key], v) then ok = false end
        end
        for key in pairs(s) do
            if t[key] == nil then ok = false end
        end
        if ok then return name end
    end
    return nil
end
local function itemAt(key, x, y)
    local b = ns.Preset and ns.Preset.Block and ns.Preset.Block(key)
    local it = b and ns.Grid.ItemAt(b, x, y)
    return b, it
end
function St.Item(key, x, y, knob)
    local b, it = itemAt(key, x, y)
    return St.Get(knob, b, it)
end
function St.OwnItem(key, x, y, knob)
    local _, it = itemAt(key, x, y)
    return itemOwn(it, knob) ~= nil
end
function St.SetItem(key, x, y, knob, v)
    local k = St.KNOBS[knob]
    local b, it = itemAt(key, x, y)
    if not (k and k.item and it) then return false end
    if v ~= nil and not St.Valid(knob, v, "item") then return false end
    if fighting() then return false end
    if v ~= nil and same(v, St.Get(knob, b, nil)) then v = nil end
    if v == nil and itemOwn(it, knob) == nil then return true end
    return ns.Preset.Set(key, x, y, "style", with(it.style, knob, v)) and true or false
end
function St.Resolve(f, b, it)
    local st = f._st or {}
    for key, k in pairs(St.KNOBS) do
        if k.item or key ~= "frame" and key ~= "title" then st[key] = St.Get(key, b, it) end
    end
    f._st = st
    return st
end
function St.Of(f, key)
    local st = f and f._st
    local v = st and st[key]
    if v ~= nil then return v end
    return St.Get(key, nil, nil)
end
local WHITE = "Interface\\Buttons\\WHITE8X8"
local TIP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local TIP_BG = "Interface\\Tooltips\\UI-Tooltip-Background"
local QUICKSLOT = "Interface\\Buttons\\UI-Quickslot2"
local DIALOG = "Interface\\DialogFrame\\UI-DialogBox-Border"
local MEDIA = "Interface\\AddOns\\ManaCode_LazyBuffBar\\media\\"
St.METAL = MEDIA .. "metal"
St.METAL_SIZE = 6
St.GLOW = MEDIA .. "glow"
St.ROUND = MEDIA .. "round"
St.ROUND_SIZE = 6
St.ROUND_OUT = 2
local EMPTY_SLOT = "Interface\\Buttons\\UI-EmptySlot-White"
local HILITE = "Interface\\Buttons\\ButtonHilight-Square"
local COLORS = {
    black = { 0, 0, 0, 1 }, gold = { 1, 0.78, 0.25, 1 }, silver = { 0.8, 0.82, 0.88, 1 },
    bronze = { 0.82, 0.52, 0.28, 1 }, brick = { 0.72, 0.36, 0.24, 1 }, red = { 0.9, 0.15, 0.15, 1 },
    green = { 0.3, 0.85, 0.3, 1 }, blue = { 0.3, 0.55, 1, 1 }, purple = { 0.65, 0.35, 1, 1 }, white = { 1, 1, 1, 1 },
    glass = { 0.85, 0.92, 1, 0.85 }, line = { 0.35, 0.35, 0.35, 1 },
    up = { 0.3, 0.9, 0.3, 1 }, soon = { 1, 0.85, 0.2, 1 }, miss = { 0.9, 0.2, 0.2, 1 }, off = { 0.4, 0.4, 0.4, 1 },
    mana = { 0.35, 0.5, 1, 1 }, far = { 1, 0.2, 0.2, 1 },
    talent = { 0.9, 0.74, 0.32, 1 }, action = { 0.62, 0.55, 0.38, 0.85 },
}
local UNDERS = {
    action = { file = TIP_BG, out = 2, color = { 0.08, 0.07, 0.05, 0.75 } },
    socket = { file = EMPTY_SLOT, scale = 64 / 37, dy = -1, color = { 0.5, 0.5, 0.5, 1 } },
}
St.COLORS = COLORS
local EDGES = {
    rounded   = { round = true, color = "black", crop = 0.07 },
    roundgold = { round = true, color = "gold", crop = 0.07 },
    talent    = { file = TIP_EDGE, size = 9, out = 2, color = "talent", crop = 0.07 },
    native    = { crop = 0 },
    socket    = { crop = 0, socket = true, under = "socket" },
    darkglow  = { round = true, color = "black", crop = 0.07, hover = true },
    roundcolor = { round = true, crop = 0.07 },
    action    = { file = TIP_EDGE, size = 8, out = 3, color = "action", crop = 0.07, under = "action" },
    thick    = { file = WHITE, size = 2, out = 0, color = "black", crop = 0.07 },
    goldflat = { file = WHITE, size = 2, out = 1, color = "gold", crop = 0.07 },
    gold     = { metal = true, out = 2, color = "gold", crop = 0.08 },
    silver   = { metal = true, out = 2, color = "silver", crop = 0.08 },
    bronze   = { metal = true, out = 2, color = "bronze", crop = 0.08 },
    brick    = { file = WHITE, size = 3, out = 1, color = "brick", crop = 0.07 },
    quality  = { file = WHITE, size = 2, out = 1, crop = 0.07 },
    class    = { file = WHITE, size = 2, out = 1, crop = 0.07 },
    color    = { file = WHITE, size = 2, out = 1, crop = 0.07 },
    glass    = { file = WHITE, size = 1, out = 0, color = "glass", crop = 0.07, gloss = true },
    blizz    = { crop = 0.07, slot = true },
    state    = { file = WHITE, size = 2, out = 1, color = "black", crop = 0.07 },
}
St.MISS_DIM = 0.3
local COLORED = { gold = true, goldflat = true, silver = true, bronze = true, brick = true, quality = true,
                  class = true, color = true, glass = true, blizz = true, roundgold = true, talent = true,
                  socket = true, action = true, roundcolor = true }
function St.EdgeSpec(style)
    return EDGES[style]
end
function St.Colored(f)
    return COLORED[St.Of(f, "edge")] or false
end
local classColors = {}
local function classColor()
    local _, class = UnitClass("player")
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if not c then return COLORS.gold end
    local out = classColors[class]
    if not out then
        out = { c.r, c.g, c.b, 1 }
        classColors[class] = out
    end
    return out
end
local function qualityColor(f)
    local id = f.itemId or (f._entry and f._entry.item)
    local q = id and select(3, GetItemInfo(id))
    if q and GetItemQualityColor then
        local r, g, b = GetItemQualityColor(q)
        if r then return { r, g, b, 1 } end
    end
    return COLORS.black
end
function St.EdgeColor(f, style)
    local e = EDGES[style]
    if e and e.color then return COLORS[e.color] end
    if style == "quality" then return qualityColor(f) end
    if style == "class" then return classColor() end
    local c = St.Of(f, "edgeColor")
    if c == "class" then return classColor() end
    return COLORS[c] or COLORS.gold
end
local function part(e, name, layer)
    local t = e[name]
    if t then return t end
    t = e:CreateTexture(nil, layer or "OVERLAY")
    e[name] = t
    return t
end
local function gloss(f, on)
    local e = f.edge
    if not on then
        if e.gloss then e.gloss:Hide(); e.inner:Hide() end
        return
    end
    local g = part(e, "gloss", "OVERLAY")
    g:SetTexture(WHITE)
    g:SetBlendMode("ADD")
    g:ClearAllPoints()
    g:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    g:SetPoint("BOTTOMRIGHT", f, "RIGHT", -1, 0)
    if g.SetGradientAlpha then g:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.3) end
    g:Show()
    local l = part(e, "inner", "OVERLAY")
    l:SetTexture(WHITE)
    l:SetVertexColor(1, 1, 1, 0.35)
    l:ClearAllPoints()
    l:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    l:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    l:SetHeight(1)
    l:Show()
end
local function slot(f, scale, dy)
    local e = f.edge
    if not scale then
        if e.slot then e.slot:Hide() end
        return
    end
    local t = part(e, "slot", "OVERLAY")
    t:SetTexture(QUICKSLOT)
    local w = (f:GetWidth() or 32) * scale
    t:SetWidth(w)
    t:SetHeight(w)
    t:ClearAllPoints()
    t:SetPoint("CENTER", f, "CENTER", 0, dy or 0)
    t:Show()
end
local function under(f, name)
    local u = name and UNDERS[name]
    if not u then
        if f.sunder then f.sunder:Hide() end
        return
    end
    local t = f.sunder
    if not t then
        t = f:CreateTexture(nil, "BACKGROUND")
        f.sunder = t
    end
    t:SetTexture(u.file)
    t:SetVertexColor(u.color[1], u.color[2], u.color[3], u.color[4])
    t:ClearAllPoints()
    if u.scale then
        local w = (f:GetWidth() or 32) * u.scale
        t:SetWidth(w)
        t:SetHeight(w)
        t:SetPoint("CENTER", f, "CENTER", 0, u.dy or 0)
    else
        t:SetPoint("TOPLEFT", f, "TOPLEFT", -u.out, u.out)
        t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", u.out, -u.out)
    end
    t:Show()
end
local function hoverArm(f, on)
    local e = f.edge
    e.hoverOn = on or nil
    if not on then
        if e.hover then e.hover:Hide() end
        return
    end
    local t = part(e, "hover", "OVERLAY")
    t:SetTexture(HILITE)
    t:SetBlendMode("ADD")
    t:ClearAllPoints()
    t:SetAllPoints(f)
    t:Hide()
end
function St.Hover(f, on)
    local e = f and f.edge
    local t = e and e.hoverOn and e.hover
    if not t then return end
    if on then t:Show() else t:Hide() end
end
function St.EdgeKey(f, style)
    if style == "quality" or style == "class" or style == "color" or style == "roundcolor" then
        local c = St.EdgeColor(f, style)
        return style .. ":" .. c[1] .. "," .. c[2] .. "," .. c[3]
    end
    return style
end
function St.PaintEdge(f, style)
    local s = style and EDGES[style]
    gloss(f, s and s.gloss or false)
    slot(f, s and ((s.slot and 1.8) or (s.socket and 64 / 37)) or nil, s and s.socket and -1 or nil)
    under(f, s and s.under or nil)
    hoverArm(f, s and s.hover or false)
    if not s then
        f.edge._rgb, f.edge._ec = nil, nil
        return nil
    end
    local e = f.edge
    local file, size, out = s.file, s.size, s.out
    if s.metal then file, size = St.METAL, St.METAL_SIZE end
    if s.round then file, size, out = St.ROUND, St.ROUND_SIZE, St.ROUND_OUT end
    if file then
        e:ClearAllPoints()
        e:SetPoint("TOPLEFT", f, "TOPLEFT", -out, out)
        e:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", out, -out)
        e:SetBackdrop({ edgeFile = file, edgeSize = size })
        local c = St.EdgeColor(f, style)
        e._rgb = c
        e._ec = nil
        St.EdgeTint(f)
    else
        e:SetBackdrop(nil)
        e._rgb = nil
    end
    e:Show()
    return s.crop
end
function St.State(f, state)
    if f._sState == state then return end
    f._sState = state
    St.EdgeTint(f)
end
function St.EdgeTintBy(f, tint)
    if f._sTint == tint then return end
    f._sTint = tint
    St.EdgeTint(f)
end
function St.EdgeTint(f)
    local e = f.edge
    local base = e and e._rgb
    if not base then return end
    local c = base
    if f._sTint then
        c = COLORS[f._sTint]
    elseif St.Of(f, "edge") == "state" and f._sState and COLORS[f._sState] then
        c = COLORS[f._sState]
    end
    if e._ec == c then return end
    e._ec = c
    e:SetBackdropBorderColor(c[1], c[2], c[3], c[4] or 1)
end
local PLATES = {
    thin  = { bgFile = TIP_BG, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } },
    plate = { bgFile = TIP_BG, insets = { left = 0, right = 0, top = 0, bottom = 0 } },
    soft  = { bgFile = TIP_BG, edgeFile = TIP_EDGE, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 } },
}
PLATES.titled = PLATES.soft
local FILL = { plate = 0.55, soft = 0.55, titled = 0.55, gold = 0.55, silver = 0.55, dialog = 0.75 }
local RIMS = {
    gold   = { metal = true, out = 3, color = "gold" },
    silver = { metal = true, out = 3, color = "silver" },
    glow   = { glow = true, size = 12, out = 12, color = "black", alpha = 1 },
    dialog = { file = DIALOG, size = 32, out = 10, color = "white" },
}
function St.Plate(fr, frame, c, a, border)
    if frame == "none" then
        fr:SetBackdrop(nil)
        return
    end
    local bd = PLATES[frame] or PLATES.plate
    local fill = FILL[frame]
    if fill and a < fill then a = fill end
    fr:SetBackdrop(bd)
    fr:SetBackdropColor(c[1], c[2], c[3], a)
    if bd.edgeFile then
        local b = (frame == "thin") and COLORS.line or border or COLORS.black
        fr:SetBackdropBorderColor(b[1], b[2], b[3], 1)
    end
end
local function bits(d, n)
    d.bits = d.bits or {}
    for i = #d.bits + 1, n do
        local t = d:CreateTexture(nil, "OVERLAY")
        t:SetTexture(WHITE)
        d.bits[i] = t
    end
    return d.bits
end
local CORNERS = {
    { "TOPLEFT", -2, 2, 10, 2 }, { "TOPLEFT", -2, 2, 2, 10 },
    { "TOPRIGHT", 2, 2, 10, 2 }, { "TOPRIGHT", 2, 2, 2, 10 },
    { "BOTTOMLEFT", -2, -2, 10, 2 }, { "BOTTOMLEFT", -2, -2, 2, 10 },
    { "BOTTOMRIGHT", 2, -2, 10, 2 }, { "BOTTOMRIGHT", 2, -2, 2, 10 },
}
local BRACKETS = {
    { "LEFT", -4, 0, 2, 0 }, { "TOPLEFT", -4, 0, 6, 2 }, { "BOTTOMLEFT", -4, 0, 6, 2 },
    { "RIGHT", 4, 0, 2, 0 }, { "TOPRIGHT", 4, 0, 6, 2 }, { "BOTTOMRIGHT", 4, 0, 6, 2 },
}
local function bit(fr, t, spec, c)
    t:ClearAllPoints()
    t:SetPoint(spec[1], fr, spec[1], spec[2], spec[3])
    t:SetWidth(spec[4])
    if spec[5] == 0 then
        t:SetPoint("TOP", fr, "TOP", 0, 0)
        t:SetPoint("BOTTOM", fr, "BOTTOM", 0, 0)
    else
        t:SetHeight(spec[5])
    end
    t:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
    t:Show()
end
local function themeAccent()
    local t = ns.CurrentTheme and ns.CurrentTheme()
    local c = t and t.tabbar and t.tabbar.underline
    if c then return { c[1], c[2], c[3], 1 } end
    return COLORS.gold
end
local function paintDeco(fr, frame, title, name, bg)
    local d = fr._sdeco
    if not d then
        d = CreateFrame("Frame", nil, fr)
        d:SetAllPoints(fr)
        fr._sdeco = d
    end
    d:SetFrameLevel(fr:GetFrameLevel() + 1)
    local r = RIMS[frame]
    if r then
        local rim = d.rim
        if not rim then
            rim = CreateFrame("Frame", nil, d)
            d.rim = rim
        end
        rim:ClearAllPoints()
        rim:SetPoint("TOPLEFT", fr, "TOPLEFT", -r.out, r.out)
        rim:SetPoint("BOTTOMRIGHT", fr, "BOTTOMRIGHT", r.out, -r.out)
        local file, size = r.file, r.size
        if r.metal then file, size = St.METAL, St.METAL_SIZE end
        if r.glow then file = St.GLOW end
        rim:SetBackdrop({ edgeFile = file, edgeSize = size })
        local c = COLORS[r.color]
        rim:SetBackdropBorderColor(c[1], c[2], c[3], r.alpha or 1)
        rim:Show()
    elseif d.rim then
        d.rim:Hide()
    end
    local list, n
    if frame == "corners" then list, n = CORNERS, 8
    elseif frame == "brackets" then list, n = BRACKETS, 6
    elseif frame == "underline" then list, n = nil, 1
    else list, n = nil, 0 end
    local b = bits(d, n)
    if list then
        local c = frame == "corners" and themeAccent() or COLORS.silver
        for i = 1, n do bit(fr, b[i], list[i], c) end
    elseif frame == "underline" then
        local t = b[1]
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", fr, "BOTTOMLEFT", 0, -1)
        t:SetPoint("TOPRIGHT", fr, "BOTTOMRIGHT", 0, -1)
        t:SetHeight(2)
        local c = themeAccent()
        t:SetVertexColor(c[1], c[2], c[3], 1)
        t:Show()
    end
    for i = n + 1, #(d.bits or {}) do d.bits[i]:Hide() end
    local edgeTitle = frame == "titled"
    if title or edgeTitle then
        if not d.title then
            d.tbg = d:CreateTexture(nil, "ARTWORK")
            d.tbg:SetTexture(WHITE)
            d.title = d:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            d.title:SetJustifyH("LEFT")
        end
        d.title:SetText(name)
        d.title:ClearAllPoints()
        d.tbg:ClearAllPoints()
        if edgeTitle then
            d.title:SetPoint("LEFT", fr, "TOPLEFT", 8, 0)
            d.tbg:SetPoint("TOPLEFT", d.title, "TOPLEFT", -3, 1)
            d.tbg:SetPoint("BOTTOMRIGHT", d.title, "BOTTOMRIGHT", 3, -1)
            d.tbg:SetVertexColor(bg[1], bg[2], bg[3], 1)
        else
            d.title:SetPoint("BOTTOMLEFT", fr, "TOPLEFT", 3, 2)
            d.tbg:SetPoint("BOTTOMLEFT", fr, "TOPLEFT", 0, 0)
            d.tbg:SetPoint("BOTTOMRIGHT", fr, "TOPRIGHT", 0, 0)
            d.tbg:SetHeight(13)
            d.tbg:SetVertexColor(bg[1], bg[2], bg[3], 0.6)
        end
        d.title:Show()
        d.tbg:Show()
    elseif d.title then
        d.title:Hide()
        d.tbg:Hide()
    end
    d:Show()
end
function St.Deco(fr, i, b, edit)
    local frame = St.Get("frame", b, nil)
    local title = St.Get("title", b, nil) == "on" and not edit
    if frame == "titled" and edit then frame = "soft" end
    local plain = not RIMS[frame] and frame ~= "corners" and frame ~= "brackets" and frame ~= "underline"
        and frame ~= "titled" and not title
    if plain then
        if fr._sdeco and fr._sdecoKey ~= nil then fr._sdeco:Hide() end
        fr._sdecoKey = nil
        return
    end
    local name = ns.BarName and ns.BarName(b, i) or ""
    local t = ns.CurrentTheme and ns.CurrentTheme()
    local bg = (t and t.panel and t.panel.bgColor) or { 0, 0, 0, 0.6 }
    local key = frame .. ":" .. tostring(title) .. ":" .. name .. ":" .. bg[1] .. bg[2] .. bg[3] .. ":" .. St.METAL
    if fr._sdecoKey == key and fr._sdeco:IsShown() then return end
    fr._sdecoKey = key
    paintDeco(fr, frame, title, name, bg)
end
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local FILL_TICK = 0.05
local RING_DOTS = 16
local STRIP_H = 3
local LINE = 2
local SPIRAL = { auto = true, spiral = true, edge = true, reverse = true }
function St.Layer(f)
    local l = f.sty
    if l then return l end
    l = CreateFrame("Frame", nil, f)
    l:SetAllPoints(f)
    l:SetFrameLevel((f.cd and f.cd:GetFrameLevel() or f:GetFrameLevel()) + 1)
    f.sty = l
    return l
end
local function stex(f, name, layer, file)
    local l = St.Layer(f)
    local t = l[name]
    if t then return t end
    t = l:CreateTexture(nil, layer or "ARTWORK")
    t:SetTexture(file or WHITE)
    t:Hide()
    l[name] = t
    return t
end
local moving = {}
local drv = CreateFrame("Frame")
drv:Hide()
local acc = 0
local function hideFill(f)
    local l = f.sty
    if l then
        for _, name in ipairs({ "shade", "strip", "r1", "r2", "r3", "r4" }) do
            if l[name] then l[name]:Hide() end
        end
        for _, d in ipairs(l.dots or {}) do d:Hide() end
    end
    f._fillKind, f._fillPx = nil, nil
    moving[f] = nil
end
local function shown(t, on)
    if on then
        if not t:IsShown() then t:Show() end
    elseif t:IsShown() then
        t:Hide()
    end
end
local function size(t, px, horiz)
    shown(t, px > 0)
    if px > 0 then
        if horiz then t:SetWidth(px) else t:SetHeight(px) end
    end
end
local function setupFill(f, kind)
    local alpha = f._fillA or 1
    if kind == "fillUp" or kind == "fillDown" or kind == "curtain" then
        local t = stex(f, "shade", "ARTWORK")
        t:ClearAllPoints()
        if kind == "fillUp" then
            t:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
            t:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        elseif kind == "fillDown" then
            t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
            t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        else
            t:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
            t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        end
        t:SetVertexColor(0, 0, 0, 0.75 * alpha)
    elseif kind == "strip" then
        local t = stex(f, "strip", "OVERLAY")
        t:ClearAllPoints()
        t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
        t:SetHeight(STRIP_H)
        local c = f._cdRev and COLORS.up or COLORS.soon
        t:SetVertexColor(c[1], c[2], c[3], 1)
        f._stripC = c
    elseif kind == "rocket" or kind == "rocketBack" then
        local c = kind == "rocket" and COLORS.gold or COLORS.up
        local spec = { { "TOPLEFT", true }, { "TOPRIGHT", false }, { "BOTTOMRIGHT", true }, { "BOTTOMLEFT", false } }
        for i = 1, 4 do
            local t = stex(f, "r" .. i, "OVERLAY")
            t:ClearAllPoints()
            t:SetPoint(spec[i][1], f, spec[i][1], 0, 0)
            if spec[i][2] then t:SetHeight(LINE) else t:SetWidth(LINE) end
            t:SetVertexColor(c[1], c[2], c[3], 1)
        end
    elseif kind == "ring" then
        local l = St.Layer(f)
        l.dots = l.dots or {}
        local w = f:GetWidth() or 32
        local s = math.max(2, math.floor(w * 0.14 + 0.5))
        local r = w / 2 - s / 2 - 1
        for i = 1, RING_DOTS do
            local d = l.dots[i]
            if not d then
                d = l:CreateTexture(nil, "OVERLAY")
                d:SetTexture(ROUND)
                l.dots[i] = d
            end
            local a = math.pi / 2 - (i - 0.5) * 2 * math.pi / RING_DOTS
            d:ClearAllPoints()
            d:SetPoint("CENTER", f, "CENTER", r * math.cos(a), r * math.sin(a))
            d:SetWidth(s)
            d:SetHeight(s)
            d:SetVertexColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 1)
            d:Hide()
        end
    end
end
local function paintFill(f, now)
    local kind, start, dur = f._fillKind, f._cdStart, f._cdDur
    if not (kind and start and dur and dur > 0) then return false end
    local left = start + dur - now
    if left <= 0 then return false end
    local rem = left / dur
    if rem > 1 then rem = 1 end
    local w, h = f:GetWidth() or 32, f:GetHeight() or 32
    local l = f.sty
    if kind == "fillUp" or kind == "fillDown" or kind == "curtain" then
        local share = f._cdRev and (1 - rem) or rem
        local horiz = kind == "curtain"
        local px = math.floor(share * (horiz and w or h) + 0.5)
        if px ~= f._fillPx then
            f._fillPx = px
            size(l.shade, px, horiz)
        end
    elseif kind == "strip" then
        local px = math.floor(rem * (w - 2) + 0.5)
        if px ~= f._fillPx then
            f._fillPx = px
            size(l.strip, px, true)
        end
    elseif kind == "rocket" or kind == "rocketBack" then
        local share = kind == "rocket" and (1 - rem) or rem
        local len = math.floor(share * 2 * (w + h) + 0.5)
        if len ~= f._fillPx then
            f._fillPx = len
            local sides = { w, h, w, h }
            for i = 1, 4 do
                local take = math.max(0, math.min(len, sides[i]))
                len = len - take
                size(l["r" .. i], take, i % 2 == 1)
            end
        end
    elseif kind == "ring" then
        local lit = math.ceil(rem * RING_DOTS)
        if lit ~= f._fillPx then
            f._fillPx = lit
            for i = 1, RING_DOTS do shown(l.dots[i], i <= lit) end
        end
    end
    return true
end
drv:SetScript("OnUpdate", function(self, elapsed)
    acc = acc + (elapsed or 0)
    if acc < FILL_TICK then return end
    acc = 0
    local now = GetTime()
    local any = false
    for f in pairs(moving) do
        if f:IsVisible() and paintFill(f, now) then
            any = true
        else
            hideFill(f)
        end
    end
    if not any then self:Hide() end
end)
function St.Moving()
    local n = 0
    for _ in pairs(moving) do n = n + 1 end
    return n, drv
end
local function drawEdge(f, on)
    if f._cdEdge == on then return end
    f._cdEdge = on
    if f.cd.SetDrawEdge then f.cd:SetDrawEdge(on) end
end
function St.Sweep(f, start, dur, rev, alpha, restart)
    local kind = St.Of(f, "cd")
    local cd = f.cd
    cd.noCooldownCount = (ns.Look.Get("digits") ~= "omnicc") or nil
    if f._cdStart ~= start or f._cdDur ~= dur or f._cdRev ~= rev or f._cdKind ~= kind or not cd:IsShown() then
        f._cdStart, f._cdDur, f._cdRev, f._cdKind = start, dur, rev, kind
        if kind == "reverse" then cd:SetReverse(not rev) else cd:SetReverse(rev) end
        if restart then cd:SetCooldown(0, 0) end
        cd:SetCooldown(start, dur)
        if f._fillKind and f._fillRev ~= rev then hideFill(f) end
        f._fillRev = rev
    end
    if SPIRAL[kind] then
        if f._fillKind then hideFill(f) end
        drawEdge(f, kind == "edge" or (kind == "auto" and rev) or false)
        if f._cdA ~= alpha then f._cdA = alpha; cd:SetAlpha(alpha) end
    else
        drawEdge(f, false)
        if f._cdA ~= 0 then f._cdA = 0; cd:SetAlpha(0) end
        if f._fillKind ~= kind or f._fillA ~= alpha then
            if f._fillKind then hideFill(f) end
            f._fillKind, f._fillA, f._fillPx = kind, alpha, nil
            setupFill(f, kind)
        end
        if kind ~= "number" and paintFill(f, GetTime()) then
            moving[f] = true
            drv:Show()
        end
    end
    cd:Show()
end
function St.SweepOff(f)
    f.cd:Hide()
    f._cdStart, f._cdDur, f._cdRev, f._cdKind = nil, nil, nil, nil
    if f._fillKind then hideFill(f) end
end
local ARROW = "Interface\\ChatFrame\\ChatFrameExpandArrow"
local GLOW_BORDER = "Interface\\Buttons\\UI-ActionButton-Border"
St.SOON = 5
St.BUFF_SOON = 120
St.RAMP_DIM = 0.45
local TINT_PIC = {
    mana = { pic = { 0.45, 0.55, 1 }, all = { 0.5, 0.5, 1 }, dim = { 0.45, 0.55, 1 } },
    far  = { pic = { 1, 0.35, 0.35 }, all = { 0.8, 0.1, 0.1 } },
}
local WHITE_RGB = { 1, 1, 1 }
function St.Tint(f, c)
    if not c then return WHITE_RGB, 1, nil end
    local how = St.Of(f, c == "far" and "range" or "mana")
    local pic = TINT_PIC[c][how] or WHITE_RGB
    return pic, (how == "dim") and 0.6 or 1, how
end
local function ring(f)
    local r = f.sring
    if r then return r end
    r = CreateFrame("Frame", nil, St.Layer(f))
    r:SetAllPoints(f)
    r:SetBackdrop({ edgeFile = WHITE, edgeSize = 2 })
    r:Hide()
    f.sring = r
    return r
end
function St.Ring(f)
    local c
    if f._sMark == "edge" then c = COLORS[f._sMarkC] end
    if not c and f._sSoonEdge then c = COLORS.soon end
    if not c and (f._sLitWhite or f._sProcWhite) then c = COLORS.white end
    if f._ringC == c then return end
    f._ringC = c
    if not c then
        if f.sring then f.sring:Hide() end
        return
    end
    local r = ring(f)
    r:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    r:Show()
end
local function costText(f)
    local fx = f._item and ns.Facts and ns.Facts.Of and ns.Facts.Of(f._item)
    local s = fx and fx.cost
    return s and s:match("%d+%%?") or nil
end
function St.Mark(f, c, how)
    local key = tostring(c) .. ":" .. tostring(how)
    if f._sMarkKey == key then return end
    f._sMarkKey = key
    f._sMark, f._sMarkC = how, c
    f._sFarDigit = (c == "far" and how == "digit") or nil
    local l = f.sty
    if how == "drop" then
        local t = stex(f, "drop", "OVERLAY", ROUND)
        t:SetWidth(7)
        t:SetHeight(7)
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
        t:SetVertexColor(COLORS.mana[1], COLORS.mana[2], COLORS.mana[3], 1)
        t:Show()
    elseif l and l.drop then
        l.drop:Hide()
    end
    if how == "arrow" then
        local t = stex(f, "arrow", "OVERLAY", ARROW)
        t:SetWidth(12)
        t:SetHeight(12)
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        t:SetVertexColor(COLORS.far[1], COLORS.far[2], COLORS.far[3], 1)
        t:Show()
    elseif l and l.arrow then
        l.arrow:Hide()
    end
    if how == "under" then
        local t = stex(f, "under", "OVERLAY")
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -1)
        t:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -1)
        t:SetHeight(2)
        t:SetVertexColor(COLORS.far[1], COLORS.far[2], COLORS.far[3], 1)
        t:Show()
    elseif l and l.under then
        l.under:Hide()
    end
    if how == "cost" then
        local layer = St.Layer(f)
        if not layer.cost then
            layer.cost = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
            layer.cost:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -1)
        end
        layer.cost:SetText(costText(f) or "")
        layer.cost:SetTextColor(COLORS.mana[1], COLORS.mana[2], COLORS.mana[3])
        layer.cost:Show()
    elseif l and l.cost then
        l.cost:Hide()
    end
    St.EdgeTintBy(f, how == "all" and c or nil)
    St.Ring(f)
end
local function litFrame(f, name)
    local g = f[name]
    if g then return g end
    g = CreateFrame("Frame", nil, St.Layer(f))
    g:SetPoint("TOPLEFT", f, "TOPLEFT", -3, 3)
    g:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 3, -3)
    g:Hide()
    f[name] = g
    return g
end
local function glow(f, name, shine, how)
    local g = f[name]
    if how == "pulse" or how == "ants" then
        g = litFrame(f, name)
        if how == "pulse" then
            g:SetBackdrop({ edgeFile = TIP_EDGE, edgeSize = 12 })
            g:SetBackdropBorderColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 1)
            if g.ants then g.ants:Hide() end
        else
            g:SetBackdrop(nil)
            if not g.ants then
                g.ants = g:CreateTexture(nil, "OVERLAY")
                g.ants:SetTexture(GLOW_BORDER)
                g.ants:SetBlendMode("ADD")
                g.ants:SetPoint("CENTER", f, "CENTER", 0, 0)
            end
            local w = (f:GetWidth() or 32) * 1.75
            g.ants:SetWidth(w)
            g.ants:SetHeight(w)
            g.ants:SetVertexColor(1, 0.9, 0.3, 1)
            g.ants:Show()
        end
        g:Show()
        if ns.Anim and ns.Anim.Pulse then ns.Anim.Pulse(g, true) end
    elseif g then
        if ns.Anim and ns.Anim.Pulse then ns.Anim.Pulse(g, false) end
        g:Hide()
    end
    if how == "shine" then
        local t = stex(f, shine, "OVERLAY")
        t:SetBlendMode("ADD")
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
        if t.SetGradientAlpha then t:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.45) end
        t:Show()
    elseif f.sty and f.sty[shine] then
        f.sty[shine]:Hide()
    end
end
function St.Lit(f, on)
    local how = on and St.Of(f, "ready") or nil
    if how == "auto" or how == "flash" or how == "nova" or how == "none" then how = nil end
    if f._sLit == how then return end
    f._sLit = how
    glow(f, "slit", "shine", how)
    f._sLitWhite = (how == "white") or nil
    St.Ring(f)
end
local PROC_GLOW = { pulse = "pulse", ants = "ants", white = "white", shine = "shine" }
function St.ProcLit(f, on)
    local how = on and (PROC_GLOW[St.Of(f, "ready")] or "ants") or nil
    if f._sProc == how then return end
    f._sProc = how
    glow(f, "sproc", "pshine", how)
    f._sProcWhite = (how == "white") or nil
    St.Ring(f)
end
function St.ProcCount(f, n)
    if f._sProcN == n then return end
    f._sProcN = n
    local fs = f.pcount
    if not n then
        if fs then fs:Hide() end
        return
    end
    if not fs then
        fs = (f.txt or f):CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        fs:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
        fs:SetTextColor(COLORS.soon[1], COLORS.soon[2], COLORS.soon[3])
        f.pcount = fs
    end
    fs:SetText(n)
    fs:Show()
end
function St.Event(f, event)
    local how = St.Of(f, "ready")
    if how == "auto" then return false end
    if how ~= "flash" and how ~= "nova" then return true end
    if ns.FX.Level() == "off" then return true end
    local parent = f:GetParent()
    local cx, cy = f:GetCenter()
    local pl, pb = parent and parent:GetLeft(), parent and parent:GetBottom()
    if not (cx and cy and pl and pb) then return true end
    local size = f:GetWidth()
    if how == "nova" then
        ns.FX.Nova(parent, cx - pl, cy - pb, size, f.tex:GetTexture(), 1)
    else
        ns.FX.Pulse(parent, cx - pl, cy - pb, size, GLOW_BORDER)
    end
    return true
end
function St.Soon(f, left, buff)
    local lim = buff and St.BUFF_SOON or St.SOON
    local soon = (left and left > 0 and left < lim) and true or false
    local how = soon and St.Of(f, "soon") or nil
    if how == "none" then how = nil end
    if f._sSoon ~= how then
        f._sSoon = how
        if ns.Anim and ns.Anim.Pulse and f.txt then ns.Anim.Pulse(f.txt, how == "pulse") end
        f._sSoonEdge = (how == "edge") or nil
        St.Ring(f)
    end
    if how == "strip" then
        local t = stex(f, "soonStrip", "OVERLAY")
        local w = (f:GetWidth() or 32) - 2
        local px = math.max(1, math.floor(left / lim * w + 0.5))
        if f._sSoonPx ~= px then
            if not f._sSoonPx then
                t:ClearAllPoints()
                t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
                t:SetHeight(STRIP_H)
                t:Show()
            end
            f._sSoonPx = px
            t:SetWidth(px)
            local c = (left < lim / 2) and COLORS.miss or COLORS.soon
            if f._sSoonC ~= c then
                f._sSoonC = c
                t:SetVertexColor(c[1], c[2], c[3], 1)
            end
        end
    elseif f._sSoonPx then
        f._sSoonPx, f._sSoonC = nil, nil
        if f.sty and f.sty.soonStrip then f.sty.soonStrip:Hide() end
    end
    return soon
end
function St.Ramp(f, left, dim)
    if St.Of(f, "soon") ~= "ramp" or not left or left <= 0 then return dim end
    local a = ns.Look.Absent(f)
    if a > St.RAMP_DIM then a = St.RAMP_DIM end
    if left >= St.SOON then return a end
    local k = 1 - left / St.SOON
    return math.floor((a + (1 - a) * k) * 20 + 0.5) / 20
end
local FONTS = { friz = "Fonts\\FRIZQT__.TTF", skurri = "Fonts\\skurri.ttf", morpheus = "Fonts\\MORPHEUS.ttf" }
local FLAGS = { shadow = "", thick = "THICKOUTLINE", soft = "OUTLINE", none = "" }
local SHADOW = { shadow = true, soft = true }
local PLACE_SCALE = { big = 1.35, corner = 0.8 }
local BOOST = 1.2
local STACK_BOOST = 1.3
local STACK_BIG = 5
function St.Place(f)
    local p = St.Of(f, "place")
    if p == "layout" then return nil end
    return p
end
St.TENTHS = 10
function St.Fmt(f, t)
    if not t or t <= 0 then return nil end
    if St.Of(f, "place") == "none" then return nil end
    local how = St.Of(f, "fmt")
    if how == "omni" then
        if t < 2 then return nil end
        if t < 3 then return ("%.1f"):format(t) end
        if t < 90 then return ("%d"):format(math.floor(t)) end
    elseif how == "mmss" then
        if t >= 60 and t < 3600 then return ("%d:%02d"):format(math.floor(t / 60), math.floor(t % 60)) end
    elseif how == "int" then
        if t < 60 then return ("%d"):format(math.ceil(t)) end
    end
    if t >= 3600 then return ns.T("time.hours", math.floor(t / 3600)) end
    if t >= 60   then return ns.T("time.minutes", math.floor(t / 60)) end
    if t >= St.TENTHS then return ("%d"):format(math.floor(t)) end
    return ("%.1f"):format(t)
end
function St.Font(f, fs)
    if not fs._px then return end
    local file = FONTS[St.Global("font")] or fs._file0
    local out = St.Of(f, "outline")
    local flags = FLAGS[out] or fs._flags0 or ""
    local k = (ns.Look.FontScale(fs._role == "stack" and "stack" or "time")) * (tonumber(St.Of(f, "nscale")) or 1)
    if fs._role ~= "stack" and fs._main then k = k * (PLACE_SCALE[St.Of(f, "place")] or 1) end
    k = k * (fs._boost or 1)
    local px = math.floor(fs._px * k + 0.5)
    local key = tostring(file) .. px .. flags .. out
    if fs._fk == key then return end
    fs._fk = key
    if file then fs:SetFont(file, px, flags) end
    if SHADOW[out] then
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetShadowOffset(1, -1)
        fs._shadowed = true
    elseif fs._shadowed then
        fs:SetShadowOffset(0, 0)
        fs._shadowed = nil
    end
end
local function textColor(fs, c)
    if fs._sc == c then return end
    fs._sc = c
    local x = c or WHITE_RGB
    fs:SetTextColor(x[1], x[2], x[3])
end
local NUM = { soon = { 1, 0.25, 0.25 }, secs = { 1, 0.9, 0.3 }, hours = { 0.7, 0.7, 0.7 }, gold = { 1, 0.82, 0 },
              stack = { 1, 0.9, 0.3 } }
function St.Time(f, fs, left, buff, icd)
    local how = St.Of(f, "ncolor")
    local lim = buff and St.BUFF_SOON or St.SOON
    local soon = left and left > 0 and left < lim
    local s = St.Of(f, "soon")
    local c
    local boost
    if f._sFarDigit then
        c = COLORS.far
    elseif soon and (s == "red" or s == "pulse") then
        c, boost = NUM.soon, BOOST
    elseif soon and s == "edge" then
        c = COLORS.soon
    elseif how == "remain" then
        if icd then c = NUM.hours
        elseif soon then c, boost = NUM.soon, BOOST
        elseif left and left < 90 then c = NUM.secs
        elseif left and left >= 3600 then c = NUM.hours end
    elseif how == "gold" then
        c = NUM.gold
    elseif how == "class" then
        c = classColor()
    end
    textColor(fs, c)
    if fs._boost ~= boost then
        fs._boost = boost
        St.Font(f, fs)
    end
end
function St.Stacks(f, fs, n)
    local how = St.Of(f, "stacks")
    local big = how == "big" and n and n >= STACK_BIG
    textColor(fs, big and NUM.stack or nil)
    local boost = big and STACK_BOOST or nil
    if fs._boost ~= boost then
        fs._boost = boost
        St.Font(f, fs)
    end
    local on = how == "badge" and n and n > 0 and fs:IsShown()
    if on then
        local t = stex(f, "badge", "ARTWORK", ROUND)
        if not f._sBadge then
            t:SetVertexColor(0, 0, 0, 0.75)
            t:SetWidth(16)
            t:SetHeight(16)
            t:ClearAllPoints()
            t:SetPoint("CENTER", fs, "CENTER", 0, 0)
            t:Show()
            f._sBadge = true
        end
    elseif f._sBadge then
        f._sBadge = nil
        f.sty.badge:Hide()
    end
end
function St.Zero(f, fs)
    textColor(fs, NUM.soon)
    if fs._boost ~= nil then
        fs._boost = nil
        St.Font(f, fs)
    end
    if f._sBadge then
        f._sBadge = nil
        f.sty.badge:Hide()
    end
end
function St.Release(f)
    if f._sLit then St.Lit(f, false) end
    if f._sProc then St.ProcLit(f, false) end
    if f._sProcN then St.ProcCount(f, nil) end
    if f._sSoon then
        f._sSoon = nil
        if ns.Anim and ns.Anim.Pulse and f.txt then ns.Anim.Pulse(f.txt, false) end
    end
    if f._fillKind then hideFill(f) end
end
ns.styleLoaded = true
