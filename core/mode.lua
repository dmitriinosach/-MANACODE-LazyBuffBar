local _, ns = ...
local M = {}
ns.Mode = M
local PP_ADDON = "PallyPower"
local PP_TABLE = "PallyPower_AuraAssignments"
local cache = {}
function M.Class()
    local _, class = UnitClass("player")
    return ns.widgetData.mode.classes[class or ""]
end
function M.Modes()
    local _, class = UnitClass("player")
    local list = cache[class or ""]
    if list then
        local data = M.Class()
        if data and data.fallback then
            for _, m in ipairs(list) do
                local id = M.SpellId(m) or m.id
                local name, _, icon = GetSpellInfo(id)
                m.name, m.icon = name, icon
            end
        end
        return list
    end
    list = {}
    local data = M.Class()
    for i, e in ipairs(data and data.modes or {}) do
        local name, _, icon = GetSpellInfo(e.id)
        local m = { key = e.key, id = e.id, alt = e.alt, name = name, icon = icon, names = {} }
        if name then m.names[name] = true end
        for _, id in ipairs(e.alt or {}) do
            local n = GetSpellInfo(id)
            if n then m.names[n] = true end
        end
        list[i] = m
    end
    cache[class or ""] = list
    return M.Modes()
end
function M.Get(key)
    for _, m in ipairs(M.Modes()) do
        if m.key == key then return m end
    end
    return nil
end
function M.Known(m)
    if ns.IsLearned(m.id) then return true end
    for _, id in ipairs(m.alt or {}) do
        if ns.IsLearned(id) then return true end
    end
    return false
end
function M.SpellId(m)
    if ns.IsLearned(m.id) then return m.id end
    for _, id in ipairs(m.alt or {}) do
        if ns.IsLearned(id) then return id end
    end
    return nil
end
function M.Spell(m)
    local id = M.SpellId(m)
    return id and (GetSpellInfo(id)) or nil
end
function M.FormIndex(m)
    local n = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
    for i = 1, n do
        local _, name = GetShapeshiftFormInfo(i)
        if name and m.names[name] then return i end
    end
    return nil
end
local classColors = {}
function M.ClassColor()
    local _, class = UnitClass("player")
    class = class or ""
    local g = ns.widgetData.mode.glow[class]
    if g then return g end
    local c = classColors[class]
    if c then return c end
    local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    c = cc and { cc.r, cc.g, cc.b, 1 } or { 1, 1, 1, 1 }
    classColors[class] = c
    return c
end
function M.GlowColor(opt)
    local c = opt and opt.color
    if type(c) == "table" and c[1] then return c end
    return M.ClassColor()
end
local DRIVER_HIDE = "[dead][vehicleui][mounted] hide; "
function M.Driver(st, opt)
    local data = M.Class()
    local when = opt and opt.when
    if not (data and data.bar) or (when ~= "none" and when ~= "ok") then return nil end
    local e = M.Get(st.expect)
    local i = e and M.FormIndex(e)
    if not i then return nil end
    if when == "none" then return DRIVER_HIDE .. "[stance:" .. i .. "] hide; show" end
    return DRIVER_HIDE .. "[stance:" .. i .. "] show; hide"
end
local function byName(modes, name)
    if not name then return nil end
    for _, m in ipairs(modes) do
        if m.names[name] then return m end
    end
    return nil
end
function M.Current()
    local data = M.Class()
    local modes = M.Modes()
    if not data then return nil, nil, 0 end
    if data.bar and GetShapeshiftForm then
        local i = GetShapeshiftForm()
        if i and i > 0 then
            local _, name = GetShapeshiftFormInfo(i)
            local m = byName(modes, name)
            if m then return m.key, name, 0 end
        end
    end
    local i = 1
    while true do
        local name, _, _, count = UnitAura("player", i, "HELPFUL|PLAYER")
        if not name then break end
        local m = byName(modes, name)
        if m then return m.key, name, count or 0 end
        i = i + 1
    end
    return nil, nil, 0
end
function M.Default()
    local data = M.Class()
    local v = ns.CurrentVariant and ns.CurrentVariant()
    return data and v and data.spec[v] or nil
end
function M.Avail()
    return M.Default() ~= nil
end
function M.PPLoaded()
    local _, class = UnitClass("player")
    if class ~= "PALADIN" then return false end
    if not (IsAddOnLoaded and IsAddOnLoaded(PP_ADDON)) then return false end
    return type(_G[PP_TABLE]) == "table"
end
function M.InGroup()
    return (GetNumRaidMembers() or 0) > 0 or (GetNumPartyMembers() or 0) > 0
end
function M.PPIndex()
    if not M.PPLoaded() or not M.InGroup() then return nil end
    local all = _G[PP_TABLE]
    local idx = all[(UnitName("player"))]
    if type(idx) ~= "number" then return nil end
    local m = M.Modes()[idx]
    if not m or not M.Known(m) then return nil end
    return idx
end
function M.Expected(opt)
    opt = opt or {}
    local idx = opt.pp and M.PPIndex() or nil
    if opt.expect and (idx == nil or idx == opt.ppAt) then return opt.expect, "opt", idx end
    if idx then return M.Modes()[idx].key, "pp", idx end
    local d = M.Default()
    local data = M.Class()
    local expected = M.Get(d)
    if data and data.fallback and expected and not M.Known(expected) then
        for _, key in ipairs(data.fallback) do
            local m = M.Get(key)
            if m and M.Known(m) then return key, "preset", idx end
        end
    end
    if d then return d, "preset", idx end
    return nil, "none", idx
end
function M.State(opt)
    local modes = M.Modes()
    local st = { modes = modes, known = {}, count = 0 }
    for i, m in ipairs(modes) do st.known[i] = M.Known(m) end
    st.expect, st.source, st.ppIdx = M.Expected(opt)
    st.current, st.curName, st.count = M.Current()
    st.dead = UnitIsDeadOrGhost("player") and true or false
    local e = M.Get(st.expect)
    st.spell = e and M.Spell(e) or nil
    if not e or not st.spell or st.dead then
        st.verdict = "off"
    elseif st.current == st.expect then
        st.verdict = "ok"
    elseif st.current then
        st.verdict = "bad"
    else
        st.verdict = "none"
    end
    return st
end
function M.Active(st, opt)
    local when = opt and opt.when
    if when == "none" then return st.verdict ~= "ok" end
    if when == "ok" then return st.verdict == "ok" end
    return true
end
local hooked = false
local function onLogin()
    if hooked or not M.PPLoaded() then return end
    hooked = true
    for _, fname in ipairs({ "PallyPowerAuraButton_OnClick", "PallyPowerAuraButton_OnMouseWheel" }) do
        if type(_G[fname]) == "function" then
            hooksecurefunc(fname, function() ns.Widget.Poke("mode", 0.3) end)
        end
    end
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", onLogin)
ns.modeLoaded = true
