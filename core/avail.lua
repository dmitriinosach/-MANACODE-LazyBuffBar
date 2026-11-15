local _, ns = ...
ns.Avail = {}
local A = ns.Avail
local CAST = { self = true, raid = true, cd = true, dot = true, ally = true, weapon = true }
local BOOK_KIND = { b = true, r = true, f = true, c = true, d = true }
local SLOTS = {}
for i = 1, 19 do SLOTS[i] = i end
local dropped = {}
function A.Drop(key)
    dropped[key] = true
end
function A.Dropped(key)
    return dropped[key] == true
end
function A.Reset()
    wipe(dropped)
end
function A.Worn()
    local out, slots = {}, {}
    for _, slot in ipairs(SLOTS) do
        local id = GetInventoryItemID("player", slot)
        if id then
            out[id] = true
            slots[id] = slots[id] or ("slot:" .. slot)
        end
    end
    return out, slots
end
function A.SlotOf(id)
    for _, slot in ipairs(SLOTS) do
        if GetInventoryItemID("player", slot) == id then return slot end
    end
    return nil
end
function A.Count(id)
    return (GetItemCount and GetItemCount(id)) or 0
end
function A.HasEnchant(ench)
    for _, slot in ipairs(SLOTS) do
        if ns.Trinket.LinkFields(GetInventoryItemLink("player", slot))[2] == ench then return true end
    end
    return false
end
function A.Spell(id, alt)
    if not id or ns.IsLearned(id) then return nil end
    for _, a in ipairs(alt or {}) do
        if ns.IsLearned(a) then return nil end
    end
    return ns.IsTalent(id) and "talent" or "spell", id
end
function A.Item(id)
    if A.SlotOf(id) then return nil end
    return (A.Count(id) > 0) and "worn" or "item", id
end
local function byRow(id)
    if not (ns.Catalog and ns.Catalog.RowFor) then return nil end
    local row, own = ns.Catalog.RowFor(id)
    if not row then return nil end
    local need, k, src = row.need or {}, row.srcKind, row.srcId
    if own then
        if k == "t" and src then return A.Spell(src) end
        if k == "s" and src then return A.Spell(src) end
        if k == "b" and BOOK_KIND[row.kind] then return A.Spell(row.id, row.alt) end
    end
    if need.w and src then
        if k == "i" then return A.Item(src) end
        if k == "e" and not A.HasEnchant(src) then return "ench", src end
    end
    return nil
end
local function gear(e)
    if not e.item then return nil end
    if e.passive then return "passive", e.item end
    if e.absent then return A.Item(e.item) end
    if e.use and e.link and GetItemSpell and GetItemSpell(e.link) and IsUsableItem and not IsUsableItem(e.item) then
        return "use", e.item
    end
    return nil
end
function A.Of(item, entry, cat)
    if not entry then return nil end
    if cat == "gear" then return gear(entry) end
    if not entry.mine then return nil end
    if type(entry.needs) == "number" then
        local why, what = A.Spell(entry.needs)
        if why then return why, what end
    end
    if not entry.id then return nil end
    if CAST[item and item.role or ""] then
        local why, what = A.Spell(entry.id, entry.alt)
        if why then return why, what end
    end
    return byRow(entry.id)
end
function A.Text(why, what)
    local name
    if why == "spell" or why == "talent" then
        name = what and GetSpellInfo(what)
    elseif why == "ench" then
        name = what and ns.Catalog and ns.Catalog.SourceName and ns.Catalog.SourceName("e" .. what)
    elseif what then
        name = GetItemInfo(what) or (ns.Catalog and ns.Catalog.SourceName and ns.Catalog.SourceName("i" .. what))
    end
    return ns.T("avail." .. why, name or ("#" .. tostring(what or "?")))
end
ns.availLoaded = true
