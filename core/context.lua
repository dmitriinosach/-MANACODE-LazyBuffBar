local _, ns = ...
function ns.GetSpec(group)
    group = group or ns.ActiveSlot()
    local bestIndex, bestName, bestPoints = nil, nil, -1
    local secondPoints, total = -1, 0
    for i = 1, (GetNumTalentTabs and GetNumTalentTabs()) or 0 do
        local name, _, points = GetTalentTabInfo(i, false, false, group)
        points = points or 0
        total = total + points
        if points > bestPoints then
            secondPoints = bestPoints
            bestIndex, bestName, bestPoints = i, name, points
        elseif points > secondPoints then
            secondPoints = points
        end
    end
    local confident = bestPoints >= 20 and (bestPoints - secondPoints) >= 10
    return bestIndex, bestName, bestPoints, confident, total
end
function ns.ActiveSlot()
    return (GetActiveTalentGroup and GetActiveTalentGroup()) or 1
end
function ns.SlotCount()
    return (GetNumTalentGroups and GetNumTalentGroups()) or 1
end
function ns.TalentsKnown()
    return (select(5, ns.GetSpec()) or 0) > 0
end
local lastTab = {}
function ns.BranchVariants(class, tab)
    local out = {}
    local c = ns.specs and ns.specs[class]
    if not c then return out end
    for _, key in ipairs(c.order) do
        if c.variants[key].tab == tab then out[#out + 1] = key end
    end
    return out
end
local function choices(create)
    if not (ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded()) then return nil end
    local char = ns.Profile.Char()
    if create and type(char.variant) ~= "table" then char.variant = {} end
    return type(char.variant) == "table" and char.variant or nil
end
function ns.CurrentTab(group)
    group = group or ns.ActiveSlot()
    local tab, _, _, _, total = ns.GetSpec(group)
    if (total or 0) > 0 then
        lastTab[group] = tab
    elseif lastTab[group] then
        tab = lastTab[group]
    end
    return tab or 1
end
function ns.VariantChoice(group)
    local c = choices()
    return c and c[group or ns.ActiveSlot()] or nil
end
function ns.CurrentVariant(group)
    group = group or ns.ActiveSlot()
    local _, class = UnitClass("player")
    local tab = ns.CurrentTab(group)
    local picked = ns.VariantChoice(group)
    local info = picked and ns.SpecInfo and ns.SpecInfo(class, picked)
    if info and info.tab == tab then return picked end
    local v = ns.DefaultVariant and ns.DefaultVariant(class, tab)
    if not v then
        local c = ns.specs and ns.specs[class]
        v = (c and c.order[1]) or tab
    end
    return v
end
local pendingVariant = {}
function ns.SetVariant(key, group)
    group = group or ns.ActiveSlot()
    if key == "auto" or key == "" then key = nil end
    if key ~= nil then
        local _, class = UnitClass("player")
        local info = ns.SpecInfo and ns.SpecInfo(class, key)
        if not (info and info.tab == ns.CurrentTab(group)) then return false, "bad" end
    end
    local c = choices(true)
    if not c then return false, "bad" end
    if InCombatLockdown() then
        if pendingVariant[group] == nil then
            ns.Defer(function()
                local k = pendingVariant[group]
                pendingVariant[group] = nil
                if k ~= nil then ns.SetVariant(k or "auto", group) end
            end)
        end
        pendingVariant[group] = key or false
        return true, "later"
    end
    if c[group] == key then return true end
    c[group] = key
    if not next(c) then ns.Profile.Char().variant = nil end
    if ns.ForgetSpec then ns.ForgetSpec() end
    return true
end
function ns.SpecFrom(bySpec, class, variant)
    if not bySpec then return nil end
    if variant ~= nil and bySpec[variant] ~= nil then return bySpec[variant] end
    local info = ns.SpecInfo and ns.SpecInfo(class, variant)
    if info then
        if info.base and bySpec[info.base] ~= nil then return bySpec[info.base] end
        if info.tab and bySpec[info.tab] ~= nil then return bySpec[info.tab] end
    end
    if type(variant) == "number" and bySpec[variant] ~= nil then return bySpec[variant] end
    return nil
end
function ns.SpecData(store, class, variant)
    return ns.SpecFrom(store and store[class], class, variant)
end
