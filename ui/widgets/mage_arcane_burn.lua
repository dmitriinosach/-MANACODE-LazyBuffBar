local _, ns = ...
local KEY = "mage_arcane_burn"
local MANA = 0
local PAD = 3
local FONT = 0.36
local function data()
    return ns.widgetData.mage_arcane_burn
end
local rates = { samples = {}, at = -math.huge, busy = -math.huge }
local mems = setmetatable({}, { __mode = "k" })
local NO_MARK = {}
local function avail()
    if ns.PlayerClass() ~= "MAGE" then return false end
    local d = data()
    return ns.IsLearned(d.barrage) and ns.IsLearned(d.evoc)
end
local function buffOn(id)
    local n = GetSpellInfo(id)
    return (n and UnitBuff("player", n)) and true or false
end
local function names(st)
    local d = data()
    local name, _, icon = GetSpellInfo(d.evoc)
    st.evoc, st.evocIcon = name, icon
    st.blastIcon = select(3, GetSpellInfo(d.blast))
    st.missIcon = select(3, GetSpellInfo(d.missiles))
end
local function judge(st)
    local d = data()
    if st.have and st.need > 0 then st.spare = st.have - st.need else st.spare = nil end
    if st.channel then
        st.verdict, st.why = "evoke", "channel"
    elseif st.ready and st.pct < st.low then
        st.verdict, st.why = "evoke", "low"
    elseif st.ap then
        st.verdict, st.why = "burn", "ap"
    elseif st.hero then
        st.verdict, st.why = "burn", "hero"
    elseif st.ready then
        st.verdict, st.why = "burn", "ready"
    elseif st.execute then
        st.verdict, st.why = "burn", "execute"
    elseif not st.have then
        st.verdict, st.why = "burn", "norate"
    elseif st.have >= st.need + d.margin then
        st.verdict, st.why = "burn", "enough"
    else
        st.verdict, st.why = "save", "short"
    end
end
local function settle(st, opt, now)
    local d = data()
    local key = opt or mems
    local mem = mems[key]
    if not mem then
        mem = {}
        mems[key] = mem
    end
    if mem.fight ~= st.fight then mem.fight, mem.v, mem.since = st.fight, nil, nil end
    local prev = mem.v
    if prev == "burn" and st.verdict == "save" then
        mem.since = mem.since or now
        if now - mem.since < (d.hold - 1) * d.step then st.verdict, st.why = "burn", "hold" end
    else
        mem.since = nil
    end
    if prev == "save" and st.why == "enough" and st.have < st.need + 2 * d.margin then
        st.verdict, st.why = "save", "band"
    end
    if st.verdict ~= "burn" then mem.since = nil end
    mem.v = st.verdict
end
local function sample(st, now)
    local d = data()
    if st.ap or st.hero or st.channel then
        rates.busy = now
        return
    end
    if not (st.fight and st.verdict == "burn" and st.stacks >= d.stackMin) then return end
    if now - rates.busy < ns.widgetData.mana.window then return end
    if now - rates.at < d.step then return end
    local left = ns.Mana.Left(now)
    if not (left and left > 0 and st.cur > 0) then return end
    local list = rates.samples
    list[#list + 1] = st.cur / left
    while #list > d.samples do table.remove(list, 1) end
    rates.at = now
end
local function rateOf(cur)
    local list = rates.samples
    if #list > 0 then
        local sum = 0
        for _, r in ipairs(list) do sum = sum + r end
        return sum / #list, true
    end
    local left = ns.Mana.Left()
    if left and left > 0 and cur > 0 then return cur / left, false end
    return nil, false
end
local function gemOf(opt)
    if opt and opt.gem == "off" then return 0 end
    local d = data()
    for _, id in ipairs(d.gems) do
        if (GetItemCount(id) or 0) > 0 then
            return ns.WTile.Left(d.gcd, GetItemCooldown(id)) > 0 and 0 or d.gemMana
        end
    end
    return 0
end
local function bossOf(opt)
    if opt and opt.exec == "off" then return nil end
    if not ns.TDebuff.Enemy("boss") then return nil end
    local max = UnitHealthMax("target") or 0
    if max <= 0 then return nil end
    return (UnitHealth("target") or 0) / max
end
local function lowOf(opt)
    local d = data()
    return (opt and opt.low and d.low[opt.low]) or d.evokeAt
end
local function state(opt)
    local d = data()
    ns.Mana.Start()
    local now = GetTime()
    local cur, max = UnitPower("player", MANA) or 0, UnitPowerMax("player", MANA) or 0
    local st = {
        cur = cur, max = max, pct = max > 0 and cur / max or 0, low = lowOf(opt), cd = 0, cdDur = 0,
        ready = false, channel = false, stacks = 0, gem = gemOf(opt), gemOff = (opt and opt.gem == "off") and true or false,
        fight = UnitAffectingCombat("player") and true or false, ap = buffOn(d.ap), hero = false, execute = false,
    }
    names(st)
    for _, id in ipairs(d.hero) do
        if buffOn(id) then st.hero = true end
    end
    local sname = GetSpellInfo(d.stack)
    if sname then
        local found, _, _, count = UnitDebuff("player", sname)
        if found then st.stacks = math.max(1, tonumber(count) or 0) end
    end
    if st.evoc then
        st.channel = UnitChannelInfo("player") == st.evoc
        local start, dur = GetSpellCooldown(st.evoc)
        st.cd = ns.WTile.Left(d.gcd, start, dur)
        if st.cd > 0 then st.cdStart, st.cdDur = start, dur end
    end
    st.ready = st.cd <= 0 and not st.channel
    st.need = st.cd
    st.rate, st.measured = rateOf(cur)
    st.have = st.rate and (cur + st.gem) / st.rate or nil
    st.boss = bossOf(opt)
    st.execute = st.boss ~= nil and st.boss < d.execute
    judge(st)
    settle(st, opt, now)
    sample(st, now)
    return st
end
local function fontSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, math.max(8, math.floor(px + 0.5)), (flags and flags ~= "") and flags or "OUTLINE") end
end
local function build(layer, view)
    local d = data()
    local s, gap = layer.h, layer.gap or 2
    layer.look, layer.elook = {}, {}
    if view == "bar" then
        local bw = 2 * s + gap
        layer.bar = ns.Gauge.New(layer, "bar", { w = bw - 2, h = s - 2, max = 100, color = ns.STATE.ok, bg = d.track,
            flash = false })
        layer.bar:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", 1, -1)
        local top = CreateFrame("Frame", nil, layer.bar:Frame())
        top:SetAllPoints(layer.bar:Frame())
        layer.word = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        layer.word:SetPoint("LEFT", layer.bar:Frame(), "LEFT", PAD, 0)
        fontSize(layer.word, s * FONT)
        layer.pct = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        layer.pct:SetPoint("RIGHT", layer.bar:Frame(), "RIGHT", -PAD, 0)
        fontSize(layer.pct, s * FONT)
        layer.etile = ns.WTile.New(layer, 2 * (s + gap), 0, s)
        return
    end
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    if view == "wide" then layer.etile = ns.WTile.New(layer, s + gap, 0, s) end
end
local TONE = { burn = "ok", save = "soon", evoke = "bad" }
local function signed(spare)
    if not spare then return "" end
    local a = math.abs(spare)
    local sign = spare >= 0 and "+" or "-"
    if a < 100 then return sign .. math.floor(a + 0.5) end
    return sign .. ns.T("time.minutes", math.floor(a / 60 + 0.5))
end
local function iconOf(st)
    if st.verdict == "evoke" then return st.evocIcon end
    if st.verdict == "save" then return st.missIcon end
    return st.blastIcon
end
local function paintEvoc(layer, st, glow)
    local S = ns.STATE
    local d = data()
    local k = layer.elook
    local off = st.cd > 0 and not st.channel
    k.icon = st.evocIcon
    k.grey = off
    k.alpha = off and d.dim or 1
    k.text = off and ns.Widget.Left(st.cd) or ""
    k.edge = st.verdict == "evoke" and S.bad or nil
    k.glow = glow
    ns.WTile.Paint(layer.etile, k)
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local tone = S[TONE[st.verdict]] or S.text
    local glow = st.verdict == "evoke" and not st.channel
    if view == "bar" then
        W.Text(layer.word, ns.T("widget.mab_" .. st.verdict))
        W.Color(layer.word, S.text)
        W.Text(layer.pct, math.floor(st.pct * 100 + 0.5) .. "%")
        W.Color(layer.pct, S.text)
        layer.bar:SetColor(tone[1], tone[2], tone[3], tone[4])
        layer.bar:Set(math.floor(st.pct * 100 + 0.5))
        local m = (st.rate and st.need > 0 and st.max > 0) and math.floor(st.rate * st.need * 100 / st.max + 0.5) or 0
        if m <= 0 or m >= 100 then m = 0 end
        if layer.markV ~= m then
            layer.markV = m
            layer.bar:SetTicks(m > 0 and { m } or NO_MARK)
        end
        paintEvoc(layer, st, glow)
        return
    end
    local k = layer.look
    k.icon = iconOf(st)
    k.edge = tone
    k.glow = view == "one" and glow
    k.corner = signed(st.spare)
    k.cornerColor = (st.spare and st.spare < 0) and S.soon or S.text
    ns.WTile.Paint(layer.tile, k)
    if view == "wide" then paintEvoc(layer, st, glow) end
end
local function evocAttrs(st)
    if not st.evoc then return {} end
    return { type = "spell", spell = st.evoc }
end
local CELLS = {
    one = { { cx = 0, cy = 0 } },
    wide = { { cx = 0, cy = 0 }, { cx = 1, cy = 0, attrs = evocAttrs } },
    bar = { { cx = 0, cy = 0 }, { cx = 1, cy = 0 }, { cx = 2, cy = 0, attrs = evocAttrs } },
}
local function thousands(n)
    local s = tostring(math.floor(n + 0.5))
    local out = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
    return (out:gsub("^ ", ""))
end
local function tip(i, st, view)
    local cells = CELLS[view] or CELLS.one
    if view ~= "one" and i == #cells then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local rows = {}
    rows[#rows + 1] = { l = ns.T("widget.mab_mana"), r = math.floor(st.pct * 100 + 0.5) .. "%  " .. thousands(st.cur) }
    local rate
    if not st.rate then
        rate = ns.T("widget.mab_rate_none")
    else
        rate = ns.T(st.measured and "widget.mab_rate_n" or "widget.mab_rate_now", thousands(st.rate))
    end
    rows[#rows + 1] = { l = ns.T("widget.mab_rate"), r = rate, rc = (not st.rate) and S.mute or nil }
    if st.have then
        local r = W.Left(st.have)
        if st.gem > 0 then r = ns.T("widget.mab_with_gem", r) end
        rows[#rows + 1] = { l = ns.T("widget.mab_have"), r = r, rc = (st.spare and st.spare < 0) and S.soon or nil }
    end
    local ev
    if st.channel then
        ev = ns.T("widget.mab_evoc_on")
    elseif st.ready then
        ev = ns.T("widget.mab_evoc_ready")
    else
        ev = ns.T("widget.mab_evoc_in", W.Left(st.cd))
    end
    rows[#rows + 1] = { l = st.evoc or "", r = ev, rc = st.ready and S.ok or nil }
    if st.ap then rows[#rows + 1] = { l = GetSpellInfo(data().ap) or "", r = ns.T("widget.mab_on"), rc = S.ok } end
    if st.hero then rows[#rows + 1] = { l = ns.T("widget.mab_hero"), r = ns.T("widget.mab_on"), rc = S.ok } end
    if st.boss then
        rows[#rows + 1] = { l = ns.T("widget.mab_boss"), r = math.floor(st.boss * 100 + 0.5) .. "%", rc = st.execute and S.ok or nil }
    end
    local tone = S[TONE[st.verdict]] or S.text
    rows[#rows + 1] = { l = ns.T("widget.mab_do_" .. st.verdict), lc = tone }
    return ns.T("widget.mab_" .. st.verdict), nil, rows
end
local DEMO = { solo = { 0.95, nil, 0, false, 0 }, party = { 0.42, 1000, 70, false, 4 }, raid = { 0.18, 1000, 0, false, 2 } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local max = 30000
    local st = {
        cur = math.floor(max * p[1]), max = max, pct = p[1], low = lowOf(scene.opt), cd = p[3], cdDur = 0,
        ready = p[3] <= 0, channel = false, ap = p[4], hero = false, stacks = p[5], gem = 0,
        gemOff = false, rate = p[2], measured = p[2] ~= nil, need = p[3], execute = false,
        fight = scene.fight and true or false,
    }
    names(st)
    if p[3] > 0 then
        st.cdDur = 120
        st.cdStart = GetTime() - (st.cdDur - p[3])
    end
    st.have = st.rate and st.cur / st.rate or nil
    judge(st)
    return st
end
ns.Widget.Register(KEY, {
    info = { text = "widget.mage_arcane_burn_info", demo = demo, fight = true },
    icon = 12051,
    label = "widget.mage_arcane_burn",
    class = "MAGE",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 }, bar = { w = 3, h = 1 } },
    order = { "one", "wide", "bar" },
    view = "one",
    avail = avail,
    events = {
        UNIT_MANA = "player", UNIT_MAXMANA = "player", UNIT_AURA = "player", UNIT_SPELLCAST_CHANNEL_START = "player",
        UNIT_SPELLCAST_CHANNEL_STOP = "player", SPELL_UPDATE_COOLDOWN = true, BAG_UPDATE = true,
        BAG_UPDATE_COOLDOWN = true, PLAYER_TARGET_CHANGED = true, PLAYER_REGEN_DISABLED = true,
        PLAYER_REGEN_ENABLED = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true,
        ACTIVE_TALENT_GROUP_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return st.fight and data().step or nil end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st, opt)
        if opt and opt.show == "always" then return true end
        return st.fight
    end,
    cells = function(view) return CELLS[view] or CELLS.one end,
    Tip = tip,
    opts = {
        { key = "show", label = "widget.mab_show", values = {
            { v = nil, label = "widget.mab_fight" }, { v = "always", label = "widget.mab_always" },
        } },
        { key = "low", label = "widget.mab_low", values = {
            { v = "15", label = "widget.mab_p15" }, { v = nil, label = "widget.mab_p25" }, { v = "35", label = "widget.mab_p35" },
        } },
        { key = "gem", label = "widget.mab_gem", values = {
            { v = nil, label = "widget.mab_yes" }, { v = "off", label = "widget.mab_no" },
        } },
        { key = "exec", label = "widget.mab_exec", values = {
            { v = nil, label = "widget.mab_yes" }, { v = "off", label = "widget.mab_no" },
        } },
    },
})
ns.mageArcaneBurnWidgetLoaded = true
