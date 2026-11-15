local _, ns = ...
ns.Trinket = {}
local GCD = 1.5
local TRINKET_SLOTS = { 13, 14 }
local RELIC_SLOT = 18
local ITEM_SLOTS = { 11, 12, 16, 17 }
local HEAD_SLOT = 1
local ENCHANT_SLOTS = { 15, 16, 17 }
local SET_SLOTS = { 1, 3, 5, 7, 10 }
local INSTALL_SLOTS = { 1, 6, 8, 10, 15 }
local TIP = "LazyBuffBarUseTip"
local sets = {}
local up = {}
local bySpell = {}
local worn
local setOf
local setOrder
local playerGUID
local useScan = {}
local tip
local function store()
    local c = ns.Profile.Char()
    c.procAt = c.procAt or {}
    return c.procAt
end
function ns.Trinket.ItemId(link)
    return link and tonumber(link:match("item:(%d+)")) or nil
end
function ns.Trinket.LinkFields(link)
    local out = {}
    local body = link and link:match("item:([%-%d:]+)")
    if body then
        for n in body:gmatch("%-?%d+") do out[#out + 1] = tonumber(n) end
    end
    return out
end
function ns.Trinket.Proc(id)
    return id and ns.trinketProcs and ns.trinketProcs[id] or nil
end
local function setIndex()
    if setOf then return setOf end
    setOf = {}
    for set, items in pairs(ns.gearSetItems or {}) do
        for _, id in ipairs(items) do setOf[id] = set end
    end
    return setOf
end
local function bonusOrder()
    if setOrder then return setOrder end
    setOrder = {}
    for bonus in pairs(ns.gearSets or {}) do setOrder[#setOrder + 1] = bonus end
    table.sort(setOrder)
    return setOrder
end
local function auraSet(list)
    if not list then return nil end
    local s = sets[list]
    if s then return s end
    s = {}
    for _, id in ipairs(list) do
        s[id] = true
        local n = GetSpellInfo(id)
        if n then s[n] = true end
    end
    sets[list] = s
    return s
end
local function playerAura(ids, name)
    return ns.Auras.Player(ids, name)
end
local function remember(key, at)
    local s = store()
    local now = GetTime()
    if not s[key] or at > s[key] + 1 or s[key] > now then s[key] = at end
end
local FIRES = { SPELL_CAST_SUCCESS = true, SPELL_AURA_APPLIED = true, SPELL_HEAL = true, SPELL_DAMAGE = true }
local function fired(e, at)
    local last = store()[e.key]
    if last and last <= at and at - last < (e.proc.icd or 0) - 1 then return end
    remember(e.key, at)
    if ns.Widget and ns.Widget.Poke then ns.Widget.Poke("trinkets") end
end
local function procEntry(slot, proc)
    local first = (proc.auras and proc.auras[1]) or (proc.spells and proc.spells[1])
    local _, _, icon = GetSpellInfo(first)
    return { slot = slot, key = slot, proc = proc, id = first, icon = icon, note = proc.note, noteEn = proc.noteEn }
end
local function add(out, seen, e)
    if seen[e.slot] then return end
    seen[e.slot] = true
    out[#out + 1] = e
end
local function addSets(out, seen)
    local index, count = setIndex(), {}
    for _, slot in ipairs(SET_SLOTS) do
        local set = index[ns.Trinket.ItemId(GetInventoryItemLink("player", slot)) or 0]
        if set then count[set] = (count[set] or 0) + 1 end
    end
    if not next(count) then return end
    for _, bonus in ipairs(bonusOrder()) do
        local p = ns.gearSets[bonus]
        for _, set in ipairs(p.sets) do
            if (count[set] or 0) >= p.pieces then
                add(out, seen, procEntry("set:" .. bonus, p))
                break
            end
        end
    end
end
local function scanUse(slot, link)
    local r = useScan[link]
    if r ~= nil then return r end
    r = false
    local use = ITEM_SPELL_TRIGGER_ONUSE
    if type(use) == "string" and use ~= "" then
        if not tip then tip = CreateFrame("GameTooltip", TIP, nil, "GameTooltipTemplate") end
        tip:SetOwner(WorldFrame, "ANCHOR_NONE")
        tip:ClearLines()
        tip:SetInventoryItem("player", slot)
        for i = 1, tip:NumLines() or 0 do
            local fs = _G[TIP .. "TextLeft" .. i]
            local line = fs and fs:GetText()
            if line and line:sub(1, #use) == use then r = true; break end
        end
        tip:Hide()
    end
    useScan[link] = r
    return r
end
local function procOf(id)
    if not id then return nil end
    return ns.Trinket.Proc(id) or (ns.gearRelics and ns.gearRelics[id]) or (ns.gearItems and ns.gearItems[id]) or nil
end
local function addInstalls(out, seen)
    for _, slot in ipairs(INSTALL_SLOTS) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local iid = ns.Trinket.ItemId(link)
            local gu = ns.gearUse and ns.gearUse[ns.Trinket.LinkFields(link)[2] or 0]
            local own = GetItemSpell and GetItemSpell(link) and true or false
            if own or gu or scanUse(slot, link) then
                local p = (gu and gu.auras) and gu or nil
                add(out, seen, { slot = slot, key = iid, link = link, item = iid, proc = p, use = true, off = true })
            end
        end
    end
end
local function collect()
    local out, seen = {}, {}
    for _, slot in ipairs(TRINKET_SLOTS) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local id = ns.Trinket.ItemId(link)
            local proc = ns.Trinket.Proc(id)
            local use = GetItemSpell and GetItemSpell(link) and true or false
            if use or proc then
                add(out, seen, { slot = slot, key = id, link = link, item = id, proc = proc, use = use,
                                 note = proc and proc.note, noteEn = proc and proc.noteEn })
            end
        end
    end
    local link = GetInventoryItemLink("player", RELIC_SLOT)
    local id = ns.Trinket.ItemId(link)
    local relic = id and ns.gearRelics and ns.gearRelics[id]
    if relic then
        add(out, seen, { slot = RELIC_SLOT, key = id, link = link, item = id, proc = relic,
                         note = relic.note, noteEn = relic.noteEn })
    end
    for _, slot in ipairs(ITEM_SLOTS) do
        local l = GetInventoryItemLink("player", slot)
        local iid = ns.Trinket.ItemId(l)
        local p = iid and ns.gearItems and ns.gearItems[iid]
        if p then
            add(out, seen, { slot = slot, key = iid, link = l, item = iid, proc = p, note = p.note, noteEn = p.noteEn })
        end
    end
    addInstalls(out, seen)
    local head = ns.Trinket.LinkFields(GetInventoryItemLink("player", HEAD_SLOT))
    for i = 3, 6 do
        local meta = head[i] and ns.gearMetas and ns.gearMetas[head[i]]
        if meta then add(out, seen, procEntry("meta:" .. head[i], meta)) end
    end
    for _, slot in ipairs(ENCHANT_SLOTS) do
        local ench = ns.Trinket.LinkFields(GetInventoryItemLink("player", slot))[2]
        local p = ench and ns.gearEnchants and ns.gearEnchants[ench]
        if p then add(out, seen, procEntry("ench:" .. ench, p)) end
    end
    addSets(out, seen)
    return out
end
local function mapSpells()
    wipe(bySpell)
    wipe(useScan)
    worn = collect()
    for _, e in ipairs(worn) do
        for _, sid in ipairs(e.proc and e.proc.spells or {}) do bySpell[sid] = e end
    end
end
function ns.Trinket.Scan()
    local now = GetTime()
    for _, e in ipairs(worn or collect()) do
        local p = e.proc
        if p and p.icd and p.auras then
            local expires, duration = playerAura(auraSet(p.auras))
            if expires and not up[e.key] then
                remember(e.key, (duration > 0 and expires > 0) and (expires - duration) or now)
            end
            up[e.key] = expires and true or nil
        end
    end
end
function ns.Trinket.State(entry)
    local now = GetTime()
    local icon = entry.icon
    if not icon and type(entry.slot) == "number" then icon = GetInventoryItemTexture("player", entry.slot) end
    if not icon and entry.item then icon = GetItemIcon and GetItemIcon(entry.item) end
    local link = entry.link or (entry.item and ("item:" .. entry.item)) or nil
    local st = { icon = icon, link = link, spell = (not link) and entry.id or nil }
    if entry.absent or entry.idle then return st end
    local p = entry.proc
    local useName = (not p) and entry.use and GetItemSpell and GetItemSpell(entry.link) or nil
    local expires, duration, count = playerAura(p and auraSet(p.auras), useName)
    if p and p.count then
        local e2, d2, c2 = playerAura(auraSet(p.count))
        if e2 then
            count = c2
            if not expires then expires, duration = e2, d2 end
        end
    end
    if expires then
        st.active, st.up, st.stacks = true, true, count
        if expires > now and duration > 0 then
            st.start, st.duration, st.left = expires - duration, duration, expires - now
        end
        return st
    end
    local key = entry.key or entry.item
    local at = p and p.icd and key and store()[key]
    if at and at <= now and now - at < p.icd then
        st.dim, st.icd = true, true
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
    st.active, st.ready = true, entry.use and true or nil
    return st
end
function ns.Trinket.Cell(slot)
    local link = GetInventoryItemLink("player", slot)
    if not link then return { slot = slot, s = "empty", use = false } end
    local id = ns.Trinket.ItemId(link)
    local proc = ns.Trinket.Proc(id)
    local use = GetItemSpell and GetItemSpell(link) and true or false
    local st = ns.Trinket.State({ slot = slot, key = id, link = link, item = id, proc = proc, use = use })
    local s
    if st.up then s = "act"
    elseif st.icd then s = "icd"
    elseif st.left then s = "cd"
    elseif st.ready then s = "ready"
    elseif proc then s = "armed"
    else s = "idle" end
    return { slot = slot, item = id, icon = st.icon, s = s, left = st.left, stacks = st.stacks, use = use }
end
function ns.Trinket.Entries()
    worn = collect()
    return worn
end
function ns.Trinket.ItemEntry(id)
    local slot = ns.Avail.SlotOf(id)
    if not slot then return { item = id, key = id, absent = true } end
    local link = GetInventoryItemLink("player", slot)
    local p = procOf(id)
    local use = GetItemSpell and link and GetItemSpell(link) and true or false
    return { slot = slot, key = id, link = link, item = id, proc = p, use = use or nil, idle = (not use and not p) or nil,
             note = p and p.note, noteEn = p and p.noteEn }
end
function ns.Trinket.Passive(k)
    local slot = tonumber(tostring(k or ""):match("^slot:(%d+)$"))
    local link = slot and GetInventoryItemLink("player", slot)
    if not link or (GetItemSpell and GetItemSpell(link)) then return nil end
    local id = ns.Trinket.ItemId(link)
    return { slot = slot, key = id, link = link, item = id, idle = true, passive = true }
end
local HAND_SLOT = { main = 16, off = 17 }
function ns.Trinket.ForRef(k)
    k = tostring(k or "")
    local list = worn or collect()
    local slot = tonumber(k:match("^slot:(%d+)$"))
    if slot then
        for _, e in ipairs(list) do
            if e.slot == slot then return e end
        end
        return nil
    end
    local item = tonumber(k:match("^item:(%d+)$"))
    if item then
        for _, e in ipairs(list) do
            if e.item == item then return e end
        end
        return ns.Trinket.ItemEntry(item)
    end
    local tag = k:match("^slot:(.+)$") or k
    local kind, arg = tag:match("^(%a+):?(.*)$")
    if kind == "meta" then
        for _, e in ipairs(list) do
            local id = type(e.slot) == "string" and e.slot:match("^meta:(%d+)$")
            if id and (arg == "" or arg == id) then return e end
        end
        return nil
    end
    if kind == "ench" then
        local hand = HAND_SLOT[arg]
        if hand then
            local ench = ns.Trinket.LinkFields(GetInventoryItemLink("player", hand))[2]
            if not ench then return nil end
            arg = tostring(ench)
        end
        for _, e in ipairs(list) do
            if e.slot == "ench:" .. arg then return e end
        end
        return nil
    end
    if kind == "set" then
        local n = tonumber(arg)
        local nth = 0
        for _, e in ipairs(list) do
            local bonus = type(e.slot) == "string" and e.slot:match("^set:(%d+)$")
            if bonus then
                nth = nth + 1
                if bonus == arg or (n and n <= 2 and nth == n) then return e end
            end
        end
        return nil
    end
    return nil
end
local watch = CreateFrame("Frame")
watch:RegisterEvent("UNIT_AURA")
watch:RegisterEvent("PLAYER_ENTERING_WORLD")
watch:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
watch:RegisterEvent("UNIT_INVENTORY_CHANGED")
watch:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
watch:SetScript("OnEvent", function(_, event, a1, sub, src, _, _, _, _, _, spellId)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local mana = sub == "SPELL_ENERGIZE"
        if not FIRES[sub] and not mana then return end
        local e = spellId and bySpell[spellId]
        if not e or src ~= playerGUID or (mana and not e.proc.mana) then return end
        fired(e, GetTime())
        return
    end
    if (event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED") and a1 ~= "player" then return end
    if event == "UNIT_AURA" then ns.Auras.Stale("player") end
    if event ~= "UNIT_AURA" then
        playerGUID = UnitGUID("player")
        mapSpells()
    end
    ns.Trinket.Scan()
end)
ns.trinketLoaded = true
