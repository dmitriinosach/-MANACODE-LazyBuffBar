local _, ns = ...
ns.Hit = {}
local H = ns.Hit
local function data()
    return ns.widgetData.hit
end
local ranks
local presence
function H.Kind(opt)
    local pick = opt and opt.kind
    if pick == "spell" or pick == "melee" or pick == "ranged" then return pick, false end
    local class = ns.PlayerClass()
    local info = ns.SpecInfo(class, ns.CurrentVariant())
    if info and info.nature == "caster" then return "spell", info.role == "heal" end
    if class == "HUNTER" then return "ranged", false end
    return "melee", false
end
local function readRanks()
    if ranks then return ranks end
    ranks = {}
    local group = ns.ActiveSlot()
    for _, t in ipairs(data().talents[ns.PlayerClass()] or {}) do
        local name = GetSpellInfo(t.id)
        local row = { t = t, name = name, rank = 0, max = t.max }
        for i = 1, (name and GetNumTalents and GetNumTalents(t.tab)) or 0 do
            local n, _, _, _, r, m = GetTalentInfo(t.tab, i, false, false, group)
            if n == name then
                row.rank, row.max = tonumber(r) or 0, tonumber(m) or t.max
                break
            end
        end
        ranks[#ranks + 1] = row
    end
    return ranks
end
local function works(row)
    local c = row.t.cond
    if c == "dual" then return (OffhandHasWeapon and OffhandHasWeapon()) and true or false end
    if c == "tree" then return ns.CurrentTab() == row.t.tab end
    return true
end
local function talentPct(row, kind)
    if not row.t.kinds[kind] or row.rank <= 0 or not works(row) then return 0 end
    return row.rank * row.t.per
end
local function presenceName()
    if presence == nil then
        presence = false
        for _, id in ipairs(data().presence) do
            local n = GetSpellInfo(id)
            if n then
                presence = n
                break
            end
        end
    end
    return presence or nil
end
local function presenceOn()
    local d = data()
    if UnitFactionGroup("player") ~= d.faction then return false, false end
    local _, race = UnitRace("player")
    if race == d.race then return true, true end
    local name = presenceName()
    return true, (name and UnitAura("player", name, nil, "HELPFUL")) and true or false
end
function H.State(opt)
    local d = data()
    local kind, heal = H.Kind(opt)
    local cr = d.cr[kind]
    local st = {
        kind = kind, heal = heal,
        rating = tonumber(GetCombatRating(cr)) or 0,
        gear = tonumber(GetCombatRatingBonus(cr)) or 0,
        tal = 0, aura = 0, tgt = 0, cap = d.caps[kind], verdict = "ok",
    }
    for _, row in ipairs(readRanks()) do st.tal = st.tal + talentPct(row, kind) end
    local _, on = presenceOn()
    if on then st.aura = d.presencePct end
    if kind == "spell" and ns.TDebuff.Enemy() then st.tgt = ns.TDebuff.Cat("spellhit").pct end
    st.total = st.gear + st.tal + st.aura + st.tgt
    st.delta = st.total - st.cap
    st.per = (st.rating > 0 and st.gear > 0) and (st.rating / st.gear) or d.per[kind]
    if heal then
        st.verdict = "off"
    elseif st.delta < -d.eps then
        st.verdict = "bad"
    elseif st.delta > d.over then
        st.verdict = "soon"
    end
    return st
end
function H.Num(x)
    return (string.format("%.1f", math.floor(x * 10 + 1e-6) / 10):gsub("%.", ns.T("widget.h_dec")))
end
local function plus(x)
    if x == math.floor(x) then return string.format("+%d%%", x) end
    return "+" .. H.Num(x) .. "%"
end
function H.Sub(st)
    if st.verdict == "off" then return nil end
    if st.verdict == "ok" then return ns.T("widget.h_cap") end
    return (st.delta > 0 and "+" or "-") .. H.Num(math.max(0.1, math.abs(st.delta)))
end
function H.Rows(st)
    local S = ns.STATE
    local rows = { { l = ns.T("widget.h_rating", st.rating), r = "+" .. H.Num(st.gear) .. "%" } }
    for _, row in ipairs(readRanks()) do
        if row.name and row.t.kinds[st.kind] then
            local p = talentPct(row, st.kind)
            local l = ns.T("widget.h_talent", row.name, row.rank, row.max)
            if p > 0 then
                rows[#rows + 1] = { l = l, r = plus(p) }
            else
                rows[#rows + 1] = { l = l, r = ns.T(row.rank > 0 and "widget.h_idle" or "widget.td_none"), lc = S.mute }
            end
        end
    end
    local can = presenceOn()
    if can and presenceName() then
        if st.aura > 0 then
            rows[#rows + 1] = { l = presenceName(), r = plus(st.aura) }
        else
            rows[#rows + 1] = { l = presenceName(), r = ns.T("widget.td_none"), lc = S.mute }
        end
    end
    if st.kind == "spell" then
        local hit = ns.TDebuff.Enemy() and ns.TDebuff.Cat("spellhit") or nil
        if hit and hit.on then
            rows[#rows + 1] = { l = ns.T("widget.h_target", hit.name), r = plus(hit.pct) }
        else
            local cat = ns.widgetData.tdebuff.cats.spellhit
            local list = {}
            for _, e in ipairs(cat.list) do list[#list + 1] = ns.TDebuff.Name(e.id) end
            rows[#rows + 1] = { l = ns.T("widget.h_target", table.concat(list, ", ")), r = ns.T("widget.td_none"), lc = S.mute }
            rows[#rows + 1] = { l = ns.T("widget.h_with"), r = H.Num(st.total + cat.full) .. "%", lc = S.mute }
        end
    end
    local ink = S[st.verdict] or S.text
    rows[#rows + 1] = { l = ns.T("widget.h_total"), r = ns.T("widget.h_of", H.Num(st.total), st.cap), rc = ink }
    if st.verdict == "bad" then
        rows[#rows + 1] = { l = ns.T("widget.h_need", H.Num(-st.delta), math.ceil(-st.delta * st.per - 1e-6)), lc = ink }
    elseif st.verdict == "soon" then
        rows[#rows + 1] = { l = ns.T("widget.h_spare", H.Num(st.delta), math.floor(st.delta * st.per + 1e-6)), lc = ink }
    elseif st.verdict == "ok" then
        rows[#rows + 1] = { l = ns.T("widget.h_done"), lc = ink }
    else
        rows[#rows + 1] = { l = ns.T("widget.h_heal"), lc = S.mute }
    end
    return rows
end
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_TALENT_UPDATE")
ev:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
ev:RegisterEvent("CHARACTER_POINTS_CHANGED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function()
    ranks = nil
    if ns.Widget and ns.Widget.Poke then
        ns.Widget.Poke("hit")
        ns.Widget.Poke("tdebuff")
    end
end)
ns.hitLoaded = true
