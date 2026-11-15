local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local function data()
    return ns.widgetData.sep
end
local ORDER = { "v1", "v2", "v3", "v4", "h2", "h3", "h4", "h5" }
local VIEWS = {
    v1 = { w = 1, h = 1 }, v2 = { w = 1, h = 2 }, v3 = { w = 1, h = 3 }, v4 = { w = 1, h = 4 },
    h2 = { w = 2, h = 1 }, h3 = { w = 3, h = 1 }, h4 = { w = 4, h = 1 }, h5 = { w = 5, h = 1 },
}
local tints = {}
local function tint(c)
    local d = data()
    local r, g, b = d.color[1], d.color[2], d.color[3]
    if type(c) == "table" and c[1] then r, g, b = c[1], c[2], c[3] end
    local key = string.format("%.3f,%.3f,%.3f", r, g, b)
    local t = tints[key]
    if not t then
        t = { r, g, b, d.alpha }
        tints[key] = t
    end
    return t
end
local function state(opt)
    local label = opt and type(opt.label) == "string" and opt.label or ""
    return { color = tint(opt and opt.color), label = label }
end
local function line(layer)
    local t = layer:CreateTexture(nil, "ARTWORK")
    t:SetTexture(WHITE)
    return t
end
local function ramp(layer, part, dir, out, len, th)
    local t = line(layer)
    if dir == "VERTICAL" then
        t:SetWidth(th)
        t:SetHeight(len)
    else
        t:SetWidth(len)
        t:SetHeight(th)
    end
    layer.ramps[#layer.ramps + 1] = { tex = t, part = part, dir = dir, out = out }
    return t
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), flags) end
end
local function buildV(layer, th, inset, fade, gap)
    local fs = layer.label
    local r = math.max(1, math.min(fade, math.floor((layer.h - 2 * inset) / 2)))
    fs:SetPoint("TOP", layer, "TOP", 0, 0)
    local top = ramp(layer, "full", "VERTICAL", true, r, th)
    top:SetPoint("TOP", layer, "TOP", 0, -inset)
    local bottom = ramp(layer, "full", "VERTICAL", false, r, th)
    bottom:SetPoint("BOTTOM", layer, "BOTTOM", 0, inset)
    layer.full:SetWidth(th)
    layer.full:SetPoint("TOP", top, "BOTTOM", 0, 0)
    layer.full:SetPoint("BOTTOM", bottom, "TOP", 0, 0)
    local aEnd = ramp(layer, "a", "VERTICAL", false, r, th)
    aEnd:SetPoint("BOTTOM", layer, "BOTTOM", 0, inset)
    layer.a:SetWidth(th)
    layer.a:SetPoint("TOP", fs, "BOTTOM", 0, -gap)
    layer.a:SetPoint("BOTTOM", aEnd, "TOP", 0, 0)
end
local function buildH(layer, th, inset, fade, gap)
    local fs = layer.label
    local r = math.max(1, math.min(fade, math.floor((layer.w - 2 * inset) / 2)))
    fs:SetPoint("CENTER", layer, "CENTER", 0, 0)
    local left = ramp(layer, "full", "HORIZONTAL", false, r, th)
    left:SetPoint("LEFT", layer, "LEFT", inset, 0)
    local right = ramp(layer, "full", "HORIZONTAL", true, r, th)
    right:SetPoint("RIGHT", layer, "RIGHT", -inset, 0)
    layer.full:SetHeight(th)
    layer.full:SetPoint("LEFT", left, "RIGHT", 0, 0)
    layer.full:SetPoint("RIGHT", right, "LEFT", 0, 0)
    local aStart = ramp(layer, "a", "HORIZONTAL", false, r, th)
    aStart:SetPoint("LEFT", layer, "LEFT", inset, 0)
    layer.a:SetHeight(th)
    layer.a:SetPoint("LEFT", aStart, "RIGHT", 0, 0)
    layer.a:SetPoint("RIGHT", fs, "LEFT", -gap, 0)
    local bEnd = ramp(layer, "b", "HORIZONTAL", true, r, th)
    bEnd:SetPoint("RIGHT", layer, "RIGHT", -inset, 0)
    layer.b = line(layer)
    layer.b:SetHeight(th)
    layer.b:SetPoint("LEFT", fs, "RIGHT", gap, 0)
    layer.b:SetPoint("RIGHT", bEnd, "LEFT", 0, 0)
end
local function build(layer, view)
    local d = data()
    local s = layer.cell or math.min(layer.w, layer.h)
    local th = math.max(1, math.floor(s * d.thick + 0.5))
    local inset = math.floor(s * d.inset + 0.5)
    local fade = math.max(1, math.floor(s * d.fade + 0.5))
    local gap = math.max(2, math.floor(s * d.gap + 0.5))
    local fs = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontSize(fs, s * d.font)
    layer.label = fs
    layer.full = line(layer)
    layer.a = line(layer)
    layer.ramps = {}
    if view:sub(1, 1) == "v" then
        buildV(layer, th, inset, fade, gap)
    else
        buildH(layer, th, inset, fade, gap)
    end
end
local function shown(t, on)
    if not t or (t:IsShown() and true or false) == on then return end
    if on then t:Show() else t:Hide() end
end
local function shade(rp, c)
    if rp.c == c then return end
    rp.c = c
    local a0, a1 = c[4], 0
    if not rp.out then a0, a1 = 0, c[4] end
    rp.tex:SetGradientAlpha(rp.dir, c[1], c[2], c[3], a0, c[1], c[2], c[3], a1)
end
local function paint(layer, st)
    local W = ns.Widget
    local cut = st.label ~= ""
    W.Text(layer.label, st.label)
    W.Color(layer.label, data().label)
    for _, t in ipairs({ layer.full, layer.a, layer.b }) do W.Color(t, st.color) end
    local on = { full = not cut, a = cut, b = cut }
    for _, rp in ipairs(layer.ramps) do
        shade(rp, st.color)
        shown(rp.tex, on[rp.part])
    end
    shown(layer.full, not cut)
    shown(layer.a, cut)
    shown(layer.b, cut)
    shown(layer.label, cut)
end
ns.Widget.Register("sep", {
    icon = "Interface\\Icons\\INV_Staff_02",
    label = "widget.sep",
    general = true,
    many = true,
    views = VIEWS,
    order = ORDER,
    view = "v1",
    avail = function() return true end,
    events = {},
    State = state,
    Build = build,
    Paint = paint,
    opts = {
        { key = "color", label = "widget.s_color", kind = "color", tip = "widget.s_color_tip",
          reset = "widget.s_reset", resetTip = "widget.s_reset_tip",
          palette = function() return data().color end },
        { key = "label", label = "widget.s_label", kind = "text", max = data().max, ghost = "widget.s_label_ghost" },
    },
})
ns.sepWidgetLoaded = true
