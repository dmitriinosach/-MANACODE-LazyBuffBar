local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local EDGE = ns.STATE
local WHITE_C = ns.STATE.text
local WARN_C = ns.STATE.soon
local QUAD = {
    { 0, 0, 0.5, 0.5 },
    { 0.5, 0, 1, 0.5 },
    { 0, 0.5, 0.5, 1 },
    { 0.5, 0.5, 1, 1 },
}
local function actionOf(slot, page)
    local d = ns.widgetData.totem
    return d.multicast[slot] + ((page or 1) - 1) * d.page
end
local function state(opt)
    local d = ns.widgetData.totem
    local out = {}
    for s = 1, 4 do
        local have, name, start, dur, icon = GetTotemInfo(s)
        local up = (have and name and name ~= "") and true or false
        local t = { up = up, action = actionOf(s, opt and opt.page) }
        if up then
            t.name, t.icon = name, icon
            t.left = (dur and dur > 0) and (start + dur - GetTime()) or nil
            t.verdict = (t.left and t.left < d.soon) and "soon" or "ok"
        else
            t.verdict = "none"
            t.icon = GetActionTexture(t.action)
            if not t.icon then
                local _, _, i = GetSpellInfo(d.icon[s])
                t.icon = i
            end
        end
        out[s] = t
    end
    return out
end
local function build(layer)
    local w, h = layer.w, layer.h
    layer.slots = {}
    for s = 1, 4 do
        local q = QUAD[s]
        local o = {}
        o.edge = layer:CreateTexture(nil, "BORDER")
        o.edge:SetTexture(WHITE)
        o.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", q[1] * w + (q[1] > 0 and 1 or 0), -q[2] * h - (q[2] > 0 and 1 or 0))
        o.edge:SetWidth((q[3] - q[1]) * w - 1)
        o.edge:SetHeight((q[4] - q[2]) * h - 1)
        o.icon = layer:CreateTexture(nil, "ARTWORK")
        o.icon:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
        o.icon:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
        o.text = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        o.text:SetPoint("BOTTOM", o.edge, "BOTTOM", 0, 2)
        layer.slots[s] = o
    end
end
local function paint(layer, st)
    local W = ns.Widget
    for s = 1, 4 do
        local o, t = layer.slots[s], st[s]
        W.Color(o.edge, EDGE[t.verdict])
        W.Tex(o.icon, t.icon or ns.QMARK, not t.up)
        W.Alpha(o.icon, t.up and 1 or 0.4)
        W.Text(o.text, t.left and W.Left(t.left) or "")
        W.Color(o.text, t.verdict == "soon" and WARN_C or WHITE_C)
    end
end
local CELLS = {}
for s = 1, 4 do
    local q = QUAD[s]
    CELLS[s] = {
        l = q[1], t = q[2], r = q[3], b = q[4],
        attrs = function(st) return { type = "action", action = st[s].action } end,
    }
end
ns.Widget.Register("totems", {
    icon = 66842,
    label = "widget.totems",
    views = { a = { w = 2, h = 2 } },
    order = { "a" },
    view = "a",
    avail = function()
        local _, class = UnitClass("player")
        return class == "SHAMAN"
    end,
    events = { PLAYER_TOTEM_UPDATE = true, ACTIONBAR_SLOT_CHANGED = true },
    tick = 1,
    State = state,
    Build = build,
    Paint = paint,
    cells = function() return CELLS end,
})
ns.totemWidgetLoaded = true
