local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACK = { 0, 0, 0, 0.35 }
local EDGE = ns.STATE
local TEXT_C = ns.STATE.text
local SOON_C = ns.STATE.soon
local DIM_NONE = 0.4
local TIME_FONT = 0.34
local STAT_FONT = 0.3
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function build(layer, view)
    local s = layer.h
    layer.edge = layer:CreateTexture(nil, "BORDER")
    layer.edge:SetTexture(WHITE)
    layer.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, 0)
    layer.edge:SetWidth(s)
    layer.edge:SetHeight(s)
    layer.icon = layer:CreateTexture(nil, "ARTWORK")
    layer.icon:SetPoint("TOPLEFT", layer.edge, "TOPLEFT", 1, -1)
    layer.icon:SetPoint("BOTTOMRIGHT", layer.edge, "BOTTOMRIGHT", -1, 1)
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    layer.time = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    fontSize(layer.time, s * TIME_FONT)
    if view ~= "wide" then
        layer.time:SetPoint("BOTTOM", layer.edge, "BOTTOM", 0, 2)
        return
    end
    local x = s + (layer.gap or 2)
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", x, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(BACK[1], BACK[2], BACK[3], BACK[4])
    layer.stat = top:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontSize(layer.stat, s * STAT_FONT)
    layer.stat:SetPoint("BOTTOM", bg, "CENTER", 0, 1)
    layer.time:SetPoint("TOP", bg, "CENTER", 0, -1)
end
local function paint(layer, st)
    local W = ns.Widget
    local v = st.verdict
    local none = v == "none"
    W.Tex(layer.icon, st.icon or ns.QMARK, none)
    W.Alpha(layer.icon, none and DIM_NONE or 1)
    if v ~= "ok" then W.Color(layer.edge, EDGE[v]) end
    W.Alpha(layer.edge, v ~= "ok" and 1 or 0)
    W.Text(layer.time, st.left and W.Left(st.left) or "")
    W.Color(layer.time, v == "soon" and SOON_C or TEXT_C)
    if layer.stat then
        W.Text(layer.stat, st.stat)
        W.Color(layer.stat, TEXT_C)
    end
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st) return ns.Food.Click(st) end },
}
ns.Widget.Register("food", {
    icon = ns.widgetData.food.wellFed,
    label = "widget.food",
    personal = true,
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    avail = function() return true end,
    events = { UNIT_AURA = "player", PLAYER_ENTERING_WORLD = true },
    tick = function(st) return ns.Food.Tick(st) end,
    State = function(opt) return ns.Food.State(opt) end,
    active = function(st, opt) return not (opt and opt.when == "need" and st.verdict == "ok") end,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
    Tip = function(_, st) return ns.Food.Tip(st) end,
    Caption = function(st) return ns.Food.Caption(st) end,
    opts = {
        { key = "item", label = "widget.f_item", kind = "icons",
          when = function() return #ns.Food.Bags() > 0 end,
          values = function() return ns.Food.Choices() end,
          cur = function(item)
              local p = ns.Food.Pick(item.opt)
              return p and p.id or nil
          end },
        { key = "when", label = "widget.f_when", values = {
            { v = nil, label = "widget.f_when_always" }, { v = "need", label = "widget.f_when_need" },
        } },
        { key = "icon", label = "widget.f_icon", values = {
            { v = "buff", label = "widget.f_icon_buff" }, { v = nil, label = "widget.f_icon_item" },
        } },
    },
})
ns.foodWidgetLoaded = true
