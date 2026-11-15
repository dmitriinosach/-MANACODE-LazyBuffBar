local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local EDGE = ns.STATE
local WHITE_C = ns.STATE.text
local SOON_C = ns.STATE.soon
local BAD_C = ns.STATE.bad
local MUTE_C = ns.STATE.mute
local DIM_CD = 0.4
local DIM_LOCK = 0.3
local PIPS_H = 0.16
local BAR_H = 0.6
local KINDS = { "burst", "defs" }
local function data()
    return ns.widgetData.cds
end
local function tile(layer, x, y, s, font)
    local o = {}
    o.edge = layer:CreateTexture(nil, "BORDER")
    o.edge:SetTexture(WHITE)
    o.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", x, -y)
    o.edge:SetWidth(s)
    o.edge:SetHeight(s)
    o.icon = layer:CreateTexture(nil, "ARTWORK")
    o.icon:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
    o.icon:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
    o.text = layer:CreateFontString(nil, "OVERLAY", font)
    o.text:SetPoint("BOTTOM", o.edge, "BOTTOM", 0, 2)
    return o
end
local function edgeOf(c, st)
    if not c then return nil end
    if c.s == "act" then return EDGE[c.verdict] end
    if c.s == "lock" then return EDGE.bad end
    if c.s == "ready" and st.full then return EDGE.full end
    return nil
end
local function textColor(c)
    if c.s == "act" and c.verdict == "soon" then return SOON_C end
    if c.s == "lock" then return BAD_C end
    return WHITE_C
end
local function paintTile(o, c, st, bare)
    local W = ns.Widget
    if not c or c.s == "idle" then
        W.Alpha(o.icon, 0)
        W.Alpha(o.edge, 0)
        W.Text(o.text, "")
        return
    end
    local s = c.s
    W.Tex(o.icon, c.icon or ns.QMARK, s == "cd" or s == "lock")
    W.Alpha(o.icon, (s == "cd" and DIM_CD) or (s == "lock" and DIM_LOCK) or 1)
    local edge = edgeOf(c, st)
    if edge then W.Color(o.edge, edge) end
    W.Alpha(o.edge, edge and 1 or 0)
    W.Text(o.text, (s ~= "ready" and not bare) and W.Left(c.left) or "")
    W.Color(o.text, textColor(c))
end
local function buildRow(layer, n)
    local cell, gap = layer.cell or layer.h, layer.gap or 2
    layer.tiles = {}
    for i = 1, n do layer.tiles[i] = tile(layer, (i - 1) * (cell + gap), 0, cell, "NumberFontNormalSmall") end
end
local function buildOne(layer)
    local s = layer.h
    layer.one = tile(layer, 0, 0, s, "NumberFontNormal")
    local ph = math.max(3, math.floor(s * PIPS_H + 0.5))
    layer.pips = ns.Gauge.New(layer, "pips", { w = s - 4, h = ph, max = 1, color = ns.STATE.ok, full = ns.STATE.full, gap = 1 })
    layer.pips:Frame():SetPoint("TOP", layer, "TOP", 0, -2)
end
local function buildBars(layer, rows)
    local cell, gap, gapY = layer.cell or layer.h, layer.gap or 2, layer.gapY or 2
    layer.tiles = {}
    local bw = layer.w - cell - gap
    local bh = math.max(4, math.floor(cell * BAR_H + 0.5))
    for r = 1, rows do
        local y = (r - 1) * (cell + gapY)
        local o = tile(layer, 0, y, cell, "NumberFontNormalSmall")
        o.bar = ns.Gauge.New(layer, "bar", { w = bw, h = bh, max = 1, color = MUTE_C, flash = false })
        o.bar:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", cell + gap, -y - math.floor((cell - bh) / 2))
        o.barText = o.bar:Frame():CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        o.barText:SetPoint("RIGHT", o.bar:Frame(), "RIGHT", -2, 0)
        layer.tiles[r] = o
    end
end
local function barColor(c)
    if c.s == "act" then return EDGE[c.verdict] end
    if c.s == "lock" then return BAD_C end
    return MUTE_C
end
local function paintBar(o, c, st)
    paintTile(o, c, st, true)
    local W = ns.Widget
    if not c or c.s == "idle" or c.s == "ready" then
        o.bar:Set(0, 1)
        W.Text(o.barText, "")
        return
    end
    local col = barColor(c)
    if o.barC ~= col then
        o.barC = col
        o.bar:SetColor(col[1], col[2], col[3], col[4])
    end
    if c.left and c.dur and c.dur > 0 then
        o.bar:Set(math.floor(c.left * 10 + 0.5) / 10, c.dur)
    else
        o.bar:Set(1, 1)
    end
    W.Text(o.barText, W.Left(c.left))
    W.Color(o.barText, textColor(c))
end
local function paintOne(layer, st)
    local c = st.best and st.cells[st.best] or nil
    local o = layer.one
    paintTile(o, c, st)
    local frame = layer.pips:Frame()
    if st.total > 0 then
        layer.pips:Set(st.ready, st.total)
        if not frame:IsShown() then layer.pips:Show() end
    elseif frame:IsShown() then
        layer.pips:Hide()
    end
end
local function barRows(kind)
    return math.min(ns.Cds.Width(kind), data().bars)
end
local cellCache = { burst = {}, defs = {} }
local function cellAt(i, cx, cy)
    return {
        cx = cx, cy = cy,
        attrs = function(st)
            local c = st.cells[i]
            if not (c and c.cast) then return {} end
            return { type = "spell", spell = c.cast }
        end,
    }
end
local function cellsOf(kind, view)
    if view == "one" then return {} end
    local n = (view == "bars") and barRows(kind) or ns.Cds.Width(kind)
    local key = view .. n
    local list = cellCache[kind][key]
    if list then return list end
    list = {}
    for i = 1, n do
        if view == "bars" then list[i] = cellAt(i, 0, i - 1) else list[i] = cellAt(i, i - 1, 0) end
    end
    cellCache[kind][key] = list
    return list
end
local function tipLine(c)
    if c.left then return ns.T("widget.cds_t_lock", c.lockName or "?", ns.Widget.Left(c.left)) end
    return ns.T("widget.cds_t_lock_on", c.lockName or "?")
end
local function optsOf(kind)
    local out = {}
    local onOff = {
        { v = nil, label = "widget.cds_on" }, { v = true, label = "widget.cds_off" },
    }
    if kind == "burst" then
        out[1] = { key = "hero", label = "widget.cds_hero", values = {
            { v = nil, label = "widget.cds_on" }, { v = "off", label = "widget.cds_off" },
        } }
    end
    for _, key in ipairs(ns.Cds.ClassKeys(kind)) do
        out[#out + 1] = {
            key = "off_" .. key, label = "widget.cds_one_cd", values = onOff,
            text = function() return ns.Cds.Name(key) end,
            when = function() return ns.Cds.InSet(kind, key) and ns.Cds.Known(key) end,
        }
    end
    return out
end
local EVENTS = {
    SPELL_UPDATE_COOLDOWN = true, UNIT_AURA = "player", SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
}
for _, kind in ipairs(KINDS) do
    local name = "cds_" .. kind
    ns.Widget.Register(name, {
        icon = ns.Cds.Icon(kind),
        label = "widget." .. name,
        views = {
            row = function() return ns.Cds.Width(kind), 1 end,
            one = { w = 1, h = 1 },
            bars = function() return 3, barRows(kind) end,
        },
        order = { "row", "one", "bars" },
        view = "row",
        covers = ns.Cds.Covers(kind),
        avail = function() return ns.Cds.Avail(kind) end,
        events = EVENTS,
        tick = 1,
        State = function(opt) return ns.Cds.State(kind, opt) end,
        Build = function(layer, view)
            if view == "one" then buildOne(layer)
            elseif view == "bars" then buildBars(layer, barRows(kind))
            else buildRow(layer, ns.Cds.Width(kind)) end
        end,
        Paint = function(layer, st, view)
            if view == "one" then
                paintOne(layer, st)
                return
            end
            for i, o in ipairs(layer.tiles) do
                if view == "bars" then paintBar(o, st.cells[i], st) else paintTile(o, st.cells[i], st) end
            end
        end,
        cells = function(view) return cellsOf(kind, view) end,
        Tip = function(i, st)
            local c = st.cells[i]
            if c and c.s == "act" and c.on then return c.name or "?", ns.T("widget.cds_t_on", c.on) end
            if not c or c.s ~= "lock" then return nil end
            return c.name or "?", tipLine(c)
        end,
        opts = optsOf(kind),
    })
end
ns.cdsWidgetLoaded = true
