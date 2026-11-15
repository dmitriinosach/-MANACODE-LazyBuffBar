local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local EDGE = ns.STATE
local WHITE_C = ns.STATE.text
local WARN_C = ns.STATE.soon
local MUTE_C = ns.STATE.mute
local GOLD = ns.STATE.full
local STACK = ns.STATE.stack
local DIM_NONE = 0.4
local DIM_OFF = 0.3
local UNSEEN = 0.45
local BAR_GAP = 2
local BAR_INSET = 4
local PIP_FRAC = 0.16
local function data()
    return ns.widgetData.mine
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
    o.tf = CreateFrame("Frame", nil, parent)
    o.tf:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    o.tf:SetWidth(s)
    o.tf:SetHeight(s)
    o.text = o.tf:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    o.text:SetPoint("BOTTOM", o.tf, "BOTTOM", 0, 2)
    local ph = math.max(3, math.floor(s * PIP_FRAC))
    o.pips = ns.Gauge.New(parent, "pips", { w = s - 6, h = ph, max = 3, color = STACK, full = GOLD, gap = 1, flash = false })
    o.pips:Frame():SetPoint("TOP", parent, "TOPLEFT", x + s / 2, -y - 2)
    o.pips:Hide()
    return o
end
local function pips(o, on)
    if o.pipsOn == on then return end
    o.pipsOn = on
    if on then o.pips:Show() else o.pips:Hide() end
end
local function secsOf(c)
    if c.verdict == "none" then return nil end
    if c.verdict == "off" then return c.blockLeft end
    return c.left
end
local function textColor(c)
    if c.verdict == "soon" then return WARN_C end
    if c.verdict == "off" then return MUTE_C end
    return WHITE_C
end
local function paintTile(o, c, digits, edge)
    local W = ns.Widget
    if not c then
        W.Alpha(o.edge, 0)
        W.Alpha(o.icon, 0)
        W.Text(o.text, "")
        pips(o, false)
        ns.Anim.Pulse(o.tf, false)
        return
    end
    local v = c.verdict
    W.Color(o.edge, edge or EDGE[v] or EDGE.off)
    W.Alpha(o.edge, 1)
    W.Tex(o.icon, c.info.icon or ns.QMARK, v == "none" or v == "off")
    W.Alpha(o.icon, (v == "none" and DIM_NONE) or (v == "off" and DIM_OFF) or 1)
    local secs = digits and secsOf(c) or nil
    W.Text(o.text, secs and W.Left(secs) or "")
    W.Color(o.text, textColor(c))
    local show = c.max ~= nil and v ~= "none" and v ~= "off"
    pips(o, show)
    if show then o.pips:Set(c.count, math.max(c.max, c.count)) end
    ns.Anim.Pulse(o.tf, v == "soon")
end
local function grid(layer)
    local cell = layer.cell or layer.h
    local gap = layer.gap or 2
    return cell, gap, layer.gapY or gap
end
local function buildBars(layer)
    local cell, _, gapY = grid(layer)
    local n = ns.Mine.Rows()
    layer.rows = {}
    for i = 1, n do
        local rf = CreateFrame("Frame", nil, layer)
        rf:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, -(i - 1) * (cell + gapY))
        rf:SetWidth(layer.w)
        rf:SetHeight(cell)
        local o = tile(rf, 0, 0, cell)
        o.rf = rf
        local bw = layer.w - cell - BAR_GAP
        o.bar = ns.Gauge.New(rf, "bar", { w = bw, h = cell - 2 * BAR_INSET, max = 1, color = EDGE.ok, flash = false })
        o.bar:Frame():SetPoint("LEFT", rf, "LEFT", cell + BAR_GAP, 0)
        o.time = o.bar:Frame():CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        o.time:SetPoint("RIGHT", o.bar:Frame(), "RIGHT", -3, 0)
        o.time:SetJustifyH("RIGHT")
        layer.rows[i] = o
    end
end
local function paintBar(o, c)
    local W = ns.Widget
    if not c then
        W.Alpha(o.rf, 0)
        paintTile(o, nil, false)
        ns.Anim.Pulse(o.bar:Frame(), false)
        return
    end
    W.Alpha(o.rf, 1)
    paintTile(o, c, false)
    local v = c.verdict
    local dur = (c.dur and c.dur > 0) and c.dur or nil
    if (v == "ok" or v == "soon" or v == "bad") and dur and c.left then
        o.bar:Set(math.min(c.left, dur), dur)
    else
        o.bar:Set(0)
    end
    if o.win ~= c.window then
        o.win = c.window
        o.bar:SetTicks(c.window > 0 and { c.window } or nil)
    end
    local col = EDGE[v] or EDGE.off
    o.bar:SetColor(col[1], col[2], col[3], col[4])
    local secs = secsOf(c)
    W.Text(o.time, secs and W.Left(secs) or "")
    W.Color(o.time, textColor(c))
    ns.Anim.Pulse(o.bar:Frame(), v == "soon")
end
local function buildRow(layer)
    local cell, gap = grid(layer)
    layer.tiles = {}
    for i = 1, ns.Mine.Rows() do layer.tiles[i] = tile(layer, (i - 1) * (cell + gap), 0, cell) end
end
local function buildOne(layer)
    local o = tile(layer, 0, 0, layer.h)
    o.count = o.tf:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.count:SetPoint("TOPRIGHT", o.tf, "TOPRIGHT", -2, -2)
    o.count:SetJustifyH("RIGHT")
    layer.one = o
end
local function buildTargets(layer)
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetVertexColor(0, 0, 0, 0.35)
    bg:SetAllPoints(layer)
    local d = data()
    local n, m = d.targets.rows, d.rows
    local rh = math.floor(layer.h / n)
    local s = rh - 2
    layer.lines = {}
    for r = 1, n do
        local rf = CreateFrame("Frame", nil, layer)
        rf:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, -(r - 1) * rh)
        rf:SetWidth(layer.w)
        rf:SetHeight(rh)
        local line = { rf = rf, marks = {} }
        line.name = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line.name:SetPoint("LEFT", rf, "LEFT", 2, 0)
        line.name:SetJustifyH("LEFT")
        line.name:SetWidth(math.max(8, layer.w - m * (s + 1) - 4))
        for j = 1, m do
            local x = layer.w - (m - j + 1) * (s + 1) - 1
            local e = rf:CreateTexture(nil, "BORDER")
            e:SetTexture(WHITE)
            e:SetPoint("TOPLEFT", rf, "TOPLEFT", x, -1)
            e:SetWidth(s)
            e:SetHeight(s)
            local ic = rf:CreateTexture(nil, "ARTWORK")
            ic:SetPoint("TOPLEFT", e, "TOPLEFT", 1, -1)
            ic:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", -1, 1)
            line.marks[j] = { edge = e, icon = ic }
        end
        layer.lines[r] = line
    end
end
local function paintTargets(layer, st)
    local W = ns.Widget
    for r, line in ipairs(layer.lines) do
        local row = st.rows[r]
        if not row then
            W.Alpha(line.rf, 0)
        else
            W.Alpha(line.rf, row.seen and 1 or UNSEEN)
            W.Text(line.name, row.name or "?")
            W.Color(line.name, (row.cur and GOLD) or (row.seen and WHITE_C) or MUTE_C)
            for j, mk in ipairs(line.marks) do
                local c = st.auras[j]
                local v = row.marks[j]
                if c and v then
                    W.Color(mk.edge, EDGE[v] or EDGE.off)
                    W.Alpha(mk.edge, 1)
                    W.Tex(mk.icon, c.info.icon or ns.QMARK, v == "none")
                    W.Alpha(mk.icon, v == "none" and DIM_NONE or 1)
                else
                    W.Alpha(mk.edge, 0)
                    W.Alpha(mk.icon, 0)
                end
            end
        end
    end
end
local function build(layer, view)
    if view == "bars" then buildBars(layer)
    elseif view == "one" then buildOne(layer)
    elseif view == "targets" then buildTargets(layer)
    else buildRow(layer) end
end
local function paint(layer, st, view)
    if view == "bars" then
        for i, o in ipairs(layer.rows) do paintBar(o, st.auras[i]) end
    elseif view == "one" then
        local o = layer.one
        local c = st.top and st.auras[st.top] or nil
        paintTile(o, c, true, st.verdict == "full" and GOLD or nil)
        local many = st.unit ~= nil and #st.auras > 1
        ns.Widget.Text(o.count, many and (st.up .. "/" .. #st.auras) or "")
        ns.Widget.Color(o.count, WHITE_C)
    elseif view == "targets" then
        paintTargets(layer, st)
    else
        for i, o in ipairs(layer.tiles) do paintTile(o, st.auras[i], true) end
    end
end
local cellCache = {}
local function attrsOf(i)
    return function(st) return ns.Mine.Attrs(st, i) end
end
local function cells(view)
    if view ~= "bars" and view ~= "row" then return {} end
    local n = ns.Mine.Rows()
    local key = view .. n
    local list = cellCache[key]
    if list then return list end
    list = {}
    for i = 1, n do
        if view == "bars" then
            list[i] = { l = 0, t = (i - 1) / n, r = 1, b = i / n, attrs = attrsOf(i) }
        else
            list[i] = { cx = i - 1, cy = 0, attrs = attrsOf(i) }
        end
    end
    cellCache[key] = list
    return list
end
local function stateLine(c)
    if c.verdict == "bad" then return ns.T("widget.mine_t_bad", c.by or "?") end
    return ns.T("widget.mine_t_block", c.block or "?", ns.Widget.Left(c.blockLeft))
end
local function tip(i, st)
    local c = st.auras[i]
    if not (c and st.unit) then return nil end
    if c.verdict ~= "bad" and c.verdict ~= "off" then return nil end
    local parts = { stateLine(c) }
    if c.info.cast and st.token then parts[#parts + 1] = ns.T("widget.mine_t_cast", st.who or "?") end
    return c.info.name or "?", table.concat(parts, " ")
end
local SHOW_ON = { { v = nil, label = "widget.mine_show" }, { v = "off", label = "widget.mine_hide" } }
local SHOW_OFF = { { v = "on", label = "widget.mine_show" }, { v = nil, label = "widget.mine_hide" } }
local function unitValues()
    local s = ns.Mine.Set()
    local def = s and s.unit or "target"
    local out = { { v = nil, text = ns.Units.Label(def) } }
    for _, l in ipairs(data().units[(s and s.help) and "help" or "harm"]) do
        if l ~= def then out[#out + 1] = { v = l, label = "unit." .. l } end
    end
    return out
end
local function optList()
    local out = { { key = "unit", label = "widget.mine_unit", values = unitValues, when = function() return ns.Mine.Set() ~= nil end } }
    local d = data()
    local classes = {}
    for class in pairs(d.sets) do classes[#classes + 1] = class end
    table.sort(classes)
    local seen = {}
    for _, class in ipairs(classes) do
        local variants = {}
        for v in pairs(d.sets[class]) do variants[#variants + 1] = v end
        table.sort(variants)
        for _, v in ipairs(variants) do
            local set = d.sets[class][v]
            for _, k in ipairs(set.auras) do
                if not seen[k] then
                    seen[k] = true
                    out[#out + 1] = {
                        key = "a_" .. k, label = "widget.ma_" .. k,
                        values = function()
                            local s = ns.Mine.Set()
                            return (s and s.off[k]) and SHOW_OFF or SHOW_ON
                        end,
                        when = function()
                            local s = ns.Mine.Set()
                            return s ~= nil and s.has[k] == true
                        end,
                    }
                end
            end
        end
    end
    return out
end
local function coverList()
    local out, seen = {}, {}
    for _, a in pairs(data().auras) do
        for _, id in ipairs({ a.id, a.block }) do
            if not seen[id] then
                seen[id] = true
                out[#out + 1] = "spell:" .. id
            end
        end
    end
    table.sort(out)
    return out
end
local _, myClass = UnitClass("player")
ns.Widget.Register("mine", {
    icon = data().icon[myClass or ""] or 48125,
    label = "widget.mine",
    views = {
        bars = function() return 3, ns.Mine.Rows() end,
        row = function() return ns.Mine.Rows(), 1 end,
        one = { w = 1, h = 1 },
        targets = { w = data().targets.w, h = data().targets.h },
    },
    order = { "bars", "row", "one", "targets" },
    view = "row",
    covers = coverList(),
    avail = function() return ns.Mine.Avail() end,
    events = {
        PLAYER_TARGET_CHANGED = true, PLAYER_FOCUS_CHANGED = true, SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true,
        PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
        PARTY_MEMBERS_CHANGED = true, RAID_ROSTER_UPDATE = true,
    },
    tick = 1,
    State = function(opt) return ns.Mine.State(opt) end,
    units = function(opt) return ns.Mine.Units(opt) end,
    active = function(st, _, view) return ns.Mine.Active(st, view) end,
    Build = build,
    Paint = paint,
    cells = cells,
    Tip = function(i, st) return tip(i, st) end,
    Caption = function(st)
        if not (st.l == "tank" or st.l == "tank2" or st.l == "boss") then return nil end
        return (ns.Units.Tip(st.l))
    end,
    opts = optList(),
})
ns.mineWidgetLoaded = true
