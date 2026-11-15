local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACK = { 0, 0, 0, 0.35 }
local RUN_C = ns.STATE.text
local STOP_C = ns.STATE.mute
local WIDE_FONT = 0.45
local ONE_FONT = 0.36
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), flags) end
end
local function build(layer)
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(layer)
    bg:SetVertexColor(BACK[1], BACK[2], BACK[3], BACK[4])
    local wide = layer.w > layer.h * 1.5
    layer.text = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    fontSize(layer.text, layer.h * (wide and WIDE_FONT or ONE_FONT))
    layer.text:SetPoint("CENTER", layer, "CENTER", 0, 0)
    layer.wide = wide
end
local function span(secs, wide)
    local s = math.max(0, math.floor(secs))
    local h, m, sec = math.floor(s / 3600), math.floor(s % 3600 / 60), s % 60
    if h > 0 then
        if wide then return string.format("%d:%02d:%02d", h, m, sec) end
        return ns.T("widget.rt_hm", h, m)
    end
    return string.format("%d:%02d", m, sec)
end
local function paint(layer, st)
    local W = ns.Widget
    W.Text(layer.text, st.from and span(st.secs, layer.wide) or "")
    W.Color(layer.text, st.run and RUN_C or STOP_C)
end
ns.Widget.Register("raidtime", {
    icon = "Interface\\Icons\\Spell_Holy_BorrowedTime",
    label = "widget.raidtime",
    general = true,
    views = { wide = { w = 2, h = 1 }, one = { w = 1, h = 1 } },
    order = { "wide", "one" },
    view = "wide",
    avail = function() return true end,
    events = {},
    tick = function(st) return st.run and 1 or nil end,
    State = function(opt) return ns.RaidTime.State(opt) end,
    active = function(st) return st.from ~= nil end,
    Build = build,
    Paint = paint,
    opts = {
        { key = "from", label = "widget.rt_from", values = {
            { v = nil, label = "widget.rt_from_enter" }, { v = "boss", label = "widget.rt_from_boss" },
            { v = "pull", label = "widget.rt_from_pull" },
        } },
        { key = "till", label = "widget.rt_till", values = {
            { v = nil, label = "widget.rt_till_out" }, { v = "fight", label = "widget.rt_till_fight" },
        } },
    },
})
ns.raidtimeWidgetLoaded = true
