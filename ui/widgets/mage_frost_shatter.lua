local _, ns = ...
local function data()
    return ns.widgetData.mage_frost_shatter
end
local function avail()
    if ns.PlayerClass() ~= "MAGE" then return false end
    return ns.IsLearned(data().deep)
end
local function judge(st)
    local d = data()
    if not st.hostile then
        st.verdict = "off"
    elseif st.fingers <= 0 then
        st.verdict = "none"
    elseif st.fLeft > 0 and st.fLeft < d.soon then
        st.verdict = "soon"
    elseif st.ready then
        st.verdict = "full"
    else
        st.verdict = "ok"
    end
    st.go = st.hostile and st.fingers > 0 and st.ready
    st.shatter = st.hostile and st.brain and st.fingers > 0
    if not st.hostile then
        st.bv = "off"
    elseif not st.brain then
        st.bv = "none"
    elseif st.bLeft > 0 and st.bLeft < d.soon then
        st.bv = "soon"
    elseif st.fingers > 0 then
        st.bv = "full"
    else
        st.bv = "ok"
    end
end
local function names(opt, st)
    local d = data()
    local name, _, icon = GetSpellInfo(d.deep)
    st.spell, st.icon = name, icon
    local rName, _, rIcon = GetSpellInfo((opt and opt.bf == "fireball") and d.fireball or d.ffb)
    st.rSpell, st.rIcon = rName, rIcon
end
local function buff(id, now)
    local n = GetSpellInfo(id)
    if not n then return false, 0, 0 end
    local found, _, _, count, _, _, expires = UnitBuff("player", n)
    if not found then return false, 0, 0 end
    expires = tonumber(expires) or 0
    return true, tonumber(count) or 0, expires > 0 and math.max(0, expires - now) or 0
end
local function state(opt)
    local d = data()
    local st = {
        fingers = 0, fLeft = 0, brain = false, bLeft = 0, cd = 0, cdDur = 0, ready = true,
        fight = UnitAffectingCombat("player") and true or false, num = not (opt and opt.num == "off"),
        hostile = ns.TDebuff.Enemy(nil) and true or false, talent = ns.IsLearned(d.talent),
    }
    names(opt, st)
    local now = GetTime()
    local on, count, left = buff(d.fingers, now)
    if on then
        st.fingers = math.min(d.fingersMax, math.max(1, count))
        st.fLeft = left
    end
    if st.talent then st.brain, _, st.bLeft = buff(d.brain, now) end
    if st.spell then
        local start, dur = GetSpellCooldown(st.spell)
        st.cd = ns.WTile.Left(d.gcd, start, dur)
        if st.cd > 0 then st.cdStart, st.cdDur = start, dur end
    end
    st.ready = st.cd <= 0
    judge(st)
    return st
end
local function build(layer, view)
    local d = data()
    local s, gap = layer.h, layer.gap or 2
    layer.look, layer.mlook = {}, {}
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.ringBox = CreateFrame("Frame", nil, layer)
    layer.ringBox:SetPoint("TOPLEFT", layer, "TOPLEFT", 1, -1)
    layer.ringBox:SetWidth(s - 2)
    layer.ringBox:SetHeight(s - 2)
    layer.ringBox:SetFrameLevel(layer:GetFrameLevel() + 1)
    layer.ring = ns.Gauge.New(layer.ringBox, "ring", { w = s - 2, h = s - 2, max = 1, color = d.ring, off = d.ringOff, flash = false })
    layer.ring:Frame():SetAllPoints(layer.ringBox)
    layer.ringBox:SetAlpha(0)
    layer.ringBox.lbbAlpha = 0
    if view == "pair" then layer.mtile = ns.WTile.New(layer, s + gap, 0, s) end
end
local function paintRing(layer, st)
    local g = layer.ring
    if st.cdStart then
        g:Run(st.cdStart, st.cdDur, 1)
    else
        g:Run(nil)
        g:Set(0, 1)
    end
    ns.Widget.Alpha(layer.ringBox, st.cdStart and 1 or 0)
end
local function pulse(layer, key, fs, on)
    if layer[key] == on then return end
    layer[key] = on
    ns.Anim.Pulse(fs, on)
end
local function alphaOf(v)
    local d = data()
    if v == "off" then return d.offDim end
    if v == "none" then return d.dim end
    return 1
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local v = st.verdict
    paintRing(layer, st)
    local soonC = (v == "off" and S.mute) or (v == "soon" and S.soon) or S.text
    local k = layer.look
    k.icon = st.icon
    k.grey = v == "off"
    k.alpha = alphaOf(v)
    k.corner = st.fingers > 0 and tostring(st.fingers) or nil
    k.cornerColor = soonC
    k.mark = (st.num and st.fingers > 0) and W.Left(st.fLeft) or nil
    k.markColor = soonC
    k.edge = (view == "one" and st.brain and st.hostile) and S.ok or nil
    k.glow = st.go
    ns.WTile.Paint(layer.tile, k)
    pulse(layer, "pulsing", layer.tile.corner, v == "soon")
    if view ~= "pair" then return end
    local bv = st.bv
    local m = layer.mlook
    m.icon = st.rIcon
    m.grey = not st.talent or bv == "off"
    m.alpha = st.talent and alphaOf(bv) or 0
    m.edge = (st.talent and (bv == "ok" or bv == "full")) and S.ok or ((st.talent and bv == "soon") and S.soon or nil)
    m.corner = (st.talent and st.num and st.brain) and W.Left(st.bLeft) or nil
    m.cornerColor = (bv == "off" and S.mute) or (bv == "soon" and S.soon) or S.text
    m.glow = st.talent and st.shatter
    ns.WTile.Paint(layer.mtile, m)
    pulse(layer, "mpulsing", layer.mtile.corner, st.talent and bv == "soon")
end
local CELLS = {
    one = {
        { cx = 0, cy = 0, attrs = function(st)
            if not st.spell then return {} end
            return { type = "spell", spell = st.spell }
        end },
    },
}
CELLS.pair = {
    CELLS.one[1],
    { cx = 1, cy = 0, attrs = function(st)
        if not (st.talent and st.rSpell) then return {} end
        return { type = "spell", spell = st.rSpell }
    end },
}
local function tip(i, st, view)
    local d = data()
    local S = ns.STATE
    local W = ns.Widget
    local none = ns.T("widget.mfs_none")
    if view == "pair" and i == 2 then
        local line
        if not st.talent then
            line = ns.T("widget.mfs_notalent")
        else
            line = st.brain and ns.T("widget.mfs_bf_left", W.Left(st.bLeft)) or ns.T("widget.mfs_nobf")
            if st.shatter then line = line .. "\n" .. ns.T("widget.mfs_shatter", st.rSpell or "") end
        end
        return st.rSpell or GetSpellInfo(d.brain), line
    end
    local fc = st.verdict == "soon" and S.soon or nil
    local rows = {
        { l = GetSpellInfo(d.fingers) or "", r = st.fingers > 0 and (st.fingers .. "/" .. d.fingersMax .. "  " .. W.Left(st.fLeft)) or none, rc = fc },
        { l = ns.T("widget.mfs_cd"), r = st.ready and ns.T("widget.mfs_ready") or W.Left(st.cd), rc = st.ready and S.ok or nil },
    }
    if st.talent then
        rows[#rows + 1] = { l = GetSpellInfo(d.brain) or "", r = st.brain and W.Left(st.bLeft) or none, lc = st.brain and S.ok or S.mute }
    end
    if st.go then rows[#rows + 1] = { l = ns.T("widget.mfs_go"), lc = S.full } end
    if st.shatter then rows[#rows + 1] = { l = ns.T("widget.mfs_shatter", st.rSpell or ""), lc = S.ok } end
    if not st.hostile then rows[#rows + 1] = { l = ns.T("widget.mfs_notarget"), lc = S.mute } end
    return st.spell, nil, rows
end
local DEMO = { solo = { false, 0, 0, 0, 0 }, party = { true, 2, 12, 0, 0 }, raid = { true, 1, 2, 9, 12 } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local st = {
        hostile = p[1], fingers = p[2], fLeft = p[3], brain = p[4] > 0, bLeft = p[4], cd = p[5], cdDur = 0,
        ready = p[5] <= 0, talent = true, fight = scene.fight, num = not (scene.opt and scene.opt.num == "off"),
    }
    names(scene.opt, st)
    if p[5] > 0 then
        st.cdDur = d.deepCd
        st.cdStart = GetTime() - (st.cdDur - p[5])
    end
    judge(st)
    return st
end
ns.Widget.Register("mage_frost_shatter", {
    info = { text = "widget.mage_frost_shatter_info", demo = demo },
    icon = 44572,
    label = "widget.mage_frost_shatter",
    class = "MAGE",
    views = { one = { w = 1, h = 1 }, pair = { w = 2, h = 1 } },
    order = { "one", "pair" },
    view = "pair",
    covers = { "spell:44544", "spell:57761", "spell:44572" },
    avail = avail,
    events = {
        UNIT_AURA = "player", SPELL_UPDATE_COOLDOWN = true, PLAYER_TARGET_CHANGED = true, PLAYER_REGEN_ENABLED = true,
        PLAYER_REGEN_DISABLED = true, SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true,
        PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return (st.fingers > 0 or st.brain) and data().tick or nil end,
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
        { key = "show", label = "widget.mfs_show", values = {
            { v = nil, label = "widget.mfs_fight" }, { v = "always", label = "widget.mfs_always" },
        } },
        { key = "bf", label = "widget.mfs_bf", values = {
            { v = nil, label = "widget.mfs_ffb" }, { v = "fireball", label = "widget.mfs_fireball" },
        } },
        { key = "num", label = "widget.mfs_num", values = {
            { v = nil, label = "widget.mfs_yes" }, { v = "off", label = "widget.mfs_no" },
        } },
    },
})
ns.mageFrostShatterWidgetLoaded = true
