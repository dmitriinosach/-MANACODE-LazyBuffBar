local _, ns = ...
local ENH = 2
local function data()
    return ns.widgetData.shaman_enh_magma
end
local function avail()
    local _, class = UnitClass("player")
    if class ~= "SHAMAN" or ns.CurrentTab() ~= ENH then return false end
    for _, id in ipairs(data().totems) do
        if ns.IsLearned(id) then return true end
    end
    return false
end
local function placeOf(opt)
    local want = opt and opt.place
    for _, id in ipairs(data().place) do
        if id == want then return id end
    end
    return data().place[1]
end
local VERDICT = { miss = "bad", gone = "none", soon = "soon" }
local function state(opt)
    local d = data()
    local now = GetTime()
    local st = { up = false, ours = false, left = 0, quiet = 0, ncd = 0, why = "idle" }
    st.anyone = (opt and opt.hit == "any") and true or false
    st.always = (opt and opt.show == "always") and true or false
    st.fight = (InCombatLockdown() or UnitAffectingCombat("player")) and true or false
    st.foe = (UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")) and true or false
    local pid = placeOf(opt)
    st.place, _, st.placeIcon = GetSpellInfo(pid)
    st.learned = ns.IsLearned(pid)
    st.nova, _, st.novaIcon = GetSpellInfo(d.nova)
    st.novaKnown = ns.IsLearned(d.nova)
    if st.nova then st.ncd = ns.WTile.Left(d.gcd, GetSpellCooldown(st.nova)) end
    local _, name, start, dur, icon = GetTotemInfo(1)
    if name and name ~= "" and start and dur and dur > 0 and start + dur > now then
        st.up, st.name, st.icon, st.left = true, name, icon, start + dur - now
        st.ours = ns.EnhMagma.Ours(name, icon)
    end
    if st.up and st.ours and st.fight then ns.EnhMagma.Watch() end
    if not (st.fight and st.foe) then
        st.why = "idle"
    elseif not st.up then
        st.why = st.learned and "gone" or "idle"
    elseif not st.ours then
        st.why = "other"
    else
        local M = ns.EnhMagma
        local guid = not st.anyone and UnitGUID("target") or nil
        local since = M.Since(guid) or now
        local last = st.anyone and M.Any() or M.Hit(guid)
        local base = math.max(start, since, last or 0)
        st.quiet = now - base
        if st.quiet >= d.miss then
            st.why = "miss"
        elseif st.left < d.soon then
            st.why = "soon"
        else
            st.why = "ok"
        end
    end
    st.verdict = VERDICT[st.why] or "ok"
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "nova" then return end
    layer.ring = ns.WTile.New(layer, s + (layer.gap or 2), 0, s)
    layer.ringLook = {}
end
local function hitting(st)
    return st.why == "ok" or st.why == "soon"
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local k = layer.look
    local why = st.why
    k.icon = (st.up and st.icon) or st.placeIcon
    k.grey = why == "gone"
    k.alpha = (why == "gone" and 0.6) or ((why == "ok" or why == "other" or why == "idle") and data().dim) or 1
    k.edge = (why == "miss" and S.bad) or (why == "gone" and S.bad) or (why == "soon" and S.soon) or nil
    k.mark = why == "miss" and ns.T("widget.smag_miss_mark") or nil
    k.markColor = S.bad
    k.text = (st.up and why ~= "miss") and W.Left(st.left) or ""
    k.textColor = why == "soon" and S.soon or S.text
    k.corner = (st.up and why == "miss") and W.Left(st.left) or nil
    ns.WTile.Paint(layer.tile, k)
    if view ~= "nova" then return end
    local r = layer.ringLook
    r.icon = st.novaIcon
    r.grey = (not st.novaKnown) or st.ncd > 0
    r.alpha = (st.novaKnown and (st.ncd > 0 or hitting(st))) and 1 or data().dim
    r.edge = (st.novaKnown and st.ncd <= 0 and hitting(st)) and S.ok or nil
    r.text = (st.novaKnown and st.ncd > 0) and W.Left(st.ncd) or ""
    ns.WTile.Paint(layer.ring, r)
end
local function active(st, opt, view)
    if st.why == "miss" or st.why == "gone" or st.why == "soon" then return true end
    if st.always and st.up then return true end
    return view == "nova" and st.fight and st.foe
end
local function placeAttrs(st)
    if not st.place then return {} end
    return { type = "spell", spell = st.place }
end
local function novaAttrs(st)
    if not st.nova then return {} end
    return { type = "spell", spell = st.nova }
end
local CELLS = {
    one = { { l = 0, t = 0, r = 1, b = 1, attrs = placeAttrs } },
    nova = { { l = 0, t = 0, r = 0.5, b = 1, attrs = placeAttrs }, { l = 0.5, t = 0, r = 1, b = 1, attrs = novaAttrs } },
}
local DEMO = {
    solo  = { "soon", 2, 0, 0 },
    party = { "gone", 0, 0, 0 },
    raid  = { "miss", 13, 6, 4 },
}
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local pname, _, picon = GetSpellInfo(placeOf(scene.opt))
    local nname, _, nicon = GetSpellInfo(d.nova)
    local up = p[2] > 0
    return {
        up = up, ours = up, name = up and pname or nil, icon = up and picon or nil, left = p[2], fight = true, foe = true,
        anyone = false, always = false, place = pname, placeIcon = picon, learned = true, quiet = p[3],
        nova = nname, novaIcon = nicon, novaKnown = true, ncd = p[4], why = p[1], verdict = VERDICT[p[1]] or "ok",
    }
end
local function tipLine(st)
    local W = ns.Widget
    local any = st.anyone and "_any" or ""
    if st.why == "miss" then return ns.T("widget.smag_miss" .. any, st.name, math.floor(st.quiet)) end
    if st.why == "gone" then return ns.T("widget.smag_gone") end
    if st.why == "other" then return ns.T("widget.smag_other", st.name) end
    if st.why == "ok" or st.why == "soon" then return ns.T("widget.smag_hits" .. any, st.name, W.Left(st.left)) end
    return nil
end
local function novaLine(st)
    if st.ncd > 0 then return ns.T("widget.smag_nova_cd", ns.Widget.Left(st.ncd)) end
    if hitting(st) then return ns.T("widget.smag_nova_ready") end
    return ns.T("widget.smag_nova_far")
end
local function placeValues()
    local out = {}
    for i, id in ipairs(data().place) do
        out[i] = { v = i > 1 and id or nil, text = GetSpellInfo(id) or ("#" .. id) }
    end
    return out
end
ns.Widget.Register("shaman_enh_magma", {
    info = { text = "widget.shaman_enh_magma_info", demo = demo },
    icon = 58734,
    label = "widget.shaman_enh_magma",
    class = "SHAMAN",
    views = { one = { w = 1, h = 1 }, nova = { w = 2, h = 1 } },
    order = { "one", "nova" },
    view = "one",
    avail = avail,
    events = {
        PLAYER_TOTEM_UPDATE = true, PLAYER_TARGET_CHANGED = true, PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true,
        SPELLS_CHANGED = true, PLAYER_ENTERING_WORLD = true, SPELL_UPDATE_COOLDOWN = true,
    },
    tick = function(st) return (st.up and (st.fight or st.always)) and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    active = active,
    cells = function(view) return CELLS[view] or CELLS.one end,
    Tip = function(i, st, view)
        if view == "nova" and i == 2 then
            return st.nova or ns.T("widget.shaman_enh_magma"), novaLine(st)
        end
        local rows = {}
        if st.place then rows[1] = { l = ns.T("widget.smag_click", st.place) } end
        return st.name or ns.T("widget.shaman_enh_magma"), tipLine(st), rows
    end,
    opts = {
        { key = "place", label = "widget.smag_place", values = placeValues },
        { key = "hit", label = "widget.smag_hit",
          values = { { v = nil, label = "widget.smag_hit_target" }, { v = "any", label = "widget.smag_hit_any" } } },
        { key = "show", label = "widget.smag_show",
          values = { { v = nil, label = "widget.smag_show_bad" }, { v = "always", label = "widget.smag_show_always" } } },
    },
})
ns.shamanEnhMagmaWidgetLoaded = true
