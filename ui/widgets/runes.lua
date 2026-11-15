local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACK = { 0, 0, 0, 0.35 }
local TRACK = { 0, 0, 0, 0.55 }
local DIM_OFF = 0.3
local function data()
    return ns.widgetData.runes
end
local function isDK()
    local _, class = UnitClass("player")
    return class == "DEATHKNIGHT"
end
local function state()
    local d = data()
    local st = { off = not isDK(), runes = {}, ready = { 0, 0, 0 }, death = 0, total = 0 }
    for slot = 1, 6 do
        local start, dur, ready = GetRuneCooldown(slot)
        local kind = GetRuneType(slot)
        local r = { kind = d.color[kind or 0] and kind or d.slotType[slot], ready = ready and true or false }
        if not r.ready and start and start > 0 and dur and dur > 0 then r.start, r.dur = start, dur end
        st.runes[slot] = r
    end
    for c, slots in ipairs(d.cells) do
        for _, slot in ipairs(slots) do
            local r = st.runes[slot]
            if r.ready then
                st.total = st.total + 1
                if r.kind == d.death then st.death = st.death + 1 else st.ready[c] = st.ready[c] + 1 end
            end
        end
    end
    local pmax = UnitPowerMax("player", d.powerType) or 0
    st.pmax = pmax > 0 and pmax or d.maxPower
    st.power = UnitPower("player", d.powerType) or 0
    st.spend = d.spend[ns.BarProfile()] or d.spendDefault
    if st.power >= st.pmax then
        st.verdict = "full"
    elseif st.power >= st.spend then
        st.verdict = "ok"
    else
        st.verdict = "none"
    end
    st.idle = st.total == 6 and st.power <= 0
    return st
end
local function back(layer, x, y, w, h)
    local t = layer:CreateTexture(nil, "BACKGROUND")
    t:SetTexture(WHITE)
    t:SetPoint("TOPLEFT", layer, "TOPLEFT", x, -y)
    t:SetWidth(w)
    t:SetHeight(h)
    t:SetVertexColor(BACK[1], BACK[2], BACK[3], BACK[4])
end
local function runeBar(layer, slot, x, y, w, h)
    local d = data()
    local k = d.slotType[slot]
    local g = ns.Gauge.New(layer, "fill", { w = w, h = h, max = 1, color = d.dim[k], full = d.color[k], bg = TRACK, flash = false })
    g:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", x, -y)
    layer.bars[slot] = g
    layer.kinds[slot] = k
end
local function pairCell(layer, x, s, slots)
    back(layer, x, 0, s, s)
    local p = math.max(2, math.floor(s * 0.12))
    local bw = math.floor((s - 3 * p) / 2)
    local x0 = x + math.floor((s - (2 * bw + p)) / 2)
    runeBar(layer, slots[1], x0, p, bw, s - 2 * p)
    runeBar(layer, slots[2], x0 + bw + p, p, bw, s - 2 * p)
end
local function powerCell(layer, x, s)
    local d = data()
    back(layer, x, 0, s, s)
    local p = math.max(1, math.floor(s * 0.08))
    layer.pfill = ns.Gauge.New(layer, "fill", { w = s - 2 * p, h = s - 2 * p, max = d.maxPower, color = d.power, full = d.powerFull, bg = TRACK })
    layer.pfill:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", x + p, -p)
    layer.pnum = ns.Gauge.New(layer, "digits", { w = s, h = s, max = d.maxPower, color = d.text, full = d.powerFull,
        font = math.max(8, math.floor(s * 0.38)), flash = false })
    layer.pnum:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", x, 0)
    layer.pnum:Frame():SetFrameLevel(layer.pfill:Frame():GetFrameLevel() + 1)
end
local function countCell(layer)
    local d = data()
    local s = layer.w
    back(layer, 0, 0, s, layer.h)
    local cw = math.floor(s / 3)
    local rh = math.floor(s * 0.45)
    layer.counts = {}
    for c = 1, 3 do
        local col = d.color[d.base[c]]
        local g = ns.Gauge.New(layer, "digits", { w = cw, h = rh, max = 2, color = d.mute, zero = true, flash = false,
            font = math.max(8, math.floor(s * 0.36)) })
        g:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", (c - 1) * cw + math.floor((s - 3 * cw) / 2), -1)
        layer.counts[c] = { g = g, on = col }
    end
    layer.deathG = ns.Gauge.New(layer, "digits", { w = s, h = math.floor(s * 0.3), max = 6, color = d.color[d.death], flash = false,
        font = math.max(8, math.floor(s * 0.3)) })
    layer.deathG:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", 0, -rh)
    local bh = math.max(3, math.floor(s * 0.14))
    layer.pbar = ns.Gauge.New(layer, "bar", { w = s - 4, h = bh, max = d.maxPower, color = d.power, full = d.powerFull, bg = TRACK })
    layer.pbar:Frame():SetPoint("BOTTOMLEFT", layer, "BOTTOMLEFT", 2, 2)
end
local function build(layer, view)
    local d = data()
    local s = layer.cell
    layer.bars, layer.kinds, layer.tinted = {}, {}, {}
    if view == "count" then
        countCell(layer)
        return
    end
    if view == "six" then
        local p = math.max(1, math.floor(s * 0.08))
        for c, slots in ipairs(d.cells) do
            for j, slot in ipairs(slots) do
                local x, y = (c - 1) * (s + layer.gap), (j - 1) * (s + layer.gapY)
                back(layer, x, y, s, s)
                runeBar(layer, slot, x + p, y + p, s - 2 * p, s - 2 * p)
            end
        end
        return
    end
    for c, slots in ipairs(d.cells) do pairCell(layer, (c - 1) * (s + layer.gap), s, slots) end
    if view == "full" then powerCell(layer, 3 * (s + layer.gap), s) end
end
local function paintRune(layer, slot, r)
    local d = data()
    local g = layer.bars[slot]
    if layer.kinds[slot] ~= r.kind then
        layer.kinds[slot] = r.kind
        local on, dim = d.color[r.kind], d.dim[r.kind]
        g:SetColor(dim[1], dim[2], dim[3], dim[4])
        g:SetColor(on[1], on[2], on[3], on[4], true)
    end
    if r.ready then
        g:Run(nil)
        g:Set(1, 1)
    elseif r.start then
        g:Run(r.start, r.dur, 1)
    else
        g:Run(nil)
        g:Set(0, 1)
    end
end
local function tint(layer, g, c)
    if not g or layer.tinted[g] == c then return end
    layer.tinted[g] = c
    g:SetColor(c[1], c[2], c[3], c[4])
end
local function paint(layer, st)
    local d = data()
    for slot in pairs(layer.bars) do paintRune(layer, slot, st.runes[slot]) end
    local pc = st.verdict == "none" and d.powerLow or d.power
    tint(layer, layer.pfill, pc)
    tint(layer, layer.pbar, pc)
    if layer.pfill then layer.pfill:Set(st.power, st.pmax) end
    if layer.pnum then layer.pnum:Set(st.power, st.pmax) end
    if layer.pbar then layer.pbar:Set(st.power, st.pmax) end
    if layer.counts then
        for c, o in ipairs(layer.counts) do
            local v = st.ready[c]
            tint(layer, o.g, v > 0 and o.on or d.mute)
            o.g:Set(v, 2)
        end
        layer.deathG:Set(st.death, 6)
    end
    ns.Widget.Alpha(layer, st.off and DIM_OFF or 1)
end
ns.Widget.Register("runes", {
    icon = 47568,
    label = "widget.runes",
    class = "DEATHKNIGHT",
    views = { pairs = { w = 3, h = 1 }, full = { w = 4, h = 1 }, six = { w = 3, h = 2 }, count = { w = 1, h = 1 } },
    order = { "pairs", "full", "six", "count" },
    view = "pairs",
    avail = isDK,
    events = {
        RUNE_POWER_UPDATE = true, RUNE_TYPE_UPDATE = true, UNIT_RUNIC_POWER = "player", UNIT_MAXRUNIC_POWER = "player",
        PLAYER_ENTERING_WORLD = true, PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
    },
    State = state,
    Build = build,
    Paint = paint,
    active = function(st, opt) return not (opt and opt.when == "busy" and st.idle) end,
    opts = {
        { key = "when", label = "widget.r_when", values = {
            { v = nil, label = "widget.r_when_always" }, { v = "busy", label = "widget.r_when_busy" },
        } },
    },
})
ns.runesWidgetLoaded = true
