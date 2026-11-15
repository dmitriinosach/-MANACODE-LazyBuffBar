local _, ns = ...
ns.TDebuff = {}
local T = ns.TDebuff
local function data()
    return ns.widgetData.tdebuff
end
local names = {}
function T.Name(id)
    local n = names[id]
    if n == nil then
        n = GetSpellInfo(id) or false
        names[id] = n
    end
    if not n then return nil end
    return n, (select(3, GetSpellInfo(id)))
end
local function isBoss(unit)
    local c = UnitClassification and UnitClassification(unit)
    if c == "worldboss" then return true end
    return (c == "elite" or c == "rareelite") and UnitLevel(unit) == -1
end
function T.Enemy(when)
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return false end
    if UnitIsDeadOrGhost("target") then return false end
    return when ~= "boss" or isBoss("target")
end
local function power(e, count)
    if not e.per then return e.pct or 0 end
    local n = math.min(e.max or 1, math.max(1, count))
    return e.per * n
end
function T.Cat(cat)
    local c = data().cats[cat]
    local hit = { cat = cat, on = false, count = 0, pct = 0, full = c and c.full or 0 }
    if not c then return hit end
    local now = GetTime()
    for _, e in ipairs(c.list) do
        local name = T.Name(e.id)
        if name then
            local found, _, icon, count, _, _, expires, caster = UnitAura("target", name, nil, "HARMFUL")
            if found then
                count = tonumber(count) or 0
                local p = power(e, count)
                if p > hit.pct or not hit.on then
                    hit.on, hit.id, hit.name, hit.icon = true, e.id, found, icon
                    hit.count, hit.max, hit.pct, hit.caster = count, e.max, p, caster
                    expires = tonumber(expires) or 0
                    hit.left = expires > 0 and math.max(0, expires - now) or nil
                end
            end
        end
    end
    return hit
end
function T.SetName(opt)
    local pick = opt and opt.set
    if pick == "phys" or pick == "caster" then return pick end
    return ns.Hit.Kind() == "spell" and "caster" or "phys"
end
function T.Set(opt)
    return data().sets[T.SetName(opt)]
end
function T.State(cats, opt)
    local st = { idle = not T.Enemy(opt and opt.when), cats = {}, n = 0, verdict = "none" }
    if st.idle then return st end
    for i, cat in ipairs(cats) do
        local hit = T.Cat(cat)
        st.cats[i] = hit
        if hit.on then
            st.n = st.n + 1
            if hit.left and (not st.left or hit.left < st.left) then st.left = hit.left end
        end
    end
    if st.n >= #cats and st.n > 0 then
        st.verdict = "ok"
    elseif st.n > 0 then
        st.verdict = "soon"
    end
    return st
end
function T.Caster(hit)
    if not (hit.on and hit.caster) then return "" end
    return UnitName(hit.caster) or ""
end
function T.Icon(cat)
    local c = data().cats[cat]
    for _, e in ipairs(c and c.list or {}) do
        local name, icon = T.Name(e.id)
        if name and icon then return icon end
    end
    return nil
end
function T.Rows(hit)
    local rows = {}
    local c = data().cats[hit.cat]
    for _, e in ipairs(c and c.list or {}) do
        local name = T.Name(e.id)
        if name then
            if hit.on and hit.id == e.id then
                local who = T.Caster(hit)
                local r = ns.T("widget.td_pct", hit.pct)
                if hit.max then r = ns.T("widget.td_stacks", hit.count, hit.max) .. "  " .. r end
                rows[#rows + 1] = { l = who ~= "" and ns.T("widget.td_by", name, who) or name, r = r, rc = ns.STATE.ok }
            else
                rows[#rows + 1] = { l = name, r = ns.T("widget.td_none"), lc = ns.STATE.mute }
            end
        end
    end
    return rows
end
ns.tdebuffLoaded = true
