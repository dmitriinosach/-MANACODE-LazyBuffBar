local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACK = { 0, 0, 0, 0.35 }
local EDGE = ns.STATE
local TEXT_C = ns.STATE.text
local function state(opt)
    local d = ns.widgetData.dura
    local worst, slot, broken = nil, nil, false
    for _, s in ipairs(d.slots) do
        local cur, max = GetInventoryItemDurability(s)
        cur, max = tonumber(cur), tonumber(max)
        if cur and max and max > 0 then
            local p = cur / max
            if cur <= 0 then broken = true end
            if not worst or p < worst then worst, slot = p, s end
        end
    end
    local st = { slot = slot, broken = broken, verdict = "ok", show = (opt and opt.show == "always") and "always" or "low" }
    if not worst then return st end
    st.pct = math.floor(worst * 100)
    if broken or st.pct < d.bad then st.verdict = "bad"
    elseif st.pct < d.warn then st.verdict = "soon" end
    return st
end
local function active(st)
    if not st.pct then return false end
    return st.show == "always" or st.pct < ns.widgetData.dura.warn
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function build(layer, view)
    local d = ns.widgetData.dura
    local s = layer.h
    layer.edge = layer:CreateTexture(nil, "BORDER")
    layer.edge:SetTexture(WHITE)
    layer.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, 0)
    layer.edge:SetWidth(s)
    layer.edge:SetHeight(s)
    layer.icon = layer:CreateTexture(nil, "ARTWORK")
    layer.icon:SetPoint("TOPLEFT", layer.edge, "TOPLEFT", 1, -1)
    layer.icon:SetPoint("BOTTOMRIGHT", layer.edge, "BOTTOMRIGHT", -1, 1)
    layer.icon:SetTexture(d.icon)
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    layer.pct = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    if view ~= "wide" then
        fontSize(layer.pct, s * d.pctFont)
        layer.pct:SetPoint("BOTTOM", layer.edge, "BOTTOM", 0, 2)
        return
    end
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + (layer.gap or 2), 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(BACK[1], BACK[2], BACK[3], BACK[4])
    fontSize(layer.pct, s * d.wideFont)
    layer.pct:SetPoint("CENTER", bg, "CENTER", 0, 0)
end
local function paint(layer, st)
    local W = ns.Widget
    local v = st.verdict
    if v ~= "ok" then W.Color(layer.edge, EDGE[v]) end
    W.Alpha(layer.edge, v ~= "ok" and 1 or 0)
    W.Text(layer.pct, st.pct and string.format("%d%%", st.pct) or "")
    W.Color(layer.pct, v == "ok" and TEXT_C or EDGE[v])
end
ns.Widget.Register("dura", {
    icon = ns.widgetData.dura.icon,
    label = "widget.dura",
    general = true,
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    avail = function() return true end,
    events = { UPDATE_INVENTORY_DURABILITY = true, UNIT_INVENTORY_CHANGED = "player", PLAYER_ENTERING_WORLD = true },
    State = state,
    active = function(st) return active(st) end,
    Build = build,
    Paint = paint,
    opts = {
        { key = "show", label = "widget.d_show", values = function()
            return {
                { v = "always", label = "widget.d_show_always" },
                { v = nil, text = ns.T("widget.d_show_low", ns.widgetData.dura.warn) },
            }
        end },
    },
})
ns.duraWidgetLoaded = true
