local _, ns = ...
ns.Weapon = {}
local SLOT = { main = 16, off = 17 }
local function armed(hand)
    if hand == "off" then return OffhandHasWeapon and OffhandHasWeapon() and true or false end
    return GetInventoryItemLink("player", SLOT.main) ~= nil
end
local function learnedSpell(e)
    if e.poison then return e.id end
    if ns.IsLearned(e.id) then return e.id end
    for _, id in ipairs(e.alt or {}) do
        if ns.IsLearned(id) then return id end
    end
    return nil
end
function ns.WeaponEntries(list)
    local out = {}
    for _, e in ipairs(list or {}) do
        local id = armed(e.hand) and learnedSpell(e)
        if id then
            out[#out + 1] = { id = id, hand = e.hand, dur = e.dur, note = e.note, noteEn = e.noteEn, poison = e.poison }
        end
    end
    return out
end
function ns.Weapon.Left(hand)
    local mh, mhMs, mhCh, oh, ohMs, ohCh = GetWeaponEnchantInfo()
    if hand == "off" then
        if not oh then return nil end
        return (ohMs or 0) / 1000, ohCh
    end
    if not mh then return nil end
    return (mhMs or 0) / 1000, mhCh
end
local function itemsOf(e)
    if e.poison then return ns.weaponPoisons and ns.weaponPoisons[e.poison] end
    return ns.weaponStones and ns.weaponStones[e.id]
end
local function bestInBags(list)
    for i = #list, 1, -1 do
        if (GetItemCount(list[i]) or 0) > 0 then return list[i] end
    end
    return nil
end
local function useOn(item, slot)
    local name = GetItemInfo(item)
    return "/use " .. (name or ("item:" .. item)) .. "\n/use " .. slot
end
function ns.Weapon.Macro(e)
    local spell = GetSpellInfo(e.id)
    local slot = SLOT[e.hand] or SLOT.main
    local list = itemsOf(e)
    if list and #list > 0 then
        local item = bestInBags(list)
        if item then return useOn(item, slot) end
        if e.poison then return useOn(list[#list], slot) end
        return "/cast " .. spell
    end
    return "/cast " .. spell .. "\n/use " .. slot
end
function ns.Weapon.NeedsStone(e)
    if e.poison then return false end
    local list = itemsOf(e)
    return list and not bestInBags(list) and true or false
end
function ns.Weapon.Vial(key)
    local list = ns.weaponPoisons and ns.weaponPoisons[key]
    if not list or #list == 0 then return nil end
    return bestInBags(list) or list[#list]
end
local scanned = {}
ns.Weapon.scans = 0
local TIP = "LazyBuffBarScanTip"
local tip
local function bare(s)
    if not s then return nil end
    s = s:gsub("%s+[XVI]+$", ""):gsub("%s+%d+$", "")
    return s
end
local function poisonKey(short)
    local d = ns.widgetData and ns.widgetData.poison
    for key, id in pairs(d and d.spells or {}) do
        if bare((GetSpellInfo(id))) == short then return key end
        for _, item in ipairs(ns.weaponPoisons and ns.weaponPoisons[key] or {}) do
            local n = GetItemInfo(item)
            if n and bare(n) == short then return key end
        end
    end
    return nil
end
local function scan(slot)
    if not tip then tip = CreateFrame("GameTooltip", TIP, nil, "GameTooltipTemplate") end
    ns.Weapon.scans = ns.Weapon.scans + 1
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tip:ClearLines()
    tip:SetInventoryItem("player", slot)
    for i = 1, tip:NumLines() or 0 do
        local fs = _G[TIP .. "TextLeft" .. i]
        local line = fs and fs:GetText()
        local full, short
        if line then full, short = line:match("^((.-) ?+?[XVI%d]*) %(%d+ .+%)$") end
        if short and short ~= "" then
            tip:Hide()
            return { name = short, full = full, key = poisonKey(short) }
        end
    end
    tip:Hide()
    return false
end
function ns.Weapon.Name(hand)
    if not ns.Weapon.Left(hand) then return nil end
    local r = scanned[hand]
    if r == nil then
        r = scan(SLOT[hand] or SLOT.main)
        scanned[hand] = r
    end
    if not r then return nil end
    return r.name, r.key, r.full
end
local inv = CreateFrame("Frame")
inv:RegisterEvent("UNIT_INVENTORY_CHANGED")
inv:SetScript("OnEvent", function(_, _, unit)
    if unit ~= "player" then return end
    scanned.main, scanned.off = nil, nil
end)
ns.weaponLoaded = true
