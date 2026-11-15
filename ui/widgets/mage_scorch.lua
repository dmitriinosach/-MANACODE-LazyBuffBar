local _, ns = ...
local NAME_PAD = 3
local function data()
    return ns.widgetData.mage_scorch
end
local function avail()
    if ns.PlayerClass() ~= "MAGE" then return false end
    return ns.IsLearned(data().talent)
end
local function state(opt)
    local d = data()
    local T = ns.TDebuff
    local name, _, icon = GetSpellInfo(d.scorch)
    local st = { spell = name, icon = icon, rows = {}, left = 0, mine = false, why = "idle", verdict = "off" }
    st.fight = UnitAffectingCombat("player") and true or false
    st.always = (opt and opt.show == "always") and true or false
    local warn = tonumber(opt and opt.warn) or d.warn
    local when = "boss"
    if opt and opt.boss == "any" then when = nil end
    if not T.Enemy(when) then return st end
    local now = GetTime()
    for _, e in ipairs(ns.widgetData.tdebuff.cats[d.cat].list) do
        local n = T.Name(e.id)
        local found, count, expires, caster
        if n then found, _, _, count, _, _, expires, caster = UnitAura("target", n, nil, "HARMFUL") end
        expires = tonumber(expires) or 0
        local row = { id = e.id, name = n, on = found and true or false, count = tonumber(count) or 0, caster = caster }
        if found and expires > 0 then row.left = math.max(0, expires - now) end
        st.rows[#st.rows + 1] = row
        if row.on then
            if e.id == d.imp then
                st.imp = row
            elseif e.id ~= d.chill or row.count >= d.chillMax then
                st.cover = st.cover or row
            end
        end
    end
    local imp = st.imp
    if imp then
        st.left = imp.left or 0
        st.mine = imp.caster == "player"
        if imp.caster then
            st.who = UnitName(imp.caster)
            local _, c = UnitClass(imp.caster)
            st.whoClass = c
        end
    end
    if imp and (not imp.left or imp.left >= warn) then
        st.why, st.verdict = "ok", "ok"
    elseif st.cover then
        st.why, st.verdict = "other", "off"
    elseif imp then
        st.why, st.verdict = "soon", "soon"
    else
        st.why, st.verdict = "none", "none"
    end
    return st
end
local function build(layer, view)
    local s = layer.h
    layer.tile = ns.WTile.New(layer, 0, 0, s)
    layer.look = {}
    if view ~= "wide" then return end
    local gap = layer.gap or 2
    local bg = layer:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetPoint("TOPLEFT", layer, "TOPLEFT", s + gap, 0)
    bg:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0.35)
    layer.who = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    layer.who:SetPoint("TOPLEFT", bg, "TOPLEFT", NAME_PAD, -NAME_PAD)
    layer.who:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -NAME_PAD, -NAME_PAD)
    layer.who:SetJustifyH("LEFT")
    layer.sub = layer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    layer.sub:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", NAME_PAD, NAME_PAD)
    layer.sub:SetJustifyH("LEFT")
end
local VERDICT_TIP = { none = "widget.mgs_tip_none", soon = "widget.mgs_tip_soon", ok = "widget.mgs_tip_ok" }
local function edgeOf(why)
    local S = ns.STATE
    if why == "none" then return S.none end
    if why == "soon" then return S.soon end
    if why == "ok" then return S.ok end
    return nil
end
local function whoText(st)
    if st.why == "none" then return ns.T("widget.mgs_need") end
    if st.why == "other" then return st.cover and st.cover.name or "" end
    if st.why == "soon" or st.why == "ok" then return st.mine and ns.T("widget.mgs_mine") or (st.who or "") end
    return ""
end
local function paint(layer, st, view)
    local S = ns.STATE
    local W = ns.Widget
    local why = st.why
    local timed = why == "soon" or why == "ok"
    local k = layer.look
    k.icon = st.icon
    k.grey = why == "other"
    k.alpha = (why == "other" or why == "idle") and data().dim or 1
    k.edge = edgeOf(why)
    k.text = (view ~= "wide" and timed) and W.Left(st.left) or ((view ~= "wide" and why == "none" and st.fight) and "!" or "")
    k.textColor = (why == "none" and S.none) or (why == "soon" and S.soon) or S.text
    k.glow = why == "none" and st.fight
    ns.WTile.Paint(layer.tile, k)
    if view ~= "wide" then return end
    W.Text(layer.who, whoText(st))
    local c = S.text
    if why == "none" then
        c = S.none
    elseif why == "other" then
        c = S.mute
    elseif timed and not st.mine then
        c = ns.WTile.ClassColor(st.whoClass)
    end
    W.Color(layer.who, c)
    W.Text(layer.sub, timed and W.Left(st.left) or "")
    W.Color(layer.sub, why == "soon" and S.soon or S.text)
end
local CELLS = {
    { l = 0, t = 0, r = 1, b = 1, attrs = function(st)
        if not st.spell then return {} end
        return { type = "spell", spell = st.spell }
    end },
}
local function tip(_, st)
    if st.why == "idle" then return nil end
    local S = ns.STATE
    local W = ns.Widget
    local rows = {}
    for _, r in ipairs(st.rows) do
        if r.name then
            if r.on then
                local who = r.caster and UnitName(r.caster) or nil
                local right = r.left and W.Left(r.left) or ""
                if r.id == data().chill then right = ns.T("widget.td_stacks", r.count, data().chillMax) .. "  " .. right end
                rows[#rows + 1] = { l = who and ns.T("widget.td_by", r.name, who) or r.name, r = right, rc = S.ok }
            else
                rows[#rows + 1] = { l = r.name, r = ns.T("widget.td_none"), lc = S.mute }
            end
        end
    end
    local why = st.why
    if why == "other" then
        rows[#rows + 1] = { l = ns.T("widget.mgs_closed", st.cover and st.cover.name or ""), lc = S.mute }
    else
        rows[#rows + 1] = { l = ns.T(VERDICT_TIP[why]), lc = edgeOf(why) }
    end
    return GetSpellInfo(data().imp), nil, rows
end
local DEMO = { solo = { "none", 0 }, party = { "soon", 3 }, raid = { "other", 0, "WARLOCK", 17800 } }
local function demo(scene)
    local d = data()
    local p = DEMO[scene.size] or DEMO.raid
    local name, _, icon = GetSpellInfo(d.scorch)
    local st = { spell = name, icon = icon, rows = {}, left = p[2], mine = p[1] == "soon", why = p[1], fight = true }
    st.always = (scene.opt and scene.opt.show == "always") and true or false
    st.verdict = (p[1] == "other" and "off") or p[1]
    if p[4] then
        st.cover = { id = p[4], name = GetSpellInfo(p[4]), on = true, count = 0 }
        st.who, st.whoClass = ns.T("widget.bless_demo_name", 3), p[3]
    end
    return st
end
ns.Widget.Register("mage_scorch", {
    info = { text = "widget.mage_scorch_info", demo = demo },
    icon = 42859,
    label = "widget.mage_scorch",
    class = "MAGE",
    views = { one = { w = 1, h = 1 }, wide = { w = 2, h = 1 } },
    order = { "one", "wide" },
    view = "one",
    covers = { "spell:22959" },
    avail = avail,
    events = {
        UNIT_AURA = "target", PLAYER_TARGET_CHANGED = true, PLAYER_REGEN_ENABLED = true, PLAYER_REGEN_DISABLED = true,
        SPELLS_CHANGED = true, PLAYER_TALENT_UPDATE = true, ACTIVE_TALENT_GROUP_CHANGED = true, PLAYER_ENTERING_WORLD = true,
    },
    tick = function(st) return st.imp and data().tick or nil end,
    State = state,
    Build = build,
    Paint = paint,
    active = function(st)
        if st.why == "idle" then return false end
        return st.always or st.why == "none" or st.why == "soon"
    end,
    cells = function() return CELLS end,
    Tip = tip,
    opts = {
        { key = "show", label = "widget.mgs_show", values = {
            { v = nil, label = "widget.mgs_when" }, { v = "always", label = "widget.mgs_always" },
        } },
        { key = "boss", label = "widget.mgs_boss", values = {
            { v = nil, label = "widget.mgs_yes" }, { v = "any", label = "widget.mgs_no" },
        } },
        { key = "warn", label = "widget.mgs_warn", values = function()
            local out = {}
            for _, n in ipairs(data().warns) do
                out[#out + 1] = { v = n ~= data().warn and n or nil, text = ns.T("time.seconds", n) }
            end
            return out
        end },
    },
})
ns.mageScorchWidgetLoaded = true
