local _, ns = ...
ns.Meal = {}
local M = ns.Meal
local FOOD_TYPES = {
    ["Food & Drink"] = true, ["Еда и напитки"] = true,
    ["Comida y bebida"] = true, ["Nahrung & Getränke"] = true,
    ["Nourriture et boissons"] = true, ["Comida e Bebida"] = true,
}
local cache = {}
local bagItems
local pending = false
local lastUsed
local tip = CreateFrame("GameTooltip", "LazyBuffBarMealTip", nil, "GameTooltipTemplate")
local function amount(text, patterns)
    for _, pattern in ipairs(patterns) do
        local n = text:match(pattern)
        if n then return tonumber((n:gsub("[^%d]", ""))) or 0 end
    end
    return 0
end
local HEALTH = { "([%d,%. ]+)%s*ед%.%s*здоровья", "([%d,]+)%s+health", "([%d%.]+)%s+p%.%s+de salud" }
local MANA = { "([%d,%. ]+)%s*ед%.%s*маны", "([%d,]+)%s+mana", "([%d%.]+)%s+p%.%s+de maná" }
local function inspect(id)
    if cache[id] ~= nil then return cache[id] or nil end
    local name, _, _, _, level, _, subtype, _, _, icon = GetItemInfo(id)
    if not name then pending = true; return nil end
    if not FOOD_TYPES[subtype] or ns.Food.IsFeast(id) then cache[id] = false; return nil end
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tip:ClearLines()
    tip:SetHyperlink("item:" .. id)
    local out, hp, mana, bonus = {}, 0, 0, false
    for i = 2, tip:NumLines() do
        local fs = _G[tip:GetName() .. "TextLeft" .. i]
        local text = fs and fs:GetText()
        if text then
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            local h, m = amount(text, HEALTH), amount(text, MANA)
            hp, mana = math.max(hp, h), math.max(mana, m)
            local fed = text:find("сытост") or text:find("well fed") or text:find("bien alimentado")
                or text:find("выносливость") or text:find("Stamina")
            bonus = bonus or fed ~= nil
            if text:match("%S") then out[#out + 1] = text end
        end
    end
    local n = tip:NumLines()
    tip:Hide()
    if n < 2 then pending = true; return nil end
    if hp == 0 and mana == 0 then cache[id] = false; return nil end
    local item = { id = id, name = name, icon = icon, level = level or 0, hp = hp, mana = mana, bonus = bonus, lines = out }
    cache[id] = item
    return item
end
function M.Bags()
    if bagItems then return bagItems end
    pending = false
    local out, seen = {}, {}
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            local id = link and tonumber(link:match("item:(%d+)"))
            if id and not seen[id] then
                seen[id] = true
                local item = inspect(id)
                if item then
                    local copy = {}
                    for k, v in pairs(item) do copy[k] = v end
                    copy.count = GetItemCount(id) or 0
                    if copy.count > 0 then out[#out + 1] = copy end
                end
            end
        end
    end
    if not pending then bagItems = out end
    return out
end
local function resting()
    local food, drink = GetSpellInfo(433), GetSpellInfo(430)
    for i = 1, 40 do
        local name, _, _, _, _, _, expires = UnitAura("player", i, "HELPFUL")
        if not name then break end
        if name == food or name == drink then
            return true, expires and expires > 0 and math.max(0, expires - GetTime()) or nil
        end
    end
    return false, nil
end
function M.State(opt)
    local list = {}
    local hpMax = math.max(1, UnitHealthMax("player") or 1)
    local manaMax = math.max(1, UnitPowerMax("player", 0) or 1)
    local hpNeed = math.max(0, hpMax - (UnitHealth("player") or 0))
    local manaNeed = math.max(0, manaMax - (UnitPower("player", 0) or 0))
    local _, class = UnitClass("player")
    local usesMana = class ~= "WARRIOR" and class ~= "ROGUE" and class ~= "DEATHKNIGHT"
    local full = hpNeed == 0 and (not usesMana or manaNeed == 0)
    local fed = ns.Food.Buff() ~= nil
    local level = UnitLevel("player") or 1
    for _, item in ipairs(M.Bags()) do
        if item.level <= level then
            local score = (full and item.hp or math.min(item.hp, hpNeed)) / hpMax
            if usesMana then score = score + (full and item.mana or math.min(item.mana, manaNeed)) / manaMax end
            if item.bonus and not fed then score = score + 0.1 end
            list[#list + 1] = { item = item, score = score }
        end
    end
    table.sort(list, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        if a.item.level ~= b.item.level then return a.item.level > b.item.level end
        return a.item.id < b.item.id
    end)
    local st = { items = {}, pending = pending }
    st.eating, st.left = resting()
    for i, entry in ipairs(list) do
        local item = entry.item
        st.items[i] = item
        if opt and item.id == opt.item then st.pick = item end
        if st.eating and item.id == lastUsed then st.current = item end
    end
    st.pick = st.pick or st.items[1]
    if st.eating and not st.current and lastUsed and cache[lastUsed] then
        st.current = {}
        for k, v in pairs(cache[lastUsed]) do st.current[k] = v end
        st.current.count = GetItemCount(lastUsed) or 0
    end
    st.display = st.current or st.pick
    st.verdict = st.eating and "ok" or (st.pick and "ready" or "none")
    return st
end
function M.Attrs(item, st)
    if not item then return {} end
    if st.eating or UnitIsDeadOrGhost("player") then return { mealSlot = item.id } end
    return { type1 = "macro", macrotext1 = "/stopmacro [combat]\n/use item:" .. item.id, mealItem = item.id, mealSlot = item.id }
end
function M.Post(b, button, choose)
    local h = b.host
    if not h or h.edit or InCombatLockdown() then return end
    local id = tonumber(b:GetAttribute("mealItem"))
    if button == "LeftButton" and id then lastUsed = id end
    if not choose and button ~= "RightButton" then return end
    if button ~= "RightButton" and not id then return end
    local value = button == "LeftButton" and id or nil
    local at = h.addr
    if at and ns.buffbar then
        ns.buffbar:SetWidgetOpt(at[1], at[2], at[3], "item", value)
    else
        h.opt.item = value
        ns.Widget.SetOpt(h, h.opt)
    end
end
function M.Tip(item)
    if not item then return ns.T("widget.f_nofood") end
    local lines = {}
    for i, text in ipairs(item.lines) do lines[i] = text end
    lines[#lines + 1] = ns.T("widget.f_bags", item.count)
    return item.name, table.concat(lines, "\n")
end
function M.Choices()
    local out = { { v = nil, text = ns.T("widget.meal_auto") } }
    for _, item in ipairs(M.State({}).items) do
        out[#out + 1] = { v = item.id, icon = item.icon, text = item.name }
    end
    return out
end
local ev = CreateFrame("Frame")
ev:RegisterEvent("BAG_UPDATE")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_LEVEL_UP")
ev:SetScript("OnEvent", function()
    bagItems = nil
    if ns.Widget then ns.Widget.Poke("meal") end
end)
