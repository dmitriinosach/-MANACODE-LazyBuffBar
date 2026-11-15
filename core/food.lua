local _, ns = ...
ns.Food = {}
local F = ns.Food
local function data()
    return ns.widgetData.food
end
local scans = {}
local bags
local feastSet
local tip = CreateFrame("GameTooltip", "LazyBuffBarFoodTip", nil, "GameTooltipTemplate")
local function wellFedName()
    return (GetSpellInfo(data().wellFed))
end
function F.Buff()
    local name = wellFedName()
    if not name then return nil end
    local n, _, icon, _, _, dur, expires, _, _, _, sid = UnitBuff("player", name)
    if not n then return nil end
    return n, icon, expires, dur, sid
end
function F.IsFeast(id)
    if not feastSet then
        feastSet = {}
        for _, f in ipairs(data().feasts) do feastSet[f] = true end
    end
    return feastSet[id] or false
end
function F.Bags()
    if bags then return bags end
    bags = {}
    for _, f in ipairs(data().foods) do
        local c = GetItemCount(f.id) or 0
        if c > 0 then bags[#bags + 1] = { id = f.id, aura = f.aura, count = c } end
    end
    return bags
end
local function inBags(id)
    if not id then return nil end
    for _, b in ipairs(F.Bags()) do
        if b.id == id then return b end
    end
    return nil
end
local function lastAura()
    local char = ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded() and ns.Profile.Char()
    return char and tonumber(char.foodAura) or nil
end
function F.Pick(opt)
    local own = inBags(opt and opt.item)
    if own then return own end
    local list = F.Bags()
    local last = lastAura()
    if last then
        for _, b in ipairs(list) do
            if b.aura == last then return b end
        end
    end
    return list[1]
end
function F.Known(sid)
    return sid and data().auras[sid] or nil
end
function F.ItemOf(sid)
    local a = F.Known(sid)
    if a then return a.item end
    return sid and ns.Catalog and ns.Catalog.FoodItem and ns.Catalog.FoodItem(sid) or nil
end
local function withIcon(id, text)
    local icon = id and GetItemIcon(id)
    if not icon then return text end
    return "|T" .. icon .. ":14:14|t " .. text
end
function F.Scanned(sid)
    return sid and scans[sid] or nil
end
local function clean(s)
    if not s then return nil end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:match("^%s*(.-)%s*$")
    if s == "" then return nil end
    return s
end
local function scan(sid)
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tip:ClearLines()
    tip:SetHyperlink("spell:" .. sid)
    local name, text = tip:GetName(), nil
    for i = (tip:NumLines() or 0), 2, -1 do
        local l = _G[name .. "TextLeft" .. i]
        text = l and clean(l:GetText()) or nil
        if text then break end
    end
    tip:Hide()
    local n = text and tonumber(text:match("(%d+)")) or nil
    return { n = n, text = text }
end
local function seen(sid)
    if not sid then return false end
    if F.Known(sid) then
        local char = ns.Profile and ns.Profile.Loaded and ns.Profile.Loaded() and ns.Profile.Char()
        if char and char.foodAura ~= sid then char.foodAura = sid end
        return false
    end
    if scans[sid] then return false end
    scans[sid] = scan(sid)
    return true
end
local function statText(a)
    if a.stat == "both" then
        return ns.T("widget.f_s_both", a.n, a.sp or 0), ns.T("widget.f_l_both", a.n, a.sp or 0, a.sta)
    end
    return ns.T("widget.f_s_" .. a.stat, a.n), ns.T("widget.f_l", ns.T("widget.f_l_" .. a.stat, a.n), a.sta)
end
local function itemName(id)
    local n = GetItemInfo(id)
    if n then return n end
    local src = ns.Catalog and ns.Catalog.SourceName and ns.Catalog.SourceName("i" .. id)
    return src or ("#" .. id)
end
function F.State(opt)
    local d = data()
    local st = { verdict = "none", stat = "", count = 0, bags = #F.Bags() }
    local name, icon, expires, _, sid = F.Buff()
    local p = F.Pick(opt)
    if p then st.pick, st.count = p.id, p.count end
    if name then
        st.sid = sid
        local a = F.Known(sid)
        st.food = F.ItemOf(sid)
        st.have = st.food and (GetItemCount(st.food) or 0) or nil
        if a then
            st.stat, st.line = statText(a)
        else
            local s = F.Scanned(sid)
            if s and s.n then st.stat = ns.T("widget.f_s_plus", s.n) end
            st.line = s and s.text or nil
        end
        local buff = opt and opt.icon == "buff"
        st.icon = (not buff and st.food and GetItemIcon(st.food)) or icon
        local food = sid and ns.Catalog and ns.Catalog.FoodName and ns.Catalog.FoodName(sid)
        st.ate = food or (st.food and itemName(st.food)) or name
        if expires and expires > 0 then
            st.left = math.max(0, expires - GetTime())
            st.verdict = st.left < d.soon and "soon" or "ok"
        else
            st.verdict = "ok"
        end
    else
        st.icon = p and GetItemIcon(p.id) or select(3, GetSpellInfo(d.wellFed))
    end
    return st
end
function F.Tick(st)
    if not st.left then return nil end
    if st.left > data().soon + data().slow then return data().slow end
    return 1
end
function F.Click(st)
    if st.verdict == "ok" or not st.pick then return {} end
    return { type = "item", item = "item:" .. st.pick }
end
local TIP_WHITE, TIP_ON, TIP_BAD = { 1, 1, 1 }, { 0.4, 1, 0.4 }, { 1, 0.35, 0.35 }
local function tipTime(t)
    if t >= 60 then return ns.T("tip.min", math.ceil(t / 60)) end
    return ns.T("tip.sec", math.ceil(t))
end
function F.Lines(st)
    local lines = {}
    if st.line then lines[#lines + 1] = { text = st.line, color = TIP_WHITE } end
    local on = (st.left and st.left > 0) and ns.T("tip.on", tipTime(st.left)) or ns.T("tip.on_up")
    lines[#lines + 1] = { text = on, color = TIP_ON }
    if st.have and st.have > 0 then
        lines[#lines + 1] = { text = ns.T("tip.bag", st.have), color = TIP_WHITE }
    elseif st.have then
        lines[#lines + 1] = { text = ns.T("tip.no_bag"), color = TIP_BAD }
    end
    return withIcon(st.food, st.ate), lines
end
function F.Tip(st)
    if st.sid then
        local title, lines = F.Lines(st)
        local out = {}
        for i, l in ipairs(lines) do
            local c = l.color
            out[i] = c == TIP_WHITE and l.text
                or ("|cff%02x%02x%02x%s|r"):format(c[1] * 255, c[2] * 255, c[3] * 255, l.text)
        end
        return title, table.concat(out, "\n")
    end
    if st.pick then return withIcon(st.pick, itemName(st.pick)), ns.T("widget.f_bags", st.count) end
    return ns.T("widget.f_nofood"), nil
end
function F.Caption(st)
    if not st.pick then return ns.T("widget.f_nofood") end
    return itemName(st.pick) .. ns.T("facts.sep") .. ns.T("widget.f_bags", st.count)
end
function F.Choices()
    local out = {}
    for _, b in ipairs(F.Bags()) do
        out[#out + 1] = { v = b.id, icon = GetItemIcon(b.id), text = itemName(b.id) }
    end
    return out
end
function F.Reset()
    scans, bags = {}, nil
end
local ev = CreateFrame("Frame")
ev:RegisterEvent("BAG_UPDATE")
ev:RegisterEvent("UNIT_AURA")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then
        if unit ~= "player" then return end
        local _, _, _, _, sid = F.Buff()
        if seen(sid) then ns.Widget.Poke("food") end
        return
    end
    bags = nil
    if event == "PLAYER_ENTERING_WORLD" then
        local _, _, _, _, sid = F.Buff()
        seen(sid)
    end
    ns.Widget.Poke("food")
end)
ns.foodLoaded = true
