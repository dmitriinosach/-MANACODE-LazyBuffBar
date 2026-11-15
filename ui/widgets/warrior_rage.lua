local _, ns = ...
local NAME = "war_rage"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local RAGE = 1
local BAR_PAD = 6
local function data()
    return ns.widgetData.war_rage
end
local function costOf(id, fallback)
    local _, _, _, cost = GetSpellInfo(id)
    cost = tonumber(cost) or 0
    if cost >= 100 then cost = cost / 10 end
    return cost > 0 and cost or fallback
end
local function judge(rage, need, dump, queued, qcost)
    if queued then return (rage - qcost < need) and "soon" or "ok" end
    if rage >= dump then return "full" end
    if rage < need then return "mute" end
    return "text"
end
local function ticksOf(list)
    local out, seen = {}, {}
    for _, m in ipairs(list) do
        if not seen[m.cost] then
            seen[m.cost] = true
            out[#out + 1] = m.cost
        end
    end
    table.sort(out)
    return out
end
local function queueKey(opt)
    if opt and opt.queue == "cleave" and ns.IsLearned(data().cleave) then return "cleave" end
    return "hero"
end
local function state(opt)
    local d = data()
    local v = ns.CurrentVariant and ns.CurrentVariant()
    local max = UnitPowerMax("player", RAGE) or 0
    local st = { rage = UnitPower("player", RAGE) or 0, max = max > 0 and max or 100, marks = {} }
    for i, m in ipairs(d.marks[v] or d.marks.arms) do
        st.marks[i] = { name = GetSpellInfo(m.id), cost = costOf(m.id, m.cost) }
    end
    st.ticks = ticksOf(st.marks)
    st.need = st.marks[1].cost
    st.dump = tonumber(opt and opt.dump) or d.dump[v] or d.dump.fury
    local key = queueKey(opt)
    local name, _, icon = GetSpellInfo(d[key])
    st.qname, st.qicon, st.qcost = name, icon, costOf(d[key], d.queueCost[key])
    st.queued = (name and IsCurrentSpell(name)) and true or false
    st.fight = UnitAffectingCombat("player") and true or false
    st.verdict = judge(st.rage, st.need, st.dump, st.queued, st.qcost)
    return st
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function build(layer, view)
    local d = data()
    local s = layer.h
    local step = s + (layer.gap or 2)
    layer.look = {}
    if view == "one" then
        layer.tile = ns.WTile.New(layer, 0, 0, s)
        return
    end
    if view == "queue" then
        local bg = layer:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(WHITE)
        bg:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, 0)
        bg:SetWidth(s)
        bg:SetHeight(s)
        bg:SetVertexColor(0, 0, 0, 0.35)
        layer.num = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        fontSize(layer.num, s * d.numFont)
        layer.num:SetPoint("CENTER", bg, "CENTER", 0, 0)
        layer.tile = ns.WTile.New(layer, step, 0, s)
        return
    end
    layer.bar = ns.Gauge.New(layer, "bar", { w = step + s, h = s - BAR_PAD * 2, max = 100, color = d.color, text = true })
    layer.bar:Frame():SetPoint("LEFT", layer, "LEFT", 0, 0)
    layer.tile = ns.WTile.New(layer, step * 2, 0, s)
end
local function paint(layer, st, view)
    local S = ns.STATE
    local v = st.verdict
    local ink = S[v] or S.text
    local k = layer.look
    k.icon = st.qicon
    k.edge = st.queued and S[v] or nil
    k.glow = v == "full"
    k.text = view == "one" and tostring(st.rage) or ""
    k.textColor = ink
    ns.WTile.Paint(layer.tile, k)
    if layer.num then
        ns.Widget.Text(layer.num, tostring(st.rage))
        ns.Widget.Color(layer.num, ink)
    end
    if layer.bar then
        local c = v == "full" and S.full or data().color
        layer.bar:SetColor(c[1], c[2], c[3], c[4])
        layer.bar:Set(st.rage, st.max)
        layer.bar:SetTicks(st.ticks)
    end
end
local function click(st)
    if not st.qname then return {} end
    return { type = "spell", spell = st.qname }
end
local CELLS = {
    one   = { { l = 0, t = 0, r = 1, b = 1, attrs = click } },
    queue = { { cx = 0, cy = 0 }, { cx = 1, cy = 0, attrs = click } },
    bar   = { { l = 0, t = 0, r = 2 / 3, b = 1 }, { cx = 2, cy = 0, attrs = click } },
}
local function rows(st)
    local S = ns.STATE
    local T = ns.T
    local out = { { l = T("widget.wr_rage", st.rage, st.dump), lc = S[st.verdict] or S.text } }
    for _, m in ipairs(st.marks) do
        out[#out + 1] = { l = m.name or "?", r = tostring(m.cost), lc = st.rage >= m.cost and S.text or S.mute }
    end
    if st.queued then
        out[#out + 1] = { l = T("widget.wr_queued", st.qname or "?"), lc = S.ok }
        if st.verdict == "soon" then
            out[#out + 1] = { l = T("widget.wr_eats", st.marks[1].name or "?"), lc = S.soon }
        end
    end
    return out
end
local DEMO = { solo = { 12, false }, party = { 45, true }, raid = { 78, false } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local st = { rage = p[1], max = 100, marks = {}, queued = p[2], fight = true }
    for i, m in ipairs(d.marks.fury) do st.marks[i] = { name = GetSpellInfo(m.id), cost = m.cost } end
    st.ticks = ticksOf(st.marks)
    st.need = st.marks[1].cost
    st.dump = tonumber(scene.opt and scene.opt.dump) or d.dump.fury
    local key = (scene.opt and scene.opt.queue == "cleave") and "cleave" or "hero"
    local name, _, icon = GetSpellInfo(d[key])
    st.qname, st.qicon, st.qcost = name, icon, d.queueCost[key]
    st.verdict = judge(st.rage, st.need, st.dump, st.queued, st.qcost)
    return st
end
local function dumpValues()
    local out = { { v = nil, label = "widget.h_kind_auto" } }
    for _, n in ipairs(data().steps) do out[#out + 1] = { v = n, text = tostring(n) } end
    return out
end
local function def(own)
    local out = {
        views = { one = { w = 1, h = 1 }, queue = { w = 2, h = 1 }, bar = { w = 3, h = 1 } },
        order = { "one", "queue", "bar" },
        view = "queue",
        Build = build,
        Paint = paint,
        cells = function(view) return CELLS[view] or CELLS.queue end,
    }
    for k, v in pairs(own) do out[k] = v end
    return out
end
ns.WarRage = { Def = def, Rows = rows, CostOf = costOf, TicksOf = ticksOf }
ns.Widget.Register(NAME, def({
    info = { text = "widget.war_rage_info", demo = demo },
    icon = data().hero,
    label = "widget.war_rage",
    class = "WARRIOR",
    avail = function()
        local _, class = UnitClass("player")
        return class == "WARRIOR"
    end,
    events = {
        UNIT_RAGE = "player", UNIT_MAXRAGE = "player", CURRENT_SPELL_CAST_CHANGED = true, PLAYER_TALENT_UPDATE = true,
        ACTIVE_TALENT_GROUP_CHANGED = true, SPELLS_CHANGED = true, PLAYER_REGEN_DISABLED = true,
        PLAYER_REGEN_ENABLED = true, PLAYER_ENTERING_WORLD = true,
    },
    State = state,
    active = function(st, opt) return not (opt and opt.when == "fight") or st.fight or st.rage > 0 end,
    Tip = function(_, st)
        return ns.T("widget.war_rage"), nil, rows(st)
    end,
    opts = {
        { key = "dump", label = "widget.wr_dump", values = dumpValues },
        { key = "queue", label = "widget.wr_queue", values = function()
            return {
                { v = nil, text = GetSpellInfo(data().hero) or "?" },
                { v = "cleave", text = GetSpellInfo(data().cleave) or "?" },
            }
        end },
        { key = "when", label = "widget.wr_when", values = {
            { v = nil, label = "widget.wr_when_always" }, { v = "fight", label = "widget.wr_when_fight" },
        } },
    },
}))
ns.warRageWidgetLoaded = true
