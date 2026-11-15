local _, ns = ...
local Z = {}
ns.Rez = Z
local function data()
    return ns.widgetData.rez
end
function Z.Spell()
    local _, class = UnitClass("player")
    return data().classes[class or ""]
end
function Z.Known()
    local e = Z.Spell()
    if not e then return false end
    if ns.IsLearned(e.id) then return true end
    for _, id in ipairs(e.alt) do
        if ns.IsLearned(id) then return true end
    end
    return false
end
function Z.Avail()
    return Z.Known()
end
function Z.IsTank(m)
    if UnitGroupRolesAssigned and UnitGroupRolesAssigned(m.unit) then return true end
    if ns.Raid.InRaid() then
        if select(10, GetRaidRosterInfo(m.pos)) == "MAINTANK" then return true end
    elseif GetPartyAssignment and GetPartyAssignment("MAINTANK", m.unit) then
        return true
    end
    local U = ns.Units
    if not (U and U.Resolve) then return false end
    for _, l in ipairs({ "tank", "tank2" }) do
        local u = U.Resolve(l)
        if u and UnitIsUnit(u, m.unit) then return true end
    end
    return false
end
local function before(a, b)
    if a.prio ~= b.prio then return a.prio < b.prio end
    if a.tank ~= b.tank then return a.tank end
    return a.pos < b.pos
end
local function judge(st)
    if not st.spell then return "none", "off" end
    if st.self then return "self", "off" end
    if st.n == 0 then return "idle", "off" end
    if st.fight then return "fight", "off" end
    if st.next.ghost then return "ghost", "off" end
    if st.nomana then return "res", "off" end
    if st.next.far then return "far", "bad" end
    return "go", "ok"
end
function Z.State()
    local e = Z.Spell()
    local st = { list = {}, n = 0, fight = InCombatLockdown() and true or false, nomana = false, grouped = false }
    st.self = UnitIsDeadOrGhost("player") and true or false
    if e and Z.Known() then
        local name, _, icon = GetSpellInfo(e.id)
        st.spell, st.icon = name, icon
    end
    local R = ns.Raid
    if R and st.spell then
        R.Touch()
        st.grouped = R.Grouped()
        for _, m in ipairs(R.Roster()) do
            if m.seen and m.dead and not m.off and m.click ~= "player" then
                local d = { name = m.name, class = m.class, click = m.click, unit = m.unit, pos = m.pos, far = false }
                d.tank = Z.IsTank(m)
                d.ghost = UnitIsGhost(m.unit) and true or false
                if not st.fight and not d.ghost then d.far = IsSpellInRange(st.spell, m.unit) ~= 1 end
                if d.ghost then d.prio = 3 elseif d.tank then d.prio = 0 elseif d.far then d.prio = 2 else d.prio = 1 end
                st.list[#st.list + 1] = d
            end
        end
        table.sort(st.list, before)
        st.n = #st.list
        st.next = st.list[1]
        local usable, nomana = IsUsableSpell(st.spell)
        st.nomana = (not usable and nomana) and true or false
    end
    st.why, st.verdict = judge(st)
    return st
end
local HIDDEN = { none = true, self = true, idle = true }
function Z.Active(st)
    return not HIDDEN[st.why]
end
function Z.Click(st)
    local d = st.next
    if not (st.spell and d) or d.ghost or st.self then return {} end
    return { type = "spell", spell = st.spell, unit = d.click }
end
function Z.Tick(st)
    if st.spell and st.grouped then return data().tick end
    return nil
end
if ns.Raid then
    ns.Raid.OnChange(function() ns.Widget.Poke("rez") end)
end
ns.rezLoaded = true
