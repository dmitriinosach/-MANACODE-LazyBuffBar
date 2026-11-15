local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local C = ns.STATE
local function data()
    return ns.widgetData.trinkets
end
local function state()
    local st = { cells = {}, any = false, moving = false, live = false }
    for i, slot in ipairs(data().slots) do
        local c = ns.Trinket.Cell(slot)
        st.cells[i] = c
        if c.s ~= "empty" then st.any = true end
        if c.left then st.moving = true end
        if c.s == "act" or c.s == "ready" then st.live = true end
    end
    return st
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function tile(layer, top, x, y, s)
    local d = data()
    local o = {}
    o.edge = layer:CreateTexture(nil, "BORDER")
    o.edge:SetTexture(WHITE)
    o.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", x, -y)
    o.edge:SetWidth(s)
    o.edge:SetHeight(s)
    o.icon = layer:CreateTexture(nil, "ARTWORK")
    o.icon:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
    o.icon:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
    o.time = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    fontSize(o.time, s * d.timeFont)
    o.time:SetPoint("BOTTOM", o.edge, "BOTTOM", 0, 2)
    o.count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    fontSize(o.count, s * d.stackFont)
    o.count:SetPoint("TOPRIGHT", o.edge, "TOPRIGHT", -1, -1)
    return o
end
local function build(layer, view)
    local cell, gap, gapY = layer.cell or layer.h, layer.gap or 2, layer.gapY or 2
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    layer.tiles = {}
    for i = 1, #data().slots do
        local x = (view == "col") and 0 or (i - 1) * (cell + gap)
        local y = (view == "col") and (i - 1) * (cell + gapY) or 0
        layer.tiles[i] = tile(layer, top, x, y, cell)
    end
end
local EDGE = { act = C.ok, ready = C.full }
local INK = { icd = C.mute }
local function paintTile(o, c)
    local W = ns.Widget
    if not c or c.s == "empty" then
        W.Alpha(o.icon, 0)
        W.Alpha(o.edge, 0)
        W.Text(o.time, "")
        W.Text(o.count, "")
        return
    end
    local wait = c.s == "icd" or c.s == "cd"
    W.Tex(o.icon, c.icon or ns.QMARK, wait)
    W.Alpha(o.icon, wait and data().dim or 1)
    local edge = EDGE[c.s]
    if edge then W.Color(o.edge, edge) end
    W.Alpha(o.edge, edge and 1 or 0)
    W.Text(o.time, W.Left(c.left))
    W.Color(o.time, INK[c.s] or C.text)
    W.Text(o.count, (c.s == "act" and c.stacks and c.stacks > 1) and tostring(c.stacks) or "")
    W.Color(o.count, C.text)
end
local function paint(layer, st)
    for i, o in ipairs(layer.tiles) do paintTile(o, st.cells[i]) end
end
local function cellAt(i, cx, cy)
    local macro = "/use " .. data().slots[i]
    return {
        cx = cx, cy = cy,
        attrs = function(st)
            local c = st.cells[i]
            if not (c and c.use) then return {} end
            return { type = "macro", macrotext = macro }
        end,
    }
end
local CELLS = {
    row = { cellAt(1, 0, 0), cellAt(2, 1, 0) },
    col = { cellAt(1, 0, 0), cellAt(2, 0, 1) },
}
ns.Widget.Register("trinkets", {
    icon = data().icon,
    label = "widget.trinkets",
    general = true,
    views = { row = { w = 2, h = 1 }, col = { w = 1, h = 2 } },
    order = { "row", "col" },
    view = "row",
    avail = function() return true end,
    events = {
        UNIT_AURA = "player", UNIT_INVENTORY_CHANGED = "player", PLAYER_EQUIPMENT_CHANGED = true,
        BAG_UPDATE_COOLDOWN = true, SPELL_UPDATE_COOLDOWN = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return st.moving and 1 or nil end,
    State = state,
    active = function(st, opt)
        if opt and opt.when == "live" then return st.live end
        return st.any
    end,
    Build = build,
    Paint = paint,
    cells = function(view) return CELLS[view] or CELLS.row end,
    opts = {
        { key = "when", label = "card.show", values = {
            { v = nil, label = "widget.m_when_always" }, { v = "live", label = "widget.tr_when_live" },
        } },
    },
})
ns.trinketsWidgetLoaded = true
