local _, ns = ...
local K = {}
ns.Kick = K
local function data()
    return ns.widgetData.kick
end
function K.List()
    local _, class = UnitClass("player")
    return data().classes[class or ""] or {}
end
function K.Known(e)
    if e.pet then return true end
    if e.talent and not ns.IsLearned(e.talent) then return false end
    if ns.IsLearned(e.id) then return true end
    for _, id in ipairs(e.alt or {}) do
        if ns.IsLearned(id) then return true end
    end
    return false
end
function K.Choices()
    local out = {}
    for _, e in ipairs(K.List()) do
        if K.Known(e) then out[#out + 1] = e end
    end
    return out
end
function K.Avail()
    local _, class = UnitClass("player")
    local only = data().spec[class or ""]
    if only then
        local v = ns.CurrentVariant and ns.CurrentVariant()
        if not (v and only[v]) then return false end
    end
    return #K.Choices() > 0
end
function K.FormIndex(id)
    local want = GetSpellInfo(id)
    if not want then return nil end
    for i = 1, GetNumShapeshiftForms() or 0 do
        local _, name = GetShapeshiftFormInfo(i)
        if name == want then return i end
    end
    return nil
end
local function inStance(id)
    local i = K.FormIndex(id)
    return i ~= nil and GetShapeshiftForm() == i
end
function K.Pick(opt)
    local list = K.Choices()
    local want = opt and opt.spell
    if want then
        for _, e in ipairs(list) do
            if e.id == want then return e end
        end
    end
    local plain
    for _, e in ipairs(list) do
        if e.stance then
            if inStance(e.stance) then return e end
        elseif not plain then
            plain = e
        end
    end
    return plain or list[1]
end
function K.Click(opt)
    local list = K.Choices()
    local want = opt and opt.spell
    local chosen
    for _, e in ipairs(list) do
        if want and e.id == want then chosen = e end
    end
    if not chosen then
        local parts, plain = {}, nil
        for _, e in ipairs(list) do
            if e.stance then
                local i = K.FormIndex(e.stance)
                if i then parts[#parts + 1] = "[stance:" .. i .. "] " .. (GetSpellInfo(e.id) or "") end
            elseif not plain then
                plain = e
            end
        end
        if #parts > 0 then
            if plain then parts[#parts + 1] = GetSpellInfo(plain.id) or "" end
            return { type = "macro", macrotext = "/cast " .. table.concat(parts, "; ") }
        end
        chosen = plain or list[1]
    end
    if not chosen then return {} end
    local name = GetSpellInfo(chosen.id)
    if not name then return {} end
    if chosen.pet then return { type = "macro", macrotext = "/cast " .. name } end
    return { type = "spell", spell = name }
end
function K.Cast()
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return nil end
    local channel = false
    local name, _, _, icon, s, e, _, _, lock = UnitCastingInfo("target")
    if not name then
        name, _, _, icon, s, e, _, lock = UnitChannelInfo("target")
        channel = true
    end
    if not (name and s and e) then return nil end
    local finish = e / 1000
    local left = finish - GetTime()
    if left < 0 then left = 0 end
    local total = (e - s) / 1000
    if total <= 0 then total = left > 0 and left or 1 end
    return { name = name, icon = icon, left = left, total = total, channel = channel, lock = lock and true or false }
end
function K.PetSlot(name)
    if not UnitExists("pet") or UnitIsDead("pet") then return nil end
    for i = 1, data().petSlots do
        local n = GetPetActionInfo(i)
        if n == name then return i end
    end
    return nil
end
function K.Boss()
    if UnitClassification("target") == "worldboss" or UnitLevel("target") == -1 then return true end
    local E = ns.Encounter
    return (E and E.BossOfNpc and E.BossOfNpc(E.NpcOf(UnitGUID("target")))) ~= nil
end
local function left(start, dur)
    if not (start and dur) or start <= 0 or dur <= data().gcd then return 0 end
    local l = start + dur - GetTime()
    return l > 0 and l or 0
end
local function judge(st)
    if not st.entry then return "none", "off" end
    if st.dead then return "dead", "off" end
    if st.nopet then return "pet", "off" end
    local c = st.cast
    if not c then return "idle", "off" end
    if c.lock then return "lock", "off" end
    if st.boss then return "boss", "off" end
    if st.nores then return "res", "off" end
    if st.unusable then return "use", "off" end
    if st.far then return "far", "off" end
    if st.cd > 0 then return "cd", (st.cd < c.left) and "soon" or "off" end
    return "go", "ok"
end
function K.State(opt)
    local e = K.Pick(opt)
    local st = { entry = e, cast = K.Cast(), cd = 0, nopet = false, nores = false, unusable = false, far = false }
    st.dead = UnitIsDeadOrGhost("player") and true or false
    st.dim = (opt and opt.idle == "dim") and true or false
    if e then
        local name, _, icon = GetSpellInfo(e.id)
        st.spell, st.icon = name, icon
        if e.pet then
            local slot = name and K.PetSlot(name)
            st.nopet = slot == nil
            if slot then st.cd = left(GetPetActionCooldown(slot)) end
        elseif name then
            st.cd = left(GetSpellCooldown(name))
            local usable, nomana = IsUsableSpell(name)
            st.nores = (not usable and nomana) and true or false
            st.unusable = (not usable and not nomana) and true or false
        end
        if name and st.cast then st.far = IsSpellInRange(name, "target") == 0 end
        st.boss = (e.noBoss and st.cast and K.Boss()) or false
    end
    st.why, st.verdict = judge(st)
    return st
end
local SHOWN = { go = true, cd = true, res = true, use = true, far = true }
function K.Active(st)
    return st.dim or SHOWN[st.why] == true
end
function K.Tick(st)
    if not K.Active(st) then return nil end
    if st.cast then return data().frame end
    if st.cd > 0 then return data().slow end
    return nil
end
ns.kickLoaded = true
