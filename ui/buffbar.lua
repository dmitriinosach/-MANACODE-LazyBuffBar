local _, ns = ...
local ICON = 32
local ROWGAP = 6
local SLEEP_ALPHA = 0.35
local ACT_NO_TARGET = 0.4
local NUM_MAIN, NUM_EDGE, NUM_COUNT = 13, 9, 13
local function numSize(fs, px, role)
    fs._px, fs._role = px, role or "time"
    local file, _, flags = fs:GetFont()
    fs._file0, fs._flags0 = file, flags
    if file then fs:SetFont(file, px, flags) end
end
local function sizeDigits(f)
    local kt, ks = ns.Look.FontScale("time"), ns.Look.FontScale("stack")
    local st = f._st
    local key = kt .. "," .. ks .. (st and (tostring(st.nscale) .. st.outline .. st.place) or "") .. ns.Style.Global("font")
    if f._fontK == key then return end
    f._fontK = key
    for _, fs in ipairs(f.digits) do ns.Style.Font(f, fs) end
end
local TIME_Y = -1
local SPOTS = {
    top    = { time = { "TOP", 0, TIME_Y }, count = { "BOTTOMRIGHT", -2, 2 }, hand = { "BOTTOMLEFT", 2, 1 },
               group = { "BOTTOM", 0, 0 }, gtime = { "CENTER", 0, 0 }, warn = { "TOPRIGHT", -2, -1 } },
    center = { time = { "CENTER", 0, 0 }, count = { "TOPRIGHT", -2, -2 }, hand = { "TOPLEFT", 2, -1 },
               group = { "TOPLEFT", 2, -1 }, gtime = { "BOTTOM", 0, 1 }, warn = { "BOTTOMRIGHT", -2, 1 } },
    bottom = { time = { "BOTTOM", 0, 1 }, count = { "TOPRIGHT", -2, -2 }, hand = { "TOPLEFT", 2, -1 },
               group = { "TOPLEFT", 2, -1 }, gtime = { "CENTER", 0, 0 }, warn = { "BOTTOMRIGHT", -2, 1 } },
}
SPOTS.big = SPOTS.center
SPOTS.corner = { time = { "BOTTOMRIGHT", -1, 1 }, count = { "TOPRIGHT", -2, -2 }, hand = { "TOPLEFT", 2, -1 },
                 group = { "TOPLEFT", 2, -1 }, gtime = { "CENTER", 0, 0 }, warn = { "BOTTOMLEFT", 2, 1 } }
SPOTS.above = { time = { "BOTTOM", 0, 1, "TOP" }, count = { "BOTTOMRIGHT", -2, 2 }, hand = { "BOTTOMLEFT", 2, 1 },
                group = { "TOPLEFT", 2, -1 }, gtime = { "CENTER", 0, 0 }, warn = { "TOPRIGHT", -2, -1 } }
local function spotsFor(f)
    local p = ns.Style.Place(f)
    local m = (p and p ~= "none" and p) or f._dmode or "top"
    return SPOTS[m] or SPOTS.top, m
end
local function put(fs, f, spot)
    local key = spot[1] .. spot[2] .. "," .. spot[3] .. (spot[4] or "")
    if fs._at == key then return end
    fs._at = key
    fs:ClearAllPoints()
    fs:SetPoint(spot[1], f, spot[4] or spot[1], spot[2], spot[3])
    if not fs.SetJustifyH then return end
    if spot[1]:find("LEFT") then
        fs:SetJustifyH("LEFT")
    elseif spot[1]:find("RIGHT") then
        fs:SetJustifyH("RIGHT")
    else
        fs:SetJustifyH("CENTER")
    end
end
local function placeOmni(f, spot)
    local omni = type(OmniCC) == "table" and OmniCC.Timer
    local timer = omni and omni.Get and omni:Get(f.cd)
    local text = timer and timer.text
    if not (text and timer.fontSize) then return end
    put(text, f, spot)
    local want = timer.fontSize * ns.Look.FontScale("time")
    local file, size, flags = text:GetFont()
    if file and size and math.abs(size - want) > 0.5 then text:SetFont(file, want, flags) end
end
local BAG_SPOT = { bottom = { "BOTTOMRIGHT", -2, 2 }, top = { "TOPRIGHT", -2, -2 } }
local WARN_FLIP = { BOTTOMRIGHT = { "TOPRIGHT", -2, -1 }, TOPRIGHT = { "BOTTOMRIGHT", -2, 1 } }
local MID = { "CENTER", 0, 0 }
local function half(spot)
    if spot[4] then return nil end
    return spot[1]:match("^TOP") or spot[1]:match("^BOTTOM")
end
local function bagSpots(f, s)
    local c = BAG_SPOT[ns.Style.Of(f, "bag")]
    if not c then return s.count, s.time end
    if half(s.time) and half(s.time) == half(c) then return c, MID end
    return c, s.time
end
local function layoutBuff(f, label)
    local s = spotsFor(f)
    local count, time = s.count, s.time
    if f._kind == "item" then count, time = bagSpots(f, s) end
    put(f.left, f, time)
    put(f.count, f, count)
    put(f.rmin, f, s.gtime)
    if label then put(f.rn, f, s[label]) end
    placeOmni(f, time)
end
local WARN_COLOR = { 1, 0.15, 0.15 }
local function warnMark(f)
    if f.warn then return f.warn end
    f.warn = f.txt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    local file, size = f.warn:GetFont()
    if file then f.warn:SetFont(file, size, "OUTLINE") end
    f.warn:SetText("!")
    f.warn:SetTextColor(WARN_COLOR[1], WARN_COLOR[2], WARN_COLOR[3])
    f.warn:Hide()
    return f.warn
end
local function paintWarn(f)
    if not ((f._why and f._why ~= "passive") or f._miss) then
        if f.warn then f.warn:Hide() end
        return
    end
    local w = warnMark(f)
    local spot = spotsFor(f).warn
    local bag = f._kind == "item" and BAG_SPOT[ns.Style.Of(f, "bag")]
    if bag and bag[1] == spot[1] then spot = WARN_FLIP[spot[1]] or spot end
    put(w, f, spot)
    w:Show()
end
local function warnLine(self)
    if not self._why then return end
    GameTooltip:AddLine(ns.Avail.Text(self._why, self._what), WARN_COLOR[1], 0.35, 0.35, true)
end
local TRACK_TICK = 0.1
local BUFF_TICK  = 1.0
local bar, host
local icons = {}
local ticons = {}
local STACK_OFF = 4
local STACK_SZ  = ICON - 8
local FLIP      = 0.22
local flipping  = {}
ns.buffbar = {}
local function hiddenBy(show, active, stacks, full)
    if show == "on" then return not active end
    if show == "off" then return active and true or false end
    if show == "low" then return (active and full and (stacks or 0) >= full) and true or false end
    return false
end
local function actCan(st)
    return (st.active and not (st.noTarget or st.noCause or st.noMana or st.unusable or st.far)) and true or false
end
local function cfg()
    LazyBuffBarDB = LazyBuffBarDB or {}
    return LazyBuffBarDB
end
local function locked() return cfg().locked and true or false end
local function inConfig() return not locked() end
local function ruleHidden(f)
    local r = f and f._item and f._item.rules
    return r ~= nil and not inConfig() and not ns.Cond.RulesPass(r)
end
local function barScale(i)
    local b = ns.Preset and ns.Preset.Blocks()[i]
    return (b and b.scale) or cfg().scale or 1
end
local function foodBuff(e)
    if not e then return nil end
    local set = ns.BuffNameSet(e)
    for i = 1, 40 do
        local n, _, _, _, _, _, _, _, _, _, sid = UnitBuff("player", i)
        if not n then break end
        if set[n] then return i, sid end
    end
    return nil
end
local function foodTip(self)
    local i, sid = foodBuff(self._entry)
    local st = i and ns.Food and ns.Food.State(nil)
    if st and st.sid == sid and (st.food or st.line) then
        local title, lines = ns.Food.Lines(st)
        GameTooltip:AddLine(title, 1, 1, 1)
        for _, l in ipairs(lines) do GameTooltip:AddLine(l.text, l.color[1], l.color[2], l.color[3], true) end
        return
    end
    if i then
        GameTooltip:SetUnitBuff("player", i)
        local food = sid and ns.Catalog and ns.Catalog.FoodLabel and ns.Catalog.FoodLabel(sid)
        if food then GameTooltip:AddLine(ns.T("food.ate", food), 1, 1, 1, true) end
        return
    end
    GameTooltip:AddLine(ns.T("food.title"), 1, 1, 1)
    if ns.HelpTips() then GameTooltip:AddLine(ns.T("food.body"), 1, 0.82, 0, true) end
    if not self.tipOn then
        GameTooltip:AddLine(ns.T("food.off"), 1, 0.35, 0.35, true)
    end
end
local OWN_TIP = { food = foodTip }
local function foodTex(f, entry)
    if entry.tipKind ~= "food" or not (f._item and f._item.foodIcon) then return nil end
    local _, sid = foodBuff(entry)
    local id = sid and ns.Food and ns.Food.ItemOf and ns.Food.ItemOf(sid)
    return id and GetItemIcon(id) or nil
end
local blessNext = ns.BlessClick.Next
local function blessFar(b)
    local k = 0
    for _, s in ipairs((ns.BlessingQueue(b))) do
        if s.state == "far" then k = k + 1 end
    end
    return k
end
local LIST_ROWS = 14
local LIST_NAMES = 3
local STATE_COLOR = {
    need = { 1, 0.35, 0.35 }, low = { 1, 0.65, 0.25 }, far = { 0.6, 0.6, 0.6 }, dead = { 0.5, 0.5, 0.5 },
    off = { 0.4, 0.4, 0.4 }, sent = { 0.55, 0.9, 0.55 }, has = { 0.85, 0.85, 0.85 },
}
local NEXT_COLOR = { 1, 0.82, 0 }
local function listLeft(left)
    if not left then return "" end
    if left == 0 then return ns.T("bless.forever") end
    return ns.T("bless.min", math.ceil(left / 60))
end
local function rowState(row)
    local txt
    if row.state == "has" or row.state == "low" then
        txt = listLeft(row.left)
    else
        txt = ns.T("bless.st_" .. row.state)
    end
    if row.total then txt = row.have .. "/" .. row.total .. " " .. txt end
    return txt
end
local function rowLabel(row)
    local miss = row.miss
    if not miss or #miss == 0 or row.state == "has" then return row.label end
    local names = {}
    for i = 1, math.min(#miss, LIST_NAMES) do names[i] = miss[i] end
    local tail = (#miss > LIST_NAMES) and "…" or ""
    return row.label .. ": " .. table.concat(names, ", ") .. tail
end
local function listLine(label, class, state, color)
    local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    GameTooltip:AddDoubleLine(label, state, cc and cc.r or 1, cc and cc.g or 1, cc and cc.b or 1,
                              color[1], color[2], color[3])
end
local function blessList(f)
    local rows, spell = ns.BlessingRows(f.bless)
    if not spell or #rows == 0 then return end
    local nextUnit, nextPos, nextN = blessNext(f.click)
    local need, list, hasN, hasMin = 0, {}, 0, nil
    local collapse = #rows > LIST_ROWS
    for _, r in ipairs(rows) do
        if r.state == "need" or r.state == "low" or r.state == "far" or r.state == "dead" then need = need + 1 end
        if collapse and r.state == "has" then
            hasN = hasN + 1
            if r.left and r.left > 0 and (not hasMin or r.left < hasMin) then hasMin = r.left end
        else
            list[#list + 1] = r
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(spell .. "  " .. (need > 0 and ns.T("bless.list_need", need, #rows)
                        or ns.T("bless.list_all", #rows)), NEXT_COLOR[1], NEXT_COLOR[2], NEXT_COLOR[3])
    for _, r in ipairs(list) do
        local label = rowLabel(r)
        if r.unit and r.unit == nextUnit then label = "> " .. label end
        listLine(label, r.class, rowState(r), STATE_COLOR[r.state] or STATE_COLOR.has)
    end
    if hasN > 0 then
        listLine(ns.T("bless.more", hasN), nil,
                 hasMin and ns.T("bless.from", math.ceil(hasMin / 60)) or "", STATE_COLOR.has)
    end
    if nextUnit then
        listLine(ns.T("bless.list_next", UnitName(nextUnit) or "?"), nil, ns.T("bless.of", nextPos, nextN), NEXT_COLOR)
    end
end
local function skipLine(key)
    local e = ns.EDIT.mana
    if ns.BlessPP.Key() == key then GameTooltip:AddLine(ns.T("bless.pp"), e[1], e[2], e[3], true) end
    local skip = ns.BlessSkip(key)
    if not skip then return end
    local d = ns.blessData
    local names = {}
    for _, c in ipairs(d.classes) do
        if skip[c] then names[#names + 1] = ns.CLASS_NAME[c] or c end
    end
    local text = (#names > d.names) and ns.T("bless.skip_n", #names) or ns.T("bless.skip", table.concat(names, ", "))
    if ns.BlessPP.Rules(key) then text = text .. " " .. ns.T("bless.skip_pp") end
    GameTooltip:AddLine(text, 0.6, 0.6, 0.6, true)
end
local function blessTip(self)
    local help = ns.HelpTips()
    if ns.MyBlessing() ~= self.bless.key then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(ns.T("bless.other"), 1, 1, 1, true)
        skipLine(self.bless.key)
        if help then GameTooltip:AddLine(ns.T("bless.pick"), 1, 0.82, 0, true) end
        return
    end
    blessList(self)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(ns.T("bless.mine"), 1, 1, 1, true)
    skipLine(self.bless.key)
    if not self.castGreat then
        GameTooltip:AddLine(ns.T(ns.BlessingWantsPlain() and "bless.plain_pick" or "bless.plain"),
                            1, 0.55, 0.25, true)
    end
    local c = self.click
    local combat = InCombatLockdown()
    local u, pos, total = blessNext(c)
    if u then
        local spell = c:GetAttribute("spell")
        local far = spell and IsSpellInRange and not UnitIsUnit(u, "player") and IsSpellInRange(spell, u) ~= 1
        local _, class = UnitClass(u)
        GameTooltip:AddLine(ns.T(far and "bless.next_far" or "bless.next", ns.CLASS_NAME[class] or "?",
                                 UnitName(u) or "?", pos, total), 1, 1, 1, true)
    elseif combat then
        GameTooltip:AddLine(ns.T("bless.combat_done"), 0.6, 0.6, 0.6, true)
    else
        GameTooltip:AddLine(ns.T("bless.done"), 0.4, 1, 0.4, true)
    end
    if not combat then
        local far = blessFar(self.bless)
        if far > 0 then GameTooltip:AddLine(ns.T("bless.far_left", far), 0.6, 0.6, 0.6, true) end
    end
    if not help then return end
    GameTooltip:AddLine(ns.T("bless.click"), 1, 1, 1, true)
    if not combat then GameTooltip:AddLine(ns.T("bless.flip"), 0.6, 0.6, 0.6, true) end
    if combat then
        GameTooltip:AddLine(ns.T("bless.combat"), 1, 1, 1, true)
        GameTooltip:AddLine(ns.T("bless.back"), 1, 1, 1, true)
    else
        GameTooltip:AddLine(ns.T("bless.drop"), 0.6, 0.6, 0.6, true)
    end
end
local function auraTip(self)
    if self.auraOn then
        GameTooltip:AddLine(ns.T("aura.mine"), 0.4, 1, 0.4, true)
    else
        GameTooltip:AddLine(ns.T("aura.none"), 1, 0.35, 0.35, true)
    end
end
local function noteLine(entry, gap)
    if not ns.HelpTips() then return end
    local t = ns.NoteText(entry)
    if not t then return end
    if gap then GameTooltip:AddLine(" ") end
    GameTooltip:AddLine(t, 0.9, 0.9, 0.9, true)
end
local function wantTip(self)
    local buff = self._entry and self._entry.want
    if not buff then return end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(self.tipOn and ns.T("want.have") or ns.T("want.miss"),
                        self.tipOn and 0.4 or 1, self.tipOn and 0.9 or 0.35,
                        self.tipOn and 0.4 or 0.35, true)
    noteLine(buff)
    if buff.maybe and ns.HelpTips() then GameTooltip:AddLine(ns.T("want.maybe"), 0.85, 0.7, 0.2, true) end
    GameTooltip:AddLine(ns.T("want.givers", ns.Incoming.Givers(buff)), 0.6, 0.8, 1, true)
end
local function weaponTip(self)
    local e = self._entry
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(ns.T("weapon." .. e.hand), 1, 1, 1)
    local left = ns.Weapon.Left(e.hand)
    if left then
        GameTooltip:AddLine(ns.T("weapon.left", math.ceil(left / 60)), 0.4, 1, 0.4, true)
    else
        GameTooltip:AddLine(ns.T("weapon.none"), 1, 0.35, 0.35, true)
    end
    if ns.Weapon.NeedsStone(e) then
        GameTooltip:AddLine(ns.T("weapon.stone"), 1, 0.82, 0, true)
    end
    noteLine(e)
end
local function tipTime(t)
    if t >= 60 then return ns.T("tip.min", math.ceil(t / 60)) end
    return ns.T("tip.sec", math.ceil(t))
end
local function auraState(on, left, stacks)
    if not on then
        GameTooltip:AddLine(ns.T("tip.off"), 1, 0.35, 0.35, true)
        return
    end
    GameTooltip:AddLine((left and left > 0) and ns.T("tip.on", tipTime(left)) or ns.T("tip.on_up"), 0.4, 1, 0.4, true)
    if stacks and stacks > 1 then GameTooltip:AddLine(ns.T("tip.stacks", stacks), 1, 1, 1, true) end
end
local function buffState(self)
    local e = self._entry
    if not e then return end
    local name = not e.single and ns.ActiveBuffName(self._self or e)
    auraState(self.tipOn, name and ns.BuffLeft(name), nil)
    if e._cat == "raid" and not e.single and ns.GroupBuffNumbers then
        local n, total = ns.GroupBuffNumbers(e)
        if total > 1 then GameTooltip:AddLine(ns.T("tip.group", n, total), 1, 1, 1, true) end
    end
end
local function itemState(self)
    local e = self._entry
    if not (e and e.item) then return end
    local aura = e.aura or e.buff
    local name = aura and GetSpellInfo(aura)
    local on = name and ns.HasBuff(name)
    if e.aura or on then auraState(on, on and ns.BuffLeft and ns.BuffLeft(name) or nil, nil) end
    local bag = (GetItemCount and GetItemCount(e.item)) or 0
    if bag > 0 then
        GameTooltip:AddLine(ns.T("tip.bag", bag), 1, 1, 1, true)
    else
        GameTooltip:AddLine(ns.T("tip.no_bag"), 1, 0.35, 0.35, true)
    end
end
local function iconTipsNow()
    local v = cfg().iconTips or "ooc"
    if v == "never" then return false end
    if v == "always" then return true end
    return not (InCombatLockdown() or UnitAffectingCombat("player"))
end
local function linkName(link)
    local kind, id = link:match("^(%a+):(%d+)")
    if kind == "spell" then return (GetSpellInfo(tonumber(id))) end
    if kind == "item" then return (GetItemInfo(tonumber(id))) end
    return link:match("|h%[(.-)%]|h") or (GetItemInfo(link))
end
local function tipHead(self, link)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local name = linkName(link)
    if not name then
        GameTooltip:SetHyperlink(link)
        return
    end
    GameTooltip:SetText(name, 1, 1, 1)
    if not ns.HelpTips() then return end
    local facts = ns.Facts and ns.Facts.Line and ns.Facts.Line(link)
    if facts then GameTooltip:AddLine(facts, 0.6, 0.6, 0.6, true) end
end
local function itemEnter(self)
    if inConfig() or not iconTipsNow() then
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        return
    end
    local own = self.tipKind and OWN_TIP[self.tipKind]
    if own then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        own(self)
        GameTooltip:Show()
    elseif self.spellId then
        tipHead(self, "spell:" .. self.spellId)
        warnLine(self)
        if self._entry and self._entry.hand then weaponTip(self) end
        if self.bless then blessTip(self) end
        if self.auraOn ~= nil then GameTooltip:AddLine(" "); auraTip(self) end
        if self._entry and self._entry.want then wantTip(self) end
        if self._entry and not self._entry.hand and not self._entry.want and not self.bless and self.auraOn == nil then
            buffState(self)
        end
        if self._entry and not self._entry.hand and not self._entry.want then noteLine(self._entry, true) end
        GameTooltip:Show()
    elseif self.itemId then
        tipHead(self, "item:" .. self.itemId)
        warnLine(self)
        itemState(self)
        noteLine(self._entry, true)
        GameTooltip:Show()
    end
end
local function makeClick(f, i)
    local c = CreateFrame("Button", "LazyBuffBarBtn" .. i, bar, "SecureActionButtonTemplate")
    c:SetWidth(ICON)
    c:SetHeight(ICON)
    c:RegisterForClicks("AnyUp")
    c:RegisterForDrag("LeftButton")
    c.vis = f
    f.click = c
    c:SetScript("PostClick", function(self, button)
        local v = self.vis
        local mine = v.bless and ns.MyBlessing() == v.bless.key
        if mine and button == "LeftButton" then ns.BlessingAimed(self:GetAttribute("unit")) end
        if InCombatLockdown() then
            if mine then ns.buffbar:RefreshBless() end
            return
        end
        if button == "RightButton" then
            if v.bless then
                ns.SetMyBlessing(ns.MyBlessing() ~= v.bless.key and v.bless.key or nil)
            end
            return
        end
        if mine then ns.buffbar:RefreshBless() else ns.buffbar:Update() end
    end)
    c:SetScript("OnEnter", function(self)
        if not ruleHidden(self.vis) then itemEnter(self.vis) end
        ns.Style.Hover(self.vis, true)
        ns.Blocks.EnterIcon(self:GetParent())
    end)
    c:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        ns.Style.Hover(self.vis, false)
        ns.Blocks.LeaveIcon(self:GetParent())
    end)
    c:EnableMouseWheel(false)
    c:SetScript("OnMouseWheel", function(self, delta)
        if InCombatLockdown() or not IsControlKeyDown() then return end
        ns.buffbar:FlipBlessing(self.vis, delta < 0)
    end)
    c:SetScript("OnDragStart", function(self) ns.Blocks.GrabIcon(self:GetParent(), self.vis._cx, self.vis._cy) end)
    c:SetScript("OnDragStop", function(self)
        local p = self:GetParent()
        if p then ns.Blocks.Drop(p) end
    end)
    c:SetScript("OnReceiveDrag", function(self) ns.Blocks.DropItem(self:GetParent()._key, self.vis._cx, self.vis._cy) end)
    c:Hide()
    return c
end
local function face(f, cdName)
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints(f)
    f.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.glow = CreateFrame("Frame", nil, f)
    f.glow:SetFrameLevel(f:GetFrameLevel() + 6)
    f.glow:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
    f.glow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
    f.glow:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    f.glow:SetBackdropBorderColor(1, 0.15, 0.15, 1)
    f.glow:Hide()
    f.cd = CreateFrame("Cooldown", cdName, f, "CooldownFrameTemplate")
    f.cd:SetAllPoints(f)
    f.cd:SetReverse(true)
    f.cd:Hide()
    f.cd.noCooldownCount = true
    ns.Look.AttachEdge(f)
    f.txt = CreateFrame("Frame", nil, f)
    f.txt:SetAllPoints(f)
    f.txt:SetFrameLevel(f.cd:GetFrameLevel() + 5)
    f.count = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    numSize(f.count, NUM_COUNT, "stack")
    f.count:Hide()
    f.left = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    f.left:SetPoint("TOP", f, "TOP", 0, TIME_Y)
    f.left:SetWidth(ICON); f.left:SetJustifyH("CENTER")
    numSize(f.left, NUM_MAIN)
    f.left._main = true
    f.left:Hide()
    f.rmin = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    f.rmin:SetPoint("TOP", f, "TOP", 0, TIME_Y)
    f.rmin:SetWidth(ICON); f.rmin:SetJustifyH("CENTER")
    numSize(f.rmin, NUM_EDGE)
    f.rmin:Hide()
    f.rn = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    f.rn:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
    f.rn:SetWidth(ICON); f.rn:SetJustifyH("CENTER")
    numSize(f.rn, NUM_EDGE, "stack")
    f.rn:Hide()
    f.digits = { f.count, f.left, f.rmin, f.rn }
    f.stack = f:CreateTexture(nil, "BACKGROUND")
    f.stack:SetWidth(STACK_SZ)
    f.stack:SetHeight(STACK_SZ)
    f.stack:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.stack:SetPoint("TOPLEFT", f, "TOPLEFT", -STACK_OFF, STACK_OFF)
    f.stack:SetAlpha(0.75)
    f.stack:Hide()
    f.mark = f.txt:CreateTexture(nil, "OVERLAY")
    f.mark:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.mark:SetHeight(3)
    f.mark:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    f.mark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    f.mark:Hide()
    f.ppmark = f.txt:CreateTexture(nil, "OVERLAY")
    f.ppmark:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.ppmark:SetHeight(2)
    f.ppmark:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    f.ppmark:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    f.ppmark:SetVertexColor(ns.EDIT.mana[1], ns.EDIT.mana[2], ns.EDIT.mana[3], 1)
    f.ppmark:Hide()
end
local function acquireIcon(i)
    local f = icons[i]
    if not f then
        f = CreateFrame("Frame", nil, bar)
        f:SetWidth(ICON)
        f:SetHeight(ICON)
        face(f, "LazyBuffBarCooldown" .. i)
        makeClick(f, i)
        icons[i] = f
    end
    return f
end
local function placeClick(f)
    local c = f.click
    if not c or InCombatLockdown() then return end
    local fr = f:GetParent()
    c:SetParent(fr)
    c:SetFrameLevel(ns.Blocks.ClickLevel(fr))
    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", fr, "TOPLEFT", f._bx, -f._by)
    c:EnableMouseWheel((not inConfig() and f.bless and ns.MyBlessing() == f.bless.key) and true or false)
    c:Show()
end
local GAUGE_VIEWS = { pips = true, segments = true, ring = true, fill = true }
local function gaugeOf(f, kind)
    f.gauges = f.gauges or {}
    local g = f.gauges[kind]
    if g then return g end
    local spec
    if kind == "ring" then
        spec = { w = ICON - 4, h = ICON - 4, flash = false, rim = true }
    elseif kind == "fill" then
        spec = { w = ICON, h = ICON, color = { 1, 0.82, 0, 0.35 }, full = { 0.3, 1, 0.3, 0.45 }, flash = false }
    else
        spec = { w = ICON - 4, h = 6, gap = 2, flash = false, rim = true }
    end
    g = ns.Gauge.New(f.txt, kind, spec)
    local fr = g:Frame()
    fr:SetFrameLevel(f.txt:GetFrameLevel() + 1)
    if kind == "ring" or kind == "fill" then
        fr:SetPoint("CENTER", f, "CENTER", 0, 0)
    else
        fr:SetPoint("BOTTOM", f, "BOTTOM", 0, 2)
    end
    f.gauges[kind] = g
    return g
end
local function paintStacks(f, n)
    local view = f._item and f._item.view
    local kind = GAUGE_VIEWS[view or ""] and view or nil
    for k, g in pairs(f.gauges or {}) do
        if k ~= kind then g:Hide() end
    end
    f.gauge = kind and gaugeOf(f, kind) or nil
    if not kind then return false end
    if not n or n <= 0 then f.gauge:Hide(); return true end
    local key = f._item.k
    if f._maxKey ~= key then
        local fx = ns.Facts.Of(f._item)
        f._maxStacks = fx.stacks
        if fx.stacks then f._maxKey = key end
    end
    local max = f._maxStacks or 5
    if n > max then max = n end
    f.gauge:Set(n, max)
    f.gauge:Show()
    return true
end
local function asleep(f)
    local r = f._item and f._item.rules
    return r ~= nil and not ns.Cond.RulesPass(r)
end
local function setCount(f, n)
    if paintStacks(f, n) then
        f.count:Hide()
        return (n and n > 0) and true or false
    end
    if not n or n <= 0 then
        f.count:Hide()
        ns.Style.Stacks(f, f.count, nil)
        return false
    end
    f.count:SetText(n > 999 and "*" or n)
    f.count:Show()
    ns.Style.Stacks(f, f.count, n)
    return true
end
local function ownDigits()
    return ns.Look.Get("digits") ~= "omnicc"
end
local function absentAlpha(f)
    return ns.Look.Absent(f)
end
local function sweepAlpha()
    return ns.Look.Get("sweep")
end
local function sweepTo(f, start, dur, rev, alpha)
    ns.Style.Sweep(f, start, dur, rev, alpha)
end
local function previewing(f)
    return (f._preview and f._preview > GetTime()) and true or false
end
local function sweepOff(f)
    if previewing(f) then return end
    ns.Style.SweepOff(f)
end
local function setBuffSweep(f, name)
    local left, duration, start, count = nil, nil, nil, nil
    if name and ns.BuffLeft then left, duration, start, count = ns.BuffLeft(name) end
    if left and duration and duration > 0 and start then
        sweepTo(f, start, duration, true, sweepAlpha())
    else
        sweepOff(f)
    end
    return left, count
end
local function texDesat(f, on)
    on = on and true or false
    if f._td == on then return end
    f._td = on
    f.tex:SetDesaturated(on)
end
local function texColor(f, r, g, b)
    if f._tr == r and f._tg == g and f._tb == b then return end
    f._tr, f._tg, f._tb = r, g, b
    f.tex:SetVertexColor(r, g, b)
end
local function setDim(f, dim)
    f._dim = dim
    if not f._flip then f.tex:SetAlpha(dim * (f._dimMul or 1)) end
end
local function paintHas(f, has)
    if f._entry and f._entry.excess then
        f.tipOn = has
        texDesat(f, not has)
        setDim(f, has and 1 or absentAlpha(f))
        if has and not f._why then f.glow:Show() else f.glow:Hide() end
        if f._miss then
            f._miss = nil
            paintWarn(f)
        end
        ns.Style.State(f, has and "miss" or "off")
        return
    end
    f.tipOn = has
    texDesat(f, not has)
    local soft = f._entry and f._entry.soft
    local quiet = not has and not f._why and not soft and ns.Style.Colored(f)
    setDim(f, has and 1 or (quiet and ns.Style.MISS_DIM or absentAlpha(f)))
    if has or f._why or soft or quiet then f.glow:Hide() else f.glow:Show() end
    if (quiet or nil) ~= f._miss then
        f._miss = quiet or nil
        paintWarn(f)
    end
    ns.Style.State(f, has and "up" or (f._why and "off") or "miss")
end
local BLESS_IDLE = { 0.65, 0.65, 0.65 }
local function groupInk(f, n, total)
    local c = ns.STATE.text
    local b = n and f.bless
    if b then
        local mine = ns.MyBlessing()
        if n >= total then c = ns.STATE.ok
        elseif mine == b.key then c = ns.STATE.soon
        elseif mine then c = BLESS_IDLE end
    end
    if f._rnInk == c then return end
    f._rnInk = c
    f.rn:SetTextColor(c[1], c[2], c[3])
end
local function weaponNumbers(f, e)
    local left, charges = ns.Weapon.Left(e.hand)
    local has = left ~= nil
    if has ~= f.tipOn then
        paintHas(f, has)
    end
    if left and left > 0 and e.dur then
        local dur = math.max(e.dur, math.ceil(left))
        sweepTo(f, math.floor(GetTime() + left + 0.5) - dur, dur, true, sweepAlpha())
    else
        sweepOff(f)
    end
    local txt = ownDigits() and ns.Style.Fmt(f, left)
    if txt then f.left:SetText(txt); f.left:Show() else f.left:Hide() end
    ns.Style.Time(f, f.left, left, true)
    groupInk(f)
    f.rn:SetText(ns.T("weapon.short_" .. e.hand))
    f.rn:Show()
    f.rmin:Hide()
    setCount(f, charges)
    layoutBuff(f, "hand")
end
local function itemBuffLeft(f, left)
    ns.Style.Soon(f, left, true)
    local txt = ownDigits() and ns.Style.Fmt(f, left)
    if txt then f.left:SetText(txt); f.left:Show() else f.left:Hide() end
    f._fast = (left and left > 0 and left < ns.Style.TENTHS) and true or nil
    ns.Style.Time(f, f.left, left, true)
end
local function itemNumbers(f, e)
    local bname = e.buff and GetSpellInfo(e.buff)
    local up = bname and ns.BuffLeft and ns.BuffLeft(bname)
    if up and up > 0 then
        setBuffSweep(f, bname)
        itemBuffLeft(f, up)
        return false
    end
    local start, dur, enable = GetItemCooldown(e.item)
    local locked = enable == 0
    local left = (not locked and start and start > 0 and dur and dur > 1.5) and (start + dur - GetTime()) or nil
    if left and left > 0 then
        sweepTo(f, start, dur, false, 1)
    else
        sweepOff(f)
        left = nil
    end
    local txt = ownDigits() and ns.Style.Fmt(f, left)
    if txt then f.left:SetText(txt); f.left:Show() else f.left:Hide() end
    ns.Style.Time(f, f.left, left)
    return locked
end
local function setBag(f, bag)
    if ns.Style.Of(f, "bag") == "none" then
        setCount(f, nil)
        return
    end
    if bag > 0 then
        setCount(f, bag)
        return
    end
    paintStacks(f, nil)
    f.count:SetText("0")
    f.count:Show()
    ns.Style.Zero(f, f.count)
end
local function paintItem(f, has, locked)
    f._locked = locked
    texDesat(f, locked or not has)
    if locked then texColor(f, 0.45, 0.45, 0.45) else texColor(f, 1, 1, 1) end
    local quiet = not has and not locked and ns.Style.Colored(f)
    setDim(f, (has and not locked) and 1 or (quiet and ns.Style.MISS_DIM or absentAlpha(f)))
    if has or locked or quiet then f.glow:Hide() else f.glow:Show() end
    if (quiet or nil) ~= f._miss then
        f._miss = quiet or nil
        paintWarn(f)
    end
    ns.Style.State(f, (has and not locked) and "up" or (locked and "off") or "miss")
end
local function targetStacks(ids)
    for _, id in ipairs(ids) do
        local name = GetSpellInfo(id)
        if name then
            local found, _, _, count = UnitDebuff("target", name, nil, "PLAYER")
            if found then return count end
        end
    end
    return nil
end
local function setBuffNumbers(f)
    local kind, e = f._kind, f._entry
    f._tstk = nil
    if kind == "item" and e and not e.aura then
        local locked = itemNumbers(f, e)
        if locked ~= f._locked then
            paintItem(f, f._has, locked)
        end
        f.rmin:Hide(); f.rn:Hide()
        layoutBuff(f)
        return
    end
    if kind == "item" and e and e.aura then
        itemBuffLeft(f, (setBuffSweep(f, GetSpellInfo(e.aura))))
        f.rmin:Hide(); f.rn:Hide()
        layoutBuff(f)
        return
    end
    if kind ~= "spell" or not e then
        setBuffSweep(f, nil)
        f.left:Hide(); f.rmin:Hide(); f.rn:Hide()
        layoutBuff(f)
        return
    end
    if e.hand then
        weaponNumbers(f, e)
        return
    end
    local se = f._self or e
    local name = ns.ActiveBuffName(se) or GetSpellInfo(se.id)
    local mine, charges = setBuffSweep(f, name)
    ns.Style.Soon(f, mine, true)
    local txt = ownDigits() and ns.Style.Fmt(f, mine)
    if txt then f.left:SetText(txt); f.left:Show() else f.left:Hide() end
    f._fast = (mine and mine > 0 and mine < ns.Style.TENTHS) and true or nil
    ns.Style.Time(f, f.left, mine, true)
    local link = ns.stackOnTarget and (ns.stackOnTarget[se.id] or ns.stackOnTarget[e.id])
    f._tstk = link
    if link then charges = targetStacks(link) end
    setCount(f, charges)
    if e._cat == "raid" and ns.GroupBuffNumbers then
        local n, total, min, held = ns.GroupBuffNumbers(e)
        if total > 0 then
            if e.single and n > 0 and held then
                setCount(f, held)
                f.rn:Hide()
            else
                groupInk(f, n, total)
                f.rn:SetText(n .. "/" .. total)
                f.rn:Show()
            end
            local mtxt = ns.Style.Fmt(f, min)
            if mtxt then f.rmin:SetText(mtxt); f.rmin:Show() else f.rmin:Hide() end
            layoutBuff(f, "group")
            return
        end
    end
    f.rmin:Hide(); f.rn:Hide()
    layoutBuff(f)
end
local PLAIN_MARK = { 1, 0.55, 0.25 }
local function markColor(great)
    if not great then return PLAIN_MARK[1], PLAIN_MARK[2], PLAIN_MARK[3] end
    local t = ns.CurrentTheme()
    local c = (t and t.tabbar and t.tabbar.underline) or { 1, 0.82, 0.25 }
    return c[1], c[2], c[3]
end
local function lerpFace(t, f, k)
    local sz  = STACK_SZ + (ICON - STACK_SZ) * k
    local off = STACK_OFF * (1 - k)
    t:SetWidth(sz); t:SetHeight(sz)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", f, "TOPLEFT", -off, off)
    t:SetAlpha(0.75 + 0.25 * k)
end
local function resetFaces(f)
    f.tex:SetWidth(0); f.tex:SetHeight(0)
    f.tex:ClearAllPoints()
    f.tex:SetAllPoints(f)
    f.tex:SetAlpha(f._dim or 1)
    f.tex:SetDrawLayer("ARTWORK")
    lerpFace(f.stack, f, 0)
    f.stack:SetDrawLayer("BACKGROUND")
end
local function setStack(f)
    local b = f.bless
    if not b or ns.MyBlessing() ~= b.key then f.stack:Hide(); return end
    local other = f._self and b.great or b.plain
    f.stack:SetTexture((select(3, GetSpellInfo(other))))
    f.stack:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.stack:SetDesaturated(other == b.great and ns.BlessingSymbols() == 0)
    f.stack:Show()
end
local function setMark(f)
    if f.bless and ns.BlessPP.Key() == f.bless.key then f.ppmark:Show() else f.ppmark:Hide() end
    if not (f.bless and ns.MyBlessing() == f.bless.key) then f.mark:Hide(); return end
    local r, g, b = markColor(f.castGreat)
    f.mark:SetVertexColor(r, g, b, 1)
    f.mark:Show()
end
local BLESS_PRE, BLESS_POST = ns.BlessClick.PRE, ns.BlessClick.POST
local function blessWrap(c)
    if c._bqWrapped or not SecureHandlerWrapScript then return end
    SecureHandlerWrapScript(c, "OnClick", c, BLESS_PRE, BLESS_POST)
    c._bqWrapped = true
end
local writeQueue = ns.BlessClick.Write
local function blessAction(f, c)
    local all, spell, great = ns.BlessingQueue(f.bless)
    f.castGreat = great
    local q = spell and ns.BlessingClickQueue(all) or {}
    if not spell or #q == 0 then writeQueue(c, nil); return end
    blessWrap(c)
    writeQueue(c, q, spell)
    local s = q[c:GetAttribute("bq-i") or 1] or q[1]
    f.castUnit, f.castClass = s.unit, s.class
    c:SetAttribute("type1", "spell")
    c:SetAttribute("spell", spell)
    c:SetAttribute("unit", s.unit)
end
local function setAction(f, kind, entry)
    local c = f.click
    c:SetAttribute("type", nil)
    c:SetAttribute("type1", nil)
    c:SetAttribute("unit", nil)
    f.castUnit, f.castClass, f.castGreat = nil, nil, false
    if not (f.bless and ns.MyBlessing() == f.bless.key) then writeQueue(c, nil) end
    if entry.noAction then return end
    if entry.hand then
        c:SetAttribute("type1", "macro")
        c:SetAttribute("macrotext", ns.Weapon.Macro(entry))
        return
    end
    if kind ~= "spell" then
        c:SetAttribute("type1", "item")
        c:SetAttribute("item", "item:" .. entry.item)
        return
    end
    if f.bless and ns.MyBlessing() == f.bless.key then
        blessAction(f, c)
        return
    end
    if entry.toggle then
        c:SetAttribute("type1", "macro")
        c:SetAttribute("macrotext", "/cast !" .. (GetSpellInfo(entry.id) or ""))
        return
    end
    if entry.excess then
        c:SetAttribute("type1", "macro")
        c:SetAttribute("macrotext", "/cancelaura " .. (GetSpellInfo(entry.id) or ""))
        return
    end
    c:SetAttribute("type1", "spell")
    c:SetAttribute("spell", (GetSpellInfo(entry.id)))
end
local function setTex(f, path)
    path = path or ns.QMARK
    if f._icon == path then return end
    f._icon, f._tint, f._td, f._tr = path, nil, nil, nil
    f.tex:SetTexture(path)
    ns.Look.Crop(f)
end
local function setFrameAlpha(f, entry)
    if f._anim or ns.Anim.Busy(f) then return end
    f:SetAlpha(1)
end
local function fxBuff(f, entry, has)
    local key = entry._key
    local was = (f._fxKey == key) and f._has or nil
    f._fxKey, f._has = key, has and true or false
    if was == true and not has and not inConfig() and not entry.excess then ns.FX.Icon("gone", f) end
end
local FX_MIN_CD = 8
local function fxTrack(f, kind, entry, st, sweep)
    local state = st.active and "on" or (sweep and "cd") or "off"
    if state == "on" and kind == "aura" and not ns.ProcGlows(entry, st) then state = "lit" end
    local was = (f._fxKey == entry._key) and f._state or nil
    f._fxKey, f._state = entry._key, state
    if state == "cd" then f._cdLen = st.duration end
    if not was or was == state or inConfig() then return end
    if kind == "mixed" then kind = (entry.slot or entry.item) and "item" or "spell" end
    if state ~= "on" then return end
    if was == "cd" and (kind == "spell" or kind == "item") then
        if (f._cdLen or 0) >= FX_MIN_CD and not ns.Style.Event(f, "ready") then ns.FX.Icon("ready", f) end
    elseif kind == "aura" or (kind == "item" and entry.proc) then
        if not ns.Style.Event(f, "proc") then ns.FX.Icon("proc", f) end
    end
end
local function procEvent(f, entry, on)
    local was = (f._pKey == entry._key) and f._pOn or nil
    f._pKey, f._pOn = entry._key, on
    if on and was == false and not inConfig() and not ns.Style.Event(f, "proc") then ns.FX.Icon("proc", f) end
end
local function activeAlt(entry)
    if type(entry.alt) ~= "table" or #entry.alt == 0 then return nil end
    local name = ns.ActiveBuffName(entry)
    if not name then return nil end
    if GetSpellInfo(entry.id) == name then return entry.id end
    for _, id in ipairs(entry.alt) do
        if GetSpellInfo(id) == name then return id end
    end
    return nil
end
local function fillIcon(f, kind, entry, combat)
    f._kind, f._entry = kind, entry
    ns.Look.StyleIcon(f)
    sizeDigits(f)
    if f.warn and f.warn:IsShown() then paintWarn(f) end
    f.spellId, f.itemId = nil, nil
    f.tipKind, f.tipOn = entry.tipKind, false
    if kind == "spell" then texColor(f, 1, 1, 1) end
    f._locked = nil
    local b = (kind == "spell") and ns.BlessingOf and ns.BlessingOf(entry.id) or nil
    if b and not ns.IsLearned(b.great) then b = nil end
    f.bless = b
    f.auraOn = entry.state
    f._self = nil
    if kind == "spell" then
        if not combat then setAction(f, kind, entry) end
        local shown = entry.id
        local has = entry.state
        if entry.slot == "aura" and ns.MyAura then
            local cur = ns.MyAura()
            shown, has = cur or entry.id, cur ~= nil
        end
        if b and ns.MyBlessing() == b.key and not f.castGreat then
            shown = b.plain
            f._self = { id = b.plain, alt = { b.great } }
        elseif not b and entry.slot ~= "aura" and not entry.hand then
            shown = activeAlt(entry) or shown
        end
        if f._altKey == entry._key and f._altShown and f._altShown ~= shown and not inConfig() then
            ns.FX.Icon("proc", f)
        end
        f._altKey, f._altShown = entry._key, shown
        f.spellId = shown
        setMark(f)
        if not f._flip then
            setTex(f, foodTex(f, entry) or (select(3, GetSpellInfo(shown))))
            setStack(f)
        end
        if has == nil and entry.hand then
            has = ns.Weapon.Left(entry.hand) ~= nil
        elseif has == nil and entry.single and ns.GroupBuffNumbers then
            has = ns.GroupBuffNumbers(entry) > 0
        elseif has == nil then
            has = ns.ActiveBuffName(f._self or entry) ~= nil
        end
        paintHas(f, has)
        fxBuff(f, entry, has)
        setCount(f, nil)
        setBuffNumbers(f)
    else
        f.mark:Hide()
        f.ppmark:Hide()
        f.stack:Hide()
        f.itemId = entry.item
        setTex(f, (select(10, GetItemInfo(entry.item))))
        if not combat then setAction(f, kind, entry) end
        local bag = (GetItemCount and GetItemCount(entry.item)) or 0
        local has
        if entry.aura then
            local an = GetSpellInfo(entry.aura)
            has = an and ns.HasBuff(an)
        else
            has = bag > 0
        end
        fxBuff(f, entry, has)
        paintItem(f, f._has, false)
        setBag(f, bag)
        setBuffNumbers(f)
    end
    setFrameAlpha(f, entry)
    local sleep = asleep(f)
    if not inConfig() and f._item and (sleep or hiddenBy(f._item.show, f._has)) then
        if ns.Anim.Busy(f) then ns.Anim.Stop(f) end
        f:SetAlpha(0)
    elseif sleep then
        f:SetAlpha(SLEEP_ALPHA)
    end
end
local function trackState(self)
    local kind, e = self._kind, self._entry
    if not (kind and e) then return end
    local st = ns.TrackState(kind, e, self._item)
    if kind == "mixed" then kind = (e.slot or e.item) and "item" or "spell" end
    if st.unit then
        local text, found = ns.Units.Tip(st.unit)
        if found then
            GameTooltip:AddLine(text, 1, 1, 1, true)
        else
            GameTooltip:AddLine(text, 1, 0.35, 0.35, true)
            return
        end
    end
    if kind == "aura" or kind == "debuff" then
        auraState(st.active, st.left, st.stacks)
    elseif st.locked then
        local t = st.left and ns.T("widget.cds_t_lock", st.locked, tipTime(st.left)) or ns.T("widget.cds_t_lock_on", st.locked)
        GameTooltip:AddLine(t, 1, 0.35, 0.35, true)
    elseif st.left and st.left > 0 then
        if st.active then
            GameTooltip:AddLine(ns.T("tip.on", tipTime(st.left)), 0.4, 1, 0.4, true)
        else
            GameTooltip:AddLine(ns.T("tip.cd", tipTime(st.left)), 0.6, 0.6, 0.6, true)
        end
    elseif st.active then
        GameTooltip:AddLine(ns.T("tip.ready"), 0.4, 1, 0.4, true)
    end
    local a = st.act
    if a and a.gone then
        GameTooltip:AddLine((ns.Units.Tip(a.gone)), 1, 0.35, 0.35, true)
    else
        local why = (a and a.wrong and "tip.why_wrong") or (st.noTarget and "tip.why_target")
            or (st.noMana and "tip.why_res") or (st.unusable and "tip.why_use") or (st.far and "tip.why_far") or nil
        if why then GameTooltip:AddLine(ns.T(why), 1, 0.35, 0.35, true) end
    end
    if a and a.cause and not st.noTarget then
        local yes = not st.noCause
        GameTooltip:AddLine(ns.T("tip.cause_" .. a.cause .. (yes and "_yes" or "_no")),
            yes and 0.4 or 0.6, yes and 1 or 0.6, yes and 0.4 or 0.6, true)
    end
end
local function trackEnter(self)
    if inConfig() or not iconTipsNow() then
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        return
    end
    if self.link then
        tipHead(self, self.link)
    elseif self.spellId then
        tipHead(self, "spell:" .. self.spellId)
    else
        return
    end
    warnLine(self)
    trackState(self)
    noteLine(self._entry, true)
    GameTooltip:Show()
end
local function acquireTrackIcon(i)
    local f = ticons[i]
    if not f then
        f = CreateFrame("Frame", nil, bar)
        f:SetWidth(ICON)
        f:SetHeight(ICON)
        f:EnableMouse(true)
        f.tex = f:CreateTexture(nil, "ARTWORK")
        f.tex:SetAllPoints(f)
        f.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
        f.cd:SetAllPoints(f)
        f.cd.noCooldownCount = true
        ns.Look.AttachEdge(f)
        f.txt = CreateFrame("Frame", nil, f)
        f.txt:SetAllPoints(f)
        f.txt:SetFrameLevel(f.cd:GetFrameLevel() + 5)
        f.count = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
        numSize(f.count, NUM_COUNT, "stack")
        f.count:Hide()
        f.timer = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        f.timer:SetPoint("TOP", f, "TOP", 0, TIME_Y)
        f.timer:SetWidth(ICON); f.timer:SetJustifyH("CENTER")
        numSize(f.timer, NUM_MAIN)
        f.timer._main = true
        f.timer:Hide()
        f.digits = { f.count, f.timer }
        f._track = true
        f._i = i
        f:SetScript("OnEnter", function(self)
            trackEnter(self)
            ns.Style.Hover(self, true)
            ns.Blocks.EnterIcon(self:GetParent())
        end)
        f:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            ns.Style.Hover(self, false)
            ns.Blocks.LeaveIcon(self:GetParent())
        end)
        f:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" and inConfig() then ns.Blocks.OpenCard(self:GetParent()) end
        end)
        f:EnableMouseWheel(false)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) ns.Blocks.GrabIcon(self:GetParent(), self._cx, self._cy) end)
        f:SetScript("OnDragStop", function(self)
            local p = self:GetParent()
            if p then ns.Blocks.Drop(p) end
        end)
        f:SetScript("OnReceiveDrag", function(self) ns.Blocks.DropItem(self:GetParent()._key, self._cx, self._cy) end)
        ticons[i] = f
    end
    return f
end
local function useButton(f)
    if f.useBtn then return f.useBtn end
    local c = CreateFrame("Button", "LazyBuffBarUse" .. f._i, bar, "SecureActionButtonTemplate")
    c:SetWidth(ICON)
    c:SetHeight(ICON)
    c:RegisterForClicks("AnyUp")
    c:RegisterForDrag("LeftButton")
    c:EnableMouseWheel(false)
    c.vis = f
    f.useBtn = c
    c:SetScript("PostClick", function(self, button)
        if button == "RightButton" and inConfig() and not InCombatLockdown() then ns.Blocks.OpenCard(self:GetParent()) end
    end)
    c:SetScript("OnEnter", function(self)
        if not ruleHidden(self.vis) then trackEnter(self.vis) end
        ns.Style.Hover(self.vis, true)
        ns.Blocks.EnterIcon(self:GetParent())
    end)
    c:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        ns.Style.Hover(self.vis, false)
        ns.Blocks.LeaveIcon(self:GetParent())
    end)
    c:SetScript("OnDragStart", function(self) ns.Blocks.GrabIcon(self:GetParent(), self.vis._cx, self.vis._cy) end)
    c:SetScript("OnDragStop", function(self)
        local fr = self:GetParent()
        if fr then ns.Blocks.Drop(fr) end
    end)
    c:SetScript("OnReceiveDrag", function(self) ns.Blocks.DropItem(self:GetParent()._key, self.vis._cx, self.vis._cy) end)
    c:Hide()
    return c
end
local function placeUse(f, slot)
    if InCombatLockdown() then return end
    if not slot then
        if f.useBtn then f.useBtn:Hide() end
        return
    end
    local c = useButton(f)
    local fr = f:GetParent()
    c:SetParent(fr)
    c:SetFrameLevel(ns.Blocks.ClickLevel(fr) + 1)
    c:SetAttribute("type1", "macro")
    c:SetAttribute("macrotext", "/use " .. slot)
    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", fr, "TOPLEFT", f._bx, -f._by)
    c:Show()
end
local function tintTrack(f, st)
    local tint = ns.Look.Get("tint")
    local c = (tint and st.far) and "far" or (tint and st.noMana) and "mana" or nil
    local pic, mul, how = ns.Style.Tint(f, c)
    texColor(f, pic[1], pic[2], pic[3])
    f._dimMul = (mul ~= 1) and mul or nil
    ns.Style.Mark(f, c, how)
end
local function sleepBoss(f, entry)
    local slot = type(entry.slot) == "number" and entry.slot or nil
    local icon = (slot and GetInventoryItemTexture("player", slot)) or (entry.id and select(3, GetSpellInfo(entry.id))) or nil
    f.spellId, f.link = (not slot) and entry.id or nil, slot and entry.link or nil
    setTex(f, icon)
    tintTrack(f, {})
    f._fxKey, f._state = entry._key, "off"
    sweepOff(f)
    ns.Style.Release(f)
    texDesat(f, true)
    setDim(f, absentAlpha(f))
    f.timer:Hide()
    f.count:Hide()
    paintStacks(f, nil)
    if inConfig() then
        setFrameAlpha(f, entry)
    else
        if ns.Anim.Busy(f) then ns.Anim.Stop(f) end
        f:SetAlpha(0)
    end
end
local function fillTrackIcon(f, kind, entry)
    f._kind, f._entry = kind, entry
    ns.Look.StyleIcon(f)
    sizeDigits(f)
    if f._enc and not ns.Encounter.Active(f._enc) then
        sleepBoss(f, entry)
        return
    end
    if f._why == "passive" then
        sleepBoss(f, entry)
        f:EnableMouse(inConfig())
        return
    end
    local st = ns.TrackState(kind, entry, f._item)
    f.spellId, f.link = st.spell, st.link
    setTex(f, st.icon)
    tintTrack(f, st)
    ns.Style.State(f, (f._why and "off") or (st.active and "up") or "cd")
    local sweep = st.start and st.duration and st.duration > 0 and st.left
    fxTrack(f, kind, entry, st, sweep)
    if sweep then
        local rev = st.active and true or false
        ns.Style.Sweep(f, st.start, st.duration, rev, rev and sweepAlpha() or 1, true)
        texDesat(f, st.dim)
        local d = st.dim and absentAlpha(f) or 1
        if not rev then d = ns.Style.Ramp(f, st.left, d) end
        setDim(f, d)
    else
        sweepOff(f)
        texDesat(f, not st.active or st.unusable)
        setDim(f, ((st.noTarget or st.noCause) and ACT_NO_TARGET) or (st.active and 1) or absentAlpha(f))
    end
    setFrameAlpha(f, entry)
    local lk = (kind == "mixed") and ((entry.slot or entry.item) and "item" or "spell") or kind
    local plink = lk == "spell" and not f._why and ns.ProcLink and ns.ProcLink.Of(entry) or nil
    local pmode = f._item and f._item.procLink
    local pon, pstk = false, nil
    if plink and pmode ~= "off" then pon, pstk = ns.ProcLink.State(plink) end
    procEvent(f, entry, pon)
    local glows = kind ~= "aura" or ns.ProcGlows(entry, st)
    ns.Style.Lit(f, (st.active and glows and not f._why and lk ~= "debuff" and not pon) and true or false)
    ns.Style.ProcLit(f, pon)
    ns.Style.ProcCount(f, pstk)
    ns.Style.Soon(f, st.left, false)
    local ttxt = st.left and st.left > 0 and ownDigits() and ns.Style.Fmt(f, st.left)
    if ttxt then
        f.timer:SetText(ttxt)
        f.timer:Show()
    else
        f.timer:Hide()
    end
    ns.Style.Time(f, f.timer, st.left, false, st.dim)
    if paintStacks(f, st.stacks) then
        f.count:Hide()
    elseif st.stacks and st.stacks > 1 then
        f.count:SetText(st.stacks)
        f.count:Show()
    else
        f.count:Hide()
    end
    ns.Style.Stacks(f, f.count, st.stacks)
    local s = spotsFor(f)
    put(f.timer, f, s.time)
    put(f.count, f, s.count)
    placeOmni(f, s.time)
    local sleep = asleep(f)
    local look = f._item and kind == "aura" and ns.ProcLook(entry) or nil
    local show = f._item and (kind == "aura" and ns.ProcShow(entry, f._item.show) or f._item.show)
    local gone = not inConfig() and f._item
        and (sleep or hiddenBy(show, st.active, st.stacks, look and look.full) or (plink and pmode == "only" and not pon)
            or (show == "can" and entry.act and not actCan(st))) or false
    if gone then
        if ns.Anim.Busy(f) then ns.Anim.Stop(f) end
        f:SetAlpha(0)
    elseif sleep then
        f:SetAlpha(SLEEP_ALPHA)
    end
    if not f._enc then f:EnableMouse(not gone) end
end
local function Grid()
    return ns.Grid
end
local function blocks()
    return ns.Preset.Blocks()
end
local function barIndex(id)
    if id == nil then return nil end
    for i, b in ipairs(blocks()) do
        if b.key == id then return i end
    end
    return nil
end
local function at(x)
    if type(x) == "number" then return blocks()[x] and x or nil end
    return barIndex(x)
end
function ns.BarName(b, i)
    if not b then return "?" end
    return ns.Preset.BlockName(b, i)
end
local function barOff(b)
    return (b and b.off) and true or false
end
local ROLE_CAT = {
    self = "personal", weapon = "personal", food = "food", raid = "raid", want = "want", item = "flask",
    proc = "proc", ally = "proc", cd = "cd", gear = "gear", dot = "dot",
}
local TRACK_CAT = { proc = true, cd = true, gear = true, dot = true }
local SEP_CLASS = { self = "buff", weapon = "buff", raid = "buff", food = "cons", item = "cons", want = "want",
                    proc = "track", harm = "track", ally = "track", cd = "track", dot = "track", gear = "track" }
local SEP_SIDE = 4
local function sepClass(it)
    local name = ns.Widget.NameOf(it.k)
    if name then return name ~= "sep" and "widget" or nil end
    local k = tostring(it.k or "")
    if k == "want" or k:match("^want:") then return "want" end
    return SEP_CLASS[it.role or ""]
end
local function groupName(key)
    local k = "group." .. tostring(key)
    if ns.L[k] then return ns.T(k) end
    return tostring(key)
end
local function placeBar(fr, i, b)
    if ns.Snap.Held() == fr then return end
    local p = b.point
    fr:ClearAllPoints()
    if p then
        fr:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    elseif i == 1 then
        fr:SetPoint("CENTER", UIParent, "CENTER", 0, -160)
    else
        fr:SetPoint("TOPLEFT", ns.Blocks.FrameAt(i - 1), "BOTTOMLEFT", 0, -ROWGAP * 4)
    end
end
local DIGITS_MODES = { "center", "bottom", "top" }
local function digitsMode(b)
    if not b then return "center" end
    if b.digits == "auto" then b.digits = nil end
    if b.digits then return b.digits end
    local buff, track = 0, 0
    for _, it in ipairs(b.items or {}) do
        if TRACK_CAT[ROLE_CAT[it.role or ""] or ""] then track = track + 1 else buff = buff + 1 end
    end
    return buff > track and "bottom" or "center"
end
local function iconLevel(f)
    local p = f:GetParent()
    if f._track then return ns.Blocks.ClickLevel(p) end
    return p:GetFrameLevel() + 5
end
local function restack(f)
    f:SetFrameLevel(iconLevel(f))
    if f.cd then f.cd:SetFrameLevel(f:GetFrameLevel() + 1) end
    if f.edge then f.edge:SetFrameLevel(f:GetFrameLevel() + 3) end
    if f.sty then f.sty:SetFrameLevel((f.cd and f.cd:GetFrameLevel() or f:GetFrameLevel()) + 1) end
    if f.glow then f.glow:SetFrameLevel(f:GetFrameLevel() + 6) end
    if f.txt then f.txt:SetFrameLevel((f.cd and f.cd:GetFrameLevel() or f:GetFrameLevel()) + 5) end
end
local SLIDE = 0.18
local sliding = {}
local function place(f)
    local a = f._anim
    local dx, dy = 0, 0
    if a then
        local k = 1 - a.t / SLIDE
        dx, dy = a.dx * k, a.dy * k
    end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", f:GetParent(), "TOPLEFT", f._bx + dx, -(f._by + dy))
end
function ns.buffbar.StartSlide(f, dx, dy, under)
    if dx == 0 and dy == 0 then return end
    f._anim = { dx = dx, dy = dy, t = 0, under = under, alpha = f:GetAlpha() }
    if under then f:SetFrameLevel(math.max(0, f:GetParent():GetFrameLevel())) end
    sliding[f] = true
    place(f)
end
local function slideTick(elapsed)
    if not next(sliding) then return end
    for f in pairs(sliding) do
        local a = f._anim
        if not a then
            sliding[f] = nil
        else
            a.t = a.t + elapsed
            if a.t >= SLIDE or InCombatLockdown() then
                f._anim = nil
                sliding[f] = nil
                f:SetAlpha(a.alpha)
                restack(f)
                place(f)
            else
                if a.under then
                    local k = a.t / SLIDE
                    f:SetAlpha(a.alpha * (0.4 + 0.6 * math.abs(1 - 2 * k)))
                end
                place(f)
            end
        end
    end
end
local function flipTick(elapsed)
    if not next(flipping) then return end
    for f in pairs(flipping) do
        local a = f._flip
        if not a then
            flipping[f] = nil
        else
            a.t = a.t + elapsed
            local k = a.t / FLIP
            if k >= 1 then
                f._flip = nil
                flipping[f] = nil
                resetFaces(f)
                ns.buffbar:Update()
            else
                if not a.swapped and k >= 0.5 then
                    a.swapped = true
                    f.tex:SetDrawLayer("BACKGROUND")
                    f.stack:SetDrawLayer("ARTWORK")
                end
                lerpFace(f.tex, f, 1 - k)
                lerpFace(f.stack, f, k)
            end
        end
    end
end
function ns.buffbar:FlipBlessing(f, plain)
    if InCombatLockdown() then return false end
    if not (f and f.bless and ns.MyBlessing() == f.bless.key) then return false end
    plain = plain and true or false
    if ns.BlessingWantsPlain() == plain then return true end
    if f._flip then
        ns.SetBlessingWantsPlain(plain)
        return true
    end
    f.tex:ClearAllPoints()
    lerpFace(f.tex, f, 1)
    lerpFace(f.stack, f, 0)
    f.stack:Show()
    f._flip = { t = 0 }
    flipping[f] = true
    ns.SetBlessingWantsPlain(plain)
    return true
end
function ns.buffbar:RefreshBless(reset)
    if not bar or not cfg().show then return end
    local combat = InCombatLockdown()
    for _, f in ipairs(icons) do
        if f:IsShown() and f._kind and f.bless and ns.MyBlessing() == f.bless.key then
            if reset and not combat and f.click then f.click._bqSig = nil end
            fillIcon(f, f._kind, f._entry, combat)
            if GameTooltip:IsOwned(f) then itemEnter(f) end
        end
    end
end
ns.OnBlessingChange(function(reset) ns.buffbar:RefreshBless(reset) end)
ns.Encounter.OnChange(function() ns.buffbar:UpdateTrack() end)
local layouts = 0
local function appear(f)
    if layouts < 2 or f._anim or ns.FX.Level() == "off" then return end
    local to = f:GetAlpha()
    if to <= 0 then return end
    ns.Anim.Fade(f, 0, to)
end
local function putIcon(fr, b, geo, item, x, y, entry, kind, cat, dmode, n)
    if entry._key == nil then entry._key, entry._cat = item.k, cat end
    local why, what = ns.Avail.Of(item, entry, cat)
    local f
    if TRACK_CAT[cat] then
        n.ti = n.ti + 1
        f = acquireTrackIcon(n.ti)
        f._dmode, f._item, f._round, f._why, f._what = dmode, item, n.round, why, what
        f._absent = n.absent
        ns.Style.Resolve(f, b, item)
        f._enc = ns.Encounter.OfRef(item.k)
        if f._enc then
            n.enc[f._enc] = true
            f:EnableMouse(inConfig())
        end
        fillTrackIcon(f, kind, entry)
    else
        n.bi = n.bi + 1
        f = acquireIcon(n.bi)
        f._dmode, f._item, f._round, f._why, f._what = dmode, item, n.round, why, what
        f._absent = n.absent
        ns.Style.Resolve(f, b, item)
        fillIcon(f, kind == "item" and "item" or "spell", entry, false)
    end
    paintWarn(f)
    f._key, f._cx, f._cy = b.key, x, y
    local fresh = not f:IsShown()
    f:SetParent(fr)
    restack(f)
    f._bx, f._by = Grid().CellXY(geo, x, y)
    place(f)
    f:Show()
    if f.click then placeClick(f) end
    if f._track then
        local use = cat == "gear" and entry.use and type(entry.slot) == "number" and not entry.absent
        placeUse(f, use and entry.slot or nil)
    end
    if fresh then appear(f) end
end
local function putWant(fr, b, geo, item, dmode, n, edit)
    local one = tostring(item.k):match("^want:(.+)$")
    if one then
        local e, live = ns.Incoming.Entry(one)
        if not e or not (live or edit) then return false end
        putIcon(fr, b, geo, item, item.x, item.y, e, "spell", "want", dmode, n)
        return true
    end
    local secs = (ns.IncomingSections and ns.IncomingSections(false)) or {}
    local sec = secs[1]
    if not sec then return false end
    local w = item.w or 1
    local drew, j = false, 0
    for _, e in ipairs(sec.entries) do
        j = j + 1
        if j > w then break end
        putIcon(fr, b, geo, item, item.x + j - 1, item.y, e, sec.kind or "spell", "want", dmode, n)
        drew = true
    end
    return drew
end
local whosts = {}
local function waddr(key, x, y)
    return key .. ":" .. x .. "," .. y
end
local function widgetTex(name)
    local d = ns.Widget.Get(name)
    local icon = d and d.icon
    if type(icon) == "number" then return (select(3, GetSpellInfo(icon))) end
    return icon
end
local function cellInWidget(f)
    local key, x, y = ns.Blocks.Under()
    if key == f._key and x and y then return x, y end
    return f._cx, f._cy
end
local function widgetCover(f)
    local c = f.cover
    if c then return c end
    c = CreateFrame("Button", nil, f)
    c:SetAllPoints(f)
    c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    c:RegisterForDrag("LeftButton")
    c:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        local p = self:GetParent()
        ns.Blocks.GrabIcon(p:GetParent(), cellInWidget(p))
    end)
    c:SetScript("OnDragStop", function(self) ns.Blocks.Drop(self:GetParent():GetParent()) end)
    c:SetScript("OnClick", function(self, button)
        local p = self:GetParent()
        if button == "RightButton" then
            ns.Blocks.OpenCard(p:GetParent())
            return
        end
        ns.buffbar:CycleWidgetView(p._key, p._cx, p._cy)
    end)
    c:SetScript("OnEnter", function(self) ns.Blocks.EnterIcon(self:GetParent():GetParent()) end)
    c:SetScript("OnLeave", function(self) ns.Blocks.LeaveIcon(self:GetParent():GetParent()) end)
    c:Hide()
    f.cover = c
    f.tex = f:CreateTexture(nil, "BACKGROUND")
    f.tex:Hide()
    return c
end
local function putWidget(fr, b, geo, item, edit, n)
    local name = ns.Widget.NameOf(item.k)
    if not (name and ns.Widget.Get(name) and ns.Widget.Avail(name)) then return false end
    local addr = waddr(b.key, item.x, item.y)
    n.widgets[addr] = true
    local host = whosts[addr]
    if host and (host.name ~= name or host.gap ~= geo.gap or host.parent ~= fr) then
        ns.Widget.Unmount(host)
        host = nil
    end
    if not host then
        host = ns.Widget.Mount(name, fr, item.view, item.opt, {
            cell = geo.icon, gap = geo.gap, gapY = geo.gap + 2,
            level = fr:GetFrameLevel() + 5, btnLevel = ns.Blocks.ClickLevel(fr),
        })
        host.itemOpt = item.opt
        whosts[addr] = host
    else
        ns.Widget.SetView(host, item.view)
        if host.itemOpt ~= item.opt then
            host.itemOpt = item.opt
            ns.Widget.SetOpt(host, item.opt)
        end
    end
    host.addr = { b.key, item.x, item.y }
    host.panel = { block = b, item = item, dmode = digitsMode(b), round = n.round, absent = n.absent }
    local f = ns.Widget.Frame(host)
    if not f then return true end
    local cover = widgetCover(f)
    f._widget, f._item, f._key, f._cx, f._cy = host, item, b.key, item.x, item.y
    f._icon = widgetTex(name)
    f.tex:SetTexture(f._icon)
    f._bx, f._by = Grid().CellXY(geo, item.x, item.y)
    if not f._anim then place(f) end
    cover:SetFrameLevel(ns.Blocks.ClickLevel(fr) + 1)
    if edit then cover:Show() else cover:Hide() end
    local def = ns.Widget.Get(name)
    if def.units then
        for _, l in ipairs(def.units(item.opt or {}) or {}) do n.units[l] = true end
    end
    ns.Widget.SetEdit(host, edit)
    ns.Widget.Refresh(host)
    return true
end
local function pruneWidgets(n)
    for addr, host in pairs(whosts) do
        if not n.widgets[addr] then
            ns.Widget.Unmount(host)
            whosts[addr] = nil
        end
    end
end
local function releaseMoved(list)
    local keep = {}
    for _, b in ipairs(list) do
        for _, it in ipairs(b.items or {}) do
            local name = ns.Widget.NameOf(it.k)
            if name then keep[waddr(b.key, it.x, it.y)] = name end
        end
    end
    for addr, host in pairs(whosts) do
        if keep[addr] ~= host.name then
            ns.Widget.Unmount(host)
            whosts[addr] = nil
        end
    end
end
local function widgetAt(key, x, y)
    for _, host in pairs(whosts) do
        local f = ns.Widget.Frame(host)
        if f and f:IsShown() and f._key == key and f._item then
            local w, h = Grid().Size(f._item)
            if x >= f._cx and x < f._cx + w and y >= f._cy and y < f._cy + h then return f end
        end
    end
    return nil
end
local function soleDriver(b)
    local items = b.items or {}
    local it = items[1]
    if #items ~= 1 or not (it and ns.Widget.NameOf(it.k)) then return nil end
    local host = whosts[waddr(b.key, it.x, it.y)]
    return host and ns.Widget.Driver(host) or nil
end
local laying = false
ns.Widget.OnDriver(function()
    if laying then return end
    ns.DeferKey("panel.wdrv", function()
        if ns.buffbar and ns.buffbar.Update then ns.buffbar:Update() end
    end)
end)
local function sepLines(b, geo, seps, look)
    if not (seps and seps[1]) then return nil end
    local out = {}
    for _, s in ipairs(seps) do
        local l, t, w, h = Grid().SepLine(geo, s, look.inset, look.w)
        local ox, oy = s.v and s.x + 1 or s.x, s.v and s.y or s.y + 1
        out[#out + 1] = { l = l, t = t, w = w, h = h, a = ns.buffbar:IconAt(b.key, s.x, s.y), b = ns.buffbar:IconAt(b.key, ox, oy) }
    end
    return out
end
local function layoutBlock(fr, i, b, edit, n)
    local grid = Grid()
    local geo = grid.Geo(ns.Look.Bar(i, "pad"), ns.Look.Bar(i, "gap"))
    local seps = b.seps and grid.Seps(b, sepClass) or nil
    local sepLook = ns.Blocks.SepLook(b.sepLook)
    if seps and seps[1] then geo = grid.Spread(geo, b, seps, sepLook.w + 2 * SEP_SIDE) end
    if math.abs(fr:GetScale() - barScale(i)) > 0.001 then fr:SetScale(barScale(i)) end
    placeBar(fr, i, b)
    local w, h = grid.Pixels(geo, b.cols, b.rows)
    fr:SetWidth(w)
    fr:SetHeight(h)
    ns.Blocks.Bind(fr, i, b, geo)
    local dmode = digitsMode(b)
    local now = ns.Cond.Now()
    local allowed = ns.Cond.Allows(b.cond, nil, now)
    local live = not edit and not b.off and ns.Cond.Allows(b.cond, "combat", now)
    local macro = live and ns.Cond.Driver(b.cond) or nil
    n.round = ns.Look.Bar(i, "round")
    n.absent = ns.Look.Bar(i, "absent")
    local drew = false
    if edit or (not b.off and (allowed or macro)) then
        for _, item in ipairs(b.items or {}) do
            local entry, kind, cat = ns.Preset.Resolve(item)
            if kind == "want" then
                drew = putWant(fr, b, geo, item, dmode, n, edit) or drew
            elseif kind == "widget" then
                drew = putWidget(fr, b, geo, item, edit, n) or drew
            elseif entry then
                putIcon(fr, b, geo, item, item.x, item.y, entry, kind or "spell", cat or ROLE_CAT[item.role] or "personal",
                        dmode, n)
                if entry.unit then n.units[entry.unit] = true end
                if item.rules then n.rules[#n.rules + 1] = item.rules end
                drew = true
            end
        end
    end
    if b.cond and b.cond.rules and not b.off then n.rules[#n.rules + 1] = b.cond.rules end
    ns.Blocks.Seps(fr, drew and sepLines(b, geo, seps, sepLook) or nil, sepLook)
    local wdrv = live and drew and soleDriver(b) or nil
    if wdrv then macro = ns.Cond.Combine(b.cond, wdrv) end
    if not drew then macro = nil end
    ns.Blocks.Drive(fr, macro)
    if not wdrv then
        if edit or (drew and allowed) then fr:Show() elseif not macro then fr:Hide() end
    end
    if not b.point and ns.Snap.Held() ~= fr then
        ns.Blocks.SavePos(fr)
        if b.point then placeBar(fr, i, b) end
    end
    ns.Blocks.Dress(fr, edit)
    ns.Style.Deco(fr, i, b, edit)
end
local function layout()
    layouts = layouts + 1
    local list = blocks()
    local edit = inConfig()
    local n = { bi = 0, ti = 0, units = {}, widgets = {}, enc = {}, rules = {} }
    releaseMoved(list)
    laying = true
    for i, b in ipairs(list) do
        layoutBlock(ns.Blocks.FrameAt(i), i, b, edit, n)
    end
    laying = false
    pruneWidgets(n)
    ns.Cond.Watch(n.rules)
    if ns.Cond.RuleUnits().tank then n.units.tank = true end
    ns.Auras.Want(n.units)
    ns.Encounter.Want(n.enc)
    for i = n.bi + 1, #icons  do
        icons[i]:Hide()
        icons[i].click:Hide()
        ns.Style.Release(icons[i])
    end
    for i = n.ti + 1, #ticons do
        ticons[i]:Hide()
        ns.Style.Release(ticons[i])
        if ticons[i].useBtn then ticons[i].useBtn:Hide() end
    end
    ns.Blocks.HideFrom(#list + 1)
end
local function refill(combat)
    for _, f in ipairs(icons) do
        if f:IsShown() and f._kind then fillIcon(f, f._kind, f._entry, combat) end
    end
    for _, f in ipairs(ticons) do
        if f:IsShown() and f._kind then fillTrackIcon(f, f._kind, f._entry) end
    end
    ns.Blocks.SepsTick()
end
function ns.buffbar:Refresh()
    if not bar or not cfg().show then return end
    refill(InCombatLockdown())
end
ns.Cond.OnRules(function()
    if not bar or not cfg().show then return end
    local combat = InCombatLockdown() and true or false
    for _, f in ipairs(icons) do
        if f:IsShown() and f._kind and f._item and f._item.rules then fillIcon(f, f._kind, f._entry, combat) end
    end
    for _, f in ipairs(ticons) do
        if f:IsShown() and f._kind and f._item and f._item.rules then fillTrackIcon(f, f._kind, f._entry) end
    end
end)
function ns.buffbar:Update()
    if not bar or not cfg().show then return end
    if InCombatLockdown() then
        refill(true)
        return
    end
    ns.Preset.Invalidate(true)
    layout()
    if ns.PanelCard and ns.PanelCard.IsShown() then ns.PanelCard.Refresh() end
    if ns.EntryCard then ns.EntryCard.Refresh() end
    if ns.EditBar and ns.EditBar.Refresh then ns.EditBar.Refresh() end
end
function ns.buffbar:UpdateTrack()
    if not bar or not cfg().show then return end
    for _, f in ipairs(ticons) do
        if f:IsShown() and f._kind then fillTrackIcon(f, f._kind, f._entry) end
    end
end
local pulse = 0
local PULSE_PERIOD = math.pi / 2
local function pulseGlows(elapsed)
    pulse = (pulse + elapsed) % PULSE_PERIOD
    local a = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(pulse * 4))
    for _, f in ipairs(icons) do
        if f:IsShown() and f.glow:IsShown() then f.glow:SetAlpha(a) end
    end
end
local tacc, bacc = 0, 0
local function trackTick(elapsed)
    bacc = bacc + elapsed
    if bacc >= BUFF_TICK then
        bacc = 0
        for _, f in ipairs(icons) do
            if f:IsShown() then setBuffNumbers(f) end
        end
    end
    tacc = tacc + elapsed
    if tacc < TRACK_TICK then return end
    tacc = 0
    if bacc > 0 then
        for _, f in ipairs(icons) do
            if f._fast and f:IsShown() then setBuffNumbers(f) end
        end
    end
    ns.buffbar:UpdateTrack()
    ns.Blocks.SepsTick()
end
local function targetStackIcons()
    if not bar or not cfg().show then return end
    for _, f in ipairs(icons) do
        if f._tstk and f:IsShown() then setBuffNumbers(f) end
    end
end
local function build()
    bar = ns.Blocks.Root()
    ns.buffbar:ApplyTheme()
    host = CreateFrame("Frame")
    host:RegisterEvent("UNIT_AURA")
    host:RegisterEvent("PLAYER_REGEN_ENABLED")
    host:RegisterEvent("BAG_UPDATE")
    host:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    host:RegisterEvent("UNIT_INVENTORY_CHANGED")
    host:RegisterEvent("PLAYER_TARGET_CHANGED")
    host:SetScript("OnEvent", function(self, event, unit)
        if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then return end
        if event == "UNIT_AURA" then
            if unit == "player" then ns.buffbar:Refresh()
            elseif unit == "target" then targetStackIcons() end
        elseif event == "PLAYER_TARGET_CHANGED" then
            targetStackIcons()
        elseif event == "BAG_UPDATE" then
            ns.buffbar:Refresh()
        else
            ns.buffbar:Update()
        end
    end)
    host:SetScript("OnUpdate", function(self, elapsed)
        if not cfg().show then return end
        pulseGlows(elapsed)
        slideTick(elapsed)
        flipTick(elapsed)
        trackTick(elapsed)
    end)
    bar:Hide()
end
local plate = { insets = { left = 0, right = 0, top = 0, bottom = 0 } }
local function plateBackdrop(p, round)
    local bd = p and p.backdrop
    plate.bgFile   = (bd and bd.bgFile) or "Interface\\Tooltips\\UI-Tooltip-Background"
    plate.tile     = (bd and bd.tile) and true or false
    plate.tileSize = (bd and bd.tileSize) or 16
    return plate, ns.Look.PlateEdge(plate, round)
end
function ns.buffbar:ApplyTheme()
    if not bar then return end
    local t = ns.CurrentTheme()
    local p = t and t.panel
    local config = inConfig()
    local c = (p and p.bgColor) or { 0, 0, 0, 0.6 }
    for i, f in pairs(ns.Blocks.Frames()) do
        local frame = ns.Style.Bar(i, "frame")
        if frame ~= "auto" then
            ns.Style.Plate(f, frame, c, ns.Look.Bar(i, "plate"), p and p.borderColor)
        elseif ns.Look.Get("plate") == "none" then
            f:SetBackdrop(nil)
        else
            local bd, edged = plateBackdrop(p, ns.Look.Bar(i, "plateRound"))
            local a = ns.Look.Bar(i, "plate")
            f:SetBackdrop(bd)
            f:SetBackdropColor(c[1], c[2], c[3], a)
            if edged then
                local b = (p and p.borderColor) or { 0, 0, 0 }
                f:SetBackdropBorderColor(b[1], b[2], b[3], math.min(1, a * 2.5))
            end
        end
        if not InCombatLockdown() then
            f:EnableMouse(config)
            f:EnableMouseWheel(config)
        end
        ns.Blocks.SepsTint(f)
    end
end
local function later(key, fn)
    ns.DeferKey(key, fn)
    if ns.say then ns.say(ns.T("bar.later")) end
end
function ns.buffbar:Record(x)
    local i = at(x)
    return i and blocks()[i]
end
function ns.buffbar:IndexOf(b)
    return b and barIndex(b.key)
end
function ns.buffbar:BarIndex(id)
    return barIndex(id)
end
function ns.buffbar:BarById(id)
    local i = barIndex(id)
    return i and blocks()[i]
end
function ns.buffbar:BarName(x)
    local i = at(x)
    return i and ns.BarName(blocks()[i], i)
end
function ns.buffbar:SetBarName(x, name)
    local b = self:Record(x)
    if not b then return false end
    name = tostring(name or ""):gsub("%c", ""):gsub("||", "|"):gsub("|", "||"):match("^%s*(.-)%s*$")
    name = (name ~= "") and name or nil
    if name == b.name then return true end
    ns.Preset.SetBlock(b.key, "name", name)
    if ns.PanelCard then ns.PanelCard.Refresh() end
    if ns.Options then ns.Options.Refresh() end
    return true
end
function ns.buffbar:GetScale(x)
    if x then return barScale(at(x) or 0) end
    local v
    for j = 1, #blocks() do
        local s = barScale(j)
        if v and math.abs(v - s) > 0.001 then return nil end
        v = s
    end
    return v or cfg().scale or 1
end
function ns.buffbar:SetScale(v, x)
    local i = x and at(x)
    if x and not i then return barScale(0) end
    if InCombatLockdown() then
        local id = i and blocks()[i].key
        if not id then
            for _, b in ipairs(blocks()) do ns.DeferDrop(b.key .. ".scale") end
        end
        later((id or "panel") .. ".scale", function()
            if id and not barIndex(id) then return end
            ns.buffbar:SetScale(v, id)
        end)
        return barScale(i or 1)
    end
    v = tonumber(v) or 1
    if v < ns.BAR_SCALE.min then v = ns.BAR_SCALE.min elseif v > ns.BAR_SCALE.max then v = ns.BAR_SCALE.max end
    local frames = ns.Blocks.Frames()
    if i then
        local b = blocks()[i]
        if frames[i] then ns.Blocks.Rescale(frames[i], v) end
        ns.Preset.SetBlock(b.key, "scale", v)
    else
        cfg().scale = v
        for j, b in ipairs(blocks()) do
            if frames[j] then ns.Blocks.Rescale(frames[j], v) end
            if b.scale then ns.Preset.SetBlock(b.key, "scale", nil) end
        end
        self:Update()
    end
    return v
end
function ns.buffbar:Apply()
    if not bar then return end
    self:ApplyTheme()
    if cfg().show then
        bar:Show()
        self:Update()
    else
        for _, f in pairs(ns.Blocks.Frames()) do
            if not InCombatLockdown() then ns.Blocks.Drive(f, nil) end
            f:Hide()
        end
        pruneWidgets({ widgets = {} })
    end
    if ns.Chrome then ns.Chrome.Apply() end
end
function ns.buffbar:Bars()
    local out = {}
    for i, b in ipairs(blocks()) do
        local names, seen = {}, {}
        for _, it in ipairs(b.items or {}) do
            local cat = ROLE_CAT[it.role or ""] or "personal"
            if not seen[cat] then
                seen[cat] = true
                names[#names + 1] = groupName(cat)
            end
        end
        local has = #(b.items or {}) > 0
        out[i] = { id = b.key, index = i, name = ns.BarName(b, i), cols = b.cols, rows = b.rows,
                   groups = names, empty = not has, holds = has, off = barOff(b) }
    end
    return out
end
function ns.buffbar:Removed(x)
    local out = {}
    for _, g in ipairs(ns.Preset.Gone()) do
        local item = { k = g.k, role = g.role }
        local entry, kind = ns.Preset.Resolve(item)
        local name, icon
        if entry and kind ~= "want" then
            if entry.link or entry.item then
                local nm, _, _, _, _, _, _, _, _, ic = GetItemInfo(entry.link or entry.item)
                name, icon = nm, ic
            elseif entry.id then
                local nm, _, ic = GetSpellInfo(entry.id)
                name, icon = nm, ic
            end
        end
        local cat = ROLE_CAT[g.role or ""] or "personal"
        out[#out + 1] = { key = g.k, cat = g.role or "self", name = name or g.k, icon = icon, group = groupName(cat) }
    end
    return out
end
function ns.buffbar:Restore(role, key, x)
    local b = x and self:Record(x)
    local rx = ns.Preset.Restore(key, role, b and b.key or nil)
    return rx ~= nil
end
function ns.buffbar:DigitsMode(x)
    return digitsMode(self:Record(x))
end
function ns.buffbar:BarSeps(x)
    local b = self:Record(x)
    return (b and b.seps) and true or false
end
function ns.buffbar:SetBarSeps(x, on)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    local b = self:Record(x)
    if not b then return false end
    local ok = ns.Preset.SetBlock(b.key, "seps", on and true or nil)
    if ns.PanelCard then ns.PanelCard.Refresh() end
    return ok and true or false
end
function ns.buffbar:BarSepLook(x)
    local b = self:Record(x)
    return ns.Blocks.SepLook(b and b.sepLook)
end
local SEP_DEFAULT = { w = 1, len = "inset", kind = "solid" }
local SEP_FIELDS = { c = true, w = true, a = true, len = true, kind = true }
function ns.buffbar:SetBarSepLook(x, field, v)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    local b = self:Record(x)
    if not (b and SEP_FIELDS[field]) then return false end
    if field == "a" and v ~= nil and math.abs(v - ns.Blocks.SEP_LIMITS.alpha) < 0.001 then v = nil end
    if v == SEP_DEFAULT[field] then v = nil end
    local t = {}
    for k, val in pairs(type(b.sepLook) == "table" and b.sepLook or {}) do t[k] = val end
    t[field] = v
    local ok = ns.Preset.SetBlock(b.key, "sepLook", next(t) and t or nil)
    if ns.PanelCard then ns.PanelCard.Refresh() end
    return ok and true or false
end
function ns.buffbar:DigitsModes()
    return DIGITS_MODES
end
function ns.buffbar:SetDigitsMode(x, v)
    local b = self:Record(x)
    if not b then return end
    local was = b.digits
    b.digits = nil
    local auto = digitsMode(b)
    b.digits = was
    ns.Preset.SetBlock(b.key, "digits", auto ~= v and v or nil)
    if ns.PanelCard then ns.PanelCard.Refresh() end
end
local ICON_TIPS = { "always", "ooc", "never" }
function ns.buffbar:IconTipModes()
    return ICON_TIPS
end
function ns.buffbar:IconTipsNow()
    return iconTipsNow()
end
function ns.buffbar:IconTips()
    return cfg().iconTips or "ooc"
end
function ns.buffbar:SetIconTips(v)
    cfg().iconTips = (v ~= "ooc") and v or nil
end
function ns.buffbar:IsBarOff(x)
    return barOff(self:Record(x))
end
function ns.buffbar:SetBarOff(x, v)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    local b = self:Record(x)
    if not b then return false end
    if not ns.Preset.SetBlock(b.key, "off", v and true or nil) then return false end
    if ns.Chrome then ns.Chrome.Apply() end
    if ns.PanelCard then ns.PanelCard.Refresh() end
    if ns.Options then ns.Options.Refresh() end
    return true
end
function ns.buffbar:Size(x)
    local b = self:Record(x)
    if not b then return 1, 1 end
    return b.cols, b.rows
end
function ns.buffbar:Resize(x, cols, rows)
    local b = self:Record(x)
    if not b then return false end
    local id = b.key
    if InCombatLockdown() then
        later(id .. ".size", function()
            if barIndex(id) then ns.buffbar:Resize(id, cols, rows) end
        end)
        return false
    end
    local xc, xr = ns.Blocks.MaxSize(id)
    cols = math.max(1, math.min(xc, math.floor(tonumber(cols) or 1)))
    rows = math.max(1, math.min(xr, math.floor(tonumber(rows) or 1)))
    if b.cols == cols and b.rows == rows then return true end
    local ok = ns.Preset.Resize(id, cols, rows) and true or false
    if ns.PanelCard then ns.PanelCard.Refresh() end
    if ns.Options then ns.Options.Refresh() end
    return ok
end
function ns.buffbar:PreviewCooldown(x, dur)
    local b = self:Record(x)
    if not b then return 0 end
    dur = tonumber(dur) or 2
    local now = GetTime()
    local n = 0
    for _, list in ipairs({ icons, ticons }) do
        for _, f in ipairs(list) do
            if f:IsShown() and f._key == b.key and f.cd then
                f._preview = now + dur
                f._cdStart = nil
                ns.Style.Sweep(f, now, dur, false, 1)
                n = n + 1
            end
        end
    end
    return n
end
function ns.buffbar:RemoveItem(key, x, y)
    return ns.Preset.Remove(key, x, y) and true or false
end
function ns.buffbar:SetItemShow(key, x, y, v)
    return ns.Preset.Set(key, x, y, "show", v) and true or false
end
function ns.buffbar:NewBlock(item, rect)
    local key = ns.Preset.NewBlock(item, rect)
    if not key then return nil end
    if not cfg().show then self:SetShown(true) end
    return key
end
function ns.buffbar:IconAt(key, x, y)
    for _, list in ipairs({ icons, ticons }) do
        for _, f in ipairs(list) do
            if f:IsShown() and f._key == key and f._cx == x and f._cy == y then return f end
        end
    end
    return widgetAt(key, x, y)
end
function ns.buffbar:WidgetAt(key, x, y)
    return whosts[waddr(key, x, y)]
end
function ns.buffbar:SetWidgetView(key, x, y, view)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    local ok, busy = ns.Preset.SetView(key, x, y, view)
    if ok then return true end
    if #busy > 0 then
        ns.Blocks.Blink(key, busy)
        if ns.say then ns.say(ns.T("bar.view_busy")) end
    elseif ns.say then
        ns.say(ns.T("bar.view_room"))
    end
    return false
end
function ns.buffbar:SetWidgetOpt(key, x, y, optKey, v)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    local ok, busy = ns.Preset.SetOpt(key, x, y, optKey, v)
    if ok then return true end
    if busy and #busy > 0 then
        ns.Blocks.Blink(key, busy)
        if ns.say then ns.say(ns.T("bar.view_busy")) end
    elseif ns.say then
        ns.say(ns.T("bar.view_room"))
    end
    return false
end
function ns.buffbar:CycleWidgetView(key, x, y)
    local it = ns.Preset.ItemAt(key, x, y)
    local name = it and ns.Widget.NameOf(it.k)
    local nxt = name and ns.Widget.NextView(name, it.view)
    if not nxt then return false end
    return self:SetWidgetView(key, x, y, nxt)
end
function ns.buffbar:AddBar()
    if InCombatLockdown() then
        if not ns.DeferHas("panel.add") then later("panel.add", function() ns.buffbar:AddBar() end) end
        return nil
    end
    local key = self:NewBlock(nil, nil)
    if not key then return nil end
    return barIndex(key), key
end
function ns.buffbar:RemoveBar(x)
    local b = self:Record(x)
    if not b then return false end
    local id = b.key
    if InCombatLockdown() then
        later(id .. ".remove", function()
            if barIndex(id) then ns.buffbar:RemoveBar(id) end
        end)
        return false
    end
    if #(b.items or {}) > 0 or #blocks() < 2 then return false end
    if not ns.Preset.RemoveBlock(id) then return false end
    if ns.Chrome then ns.Chrome.Apply() end
    return true
end
function ns.buffbar:Panels()
    if not bar then return {} end
    local frames = ns.Blocks.Frames()
    local out = {}
    for i, b in ipairs(blocks()) do
        local f = frames[i]
        if f and f:IsShown() then out[#out + 1] = { id = b.key, index = i, frame = f } end
    end
    return out
end
function ns.buffbar:Init()
    if not bar then build() end
    self:Apply()
end
function ns.buffbar:SetShown(v)
    v = v and true or false
    if InCombatLockdown() then
        if v == self:IsShown() and not ns.DeferHas("panel.shown") then return true end
        later("panel.shown", function() ns.buffbar:SetShown(v) end)
        return false
    end
    cfg().show = v
    self:Apply()
    return true
end
function ns.buffbar:SetLocked(v)
    v = v and true or false
    if InCombatLockdown() then
        if v == locked() and not ns.DeferHas("panel.locked") then return true end
        later("panel.locked", function() ns.buffbar:SetLocked(v) end)
        return false
    end
    cfg().locked = v
    if not v and not cfg().show then self:SetShown(true) end
    self:Apply()
    return true
end
function ns.buffbar:IsShown()  return cfg().show  and true or false end
function ns.buffbar:IsLocked() return cfg().locked and true or false end
function ns.buffbar:ResetBars(id)
    if InCombatLockdown() then
        later("panel.reset", function() ns.buffbar:ResetBars(id) end)
        return false
    end
    local ok = ns.Preset.Reset(id) and true or false
    local frames = ns.Blocks.Frames()
    for i = 2, #frames do
        if frames[i] then frames[i]:Hide() end
    end
    self:Update()
    for i, f in pairs(frames) do
        if blocks()[i] then f:SetScale(barScale(i)) end
    end
    return ok
end
ns.buffbar.Face = {}
function ns.buffbar.Face.Make(parent, size)
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(size)
    f:SetHeight(size)
    face(f, nil)
    f.txt:SetFrameLevel(f:GetFrameLevel() + 7)
    return f
end
function ns.buffbar.Face.Dress(f, panel)
    panel = panel or {}
    f._dmode, f._round, f._absent = panel.dmode or "bottom", panel.round, panel.absent
    ns.Style.Resolve(f, panel.block, panel.item)
    ns.Look.StyleIcon(f)
    sizeDigits(f)
end
function ns.buffbar.Face.Spots(f)
    return (spotsFor(f))
end
ns.buffbar.Face.Put = put
function ns.buffbar.Face.MarkColor(great)
    return markColor(great)
end
function ns.buffbar.Face.Absent(f)
    return absentAlpha(f)
end
function ns.buffbar.Face.Warn(f)
    return warnMark(f)
end
