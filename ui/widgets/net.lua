local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACK = { 0, 0, 0, 0.35 }
local INK = ns.STATE
local DOT_C = ns.STATE.mute
local function grade(v, warn, bad, low)
    if low then
        if v < bad then return "bad" end
        if v < warn then return "soon" end
        return "ok"
    end
    if v >= bad then return "bad" end
    if v >= warn then return "soon" end
    return "ok"
end
local function state(opt)
    local d = ns.widgetData.net
    local _, _, lat = GetNetStats()
    local fps = GetFramerate()
    local ms = math.max(0, math.floor((tonumber(lat) or 0) + 0.5))
    local f = math.max(0, math.floor((tonumber(fps) or 0) + 0.5))
    return {
        ms = ms, fps = f,
        msV = grade(ms, d.msWarn, d.msBad, false),
        fpsV = grade(f, d.fpsWarn, d.fpsBad, true),
        show = (opt and opt.show == "fps") and "fps" or "ms",
    }
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
local function build(layer, view)
    local d = ns.widgetData.net
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(layer)
    bg:SetVertexColor(BACK[1], BACK[2], BACK[3], BACK[4])
    local s = layer.h
    if view == "one" then
        layer.num = digits(layer, s * d.oneFont)
        layer.num:SetPoint("BOTTOM", layer, "CENTER", 0, -s * 0.08)
        layer.unit = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fontSize(layer.unit, s * d.unitFont)
        layer.unit:SetPoint("TOP", layer, "CENTER", 0, -s * 0.1)
        return
    end
    local side = math.max(2, math.floor(s * d.dot + 0.5))
    layer.dot = layer:CreateTexture(nil, "ARTWORK")
    layer.dot:SetTexture(WHITE)
    layer.dot:SetWidth(side)
    layer.dot:SetHeight(side)
    layer.dot:SetPoint("CENTER", layer, "CENTER", s * 0.2, 0)
    layer.dot:SetVertexColor(DOT_C[1], DOT_C[2], DOT_C[3], DOT_C[4])
    local pad = math.max(2, math.floor(s * 0.1 + 0.5))
    layer.ms = digits(layer, s * d.wideFont)
    layer.ms:SetPoint("RIGHT", layer.dot, "LEFT", -pad, 0)
    layer.fps = digits(layer, s * d.wideFont)
    layer.fps:SetPoint("LEFT", layer.dot, "RIGHT", pad, 0)
end
local function paint(layer, st)
    local W = ns.Widget
    if layer.num then
        local fps = st.show == "fps"
        W.Text(layer.num, tostring(fps and st.fps or st.ms))
        W.Color(layer.num, INK[fps and st.fpsV or st.msV])
        W.Text(layer.unit, ns.T(fps and "widget.n_fps" or "widget.n_ms_unit"))
        W.Color(layer.unit, ns.STATE.text)
        return
    end
    W.Text(layer.ms, ns.T("widget.n_ms", st.ms))
    W.Color(layer.ms, INK[st.msV])
    W.Text(layer.fps, tostring(st.fps))
    W.Color(layer.fps, INK[st.fpsV])
end
ns.Widget.Register("net", {
    icon = "Interface\\Icons\\Spell_Nature_Lightning",
    label = "widget.net",
    general = true,
    views = { wide = { w = 2, h = 1 }, one = { w = 1, h = 1 } },
    order = { "wide", "one" },
    view = "wide",
    avail = function() return true end,
    events = { PLAYER_ENTERING_WORLD = true },
    tick = ns.widgetData.net.tick,
    State = state,
    Build = build,
    Paint = paint,
    opts = {
        { key = "show", label = "widget.n_show",
          when = function(item) return ns.Widget.ViewOf("net", item.view) == "one" end,
          values = {
              { v = nil, label = "widget.n_show_ms" }, { v = "fps", label = "widget.n_show_fps" },
          } },
    },
})
ns.netWidgetLoaded = true
