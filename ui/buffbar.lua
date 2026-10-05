local ADDON, ns = ...
local ICON = 32
local ROWGAP = 6
local MIN_SCALE, MAX_SCALE = 0.5, 2.5
local GRAB, GRAB_STEP = 16, 150
local NUM_MAIN, NUM_EDGE = 13, 9
local function numSize(fs, px)
    local file, _, flags = fs:GetFont()
    if file then fs:SetFont(file, px, flags) end
end
local TRACK_TICK = 0.1
local BUFF_TICK  = 1.0
local bar, host
local resizers = {}
local icons = {}
local ticons = {}
local picks = {}
local swapEntry, flipBlessing, dropBar, grabBar
local STACK_OFF = 4
local STACK_SZ  = ICON - 8
local FLIP      = 0.22
local flipping  = {}
ns.buffbar = {}
local function cfg()
    LazyBuffBarDB = LazyBuffBarDB or {}
    return LazyBuffBarDB
end
local function savePos(f, i)
    if not f or not i then return end
    local p, _, rp, x, y = f:GetPoint()
    local bc = cfg().bars and cfg().bars[i]
    if bc then bc.point = { p, rp, x, y } end
end
local function locked() return cfg().locked and true or false end
local function inConfig() return not locked() end
local function barScale(i)
    local c = cfg()
    local bc = c.bars and c.bars[i]
    return (bc and bc.scale) or c.scale or 1
end
local function iconEnter(self)
    if not self.spellId then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("spell:" .. self.spellId)
    GameTooltip:Show()
end
local function foodTip(self)
    GameTooltip:AddLine(ns.T("food.title"), 1, 1, 1)
    GameTooltip:AddLine(ns.T("food.body"), 1, 0.82, 0, true)
    if not self.tipOn then
        GameTooltip:AddLine(ns.T("food.off"), 1, 0.35, 0.35, true)
    end
end
local OWN_TIP = { food = foodTip }
local function blessTip(self)
    if ns.MyBlessing() ~= self.bless.key then
        GameTooltip:AddLine(ns.T("bless.pick"), 1, 0.82, 0, true)
        return
    end
    GameTooltip:AddLine(ns.T("bless.mine"), 1, 0.82, 0, true)
    if not self.castGreat then
        GameTooltip:AddLine(ns.T(ns.BlessingWantsPlain() and "bless.plain_pick" or "bless.plain"),
                            1, 0.55, 0.25, true)
    end
    GameTooltip:AddLine(ns.T("bless.flip"), 0.6, 0.6, 0.6, true)
    if InCombatLockdown() then
        GameTooltip:AddLine(ns.T("bless.combat"), 1, 0.35, 0.35, true)
    elseif self.castUnit then
        GameTooltip:AddLine(ns.T("bless.next", ns.CLASS_NAME[self.castClass] or "?",
                                 UnitName(self.castUnit) or "?"), 1, 1, 1, true)
    else
        GameTooltip:AddLine(ns.T("bless.done"), 0.4, 1, 0.4, true)
    end
    GameTooltip:AddLine(ns.T("bless.drop"), 0.6, 0.6, 0.6, true)
end
local function auraTip(self)
    if self.auraOn then
        GameTooltip:AddLine(ns.T("aura.mine"), 0.4, 1, 0.4, true)
    else
        GameTooltip:AddLine(ns.T("aura.none"), 1, 0.35, 0.35, true)
    end
end
local function wantTip(self)
    local buff = self._entry and self._entry.want
    if not buff then return end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(self.tipOn and ns.T("want.have") or ns.T("want.miss"),
                        self.tipOn and 0.4 or 1, self.tipOn and 0.9 or 0.35,
                        self.tipOn and 0.4 or 0.35, true)
    GameTooltip:AddLine(buff.note, 0.9, 0.9, 0.9, true)
    if buff.maybe then GameTooltip:AddLine(ns.T("want.maybe"), 0.85, 0.7, 0.2, true) end
    GameTooltip:AddLine(ns.T("want.givers", ns.Incoming.Givers(buff)), 0.6, 0.8, 1, true)
end
local function itemEnter(self)
    local own = self.tipKind and OWN_TIP[self.tipKind]
    if own then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        own(self)
        GameTooltip:Show()
    elseif self.spellId then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("spell:" .. self.spellId)
        if self.bless then GameTooltip:AddLine(" "); blessTip(self) end
        if self.auraOn ~= nil then GameTooltip:AddLine(" "); auraTip(self) end
        if self._entry and self._entry.want then wantTip(self) end
        GameTooltip:Show()
    elseif self.itemId then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. self.itemId)
        GameTooltip:Show()
    end
end
local function acquireIcon(i)
    local f = icons[i]
    if not f then
        f = CreateFrame("Button", "LazyBuffBarBtn" .. i, bar, "SecureActionButtonTemplate")
        f:SetWidth(ICON)
        f:SetHeight(ICON)
        f:RegisterForClicks("AnyUp")
        f:RegisterForDrag("LeftButton")
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
        f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
        f.cd:SetAllPoints(f)
        f.cd:SetReverse(true)
        f.cd:Hide()
        f.cd.noCooldownCount = true
        ns.Look.AttachEdge(f)
        f.txt = CreateFrame("Frame", nil, f)
        f.txt:SetAllPoints(f)
        f.txt:SetFrameLevel(f.cd:GetFrameLevel() + 5)
        f.count = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
        f.count:Hide()
        f.left = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        f.left:SetPoint("CENTER", f, "CENTER", 0, 0)
        f.left:SetWidth(ICON); f.left:SetJustifyH("CENTER")
        numSize(f.left, NUM_MAIN)
        f.left:Hide()
        f.rmin = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        f.rmin:SetPoint("TOP", f, "TOP", 0, 0)
        f.rmin:SetWidth(ICON); f.rmin:SetJustifyH("CENTER")
        numSize(f.rmin, NUM_EDGE)
        f.rmin:Hide()
        f.rn = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        f.rn:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
        f.rn:SetWidth(ICON); f.rn:SetJustifyH("CENTER")
        numSize(f.rn, NUM_EDGE)
        f.rn:Hide()
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
        f:SetScript("PostClick", function(self, button)
            if InCombatLockdown() then return end
            if button == "RightButton" then
                if self.bless then
                    ns.SetMyBlessing(ns.MyBlessing() ~= self.bless.key and self.bless.key or nil)
                end
                return
            end
            ns.buffbar:Update()
        end)
        f:SetScript("OnEnter", itemEnter)
        f:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f:EnableMouseWheel(true)
        f:SetScript("OnMouseWheel", function(self, delta)
            if InCombatLockdown() then return end
            if IsControlKeyDown() then
                if self.bless and ns.MyBlessing() == self.bless.key then
                    flipBlessing(self, delta)
                end
            elseif IsAltKeyDown() then
                swapEntry(self, delta)
            end
        end)
        f:SetScript("OnDragStart", function(self) grabBar(self:GetParent()) end)
        f:SetScript("OnDragStop", function(self)
            local p = self:GetParent()
            if p then dropBar(p) end
        end)
        icons[i] = f
    end
    return f
end
local PICK_SZ = 18
local function acquirePick(i)
    local c = picks[i]
    if not c then
        c = ns.MakeCheck(bar)
        c.label:Hide()
        c:SetWidth(PICK_SZ)
        c:SetHeight(PICK_SZ)
        c:SetFrameLevel(bar:GetFrameLevel() + 20)
        c:SetScript("OnClick", function(self)
            self:SetChecked(not self:GetChecked())
            if self.pickKey and ns.SetBarPicked then
                ns.SetBarPicked(self.pickKey, self:GetChecked())
            end
        end)
        c:SetScript("OnEnter", function(self)
            self.hovered = true
            if ns.StyleCheck then ns.StyleCheck(self) end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self:GetChecked() and "Убрать с панели" or "Показывать на панели",
                                1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        c:SetScript("OnLeave", function(self)
            self.hovered = false
            if ns.StyleCheck then ns.StyleCheck(self) end
            GameTooltip:Hide()
        end)
        picks[i] = c
    end
    return c
end
local function attachPick(parentBar, anchor, entry, n)
    if not inConfig() or not entry._key then return n end
    local c = acquirePick(n)
    c:SetParent(parentBar)
    c:SetFrameLevel(parentBar:GetFrameLevel() + 20)
    c.pickKey = entry._key
    c:SetChecked(entry._on and true or false)
    c:ClearAllPoints()
    c:SetPoint("CENTER", anchor, "TOPLEFT", 2, -2)
    c:Show()
    return n + 1
end
local function setCount(f, n)
    if not n or n <= 0 then f.count:Hide(); return end
    f.count:SetText(n)
    f.count:Show()
end
local function ownDigits()
    return ns.Look.Get("digits") ~= "omnicc"
end
local function absentAlpha()
    return ns.Look.Get("absent")
end
local function fmtLeft(t)
    if not t or t <= 0 then return nil end
    if t >= 3600 then return ("%dч"):format(math.floor(t / 3600)) end
    if t >= 60   then return ("%dм"):format(math.floor(t / 60)) end
    if t >= 10   then return ("%d"):format(math.floor(t)) end
    return ("%.1f"):format(t)
end
local function setBuffSweep(f, name)
    local left, duration, start = nil, nil, nil
    if name and ns.BuffLeft then left, duration, start = ns.BuffLeft(name) end
    if left and duration and duration > 0 and start then
        f.cd.noCooldownCount = ownDigits() or nil
        f.cd:SetCooldown(start, duration)
        f.cd:Show()
    else
        f.cd:Hide()
    end
    return left
end
local function setBuffNumbers(f)
    local kind, e = f._kind, f._entry
    if kind ~= "spell" or not e then
        setBuffSweep(f, (kind == "item" and e and e.aura) and GetSpellInfo(e.aura) or nil)
        f.left:Hide(); f.rmin:Hide(); f.rn:Hide()
        return
    end
    local se = f._self or e
    local name = ns.ActiveBuffName(se) or GetSpellInfo(se.id)
    local mine = setBuffSweep(f, name)
    local txt = ownDigits() and fmtLeft(mine)
    if txt then f.left:SetText(txt); f.left:Show() else f.left:Hide() end
    if e._cat == "raid" and ns.GroupBuffNumbers then
        local n, total, min = ns.GroupBuffNumbers(e)
        if total > 0 then
            f.rn:SetText(n .. "/" .. total)
            f.rn:Show()
            local mtxt = fmtLeft(min)
            if mtxt then f.rmin:SetText(mtxt); f.rmin:Show() else f.rmin:Hide() end
            return
        end
    end
    f.rmin:Hide(); f.rn:Hide()
end
local PLAIN_MARK = { 1, 0.55, 0.25 }
local function markColor(great)
    if not great then return PLAIN_MARK[1], PLAIN_MARK[2], PLAIN_MARK[3] end
    local t = ns.themes and ns.themes[ns.window and ns.window:GetSkin() or nil]
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
    f.tex:SetAlpha(1)
    f.tex:SetDrawLayer("ARTWORK")
    lerpFace(f.stack, f, 0)
    f.stack:SetDrawLayer("BACKGROUND")
end
local function setStack(f)
    local b = f.bless
    if not b or ns.MyBlessing() ~= b.key then f.stack:Hide(); return end
    local other = f._self and b.great or b.plain
    f.stack:SetTexture((select(3, GetSpellInfo(other))))
    f.stack:SetDesaturated(other == b.great and ns.BlessingSymbols() == 0)
    f.stack:Show()
end
local function setMark(f)
    if not (f.bless and ns.MyBlessing() == f.bless.key) then f.mark:Hide(); return end
    local r, g, b = markColor(f.castGreat)
    f.mark:SetVertexColor(r, g, b, 1)
    f.mark:Show()
end
local function setAction(f, kind, entry)
    f:SetAttribute("type", nil)
    f:SetAttribute("type1", nil)
    f:SetAttribute("unit", nil)
    f.castUnit, f.castClass, f.castGreat = nil, nil, false
    if entry.noAction then return end
    if kind ~= "spell" then
        f:SetAttribute("type1", "item")
        f:SetAttribute("item", "item:" .. entry.item)
        return
    end
    if f.bless and ns.MyBlessing() == f.bless.key then
        local unit, spell, great, class = ns.NextBlessingCast(f.bless)
        f.castUnit, f.castClass, f.castGreat = unit, class, great
        if unit and spell then
            f:SetAttribute("type1", "spell")
            f:SetAttribute("spell", spell)
            f:SetAttribute("unit", unit)
        end
        return
    end
    f:SetAttribute("type1", "spell")
    f:SetAttribute("spell", (GetSpellInfo(entry.id)))
end
local function fillIcon(f, kind, entry, combat)
    f._kind, f._entry = kind, entry
    ns.Look.StyleIcon(f)
    f.spellId, f.itemId = nil, nil
    f.tipKind, f.tipOn = entry.tipKind, false
    local b = (kind == "spell") and ns.BlessingOf and ns.BlessingOf(entry.id) or nil
    if b and not ns.IsLearned(b.great) then b = nil end
    f.bless = b
    f.auraOn = entry.state
    f._self = nil
    if kind == "spell" then
        if not combat then setAction(f, kind, entry) end
        local shown = entry.id
        if b and ns.MyBlessing() == b.key and not f.castGreat then
            shown = b.plain
            f._self = { id = b.plain, alt = { b.great } }
        end
        f.spellId = shown
        setMark(f)
        if not f._flip then
            f.tex:SetTexture((select(3, GetSpellInfo(shown))))
            setStack(f)
        end
        local has = entry.state
        if has == nil and entry.single and ns.GroupBuffNumbers then
            has = ns.GroupBuffNumbers(entry) > 0
        elseif has == nil then
            has = ns.ActiveBuffName(f._self or entry) ~= nil
        end
        f.tipOn = has
        f.tex:SetDesaturated(not has)
        f._dim = has and 1 or absentAlpha()
        if has or entry.soft then f.glow:Hide() else f.glow:Show() end
        setCount(f, nil)
        setBuffNumbers(f)
    else
        f.mark:Hide()
        f.stack:Hide()
        f.itemId = entry.item
        f.tex:SetTexture((select(10, GetItemInfo(entry.item))) or ns.QMARK)
        if not combat then setAction(f, kind, entry) end
        local bag = (GetItemCount and GetItemCount(entry.item)) or 0
        local has
        if entry.aura then
            local an = GetSpellInfo(entry.aura)
            has = an and ns.HasBuff(an)
        else
            has = bag > 0
        end
        f.tex:SetDesaturated(not has)
        f._dim = has and 1 or absentAlpha()
        if has then f.glow:Hide() else f.glow:Show() end
        setCount(f, bag)
        setBuffNumbers(f)
    end
    if inConfig() and not entry._on then
        f:SetAlpha(0.3)
        f.glow:Hide()
    else
        f:SetAlpha(f._dim or 1)
    end
end
local function trackEnter(self)
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    elseif self.spellId then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("spell:" .. self.spellId)
        GameTooltip:Show()
    end
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
        f.count:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
        f.count:Hide()
        f.timer = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        f.timer:SetPoint("CENTER", f, "CENTER", 0, 0)
        f.timer:SetWidth(ICON); f.timer:SetJustifyH("CENTER")
        f.timer:Hide()
        f:SetScript("OnEnter", trackEnter)
        f:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f:EnableMouseWheel(true)
        f:SetScript("OnMouseWheel", function(self, delta)
            if not IsAltKeyDown() or InCombatLockdown() then return end
            swapEntry(self, delta)
        end)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) grabBar(self:GetParent()) end)
        f:SetScript("OnDragStop", function(self)
            local p = self:GetParent()
            if p then dropBar(p) end
        end)
        ticons[i] = f
    end
    return f
end
local function tintTrack(f, st)
    if ns.Look.Get("tint") and st.far then
        f.tex:SetVertexColor(1, 0.35, 0.35)
    elseif ns.Look.Get("tint") and st.noMana then
        f.tex:SetVertexColor(0.45, 0.55, 1)
    else
        f.tex:SetVertexColor(1, 1, 1)
    end
end
local function fillTrackIcon(f, kind, entry)
    f._kind, f._entry = kind, entry
    ns.Look.StyleIcon(f)
    local st = ns.TrackState(kind, entry)
    f.spellId, f.link = st.spell, st.link
    f.tex:SetTexture(st.icon or ns.QMARK)
    tintTrack(f, st)
    local off = inConfig() and not entry._on
    local sweep = st.start and st.duration and st.duration > 0 and st.left
    if sweep then
        f.cd:Show()
        f.cd.noCooldownCount = ownDigits() or nil
        if f._cdStart ~= st.start or f._cdDur ~= st.duration then
            f._cdStart, f._cdDur = st.start, st.duration
            f.cd:SetCooldown(st.start, st.duration)
        end
        f.tex:SetDesaturated(st.dim and true or false)
        f:SetAlpha(off and 0.3 or (st.dim and math.min(0.6, absentAlpha() + 0.2) or 1))
    else
        f.cd:Hide()
        f._cdStart, f._cdDur = nil, nil
        f.tex:SetDesaturated(not st.active)
        f:SetAlpha(off and 0.3 or (st.active and 1 or math.min(0.5, absentAlpha())))
    end
    if st.left and st.left > 0 and ownDigits() then
        f.timer:SetText(fmtLeft(st.left))
        f.timer:Show()
    else
        f.timer:Hide()
    end
    if st.stacks and st.stacks > 1 then
        f.count:SetText(st.stacks)
        f.count:Show()
    else
        f.count:Hide()
    end
end
local DEFAULT_BARS = {
    { perRow = 0, groups = { "personal", "flask", "food", "raid", "potion", "want" } },
    { perRow = 0, groups = { "proc", "cd", "gear", "dot" } },
}
local function barsCfg()
    local c = cfg()
    if not c.bars then
        c.bars = {}
        for i, d in ipairs(DEFAULT_BARS) do
            local g = {}
            for j, k in ipairs(d.groups) do g[j] = k end
            c.bars[i] = { perRow = d.perRow, groups = g }
        end
    end
    if c.point then
        if c.bars[1] and not c.bars[1].point then c.bars[1].point = c.point end
        c.point = nil
    end
    return c.bars
end
local function pruneEmpty()
    local conf = barsCfg()
    local cut = false
    for i = #conf, 2, -1 do
        if #(conf[i].groups or {}) == 0 then tremove(conf, i); cut = true end
    end
    return cut
end
local barFrames = {}
local function settle(p)
    savePos(p, p._barIndex)
end
function grabBar(p)
    if not p or locked() then return end
    barFrames[1] = bar
    if not ns.Snap.Begin(p, barFrames, settle) and not InCombatLockdown() then p:StartMoving() end
end
function dropBar(p)
    p:StopMovingOrSizing()
    if not ns.Snap.Finish(p) then settle(p) end
end
local function wheelAlpha(f, delta)
    if locked() or not f._barIndex then return end
    local i = f._barIndex
    local k = ns.Look.BAR.alpha
    local v = ns.Look.SetBar(i, "alpha", ns.Look.Bar(i, "alpha") + (delta > 0 and k.step or -k.step))
    f:SetAlpha(v)
    GameTooltip:SetOwner(f, "ANCHOR_TOP")
    GameTooltip:SetText(ns.T("look.alpha_now", i, ns.Look.Format("alpha", v)), 1, 1, 1, 1, true)
    GameTooltip:Show()
    if ns.BarMenu then ns.BarMenu.Refresh() end
end
local function enableBarDrag(f)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", grabBar)
    f:SetScript("OnDragStop", dropBar)
    f:SetScript("OnMouseUp", function(self, button)
        if button ~= "RightButton" or locked() or not ns.BarMenu then return end
        ns.BarMenu.Open(self._barIndex, self)
    end)
    f:SetScript("OnMouseWheel", wheelAlpha)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
local function rescale(f, i, v)
    local x, y = f:GetLeft(), f:GetTop()
    local k = f:GetEffectiveScale()
    f:SetScale(v)
    if not (x and y) then return end
    local nk = f:GetEffectiveScale()
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x * k / nk, y * k / nk)
    savePos(f, i)
end
local function makeResize(fr, i)
    local g = CreateFrame("Button", nil, fr)
    g:SetWidth(GRAB)
    g:SetHeight(GRAB)
    g:SetFrameLevel(fr:GetFrameLevel() + 30)
    g:SetPoint("BOTTOMRIGHT", fr, "BOTTOMRIGHT", 0, 0)
    g:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    g:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    g:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.T("bar.scale_tip", i), 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    g:SetScript("OnLeave", function() GameTooltip:Hide() end)
    g:SetScript("OnMouseDown", function(self)
        if locked() then return end
        if InCombatLockdown() then
            if ns.say then ns.say(ns.T("bar.combat")) end
            return
        end
        self.scaling = true
        self.baseScale = fr:GetScale()
        self.baseY = select(2, GetCursorPosition())
    end)
    g:SetScript("OnMouseUp", function(self)
        if not self.scaling then return end
        self.scaling = false
        ns.buffbar:SetScale(fr:GetScale(), i)
    end)
    g:SetScript("OnUpdate", function(self)
        if not self.scaling then return end
        if InCombatLockdown() or not IsMouseButtonDown("LeftButton") then
            self.scaling = false
            ns.buffbar:SetScale(fr:GetScale(), i)
            return
        end
        local _, y = GetCursorPosition()
        local s = self.baseScale + (self.baseY - y) / GRAB_STEP
        if s < MIN_SCALE then s = MIN_SCALE elseif s > MAX_SCALE then s = MAX_SCALE end
        local bc = barsCfg()[i]
        if bc then bc.scale = s end
        rescale(fr, i, s)
    end)
    if locked() then g:Hide() end
    resizers[i] = g
end
local function styleBar(f, i)
    f._barIndex = i
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetScale(barScale(i))
    enableBarDrag(f)
    makeResize(f, i)
end
local function barFrame(i)
    if i == 1 then barFrames[1] = bar; return bar end
    local f = barFrames[i]
    if not f then
        f = CreateFrame("Frame", "LazyBuffBar" .. i, UIParent)
        barFrames[i] = f
        styleBar(f, i)
        if ns.buffbar.ApplyTheme then ns.buffbar:ApplyTheme() end
    end
    return f
end
local function placeBar(fr, i, bc)
    if ns.Snap.Held() == fr then return end
    local p = bc.point
    fr:ClearAllPoints()
    if p then
        fr:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    elseif i == 1 then
        fr:SetPoint("CENTER", UIParent, "CENTER", 0, -160)
    else
        fr:SetPoint("TOPLEFT", barFrames[i - 1] or bar, "BOTTOMLEFT", 0, -ROWGAP * 4)
    end
end
local function belowAll(i)
    barFrames[1] = bar
    local lowY, lowX
    for j = 1, i - 1 do
        local f = barFrames[j]
        if f and f:GetBottom() and f:GetLeft() then
            local k = f:GetEffectiveScale()
            local y, x = f:GetBottom() * k, f:GetLeft() * k
            if not lowY or y < lowY then lowY, lowX = y, x end
        end
    end
    if not lowY then return nil end
    local u = UIParent:GetEffectiveScale()
    local nk = u * barScale(i)
    return { "TOPLEFT", "BOTTOMLEFT", lowX / nk, (lowY - ROWGAP * 4 * u) / nk }
end
local EXTRA_NAME = { flask = "фласка", food = "сытость", want = "ждём" }
local function groupName(key)
    for _, c in ipairs(ns.BAR_CATEGORIES or {}) do if c.key == key then return c.label end end
    for _, c in ipairs(ns.TRACK_CATEGORIES or {}) do if c.key == key then return c.label end end
    return EXTRA_NAME[key] or key
end
local function dropGroup(from, key)
    local conf = barsCfg()
    barFrames[1] = bar
    local to
    for i, f in pairs(barFrames) do
        if conf[i] and f:IsShown() and f:IsMouseOver() then to = i; break end
    end
    if not to then
        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale() * barScale(#conf + 1)
        conf[#conf + 1] = { perRow = 0, groups = {},
                            point = { "TOPLEFT", "BOTTOMLEFT", cx / s, cy / s } }
        to = #conf
    end
    if to == from then return end
    for _, bc in ipairs(conf) do
        for j = #(bc.groups or {}), 1, -1 do
            if bc.groups[j] == key then tremove(bc.groups, j) end
        end
    end
    tinsert(conf[to].groups, key)
    pruneEmpty()
    ns.buffbar:Update()
end
local SEP_GAP, SEP_W, SEP_INSET = 10, 1, 4
local SEP_ALPHA = 0.35
local seps = {}
local function sepColor()
    local t = ns.themes and ns.themes[ns.window and ns.window:GetSkin() or nil]
    local c = (t and t.tabbar and t.tabbar.sep) or { 1, 1, 1 }
    return c[1], c[2], c[3]
end
local function acquireSep(n)
    local f = seps[n]
    if not f then
        f = CreateFrame("Frame", nil, bar)
        f:SetWidth(SEP_W)
        f.tex = f:CreateTexture(nil, "ARTWORK")
        f.tex:SetAllPoints(f)
        f.tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        seps[n] = f
    end
    return f
end
local function putSep(n, fr, x, y)
    local f = acquireSep(n)
    f:SetParent(fr)
    f:SetFrameLevel(fr:GetFrameLevel() + 1)
    f:SetHeight(ICON - SEP_INSET * 2)
    local r, g, b = sepColor()
    f.tex:SetVertexColor(r, g, b, SEP_ALPHA)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", fr, "TOPLEFT", x, -(y + SEP_INSET))
    f:Show()
    return n + 1
end
local LABEL_H = 15
local labels = {}
local function acquireLabel(n)
    local b = labels[n]
    if not b then
        b = CreateFrame("Button", nil, bar)
        b:SetHeight(LABEL_H)
        b:SetMovable(true)
        b:RegisterForDrag("LeftButton")
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints(b)
        b.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.text:SetPoint("LEFT", b, "LEFT", 3, 0)
        b:SetScript("OnDragStart", function(self)
            if self.isCtl or InCombatLockdown() then return end
            self:StartMoving()
        end)
        b:SetScript("OnDragStop", function(self)
            if self.isCtl then return end
            self:StopMovingOrSizing()
            if InCombatLockdown() then ns.buffbar:Update(); return end
            dropGroup(self.barIndex, self.groupKey)
        end)
        b:SetScript("OnClick", function(self, button)
            if InCombatLockdown() then return end
            if not self.isCtl then
                if button == "RightButton" and ns.BarMenu then
                    ns.BarMenu.Open(self.barIndex, self:GetParent())
                end
                return
            end
            local bc = barsCfg()[self.barIndex]
            if not bc then return end
            local v = (bc.perRow or 0) + (button == "RightButton" and -1 or 1)
            if v < 0 then v = 0 end
            bc.perRow = v
            ns.buffbar:Update()
        end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(ns.T(self.isCtl and "bar.row_tip" or "bar.drag_tip"), 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        labels[n] = b
    end
    return b
end
local function putLabel(n, fr, i, x, y, w, key)
    local b = acquireLabel(n)
    b:SetParent(fr)
    b:SetFrameLevel(fr:GetFrameLevel() + 25)
    b.barIndex, b.groupKey, b.isCtl = i, key, (key == nil)
    if key then
        b.text:SetText(groupName(key))
        b.bg:SetVertexColor(0, 0, 0, 0.55)
    else
        local per = (barsCfg()[i] or {}).perRow or 0
        b.text:SetText(ns.T("bar.row_ctl", i, per > 0 and per or ns.T("bar.row_all")))
        b.bg:SetVertexColor(0.25, 0.2, 0.05, 0.8)
    end
    b:SetWidth(math.max(w or 0, b.text:GetStringWidth() + 8))
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", fr, "TOPLEFT", x, -y)
    b:Show()
    return n + 1
end
local function hideExtraBars(n)
    for i = 2, #barFrames do
        if i > n and barFrames[i] then barFrames[i]:Hide() end
    end
end
local GROUP_ROW = {
    personal = "buff", flask = "buff", food = "buff", raid = "buff", potion = "buff",
    want = "buff",
    proc = "track", cd = "track", gear = "track", dot = "track",
}
local function restack(f)
    if f.cd then f.cd:SetFrameLevel(f:GetFrameLevel() + 1) end
    if f.edge then f.edge:SetFrameLevel(f:GetFrameLevel() + 3) end
    if f.glow then f.glow:SetFrameLevel(f:GetFrameLevel() + 6) end
    if f.txt then f.txt:SetFrameLevel((f.cd and f.cd:GetFrameLevel() or f:GetFrameLevel()) + 5) end
end
local function sectionMap()
    local m = {}
    local all = inConfig()
    for _, s in ipairs((ns.BarSections and ns.BarSections(all)) or {}) do m[s.key] = s end
    for _, s in ipairs((ns.TrackSections and ns.TrackSections(all)) or {}) do m[s.key] = s end
    for _, s in ipairs((ns.IncomingSections and ns.IncomingSections(all)) or {}) do m[s.key] = s end
    return m
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
local function startSlide(f, dx, dy, under)
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
            if a.t >= SLIDE then
                f._anim = nil
                sliding[f] = nil
                f:SetAlpha(a.alpha)
                f:SetFrameLevel(f:GetParent():GetFrameLevel() + 5)
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
function flipBlessing(f, delta)
    local want = delta < 0
    if ns.BlessingWantsPlain() == want then return end
    if f._flip then return end
    f.tex:ClearAllPoints()
    lerpFace(f.tex, f, 1)
    lerpFace(f.stack, f, 0)
    f.stack:Show()
    f._flip = { t = 0 }
    flipping[f] = true
    ns.SetBlessingWantsPlain(want)
end
local function iconByKey(key)
    for _, f in ipairs(icons) do
        if f:IsShown() and f._entry and f._entry._key == key then return f end
    end
    for _, f in ipairs(ticons) do
        if f:IsShown() and f._entry and f._entry._key == key then return f end
    end
    return nil
end
function swapEntry(f, delta)
    local e = f._entry
    if not (e and e._cat and e._key) then return end
    local sec = sectionMap()[e._cat]
    if not sec then return end
    local keys, at = {}, nil
    for i, x in ipairs(sec.entries) do
        keys[i] = x._key
        if x._key == e._key then at = i end
    end
    if not at then return end
    local to = at + (delta > 0 and -1 or 1)
    if to < 1 or to > #keys then return end
    local other = iconByKey(keys[to])
    if not other then return end
    local ax, ay = f._bx, f._by
    local bx, by = other._bx, other._by
    keys[at], keys[to] = keys[to], keys[at]
    ns.SetBarOrder(e._cat, keys)
    ns.buffbar:Update()
    local mine = iconByKey(e._key)
    local his  = iconByKey(keys[at])
    if mine then startSlide(mine, ax - mine._bx, ay - mine._by, false) end
    if his  then startSlide(his,  bx - his._bx,  by - his._by,  true)  end
end
local function layoutAll()
    local conf = barsCfg()
    local map = sectionMap()
    local bi, ti, pn = 0, 0, 1
    local ln, sn = 1, 1
    for i, bc in ipairs(conf) do
        local fr = barFrame(i)
        local pad, gap = ns.Look.Bar(i, "pad"), ns.Look.Bar(i, "gap")
        local rowgap = gap + 2
        placeBar(fr, i, bc)
        if math.abs(fr:GetScale() - barScale(i)) > 0.001 then fr:SetScale(barScale(i)) end
        local labelRow = inConfig()
        local top = pad + (labelRow and (LABEL_H + 2) or 0)
        local x, y, col, wide = pad, top, 0, 0
        local first = true
        for _, key in ipairs(bc.groups or {}) do
            local sec = map[key]
            if sec and #sec.entries > 0 then
                if not first and col > 0 then
                    sn = putSep(sn, fr, x + math.floor((SEP_GAP - SEP_W) / 2), y)
                    x = x + SEP_GAP
                end
                first = false
                local gx = x
                for _, entry in ipairs(sec.entries) do
                    if (bc.perRow or 0) > 0 and col >= bc.perRow then
                        x, y, col = pad, y + ICON + rowgap, 0
                    end
                    local f
                    if GROUP_ROW[key] == "track" then
                        ti = ti + 1
                        f = acquireTrackIcon(ti)
                        fillTrackIcon(f, sec.kind, entry)
                    else
                        bi = bi + 1
                        f = acquireIcon(bi)
                        fillIcon(f, sec.kind, entry, false)
                    end
                    f:SetParent(fr)
                    restack(f)
                    f._bx, f._by = x, y
                    place(f)
                    f:Show()
                    pn = attachPick(fr, f, entry, pn)
                    x = x + ICON + gap
                    col = col + 1
                    if x > wide then wide = x end
                end
                if labelRow then
                    ln = putLabel(ln, fr, i, gx, pad, x - gx - gap, key)
                end
            end
        end
        local drew = wide > pad
        local w = drew and (wide - gap + pad) or (pad * 2 + ICON)
        fr:SetWidth(w)
        fr:SetHeight(y + ICON + pad)
        if drew or inConfig() then fr:Show() else fr:Hide() end
        if labelRow then
            ln = putLabel(ln, fr, i, pad, pad, 0, nil)
            labels[ln - 1]:ClearAllPoints()
            labels[ln - 1]:SetPoint("TOPRIGHT", fr, "TOPRIGHT", -pad, -pad)
        end
    end
    for i = bi + 1, #icons  do icons[i]:Hide()  end
    for i = ti + 1, #ticons do ticons[i]:Hide() end
    for i = pn,     #picks  do picks[i]:Hide()  end
    for i = ln,     #labels do labels[i]:Hide() end
    for i = sn,     #seps   do seps[i]:Hide()   end
    hideExtraBars(#conf)
end
function ns.buffbar:Update()
    if not bar or not cfg().show then return end
    if InCombatLockdown() then
        for _, f in ipairs(icons) do
            if f:IsShown() and f._kind then fillIcon(f, f._kind, f._entry, true) end
        end
        for _, f in ipairs(ticons) do
            if f:IsShown() and f._kind then fillTrackIcon(f, f._kind, f._entry) end
        end
        return
    end
    layoutAll()
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
    ns.buffbar:UpdateTrack()
end
local function build()
    bar = CreateFrame("Frame", "LazyBuffBar", UIParent)
    barFrames[1] = bar
    styleBar(bar, 1)
    ns.buffbar:ApplyTheme()
    host = CreateFrame("Frame")
    host:RegisterEvent("UNIT_AURA")
    host:RegisterEvent("PLAYER_TALENT_UPDATE")
    host:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    host:RegisterEvent("PLAYER_REGEN_ENABLED")
    host:RegisterEvent("BAG_UPDATE")
    host:RegisterEvent("PLAYER_TARGET_CHANGED")
    host:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    host:SetScript("OnEvent", function(self, event, unit)
        if event == "UNIT_AURA" and unit ~= "player" then
            if unit == "target" then ns.buffbar:UpdateTrack() end
            return
        end
        ns.buffbar:Update()
    end)
    host:SetScript("OnUpdate", function(self, elapsed)
        if not cfg().show then return end
        pulseGlows(elapsed)
        slideTick(elapsed)
        flipTick(elapsed)
        trackTick(elapsed)
    end)
    placeBar(bar, 1, barsCfg()[1] or {})
    bar:Hide()
end
local plate = { insets = { left = 0, right = 0, top = 0, bottom = 0 } }
local function plateBackdrop(p)
    local bd = p and p.backdrop
    plate.bgFile   = (bd and bd.bgFile) or "Interface\\Tooltips\\UI-Tooltip-Background"
    plate.tile     = (bd and bd.tile) and true or false
    plate.tileSize = (bd and bd.tileSize) or 16
    return plate, ns.Look.PlateEdge(plate)
end
function ns.buffbar:ApplyTheme()
    if not bar then return end
    local t = ns.themes and ns.themes[ns.window and ns.window:GetSkin() or nil]
    local p = t and t.panel
    local config = inConfig()
    local c = (p and p.bgColor) or { 0, 0, 0, 0.6 }
    barFrames[1] = bar
    for i, f in pairs(barFrames) do
        if config and p then
            local b = p.borderColor
            f:SetBackdrop(p.backdrop)
            f:SetBackdropColor(c[1], c[2], c[3], c[4])
            if b then f:SetBackdropBorderColor(b[1], b[2], b[3], b[4]) end
        else
            local bd, edged = plateBackdrop(p)
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
    end
end
function ns.buffbar:GetScale(i)
    if i then return barScale(i) end
    local v
    for j = 1, #barsCfg() do
        local s = barScale(j)
        if v and math.abs(v - s) > 0.001 then return nil end
        v = s
    end
    return v or cfg().scale or 1
end
function ns.buffbar:SetScale(v, i)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return barScale(i or 1)
    end
    v = tonumber(v) or 1
    if v < MIN_SCALE then v = MIN_SCALE elseif v > MAX_SCALE then v = MAX_SCALE end
    local conf = barsCfg()
    barFrames[1] = bar
    if i then
        if not conf[i] then return barScale(i) end
        conf[i].scale = v
        if barFrames[i] then rescale(barFrames[i], i, v) end
    else
        cfg().scale = v
        for _, bc in ipairs(conf) do bc.scale = nil end
        for j, f in pairs(barFrames) do rescale(f, j, v) end
    end
    return v
end
function ns.buffbar:Apply()
    if not bar then return end
    self:ApplyTheme()
    for _, g in pairs(resizers) do
        if cfg().locked then g:Hide() else g:Show() end
    end
    if cfg().show then
        bar:Show()
        self:Update()
    else
        barFrames[1] = bar
        for _, f in pairs(barFrames) do f:Hide() end
    end
    if ns.Chrome then ns.Chrome.Apply() end
end
local function barDraws(bc, map)
    for _, key in ipairs(bc.groups or {}) do
        local sec = map[key]
        if sec and #sec.entries > 0 then return true end
    end
    return false
end
function ns.buffbar:Bars()
    local map = sectionMap()
    local out = {}
    for i, bc in ipairs(barsCfg()) do
        local names = {}
        for j, key in ipairs(bc.groups or {}) do names[j] = groupName(key) end
        out[i] = { id = i, perRow = bc.perRow or 0, groups = names,
                   empty = not barDraws(bc, map), holds = #names > 0 }
    end
    return out
end
function ns.buffbar:AddBar()
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return nil
    end
    local conf = barsCfg()
    local i = #conf + 1
    conf[i] = { perRow = 0, groups = {}, point = belowAll(i) }
    if cfg().show then self:Update() else self:SetShown(true) end
    return i
end
function ns.buffbar:RemoveBar(i)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    local conf = barsCfg()
    local bc = conf[i]
    if not bc or #conf < 2 then return false end
    if barDraws(bc, sectionMap()) then return false end
    local to = conf[(i == 1) and 2 or 1]
    to.groups = to.groups or {}
    for _, key in ipairs(bc.groups or {}) do tinsert(to.groups, key) end
    tremove(conf, i)
    self:Update()
    return true
end
function ns.buffbar:SetPerRow(i, v)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return
    end
    local bc = barsCfg()[i]
    if not bc then return end
    if v < 0 then v = 0 end
    bc.perRow = v
    self:Update()
end
function ns.buffbar:Panels()
    if not bar then return {} end
    barFrames[1] = bar
    local out = {}
    for i = 1, #barsCfg() do
        local f = barFrames[i]
        if f and f:IsShown() then out[#out + 1] = { id = i, frame = f } end
    end
    return out
end
function ns.buffbar:Init()
    if not bar then build() end
    self:Apply()
end
function ns.buffbar:SetShown(v)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return
    end
    cfg().show = v and true or false
    self:Apply()
end
function ns.buffbar:SetLocked(v)
    v = v and true or false
    if v ~= locked() and InCombatLockdown() then
        if ns.say then ns.say("Фиксацию панели меняют вне боя.") end
        return
    end
    cfg().locked = v
    if not v and not cfg().show then self:SetShown(true) end
    self:Apply()
    if ns.window and ns.window.RefreshIfShown then ns.window:RefreshIfShown() end
end
function ns.buffbar:IsShown()  return cfg().show  and true or false end
function ns.buffbar:IsLocked() return cfg().locked and true or false end
function ns.buffbar:ResetBars()
    if InCombatLockdown() then
        if ns.say then ns.say("Полосы перекладывают вне боя.") end
        return
    end
    cfg().bars = nil
    for i = 2, #barFrames do
        if barFrames[i] then barFrames[i]:Hide() end
    end
    barFrames[1] = bar
    for i, f in pairs(barFrames) do rescale(f, i, barScale(i)) end
    self:Update()
end
