local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MEDIA = "Interface\\AddOns\\ManaCode_LazyBuffBar\\media\\"
local TEX = {
    dial = MEDIA .. "dial", ring = MEDIA .. "ring", hand = MEDIA .. "hand", gear = MEDIA .. "gear",
    blob = MEDIA .. "blob", seg = MEDIA .. "seg7", metal = MEDIA .. "metal",
    tip = "Interface\\Tooltips\\UI-Tooltip-Background", tipEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
}
local BACK = { 0, 0, 0, 0.35 }
local TEXT_C = ns.STATE.text
local WIDE_FONT = 0.5
local ONE_FONT = 0.4
local DIAL_FONT = 0.4
local SEG_CELLS = 16
local SEG_COLON = 10
local GEAR_TEETH = 8
local ROT_K = 0.70710678
local P = {
    plate  = { bg = { 0, 0, 0, 0.75 }, edge = { 0.55, 0.55, 0.6, 1 }, text = { 1, 0.95, 0.8, 1 } },
    lcd    = { bg = { 0.56, 0.66, 0.5, 1 }, edge = { 0.1, 0.12, 0.1, 1 }, seg = { 0.07, 0.1, 0.07, 1 }, ghost = 0.1 },
    nixie  = { bg = { 0.05, 0.03, 0.02, 1 }, edge = { 0.85, 0.62, 0.25, 1 }, text = { 1, 0.55, 0.15, 1 }, glow = { 1, 0.4, 0.05, 0.55 }, glass = 0.16 },
    brass  = { ring = { 0.85, 0.62, 0.25, 1 }, face = { 1, 0.95, 0.8, 1 }, hand = { 0.1, 0.1, 0.12, 1 }, cap = { 0.85, 0.62, 0.25, 1 } },
    pocket = { ring = { 0.8, 0.82, 0.85, 1 }, face = { 1, 0.97, 0.9, 1 }, hand = { 0.1, 0.1, 0.12, 1 }, cap = { 0.5, 0.5, 0.55, 1 }, gear = { 0.85, 0.62, 0.25, 1 } },
}
local function state(opt)
    if opt and opt.src == "local" then
        local t = date("*t")
        if type(t) == "table" then return { h = t.hour or 0, m = t.min or 0 } end
        return { h = 0, m = 0 }
    end
    local h, m = GetGameTime()
    return { h = h or 0, m = m or 0 }
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), flags) end
end
local function digits(layer, px)
    local fs = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    fontSize(fs, px)
    return fs
end
local function rotate(t, deg)
    local d = math.floor(deg * 10 + 0.5) / 10
    if t.lbbRot == d then return end
    t.lbbRot = d
    local a = math.rad(d)
    local c, s = math.cos(a) * ROT_K * 0.5, math.sin(a) * ROT_K * 0.5
    t:SetTexCoord(0.5 - c - s, 0.5 + s - c, 0.5 - c + s, 0.5 + s + c, 0.5 + c - s, 0.5 - s - c, 0.5 + c + s, 0.5 - s + c)
end
local function segShow(t, d)
    if t.lbbDigit == d then return end
    t.lbbDigit = d
    t:SetTexCoord(d / SEG_CELLS, (d + 1) / SEG_CELLS, 0, 1)
end
local function tex(layer, path, sublayer, w, h, color)
    local t = layer:CreateTexture(nil, sublayer)
    t:SetTexture(path)
    t:SetWidth(w)
    t:SetHeight(h)
    if color then t:SetVertexColor(color[1], color[2], color[3], color[4] or 1) end
    return t
end
local function plainBack(layer, color)
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(layer)
    bg:SetVertexColor(color[1], color[2], color[3], color[4])
end
local function textDigits(layer, view, color)
    local s = layer.h
    layer.tc = color
    if view == "one" then
        layer.hh = digits(layer, s * ONE_FONT)
        layer.hh:SetPoint("BOTTOM", layer, "CENTER", 0, 0)
        layer.mm = digits(layer, s * ONE_FONT)
        layer.mm:SetPoint("TOP", layer, "CENTER", 0, 0)
        return
    end
    layer.hm = digits(layer, s * WIDE_FONT)
    layer.hm:SetPoint("CENTER", layer, "CENTER", 0, 0)
end
local function buildPlain(layer, view)
    plainBack(layer, BACK)
    textDigits(layer, view, TEXT_C)
end
local function buildPlate(layer, view)
    local e = math.max(8, math.floor(layer.h / 4))
    layer:SetBackdrop({ bgFile = TEX.tip, edgeFile = TEX.tipEdge, tile = true, tileSize = 16, edgeSize = e,
                        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    layer:SetBackdropColor(P.plate.bg[1], P.plate.bg[2], P.plate.bg[3], P.plate.bg[4])
    layer:SetBackdropBorderColor(P.plate.edge[1], P.plate.edge[2], P.plate.edge[3], P.plate.edge[4])
    textDigits(layer, view, P.plate.text)
end
local function segRow(layer, n, dh, cy)
    local dw = dh / 2
    local gap = dw * 0.18
    local colon = n == 4 and dw * 0.55 or 0
    local total = n * dw + (n - 1) * gap + colon
    local x = -total / 2
    local out = {}
    for i = 1, n do
        if i == 3 and colon > 0 then
            local c = tex(layer, TEX.seg, "ARTWORK", dw, dh, P.lcd.seg)
            c:SetPoint("CENTER", layer, "CENTER", x + colon / 2, cy)
            segShow(c, SEG_COLON)
            x = x + colon
        end
        local g = tex(layer, TEX.seg, "BORDER", dw, dh, P.lcd.seg)
        g:SetPoint("CENTER", layer, "CENTER", x + dw / 2, cy)
        g:SetAlpha(P.lcd.ghost)
        segShow(g, 8)
        local t = tex(layer, TEX.seg, "ARTWORK", dw, dh, P.lcd.seg)
        t:SetPoint("CENTER", layer, "CENTER", x + dw / 2, cy)
        out[#out + 1] = t
        x = x + dw + gap
    end
    return out
end
local function buildLcd(layer, view)
    layer:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    layer:SetBackdropColor(P.lcd.bg[1], P.lcd.bg[2], P.lcd.bg[3], P.lcd.bg[4])
    layer:SetBackdropBorderColor(P.lcd.edge[1], P.lcd.edge[2], P.lcd.edge[3], P.lcd.edge[4])
    local h = layer.h
    if view == "one" then
        local dh = h * 0.42
        local top, bot = segRow(layer, 2, dh, h * 0.23), segRow(layer, 2, dh, -h * 0.23)
        layer.segs = { top[1], top[2], bot[1], bot[2] }
        return
    end
    layer.segs = segRow(layer, 4, h * 0.68, 0)
end
local function buildNixie(layer, view)
    local h = layer.h
    local e = math.max(6, math.floor(h / 5))
    layer:SetBackdrop({ bgFile = WHITE, edgeFile = TEX.metal, edgeSize = e, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    layer:SetBackdropColor(P.nixie.bg[1], P.nixie.bg[2], P.nixie.bg[3], P.nixie.bg[4])
    layer:SetBackdropBorderColor(P.nixie.edge[1], P.nixie.edge[2], P.nixie.edge[3], P.nixie.edge[4])
    local glass = layer:CreateTexture(nil, "BORDER")
    glass:SetTexture(WHITE)
    glass:SetPoint("TOPLEFT", layer, "TOPLEFT", e - 2, -(e - 2))
    glass:SetPoint("BOTTOMRIGHT", layer, "RIGHT", -(e - 2), 0)
    glass:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, P.nixie.glass)
    local blob = h * 1.1
    if view == "one" then
        local a = tex(layer, TEX.blob, "ARTWORK", blob, blob * 0.7, P.nixie.glow)
        a:SetPoint("CENTER", layer, "CENTER", 0, h * 0.2)
        local b = tex(layer, TEX.blob, "ARTWORK", blob, blob * 0.7, P.nixie.glow)
        b:SetPoint("CENTER", layer, "CENTER", 0, -h * 0.2)
        a:SetBlendMode("ADD")
        b:SetBlendMode("ADD")
    else
        local a = tex(layer, TEX.blob, "ARTWORK", blob, blob, P.nixie.glow)
        a:SetPoint("CENTER", layer, "CENTER", -layer.w * 0.17, 0)
        local b = tex(layer, TEX.blob, "ARTWORK", blob, blob, P.nixie.glow)
        b:SetPoint("CENTER", layer, "CENTER", layer.w * 0.17, 0)
        a:SetBlendMode("ADD")
        b:SetBlendMode("ADD")
    end
    textDigits(layer, view, P.nixie.text)
end
local function dialAt(layer, c, d, cx, cy)
    local face = tex(layer, TEX.dial, "BORDER", d, d, c.face)
    face:SetPoint("CENTER", layer, "CENTER", cx, cy)
    local ring = tex(layer, TEX.ring, "ARTWORK", d, d, c.ring)
    ring:SetPoint("CENTER", layer, "CENTER", cx, cy)
    layer.hour = tex(layer, TEX.hand, "ARTWORK", d * 0.62, d * 0.62, c.hand)
    layer.hour:SetPoint("CENTER", layer, "CENTER", cx, cy)
    layer.min = tex(layer, TEX.hand, "ARTWORK", d * 0.86, d * 0.86, c.hand)
    layer.min:SetPoint("CENTER", layer, "CENTER", cx, cy)
    local cap = tex(layer, TEX.blob, "OVERLAY", d * 0.16, d * 0.16, c.cap)
    cap:SetPoint("CENTER", layer, "CENTER", cx, cy)
    rotate(layer.hour, 0)
    rotate(layer.min, 0)
end
local function buildBrass(layer, view)
    plainBack(layer, BACK)
    local h, w = layer.h, layer.w
    local d = h - 2
    if view == "one" then
        dialAt(layer, P.brass, d, 0, 0)
        return
    end
    dialAt(layer, P.brass, d, -(w - d) / 2 + 1, 0)
    layer.tc = TEXT_C
    layer.hm = digits(layer, h * DIAL_FONT)
    layer.hm:SetPoint("CENTER", layer, "CENTER", d / 2 + 1, 0)
end
local function buildPocket(layer, view)
    plainBack(layer, BACK)
    local h, w = layer.h, layer.w
    local d = h * 0.86
    local cy = -h * 0.06
    local cx = view == "one" and 0 or -(w - d) / 2 + 1
    dialAt(layer, P.pocket, d, cx, cy)
    local crown = tex(layer, WHITE, "ARTWORK", d * 0.14, d * 0.1, P.pocket.ring)
    crown:SetPoint("BOTTOM", layer, "CENTER", cx, cy + d / 2 - 1)
    local stem = tex(layer, WHITE, "ARTWORK", d * 0.06, d * 0.06, P.pocket.ring)
    stem:SetPoint("BOTTOM", crown, "TOP", 0, 0)
    if view == "one" then return end
    local g = (w - d - 2) * 0.5
    local mid = d / 2 + 1
    local g1 = tex(layer, TEX.gear, "ARTWORK", g, g, P.pocket.gear)
    g1:SetPoint("CENTER", layer, "CENTER", mid - g * 0.45, h * 0.18)
    local g2 = tex(layer, TEX.gear, "ARTWORK", g * 0.8, g * 0.8, P.pocket.gear)
    g2:SetPoint("CENTER", layer, "CENTER", mid + g * 0.35, -h * 0.2)
    layer.gears = { g1, g2 }
    layer.gstep = 0
    rotate(g1, 0)
    rotate(g2, 360 / GEAR_TEETH / 2)
end
local BUILD = { plain = buildPlain, plate = buildPlate, lcd = buildLcd, nixie = buildNixie, brass = buildBrass, pocket = buildPocket }
local function build(layer, view, opt)
    layer.sk = ns.Widget.SkinOf("clock", opt)
    BUILD[layer.sk](layer, view)
end
local function paintText(layer, st)
    local W = ns.Widget
    if layer.hm then
        W.Text(layer.hm, string.format("%02d:%02d", st.h, st.m))
        W.Color(layer.hm, layer.tc)
    end
    if layer.hh then
        W.Text(layer.hh, string.format("%02d", st.h))
        W.Text(layer.mm, string.format("%02d", st.m))
        W.Color(layer.hh, layer.tc)
        W.Color(layer.mm, layer.tc)
    end
end
local function paintDial(layer, st)
    rotate(layer.hour, (st.h % 12 + st.m / 60) * 30)
    rotate(layer.min, st.m * 6)
    if layer.gears then
        layer.gstep = (layer.gstep + 1) % GEAR_TEETH
        local a = layer.gstep * (360 / GEAR_TEETH)
        rotate(layer.gears[1], a)
        rotate(layer.gears[2], 360 / GEAR_TEETH / 2 - a)
    end
    paintText(layer, st)
end
local function paintSeg(layer, st)
    local s = layer.segs
    segShow(s[1], math.floor(st.h / 10))
    segShow(s[2], st.h % 10)
    segShow(s[3], math.floor(st.m / 10))
    segShow(s[4], st.m % 10)
end
local function paint(layer, st)
    if layer.segs then return paintSeg(layer, st) end
    if layer.hour then return paintDial(layer, st) end
    paintText(layer, st)
end
ns.Widget.Register("clock", {
    icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    label = "widget.clock",
    general = true,
    views = { wide = { w = 2, h = 1 }, one = { w = 1, h = 1 } },
    order = { "wide", "one" },
    view = "wide",
    skins = {
        plain = { label = "widget.c_sk_plain" }, plate = { label = "widget.c_sk_plate" }, lcd = { label = "widget.c_sk_lcd" },
        nixie = { label = "widget.c_sk_nixie" }, brass = { label = "widget.c_sk_brass" }, pocket = { label = "widget.c_sk_pocket" },
    },
    skinOrder = { "plain", "plate", "lcd", "nixie", "brass", "pocket" },
    skin = "plain",
    avail = function() return true end,
    events = { PLAYER_ENTERING_WORLD = true },
    tick = 1,
    State = state,
    Build = build,
    Paint = paint,
    opts = {
        { key = "src", label = "widget.c_src", values = {
            { v = nil, label = "widget.c_src_server" }, { v = "local", label = "widget.c_src_local" },
        } },
    },
})
ns.clockWidgetLoaded = true
