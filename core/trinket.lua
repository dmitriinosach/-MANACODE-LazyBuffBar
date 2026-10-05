local _, ns = ...
ns.Trinket = {}
local GCD = 1.5
local SLOTS = { 13, 14 }
local sets = {}
local up = {}
local bySpell = {}
local playerGUID
local function store()
    local c = ns.Profile.Char()
    c.procAt = c.procAt or {}
    return c.procAt
end
function ns.Trinket.ItemId(link)
    return link and tonumber(link:match("item:(%d+)")) or nil
end
function ns.Trinket.Proc(id)
    return id and ns.trinketProcs and ns.trinketProcs[id] or nil
end
local function auraSet(p)
    local s = sets[p]
    if s then return s end
    s = {}
    for _, id in ipairs(p.auras or {}) do
        s[id] = true
        local n = GetSpellInfo(id)
        if n then s[n] = true end
    end
    sets[p] = s
    return s
end
local function playerAura(ids, name)
    if not ids and not name then return nil end
    for i = 1, 40 do
        local n, _, _, count, _, duration, expires, _, _, _, spellId = UnitAura("player", i, "HELPFUL")
        if not n then break end
        local hit
        if ids and spellId then hit = ids[spellId] elseif ids then hit = ids[n] end
        if hit or (name and n == name) then
            return expires or 0, duration or 0, count
        end
    end
    return nil
end
local function remember(id, at)
    local s = store()
    local now = GetTime()
    if not s[id] or at > s[id] + 1 or s[id] > now then s[id] = at end
end
local function mapSpells()
    wipe(bySpell)
    for _, slot in ipairs(SLOTS) do
        local id = ns.Trinket.ItemId(GetInventoryItemLink("player", slot))
        local p = ns.Trinket.Proc(id)
        for _, sid in ipairs(p and p.spells or {}) do bySpell[sid] = id end
    end
end
function ns.Trinket.Scan()
    local now = GetTime()
    for _, slot in ipairs(SLOTS) do
        local id = ns.Trinket.ItemId(GetInventoryItemLink("player", slot))
        local p = ns.Trinket.Proc(id)
        if p and p.icd and p.auras then
            local expires, duration = playerAura(auraSet(p))
            if expires and not up[id] then
                remember(id, (duration > 0 and expires > 0) and (expires - duration) or now)
            end
            up[id] = expires and true or nil
        end
    end
end
function ns.Trinket.State(entry)
    local now = GetTime()
    local st = { icon = GetInventoryItemTexture("player", entry.slot), link = entry.link }
    local p = entry.proc
    local useName = (not p) and entry.use and GetItemSpell and GetItemSpell(entry.link) or nil
    local expires, duration, count = playerAura(p and p.auras and auraSet(p), useName)
    if expires then
        st.active, st.stacks = true, count
        if expires > now and duration > 0 then
            st.start, st.duration, st.left = expires - duration, duration, expires - now
        end
        return st
    end
    local at = p and p.icd and entry.item and store()[entry.item]
    if at and at <= now and now - at < p.icd then
        st.dim = true
        st.start, st.duration, st.left = at, p.icd, at + p.icd - now
        return st
    end
    if entry.use then
        local start, dur = GetInventoryItemCooldown("player", entry.slot)
        if dur and dur > GCD and start + dur > now then
            st.start, st.duration, st.left = start, dur, start + dur - now
            return st
        end
    end
    st.active = true
    return st
end
function ns.Trinket.Entries()
    local out = {}
    for _, slot in ipairs(SLOTS) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local id = ns.Trinket.ItemId(link)
            local proc = ns.Trinket.Proc(id)
            local use = GetItemSpell and GetItemSpell(link) and true or false
            if use or proc then
                out[#out + 1] = { slot = slot, link = link, item = id, proc = proc, use = use }
            end
        end
    end
    return out
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("UNIT_AURA")
watch:RegisterEvent("PLAYER_ENTERING_WORLD")
watch:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
watch:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
watch:SetScript("OnEvent", function(_, event, a1, _, src, _, _, _, _, _, spellId)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local item = spellId and bySpell[spellId]
        if item and src == playerGUID then remember(item, GetTime()) end
        return
    end
    if event == "UNIT_AURA" and a1 ~= "player" then return end
    if event ~= "UNIT_AURA" then
        playerGUID = UnitGUID("player")
        mapSpells()
    end
    ns.Trinket.Scan()
end)
ns.trinketLoaded = true
