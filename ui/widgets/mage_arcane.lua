local _, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local PAD = 2
local RUN_PART = 0.14
local SEG_PART = 0.5
local BAR_PART = 0.3
local STAR_PART = 0.45
local function data()
    return ns.widgetData.mage_arcane
end
local function avail()
    if ns.PlayerClass() ~= "MAGE" then return false end
    local d = data()
    if ns.IsLearned(d.blast) then return true end
    for _, id in ipairs(d.alt) do
        if ns.IsLearned(id) then return true end
    end
    return false
end
local function threshold(opt)
    local at = opt and opt.at
    if at == "any" then return 0 end
    return tonumber(at) or data().at
end
local function verdictOf(st)
    local d = data()
    if st.stacks <= 0 then return "none" end
    if st.left > 0 and st.left < d.soon then return "soon" end
    if st.stacks >= d.max then return "full" end
    return "ok"
end
local function state(opt)
    local d = data()
    local st = {
        stacks = 0, left = 0, dur = d.window, proc = false, procLeft = 0, go = false,
        fight = UnitAffectingCombat("player") and true or false, num = not (opt and opt.num == "off"),
    }
    local _, _, icon = GetSpellInfo(d.blast)
    st.icon = icon
    local mname, _, micon = GetSpellInfo(d.missiles)
    st.missiles, st.mIcon = mname, micon
    local now = GetTime()
    local sname = GetSpellInfo(d.stack)
    if sname then
        local found, _, _, count, _, dur, expires = UnitDebuff("player", sname)
        if found then
            st.stacks = math.min(d.max, math.max(1, tonumber(count) or 0))
            dur, expires = tonumber(dur) or 0, tonumber(expires) or 0
            if dur > 0 then st.dur = dur end
            if expires > 0 then
                st.left = math.max(0, expires - now)
                st.start = expires - st.dur
            end
        end
    end
    local pname = GetSpellInfo(d.proc)
    if pname then
        local found, _, _, _, _, _, expires = UnitBuff("player", pname)
        if found then
            st.proc = true
            expires = tonumber(expires) or 0
            st.procLeft = expires > 0 and math.max(0, expires - now) or 0
        end
    end
    st.go = st.proc and st.stacks >= threshold(opt)
    st.verdict = verdictOf(st)
    return st
end
local function buildRun(layer, x, y, w, h)
    local d = data()
    layer.runBox = CreateFrame("Frame", nil, layer)
    layer.runBox:SetPoint("TOPLEFT", layer, "TOPLEFT", x, -y)
    layer.runBox:SetWidth(w)
    layer.runBox:SetHeight(h)
    layer.run = ns.Gauge.New(layer.runBox, "bar", { w = w, h = h, max = 1, color = d.gone, bg = d.left })
    layer.run:Frame():SetAllPoints(layer.runBox)
    layer.runBox:SetAlpha(0)
    layer.runBox.lbbAlpha = 0
end
local function build(layer, view)
    local d = data()
    local s, gap = layer.h, layer.gap or 2
    layer.look, layer.mlook = {}, {}
    if view == "bar" then
        local w = layer.w
        local bg = layer:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(WHITE)
        bg:SetAllPoints(layer)
        bg:SetVertexColor(0, 0, 0, 0.35)
        layer.icon = layer:CreateTexture(nil, "ARTWORK")
        layer.icon:SetPoint("TOPLEFT", layer, "TOPLEFT", PAD, -PAD)
        layer.icon:SetWidth(s - 2 * PAD)
        layer.icon:SetHeight(s - 2 * PAD)
        local x = s + PAD
        local sw = w - x - PAD
        local sh = math.floor(s * SEG_PART)
        layer.segs = ns.Gauge.New(layer, "segments", { w = sw, h = sh, max = d.max, color = d.seg, full = ns.STATE.full })
        layer.segs:Frame():SetPoint("TOPLEFT", layer, "TOPLEFT", x, -PAD)
        local bh = math.max(3, math.floor(s * BAR_PART))
        buildRun(layer, x, s - PAD - bh, sw, bh)
        local top = CreateFrame("Frame", nil, layer)
        top:SetAllPoints(layer)
        top:SetFrameLevel(layer.runBox:GetFrameLevel() + 2)
        layer.star = top:CreateTexture(nil, "OVERLAY")
        layer.star:SetTexture(d.star)
        layer.star:SetWidth(math.floor(s * STAR_PART))
        layer.star:SetHeight(math.floor(s * STAR_PART))
        layer.star:SetPoint("TOPRIGHT", layer, "TOPRIGHT", -1, -1)
        layer.star:SetAlpha(0)
        layer.star.lbbAlpha = 0
        layer.text = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        layer.text:SetPoint("RIGHT", layer.runBox, "RIGHT", -1, 0)
        return
    end
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    buildRun(layer, 1, 1, s - 2, math.max(3, math.floor(s * RUN_PART)))
    layer.runBox:SetFrameLevel(layer:GetFrameLevel() + 1)
    if view == "pair" then layer.mtile = ns.WTile.New(layer, s + gap, 0, s) end
end
local function paintRun(layer, st)
    local g = layer.run
    if st.stacks > 0 and st.start then
        g:Run(st.start, st.dur, 1)
    else
        g:Run(nil)
        g:Set(0, 1)
    end
    ns.Widget.Alpha(layer.runBox, st.stacks > 0 and 1 or 0)
    local soon = st.verdict == "soon"
    if layer.pulsing ~= soon then
        layer.pulsing = soon
        ns.Anim.Pulse(g:Frame(), soon)
    end
end
local function stackColor(st)
    local S = ns.STATE
    if st.verdict == "soon" then return S.soon end
    if st.verdict == "full" then return S.full end
    return S.text
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local d = data()
    local on = st.stacks > 0
    paintRun(layer, st)
    if view == "bar" then
        W.Tex(layer.icon, st.icon or ns.QMARK, false)
        W.Alpha(layer.icon, on and 1 or d.dim)
        local c = st.verdict == "soon" and S.soon or d.seg
        layer.segs:SetColor(c[1], c[2], c[3], c[4])
        layer.segs:Set(st.stacks, d.max)
        W.Alpha(layer.star, st.proc and (st.go and 1 or 0.5) or 0)
        W.Text(layer.text, (st.num and on) and W.Left(st.left) or "")
        W.Color(layer.text, st.verdict == "soon" and S.soon or S.text)
        return
    end
    local k = layer.look
    k.icon = st.icon
    k.alpha = on and 1 or d.dim
    k.text = on and tostring(st.stacks) or ""
    k.textColor = stackColor(st)
    k.corner = (st.num and on) and W.Left(st.left) or nil
    k.cornerColor = st.verdict == "soon" and S.soon or S.text
    k.edge = (view == "one" and st.proc) and S.ok or nil
    k.glow = view == "one" and st.go
    ns.WTile.Paint(layer.tile, k)
    if view ~= "pair" then return end
    local m = layer.mlook
    m.icon = st.mIcon
    m.grey = not st.proc
    m.alpha = st.proc and 1 or d.dim
    m.edge = st.proc and S.ok or nil
    m.corner = (st.proc and st.num) and W.Left(st.procLeft) or nil
    m.glow = st.go
    ns.WTile.Paint(layer.mtile, m)
end
local CELLS = {
    one = { { cx = 0, cy = 0 } },
    pair = {
        { cx = 0, cy = 0 },
        { cx = 1, cy = 0, attrs = function(st)
            if not st.missiles then return {} end
            return { type = "spell", spell = st.missiles }
        end },
    },
    bar = { { l = 0, t = 0, r = 1, b = 1 } },
}
local function tip(i, st, view)
    local d = data()
    local S = ns.STATE
    local W = ns.Widget
    local pname = GetSpellInfo(d.proc)
    if view == "pair" and i == 2 then
        local line = st.proc and ns.T("widget.mga_proc_left", W.Left(st.procLeft)) or ns.T("widget.mga_noproc")
        if st.go then line = line .. "\n" .. ns.T("widget.mga_go") end
        return st.missiles or pname, line
    end
    local rows = {
        { l = ns.T("widget.mga_stacks"), r = st.stacks .. "/" .. d.max, rc = stackColor(st) },
        { l = ns.T("widget.mga_window"), r = st.stacks > 0 and W.Left(st.left) or ns.T("widget.mga_none"),
          rc = st.verdict == "soon" and S.soon or nil },
    }
    if pname then
        rows[#rows + 1] = { l = pname, r = st.proc and W.Left(st.procLeft) or ns.T("widget.mga_none"), lc = st.proc and S.ok or S.mute }
    end
    if st.go then rows[#rows + 1] = { l = ns.T("widget.mga_go"), lc = S.ok } end
    return GetSpellInfo(d.stack), nil, rows
end
local DEMO = { solo = { 0, 0, 0 }, party = { 3, 4, 0 }, raid = { 4, 1.5, 9 } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local _, _, icon = GetSpellInfo(d.blast)
    local mname, _, micon = GetSpellInfo(d.missiles)
    local st = {
        icon = icon, mIcon = micon, missiles = mname, stacks = p[1], left = p[2], dur = d.window,
        proc = p[3] > 0, procLeft = p[3], fight = scene.fight, num = not (scene.opt and scene.opt.num == "off"),
    }
    if st.stacks > 0 then st.start = GetTime() - (d.window - st.left) end
    st.go = st.proc and st.stacks >= threshold(scene.opt)
    st.verdict = verdictOf(st)
    return st
end
ns.Widget.Register("mage_arcane", {
    info = { text = "widget.mage_arcane_info", demo = demo },
    icon = 42897,
    label = "widget.mage_arcane",
    class = "MAGE",
    views = { one = { w = 1, h = 1 }, pair = { w = 2, h = 1 }, bar = { w = 3, h = 1 } },
    order = { "one", "pair", "bar" },
    view = "pair",
    covers = { "spell:36032", "spell:44401" },
    avail = avail,
    events = {
        UNIT_AURA = "player", PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true, SPELLS_CHANGED = true,
        PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return (st.stacks > 0 or st.proc) and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st, opt)
        if opt and opt.show == "fight" then return st.fight end
        return true
    end,
    cells = function(view) return CELLS[view] or CELLS.one end,
    Tip = tip,
    opts = {
        { key = "at", label = "widget.mga_at", values = {
            { v = 3, label = "widget.mga_at3" }, { v = nil, label = "widget.mga_at4" }, { v = "any", label = "widget.mga_any" },
        } },
        { key = "show", label = "widget.mga_show", values = {
            { v = nil, label = "widget.mga_always" }, { v = "fight", label = "widget.mga_fight" },
        } },
        { key = "num", label = "widget.mga_num", values = {
            { v = nil, label = "widget.mga_yes" }, { v = "off", label = "widget.mga_no" },
        } },
    },
})
ns.mageArcaneWidgetLoaded = true
