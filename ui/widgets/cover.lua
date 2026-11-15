local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local EDGE = ns.STATE
local WHITE_C = ns.STATE.text
local WARN_C = ns.STATE.soon
local MUTE_C = ns.STATE.mute
local DIM_NONE = 0.4
local DIM_OFF = 0.3
local LINES = 3
local LEFT = 1 / 3
local PAD = 3
local MARK = 0.16
local INSET = 0.07
local SPAN = 0.86
local classColors = {}
local function classColor(class)
    local c = classColors[class]
    if c then return c end
    local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    c = cc and { cc.r, cc.g, cc.b, 1 } or WHITE_C
    classColors[class] = c
    return c
end
local function rowWidth()
    local n = #ns.Cover.Buffs()
    return n > 0 and n or 1
end
local function tile(parent, x, y, s)
    local o = {}
    o.edge = parent:CreateTexture(nil, "BORDER")
    o.edge:SetTexture(WHITE)
    o.edge:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    o.edge:SetWidth(s)
    o.edge:SetHeight(s)
    o.icon = parent:CreateTexture(nil, "ARTWORK")
    o.icon:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 1, -1)
    o.icon:SetPoint("BOTTOMRIGHT", o.edge, "BOTTOMRIGHT", -1, 1)
    o.top = CreateFrame("Frame", nil, parent)
    o.top:SetAllPoints(o.edge)
    o.count = o.top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.count:SetPoint("BOTTOM", o.edge, "BOTTOM", 0, 2)
    o.timeF = CreateFrame("Frame", nil, o.top)
    o.timeF:SetAllPoints(o.edge)
    o.time = o.timeF:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.time:SetPoint("TOPRIGHT", o.edge, "TOPRIGHT", -2, -2)
    o.time:SetJustifyH("RIGHT")
    return o
end
local function paintTile(o, s)
    local W = ns.Widget
    local v = s and s.verdict or "off"
    local empty = v == "off" or not s or s.n == 0
    W.Tex(o.icon, s and s.icon or ns.QMARK, empty)
    W.Alpha(o.icon, v == "off" and DIM_OFF or (empty and DIM_NONE or 1))
    W.Color(o.edge, EDGE[v])
    W.Text(o.count, (s and s.total > 0) and (s.n .. "/" .. s.total) or "")
    W.Color(o.count, WHITE_C)
    W.Text(o.time, (s and s.min) and W.Left(s.min) or "")
    W.Color(o.time, v == "soon" and WARN_C or WHITE_C)
    ns.Anim.Pulse(o.timeF, v == "soon")
end
local function buildRow(layer)
    local cell, gap = layer.cell or layer.h, layer.gap or 2
    layer.tiles = {}
    for i = 1, #ns.Cover.Buffs() do layer.tiles[i] = tile(layer, (i - 1) * (cell + gap), 0, cell) end
end
local function buildOne(layer)
    local s = layer.h
    local o = tile(layer, 0, 0, s)
    local n = #ns.Cover.Buffs()
    if n > 1 then
        o.marks = {}
        local dot = math.max(3, math.floor(s * MARK))
        for k = 1, n do
            local t = o.top:CreateTexture(nil, "OVERLAY")
            t:SetTexture(WHITE)
            t:SetPoint("TOPLEFT", o.edge, "TOPLEFT", 2, -2 - (k - 1) * (dot + 1))
            t:SetWidth(dot)
            t:SetHeight(dot)
            o.marks[k] = t
        end
    end
    layer.one = o
end
local function buildList(layer)
    local cell, gapY = layer.cell or 32, layer.gapY or 2
    local w, h = layer.w, layer.h
    layer.one = tile(layer, 0, 0, cell)
    local top = CreateFrame("Frame", nil, layer)
    top:SetAllPoints(layer)
    layer.more = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.more:SetPoint("CENTER", layer, "TOPLEFT", cell / 2, -(cell + gapY + cell / 2))
    layer.names = {}
    local lh = h / LINES
    for i = 1, LINES do
        local fs = top:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", layer, "TOPLEFT", w * LEFT + PAD, -(i - 1) * lh)
        fs:SetWidth(w * (1 - LEFT) - PAD * 2)
        fs:SetHeight(lh)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("MIDDLE")
        layer.names[i] = fs
    end
end
local function paintOne(layer, st)
    local o = layer.one
    paintTile(o, st.buffs[st.pick])
    for k, t in ipairs(o.marks or {}) do
        local s = st.buffs[k]
        ns.Widget.Color(t, EDGE[s and s.verdict or "off"])
    end
end
local function paintList(layer, st)
    local W = ns.Widget
    local s = st.buffs[st.pick]
    paintTile(layer.one, s)
    local list = s and s.list or {}
    for i, fs in ipairs(layer.names) do
        local m = list[i]
        W.Text(fs, m and m.name or "")
        if m then W.Color(fs, ns.Cover.Far(m) and MUTE_C or classColor(m.class)) end
    end
    local rest = s and (s.missN - #list) or 0
    W.Text(layer.more, rest > 0 and ns.T("widget.cv_more", rest) or "")
    W.Color(layer.more, WHITE_C)
end
local function buildBars(layer)
    local w, h = layer.w, layer.h
    local n = math.max(1, #ns.Cover.Buffs())
    layer.slots = {}
    for k = 1, n do
        local list = {}
        for j = 1, k do
            local y0, y1 = math.floor((j - 1) * h / k + 0.5), math.floor(j * h / k + 0.5)
            local b = {}
            b.edge = layer:CreateTexture(nil, "BORDER")
            b.edge:SetTexture(WHITE)
            b.edge:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, -y0)
            b.edge:SetWidth(w)
            b.edge:SetHeight(y1 - y0)
            b.icon = layer:CreateTexture(nil, "ARTWORK")
            b.icon:SetPoint("TOPLEFT", b.edge, "TOPLEFT", 1, -1)
            b.icon:SetPoint("BOTTOMRIGHT", b.edge, "BOTTOMRIGHT", -1, 1)
            local part = SPAN * math.max(1, y1 - y0 - 2) / math.max(1, w - 2)
            b.v1, b.v2 = 0.5 - part / 2, 0.5 + part / 2
            b.edge:Hide()
            b.icon:Hide()
            b.on = false
            list[j] = b
        end
        layer.slots[k] = list
    end
end
local function barList(st)
    local out = {}
    if st.fixed then
        out[1] = st.pick
        return out
    end
    for i, s in ipairs(st.buffs) do
        if s.known then out[#out + 1] = i end
    end
    if #out == 0 then
        for i = 1, #st.buffs do out[i] = i end
    end
    return out
end
local function barShow(b, on)
    if b.on == on then return end
    b.on = on
    if on then
        b.edge:Show()
        b.icon:Show()
    else
        b.edge:Hide()
        b.icon:Hide()
    end
end
local function paintBar(b, s)
    local W = ns.Widget
    local v = s and s.verdict or "off"
    local t, path = b.icon, s and s.icon or ns.QMARK
    if t.lbbTex ~= path then
        t.lbbTex = path
        t:SetTexture(path)
        t:SetTexCoord(INSET, INSET + SPAN, b.v1, b.v2)
    end
    local dim = v == "none" or v == "off"
    if t.lbbDesat ~= dim then
        t.lbbDesat = dim
        t:SetDesaturated(dim)
    end
    W.Alpha(t, v == "off" and DIM_OFF or (v == "none" and DIM_NONE or 1))
    W.Color(b.edge, EDGE[v])
end
local function paintBars(layer, st)
    local list = barList(st)
    local k = math.min(#list, #layer.slots)
    if layer.barK and layer.barK ~= k then
        for _, b in ipairs(layer.slots[layer.barK] or {}) do barShow(b, false) end
    end
    layer.barK = k
    for j, b in ipairs(layer.slots[k] or {}) do
        barShow(b, true)
        paintBar(b, st.buffs[list[j]])
    end
end
local function barsLine(st)
    local T, W = ns.T, ns.Widget
    local out = {}
    for _, i in ipairs(barList(st)) do
        local s = st.buffs[i]
        if s and (s.verdict == "none" or s.verdict == "soon") then
            local name = T("widget.cvb_" .. s.key)
            if s.min then
                out[#out + 1] = T("widget.cv_bar_min", name, s.n, s.total, W.Left(s.min))
            else
                out[#out + 1] = T("widget.cv_bar", name, s.n, s.total)
            end
        end
    end
    if #out == 0 then return nil end
    local s = st.buffs[st.pick]
    if s and s.next then
        if s.group and st.raid then
            out[#out + 1] = T("widget.cv_click_sub", s.spell, s.next.sub, s.next.name)
        else
            out[#out + 1] = T("widget.cv_click", s.spell, s.next.name)
        end
    end
    return table.concat(out, "\n")
end
local function build(layer, view)
    if view == "one" then buildOne(layer)
    elseif view == "bars" then buildBars(layer)
    elseif view == "list" then buildList(layer)
    else buildRow(layer) end
end
local function paint(layer, st, view)
    if view == "one" then
        paintOne(layer, st)
    elseif view == "bars" then
        paintBars(layer, st)
    elseif view == "list" then
        paintList(layer, st)
    else
        for i, o in ipairs(layer.tiles) do paintTile(o, st.buffs[i]) end
    end
end
local function castAttrs(s)
    if not (s and s.next and s.spell) then return {} end
    return { type = "spell", spell = s.spell, unit = s.next.click }
end
local function pickAttrs(st)
    return castAttrs(st.buffs[st.pick])
end
local ONE_CELLS = { { l = 0, t = 0, r = 1, b = 1, attrs = pickAttrs } }
local LIST_CELLS = { { cx = 0, cy = 0, attrs = pickAttrs } }
for i = 1, LINES do
    LIST_CELLS[i + 1] = {
        l = LEFT, t = (i - 1) / LINES, r = 1, b = i / LINES,
        attrs = function(st)
            local s = st.buffs[st.pick]
            local m = s and s.list[i]
            if not (m and s.single) or ns.Cover.Far(m) then return {} end
            return { type = "spell", spell = s.single, unit = m.click }
        end,
    }
end
local rowCells = {}
local function rowList()
    local _, class = UnitClass("player")
    local list = rowCells[class or ""]
    if list then return list end
    list = {}
    for i = 1, #ns.Cover.Buffs() do
        list[i] = { cx = i - 1, cy = 0, attrs = function(st) return castAttrs(st.buffs[i]) end }
    end
    rowCells[class or ""] = list
    return list
end
local function buffLine(s, st)
    local T, W = ns.T, ns.Widget
    local v = s.verdict
    if v == "off" then return T("widget.cv_off") end
    local line
    if v == "ok" then
        line = s.min and T("widget.cv_ok", s.n, s.total, W.Left(s.min)) or T("widget.cv_ok_all", s.n, s.total)
    elseif v == "soon" then
        line = T("widget.cv_soon_line", s.minWho and s.minWho.name or "?", W.Left(s.min))
    else
        line = T("widget.cv_none", s.missN, s.total)
    end
    if s.next then
        if s.group and st.raid then
            line = line .. " " .. T("widget.cv_click_sub", s.spell, s.next.sub, s.next.name)
        else
            line = line .. " " .. T("widget.cv_click", s.spell, s.next.name)
        end
    elseif v == "none" and s.farWho then
        line = line .. " " .. T("widget.cv_far", s.farWho.name)
    end
    return line
end
local function buffTitle(s)
    local b = ns.Cover.Get(s.key)
    return b and (b.gname or b.sname) or "?"
end
local function canPick(item)
    return ns.Widget.ViewOf("cover", item.view) ~= "row" and #ns.Cover.Buffs() > 1
end
local function iconId()
    local list = ns.widgetData.cover.classes
    local _, class = UnitClass("player")
    local e = list[class or ""] and list[class][1]
    return e and (e.group or e.single) or 48162
end
ns.Widget.Register("cover", {
    icon = iconId(),
    label = "widget.cover",
    views = { row = function() return rowWidth(), 1 end, one = { w = 1, h = 1 }, bars = { w = 1, h = 1 }, list = { w = 3, h = 2 } },
    order = { "row", "one", "bars", "list" },
    view = "row",
    avail = function() return ns.Cover.Avail() end,
    events = { SPELLS_CHANGED = true, RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true, PLAYER_REGEN_ENABLED = true },
    tick = 1,
    State = function(opt) return ns.Cover.State(opt) end,
    active = function(st, opt) return ns.Cover.Active(st, opt) end,
    Build = build,
    Paint = paint,
    cells = function(view)
        if view == "one" or view == "bars" then return ONE_CELLS end
        if view == "list" then return LIST_CELLS end
        return rowList()
    end,
    Tip = function(i, st, view)
        local s
        if view == "bars" then
            local line = barsLine(st)
            if not line then return nil end
            return ns.T("widget.cover"), line
        elseif view == "row" then
            s = st.buffs[i]
        elseif view == "list" and i > 1 then
            s = st.buffs[st.pick]
            local m = s and s.list[i - 1]
            if not m then return nil end
            if m.dead then return m.name, ns.T("widget.cv_dead") end
            if m.out.cover then return m.name, ns.T("widget.cv_far_one") end
            return m.name, s.single and ns.T("widget.cv_click_one", s.single) or nil
        else
            s = st.buffs[st.pick]
        end
        if not s then return nil end
        return buffTitle(s), buffLine(s, st)
    end,
    opts = {
        { key = "buff", label = "widget.cv_buff", when = canPick,
          values = function()
              local out = { { v = nil, label = "widget.cv_buff_auto" } }
              for _, b in ipairs(ns.Cover.Buffs()) do out[#out + 1] = { v = b.key, label = "widget.cvb_" .. b.key } end
              return out
          end },
        { key = "watch", label = "widget.cv_watch", kind = "checks", when = canPick,
          checks = function()
              local out = {}
              for i, b in ipairs(ns.Cover.Buffs()) do out[i] = { key = "w_" .. b.key, def = b.watch, label = "widget.cvb_" .. b.key } end
              return out
          end },
        { key = "cast", label = "widget.cv_cast", values = {
            { v = nil, label = "widget.cv_cast_auto" }, { v = "group", label = "widget.cv_cast_group" },
            { v = "single", label = "widget.cv_cast_single" },
        } },
        { key = "soon", label = "widget.cv_soon", values = {
            { v = 120, label = "widget.cv_soon_2" }, { v = nil, label = "widget.cv_soon_5" }, { v = 600, label = "widget.cv_soon_10" },
        } },
        { key = "when", label = "widget.cv_when", values = {
            { v = nil, label = "widget.cv_when_always" }, { v = "need", label = "widget.cv_when_need" },
        } },
    },
})
ns.coverWidgetLoaded = true
