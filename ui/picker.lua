local _, ns = ...
ns.Picker = {}
local P = ns.Picker
local W = 400
local PAD = 12
local TOP = 30
local GAP = 6
local ROW_H = 24
local ROWS = 12
local ICON = 20
local ADD_W = 22
local WARN_W = 14
local WHEEL_ROWS = 3
local CHIP_H = 16
local CHIP_PAD = 8
local CHIP_GAP = 4
local CAT_H = 16
local CAT_GAP = 10
local BADGE_PAD = 4
local PREVIEW_ICON = 36
local PREVIEW_MIN = 44
local VIEW_H = 26
local FOOT_GAP = 6
local WHITE = "Interface\\Buttons\\WHITE8X8"
local C_SRC = "|cffc9a85c"
local C_MUTE = "|cff9b9eae"
local C_WARN = "|cffff9933"
local MSG_KEYS = { added = true, on = true, already = true, later = true, grid = true, full = true }
local GONE = "gone"
local C_NOTE = { 1, 0.6, 0.2 }
local function ink(fs, c)
    fs:SetTextColor(c[1], c[2], c[3])
end
local function isPending(hit)
    return ns.DeferHas(ns.Catalog.DeferKey(hit))
end
local function warnEnter(tip)
    if not tip.warnText then return end
    GameTooltip:SetOwner(tip, "ANCHOR_RIGHT")
    GameTooltip:SetText(tip.warnText, C_NOTE[1], C_NOTE[2], C_NOTE[3], 1, true)
    GameTooltip:Show()
end
local function soon(hit)
    if hit.warn == "grid" then return true end
    return ns.Catalog.Item(hit) == nil
end
local function widgetSize(hit)
    if hit.role ~= "widget" then return nil end
    local name = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(hit.ref)
    if not (name and ns.Widget.Get and ns.Widget.Get(name)) then return nil end
    return ns.Widget.Size(name)
end
local function refInfo(k)
    local id = k:match("^spell:(%d+)$")
    if id then
        local name, _, icon = GetSpellInfo(tonumber(id))
        return name or k, icon
    end
    id = k:match("^item:(%d+)$")
    if id then
        local name = GetItemInfo(tonumber(id))
        return name or k, GetItemIcon(tonumber(id))
    end
    local w = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(k)
    if w then return ns.WidgetLabel(w), nil end
    return k, nil
end
local function roleText(role)
    local key = "catalog.role." .. tostring(role)
    if ns.L[key] then return ns.T(key) end
    return tostring(role)
end
local function styleChip(b)
    local e = ns.EDIT
    if b.active then
        b:SetBackdropBorderColor(e.gold[1], e.gold[2], e.gold[3], 1)
        ink(b.text, e.gold)
    elseif b.hovered then
        b:SetBackdropBorderColor(e.border[1], e.border[2], e.border[3], 1)
        ink(b.text, e.white)
    else
        b:SetBackdropBorderColor(e.line[1], e.line[2], e.line[3], 1)
        ink(b.text, e.text)
    end
end
local function makeChip(parent, label)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(CHIP_H)
    b:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.text:SetText(label)
    b:SetWidth((b.text:GetStringWidth() or 0) + CHIP_PAD * 2)
    b.SetActive = function(self, on) self.active = on and true or false; styleChip(self) end
    b:SetScript("OnEnter", function(self)
        self.hovered = true
        styleChip(self)
        if self.tip then ns.TipShow(self) end
    end)
    b:SetScript("OnLeave", function(self)
        self.hovered = nil
        styleChip(self)
        if self.tip then ns.TipHide() end
    end)
    b:SetScript("OnClick", function(self)
        if self.onClick then self.onClick(self) end
    end)
    styleChip(b)
    return b
end
local function styleCat(b)
    local e = ns.EDIT
    if b.zero and not b.active then
        ink(b.text, e.mute)
        b.badge:SetVertexColor(e.line[1], e.line[2], e.line[3], 1)
        ink(b.count, e.mute)
    else
        ink(b.text, (b.active or b.hovered) and e.white or e.text)
        b.badge:SetVertexColor(e.gold[1], e.gold[2], e.gold[3], 1)
        ink(b.count, e.dark)
    end
    if b.active then b.line:Show() else b.line:Hide() end
end
local function makeCat(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(CAT_H)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", b, "LEFT", 0, 0)
    b.badge = b:CreateTexture(nil, "ARTWORK")
    b.badge:SetTexture(WHITE)
    b.badge:SetHeight(CAT_H - 2)
    b.badge:SetPoint("LEFT", b.text, "RIGHT", 4, 0)
    b.count = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.count:SetPoint("CENTER", b.badge, "CENTER", 0, 0)
    b.line = b:CreateTexture(nil, "ARTWORK")
    b.line:SetTexture(WHITE)
    b.line:SetHeight(1)
    b.line:SetPoint("BOTTOMLEFT", b.text, "BOTTOMLEFT", 0, -2)
    b.line:SetPoint("BOTTOMRIGHT", b.text, "BOTTOMRIGHT", 0, -2)
    b.line:SetVertexColor(ns.EDIT.gold[1], ns.EDIT.gold[2], ns.EDIT.gold[3], 1)
    function b:SetCount(label, n)
        self.text:SetText(label)
        self.count:SetText(tostring(n))
        self.zero = n == 0
        self.badge:SetWidth(math.max(14, (self.count:GetStringWidth() or 0) + BADGE_PAD * 2))
        self:SetWidth((self.text:GetStringWidth() or 0) + 4 + self.badge:GetWidth())
        styleCat(self)
    end
    b.SetActive = function(self, on) self.active = on and true or false; styleCat(self) end
    b:SetScript("OnEnter", function(self)
        self.hovered = true
        styleCat(self)
        if self.tip then ns.TipShow(self) end
    end)
    b:SetScript("OnLeave", function(self)
        self.hovered = nil
        styleCat(self)
        if self.tip then ns.TipHide() end
    end)
    b:SetScript("OnClick", function(self)
        if self.onClick then self.onClick(self) end
    end)
    return b
end
local function newList(spec)
    local host = spec.host
    local ROWN = spec.rows
    local L = { state = spec.state or { q = "", tags = {}, offset = 0, flat = {}, done = {}, pending = {} },
                rows = {}, tagBtns = {}, catBtns = {}, scopeBtns = {}, raidBtns = {}, bossBtns = {} }
    local state = L.state
    state.scope = state.scope or "spec"
    local field, clearBtn, listFrame, preview, emptyFs, foundFs, footFs
    local rows, tagBtns, catBtns = L.rows, L.tagBtns, L.catBtns
    local scopeBtns, raidBtns, bossBtns = L.scopeBtns, L.raidBtns, L.bossBtns
    local paint, layout
    local function flatten()
        local flat = {}
        for _, g in ipairs((state.result and state.result.groups) or {}) do
            if g.cat == "own" or not state.cat or state.cat == g.cat then
                flat[#flat + 1] = { head = g.cat, count = g.count }
                for _, h in ipairs(g.rows) do flat[#flat + 1] = { hit = h } end
            end
        end
        if spec.gone then
            local gone = ns.Preset.Gone()
            if #gone > 0 and (not state.cat or state.cat == GONE) then
                flat[#flat + 1] = { head = GONE, count = #gone }
                for _, g in ipairs(gone) do flat[#flat + 1] = { gone = g } end
            end
        end
        state.flat = flat
    end
    local function nextHit(from, dir)
        local i = from
        while true do
            i = i + dir
            local x = state.flat[i]
            if not x then return nil end
            if x.hit then return i end
        end
    end
    local function clampOffset()
        local most = math.max(0, #state.flat - ROWN)
        if state.offset > most then state.offset = most end
        if state.offset < 0 then state.offset = 0 end
    end
    local function showRow(i)
        if i <= state.offset then state.offset = i - 1 end
        if i > state.offset + ROWN then state.offset = i - ROWN end
        if state.offset == 1 and state.flat[1] and state.flat[1].head then state.offset = 0 end
        clampOffset()
    end
    function L.Move(dir)
        local i = state.sel and nextHit(state.sel, dir) or nextHit(0, 1)
        if not i then return end
        state.sel = i
        showRow(i)
        paint()
    end
    function L.Scroll(delta)
        state.offset = state.offset + delta
        clampOffset()
        paint()
    end
    function L.Selected()
        local x = state.sel and state.flat[state.sel]
        if x and x.hit then return x.hit end
        local i = nextHit(0, 1)
        return i and state.flat[i].hit or nil
    end
    function L.Add(hit)
        if not hit then return false, "none" end
        local ok, why = L.place(hit)
        if why == "later" then state.pending[hit.key] = hit end
        if ok or why == "already" then state.done[hit.key] = true end
        if MSG_KEYS[why] and ns.say then ns.say(ns.T("picker.msg." .. why, hit.name)) end
        if host:IsVisible() then L.Refresh(true) end
        return ok, why
    end
    function L.Restore(g)
        local x = ns.Preset.Restore(g.k, g.role, nil)
        if x and ns.say then ns.say(ns.T("picker.msg.on", (refInfo(g.k)))) end
        L.Refresh(true)
        return x ~= nil
    end
    function L.MarkDone(hit)
        state.done[hit.key] = true
        if host:IsVisible() then L.Refresh(true) end
    end
    local function fillViews(hit)
        local name = hit.role == "widget" and ns.Widget and ns.Widget.NameOf(hit.ref)
        local views = name and ns.Widget.Get(name) and ns.Widget.Views(name) or {}
        if #views < 2 then
            preview.view:Hide()
            return false
        end
        local opts = {}
        for i, v in ipairs(views) do
            local key = "widget." .. name .. "_" .. v
            opts[i] = { key = v, label = ns.L[key] and ns.T(key) or v }
        end
        preview.view.hit = hit
        preview.view:SetOptions(opts)
        preview.view:SetValue(ns.Widget.ViewOf(name, hit.view))
        local bw = 0
        for i = 1, #opts do bw = math.max(bw, preview.view.buttons[i].text:GetStringWidth() or 0) end
        preview.view:SetWidth((preview.view.label:GetWidth() or 0) + 6 + #opts * (bw + 12))
        preview.view:Layout()
        preview.view:Show()
        return true
    end
    local function fillPreview(hit)
        if not preview then return end
        if not hit then
            preview.icon:Hide()
            preview.name:SetText("")
            preview.sub:SetText("")
            preview.text:SetText("")
            preview.view:Hide()
            return
        end
        fillViews(hit)
        preview.icon:SetTexture(hit.icon or ns.QMARK)
        preview.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        preview.icon:Show()
        preview.name:SetText(hit.name)
        local sub = hit.roleText
        if hit.src then sub = sub .. ", " .. C_SRC .. hit.src .. "|r" end
        preview.sub:SetText(sub)
        local lines = {}
        local w, h = widgetSize(hit)
        if w then lines[#lines + 1] = ns.T("picker.widget", hit.w or w, hit.h or h) end
        if soon(hit) then
            lines[#lines + 1] = ns.T("picker.nogrid")
        else
            local wh = ns.Catalog.Where(hit, state.target)
            if wh then lines[#lines + 1] = ns.T(wh.placed and "picker.placed" or "picker.lands", wh.barName or "?") end
        end
        if hit.warn then lines[#lines + 1] = C_WARN .. ns.T("catalog.warn." .. hit.warn) .. "|r" end
        if hit.boss then lines[#lines + 1] = ns.T("picker.boss_tip") end
        preview.text:SetText(table.concat(lines, "  "))
    end
    local function fillRow(r, x, index)
        r.index = index
        r.hit = x.hit
        r.gone = x.gone
        r.head:Hide()
        r.icon:Hide()
        r.add:Hide()
        r.warn:Hide()
        r.check:Hide()
        r.sel:Hide()
        r.name:Hide()
        if r.back then r.back:Hide() end
        if x.head then
            local label = x.head == GONE and ns.T("options.gone") or ns.T("picker.cat." .. x.head)
            r.head:SetText(label .. "  " .. C_MUTE .. x.count .. "|r")
            r.head:Show()
            r:EnableMouse(false)
            return
        end
        r:EnableMouse(true)
        if x.gone then
            local name, icon = refInfo(x.gone.k)
            r.icon:SetTexture(icon or ns.QMARK)
            r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            r.icon:Show()
            r.name:SetText(name .. "  " .. C_MUTE .. roleText(x.gone.role) .. "|r")
            r.name:Show()
            r.back:Show()
            return
        end
        local hit = x.hit
        r.icon:SetTexture(hit.icon or ns.QMARK)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        r.icon:Show()
        local text = hit.name .. "  " .. C_MUTE .. hit.roleText .. "|r"
        if hit.src then text = text .. C_MUTE .. ", |r" .. C_SRC .. hit.src .. "|r" end
        local later = soon(hit)
        if later then text = text .. "  " .. C_MUTE .. ns.T("picker.soon") .. "|r"
        elseif isPending(hit) then text = text .. "  " .. C_WARN .. ns.T("picker.later") .. "|r" end
        r.name:SetText(text)
        r.name:Show()
        if hit.warn then
            r.warn.warnText = ns.T("catalog.warn." .. hit.warn)
            r.warn:Show()
        else
            r.warn.warnText = nil
        end
        if later then
        elseif state.done[hit.key] or hit.onBlock then
            r.check:Show()
        else
            r.add:Show()
        end
        if state.sel == index then r.sel:Show() end
    end
    paint = function()
        clampOffset()
        for i = 1, ROWN do
            local r = rows[i]
            local x = state.flat[state.offset + i]
            if x then
                fillRow(r, x, state.offset + i)
                r:Show()
            else
                r.hit, r.gone = nil, nil
                r:Hide()
            end
        end
        if #state.flat == 0 then emptyFs:Show() else emptyFs:Hide() end
        fillPreview(state.hover or L.Selected())
    end
    local function flow(made, y, gap, lead)
        local x = PAD
        local room = spec.width() - PAD
        if lead then
            lead:ClearAllPoints()
            lead:SetPoint("TOPLEFT", host, "TOPLEFT", x, -(y + 2))
            x = x + (lead:GetStringWidth() or 0) + GAP
        end
        local h = 0
        for _, b in ipairs(made) do
            if b:IsShown() then
                local bw = b:GetWidth() or 0
                if x + bw > room and x > PAD then
                    x = PAD
                    y = y + h + 3
                    h = 0
                end
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", host, "TOPLEFT", x, -y)
                x = x + bw + gap
                h = math.max(h, b:GetHeight() or 0)
            end
        end
        return y + h
    end
    layout = function()
        local w = spec.width()
        local y = spec.top + (field:GetHeight() or 22) + GAP
        y = flow(scopeBtns, y, CHIP_GAP) + GAP
        y = flow(tagBtns, y, CHIP_GAP) + GAP
        if state.tags.boss then
            y = flow(raidBtns, y, CHIP_GAP) + GAP
            if state.raid then y = flow(bossBtns, y, CHIP_GAP) + GAP end
        end
        local cats = {}
        for _, cat in ipairs(ns.Catalog.CATS) do cats[#cats + 1] = catBtns[cat] end
        if spec.gone then cats[#cats + 1] = catBtns[GONE] end
        y = flow(cats, y, CAT_GAP, foundFs) + GAP
        listFrame:ClearAllPoints()
        listFrame:SetPoint("TOPLEFT", host, "TOPLEFT", PAD, -y)
        listFrame:SetWidth(w - 2 * PAD)
        listFrame:SetHeight(ROWN * ROW_H)
        y = y + ROWN * ROW_H + GAP
        if preview then
            preview:ClearAllPoints()
            preview:SetPoint("TOPLEFT", host, "TOPLEFT", PAD, -y)
            preview:SetWidth(w - 2 * PAD)
            y = y + (preview:GetHeight() or PREVIEW_MIN) + FOOT_GAP
        end
        footFs:ClearAllPoints()
        footFs:SetPoint("TOPLEFT", host, "TOPLEFT", PAD, -y)
        footFs:SetWidth(w - 2 * PAD)
        y = y + ns.NoteHeight(footFs)
        spec.onLayout(y)
    end
    local function paintCats()
        local counts = (state.result and state.result.counts) or {}
        for _, cat in ipairs(ns.Catalog.CATS) do
            local b = catBtns[cat]
            b:SetCount(ns.T("picker.cat." .. cat), counts[cat] or 0)
            b:SetActive(state.cat == cat)
        end
        if spec.gone then
            local b = catBtns[GONE]
            b:SetCount(ns.T("options.gone"), #ns.Preset.Gone())
            b:SetActive(state.cat == GONE)
        end
        layout()
    end
    local function paintChips()
        for _, b in ipairs(scopeBtns) do b:SetActive(state.scope == b.scope) end
        local boss = state.tags.boss and true or false
        for _, b in ipairs(raidBtns) do
            b:SetActive(state.raid == b.raid)
            if boss then b:Show() else b:Hide() end
        end
        for _, b in ipairs(bossBtns) do
            b:SetActive(state.boss == b.boss)
            if boss and state.raid == b.raid then b:Show() else b:Hide() end
        end
    end
    function L.Refresh(keepSel)
        paintChips()
        state.result = ns.Catalog.Search(state.q, state.tags,
            { scope = state.scope, raid = state.raid, boss = state.boss })
        flatten()
        if not keepSel then
            state.offset = 0
            state.sel = nextHit(0, 1)
        elseif state.sel and not (state.flat[state.sel] and state.flat[state.sel].hit) then
            state.sel = nextHit(0, 1)
        end
        paintCats()
        paint()
    end
    function L.SetQuery(text)
        state.q = text or ""
        if state.q == "" then clearBtn:Hide() else clearBtn:Show() end
        L.Refresh()
    end
    function L.ToggleTag(tag)
        state.tags[tag] = (not state.tags[tag]) or nil
        for _, b in ipairs(tagBtns) do b:SetActive(state.tags[b.tag] and true or false) end
        L.Refresh()
    end
    function L.SetCat(cat)
        if state.cat == cat then cat = nil end
        state.cat = cat
        L.Refresh()
    end
    function L.SetScope(scope)
        state.scope = scope
        L.Refresh()
    end
    function L.SetRaid(raid)
        if state.raid == raid then raid = nil end
        state.raid, state.boss = raid, nil
        L.Refresh()
    end
    function L.SetBoss(boss)
        if state.boss == boss then boss = nil end
        state.boss = boss
        if boss then state.raid = ns.Encounter.RaidOf(boss) end
        L.Refresh()
    end
    local function makeRow(i)
        local r = CreateFrame("Button", nil, listFrame)
        r:SetHeight(ROW_H)
        r:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -(i - 1) * ROW_H)
        r:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", 0, -(i - 1) * ROW_H)
        r:RegisterForDrag("LeftButton")
        r.sel = r:CreateTexture(nil, "BACKGROUND")
        r.sel:SetAllPoints(r)
        r.sel:SetTexture(WHITE)
        r.sel:SetVertexColor(1, 0.82, 0, 0.15)
        r.sel:Hide()
        r.hl = r:CreateTexture(nil, "HIGHLIGHT")
        r.hl:SetAllPoints(r)
        r.hl:SetTexture(WHITE)
        r.hl:SetVertexColor(1, 1, 1, 0.06)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetWidth(ICON)
        r.icon:SetHeight(ICON)
        r.icon:SetPoint("LEFT", r, "LEFT", 2, 0)
        r.add = ns.MakeButton(r)
        r.add:SetLabel("+")
        r.add:SetWidth(ADD_W)
        r.add:SetPoint("RIGHT", r, "RIGHT", -2, 0)
        r.add.tipTitle = ns.T("picker.add_tip")
        r.add.onClick = function() L.Add(r.hit) end
        if spec.gone then
            r.back = ns.MakeButton(r)
            r.back:SetLabel(ns.T("options.restore"))
            r.back:SetPoint("RIGHT", r, "RIGHT", -2, 0)
            r.back.tip = ns.T("options.restore_tip")
            r.back.onClick = function() if r.gone then L.Restore(r.gone) end end
            r.back:Hide()
        end
        r.check = r:CreateTexture(nil, "OVERLAY")
        r.check:SetWidth(ADD_W)
        r.check:SetHeight(ADD_W)
        r.check:SetPoint("RIGHT", r, "RIGHT", -2, 0)
        r.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        r.check:Hide()
        r.warn = CreateFrame("Button", nil, r)
        r.warn:SetWidth(WARN_W)
        r.warn:SetHeight(ROW_H)
        r.warn:SetPoint("RIGHT", r.add, "LEFT", -2, 0)
        r.warn.text = r.warn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r.warn.text:SetPoint("CENTER", r.warn, "CENTER", 0, 0)
        r.warn.text:SetText("!")
        ink(r.warn.text, C_NOTE)
        r.warn:SetScript("OnEnter", warnEnter)
        r.warn:SetScript("OnLeave", ns.TipHide)
        r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.name:SetPoint("RIGHT", r.warn, "LEFT", -2, 0)
        r.name:SetHeight(ROW_H)
        r.name:SetJustifyH("LEFT")
        r.name:SetWordWrap(false)
        r.head = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.head:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 2, 4)
        ink(r.head, ns.EDIT.gold)
        r:SetScript("OnClick", function(self)
            if not self.hit then return end
            state.sel = self.index
            paint()
        end)
        r:SetScript("OnDoubleClick", function(self) if self.hit then L.Add(self.hit) end end)
        r:SetScript("OnEnter", function(self)
            state.hover = self.hit
            fillPreview(self.hit)
        end)
        r:SetScript("OnLeave", function()
            state.hover = nil
            fillPreview(L.Selected())
        end)
        r:SetScript("OnDragStart", function(self)
            if self.hit and P.OnDragStart then P.OnDragStart(self.hit, self, L) end
        end)
        r:Hide()
        return r
    end
    local function buildPreview()
        preview = CreateFrame("Frame", nil, host)
        preview:SetHeight(PREVIEW_MIN + VIEW_H)
        preview:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
                              insets = { left = 1, right = 1, top = 1, bottom = 1 } })
        preview:SetBackdropColor(1, 1, 1, 0.04)
        preview:SetBackdropBorderColor(ns.EDIT.line[1], ns.EDIT.line[2], ns.EDIT.line[3], 1)
        preview.icon = preview:CreateTexture(nil, "ARTWORK")
        preview.icon:SetWidth(PREVIEW_ICON)
        preview.icon:SetHeight(PREVIEW_ICON)
        preview.icon:SetPoint("TOPLEFT", preview, "TOPLEFT", 4, -4)
        preview.name = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        preview.name:SetPoint("TOPLEFT", preview, "TOPLEFT", PREVIEW_ICON + 10, -4)
        preview.name:SetPoint("RIGHT", preview, "RIGHT", -4, 0)
        preview.name:SetJustifyH("LEFT")
        preview.name:SetWordWrap(false)
        preview.sub = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        preview.sub:SetPoint("TOPLEFT", preview.name, "BOTTOMLEFT", 0, -1)
        preview.sub:SetPoint("RIGHT", preview, "RIGHT", -4, 0)
        preview.sub:SetJustifyH("LEFT")
        preview.sub:SetWordWrap(false)
        ink(preview.sub, ns.EDIT.mute)
        preview.text = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        preview.text:SetPoint("TOPLEFT", preview.sub, "BOTTOMLEFT", 0, -1)
        preview.text:SetPoint("RIGHT", preview, "RIGHT", -4, 0)
        preview.text:SetJustifyH("LEFT")
        preview.text:SetWordWrap(false)
        preview.view = ns.MakeSegments(preview, {}, { label = ns.T("card.view"), labelW = 1 })
        preview.view.label:SetWidth(preview.view.label:GetStringWidth() + 2)
        preview.view.body:ClearAllPoints()
        preview.view.body:SetPoint("TOP", preview.view, "TOP", 0, 0)
        preview.view.body:SetPoint("BOTTOM", preview.view, "BOTTOM", 0, 0)
        preview.view.body:SetPoint("RIGHT", preview.view, "RIGHT", 0, 0)
        preview.view.body:SetPoint("LEFT", preview.view, "LEFT", preview.view.label:GetWidth() + 6, 0)
        preview.view:SetPoint("TOPLEFT", preview.text, "BOTTOMLEFT", 0, -3)
        ink(preview.view.label, ns.EDIT.mute)
        preview.view.onPick = function(k)
            local hit = preview.view.hit
            local name = hit and ns.Widget.NameOf(hit.ref)
            if not name then return end
            hit.view = k
            hit.w, hit.h = ns.Widget.Size(name, k)
            fillPreview(hit)
        end
        preview.view:Hide()
        L.preview = preview
    end
    field = ns.MakeField(host, { ghost = ns.T("picker.ghost"), maxLetters = 255 })
    field:SetPoint("TOPLEFT", host, "TOPLEFT", PAD, -spec.top)
    field:SetPoint("TOPRIGHT", host, "TOPRIGHT", -PAD, -spec.top)
    L.field = field
    local box = field.box
    box:SetScript("OnTextChanged", function(self)
        field:Restyle()
        local text = self:GetText() or ""
        if text ~= state.q then L.SetQuery(text) end
    end)
    box:SetScript("OnEnterPressed", function() L.Add(L.Selected()) end)
    box:SetScript("OnEscapePressed", function() spec.onEsc() end)
    box:SetScript("OnTabPressed", function() L.Move(IsShiftKeyDown() and -1 or 1) end)
    if box:HasScript("OnArrowPressed") then
        box:SetScript("OnArrowPressed", function(_, key)
            if key == "UP" then L.Move(-1) elseif key == "DOWN" then L.Move(1) end
        end)
    end
    clearBtn = ns.MakeCloseX(field)
    clearBtn:SetPoint("RIGHT", field, "RIGHT", -4, 0)
    clearBtn:SetFrameLevel(field:GetFrameLevel() + 5)
    clearBtn.onClick = function()
        field:SetText("")
        L.SetQuery("")
        field:SetFocus()
    end
    clearBtn:Hide()
    for _, scope in ipairs(ns.Catalog.SCOPES) do
        local b = makeChip(host, ns.T("picker.scope." .. scope))
        b.scope = scope
        b.tip = ns.T("picker.scope_tip." .. scope)
        b.onClick = function() L.SetScope(scope) end
        scopeBtns[#scopeBtns + 1] = b
    end
    for _, tag in ipairs(ns.Catalog.TAGS) do
        local b = makeChip(host, ns.T("picker.tag." .. tag))
        b.tag = tag
        b.onClick = function() L.ToggleTag(tag) end
        tagBtns[#tagBtns + 1] = b
    end
    for _, r in ipairs(ns.Encounter.Raids()) do
        local b = makeChip(host, ns.Encounter.RaidName(r.key))
        b.raid = r.key
        b.tip = ns.T("picker.boss_raid_tip", ns.T("enc.raid_full." .. r.key))
        b.onClick = function() L.SetRaid(r.key) end
        b:Hide()
        raidBtns[#raidBtns + 1] = b
        for _, key in ipairs(r.bosses) do
            local c = makeChip(host, ns.Encounter.Name(key))
            c.raid, c.boss = r.key, key
            c.onClick = function() L.SetBoss(key) end
            c:Hide()
            bossBtns[#bossBtns + 1] = c
        end
    end
    foundFs = host:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    foundFs:SetText(ns.T("picker.found"))
    ink(foundFs, ns.EDIT.mute)
    for _, cat in ipairs(ns.Catalog.CATS) do
        local b = makeCat(host)
        b.onClick = function() L.SetCat(cat) end
        catBtns[cat] = b
    end
    if spec.gone then
        local b = makeCat(host)
        b.tip = ns.T("options.gone_tip")
        b.onClick = function() L.SetCat(GONE) end
        catBtns[GONE] = b
    end
    listFrame = CreateFrame("Frame", nil, host)
    listFrame:EnableMouseWheel(true)
    listFrame:SetScript("OnMouseWheel", function(_, delta) L.Scroll(-delta * WHEEL_ROWS) end)
    for i = 1, ROWN do rows[i] = makeRow(i) end
    emptyFs = listFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyFs:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 4, -6)
    emptyFs:SetText(ns.T("picker.empty"))
    ink(emptyFs, ns.EDIT.mute)
    if spec.preview then buildPreview() end
    footFs = host:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footFs:SetJustifyH("LEFT")
    footFs:SetText(ns.T(spec.foot))
    ink(footFs, ns.EDIT.mute)
    layout()
    local regen = CreateFrame("Frame", nil, host)
    regen:RegisterEvent("PLAYER_REGEN_ENABLED")
    regen:SetScript("OnEvent", function()
        for key, hit in pairs(state.pending) do
            if not isPending(hit) then
                state.pending[key] = nil
                state.done[key] = true
            end
        end
        if host:IsVisible() then L.Refresh(true) end
    end)
    if hooksecurefunc then
        hooksecurefunc("ChatEdit_InsertLink", function(link)
            if host:IsVisible() and box:HasFocus() and link and box.Insert then box:Insert(link) end
        end)
    end
    return L
end
ns.CatalogList = newList
local state = { q = "", tags = {}, offset = 0, flat = {}, done = {}, pending = {} }
local win
local list
local function build()
    if win then return end
    win = ns.MakeEditFrame("LazyBuffBarPicker", "window")
    win:SetWidth(W)
    win.title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    win.title:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -PAD)
    win.title:SetText(ns.T("picker.title"))
    ink(win.title, ns.EDIT.gold)
    list = newList({
        host = win, top = TOP, width = function() return W end, rows = ROWS, preview = true, foot = "picker.foot",
        state = state,
        onEsc = function() win:Hide() end,
        onLayout = function(h) win:SetHeight(h + PAD) end,
    })
    list.place = function(hit)
        local cell = state.cell
        local ok, why = ns.Catalog.Place(hit, state.target, cell and cell.x, cell and cell.y)
        if ok or why == "later" then state.cell = nil end
        return ok, why
    end
    win:SetScript("OnHide", function()
        list.field.box:ClearFocus()
        ns.TipHide()
    end)
end
function P.Move(dir) if list then list.Move(dir) end end
function P.Scroll(delta) if list then list.Scroll(delta) end end
function P.Selected() return list and list.Selected() or nil end
function P.Add(hit)
    build()
    return list.Add(hit)
end
function P.Refresh(keepSel)
    if list then list.Refresh(keepSel) end
end
function P.SetQuery(text) if list then list.SetQuery(text) end end
function P.ToggleTag(tag) if list then list.ToggleTag(tag) end end
function P.SetCat(cat) if list then list.SetCat(cat) end end
function P.SetScope(scope)
    if list then list.SetScope(scope) else state.scope = scope end
end
function P.SetRaid(raid) if list then list.SetRaid(raid) end end
function P.SetBoss(boss) if list then list.SetBoss(boss) end end
function P.List() return list end
function P.Open(anchor, target, x, y)
    build()
    ns.Catalog.Ensure()
    state.target = target
    state.cell = (target and x and y) and { x = x, y = y } or nil
    state.done, state.cat, state.hover = {}, nil, nil
    win:ClearAllPoints()
    if anchor then
        win:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
        ns.PinTopLeft(win)
    else
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    end
    win:Show()
    state.q = ""
    list.field:SetText("")
    list.SetQuery("")
    list.field:SetFocus()
end
function P.Close()
    if win then win:Hide() end
end
function P.IsShown()
    return win ~= nil and win:IsShown() and true or false
end
function P.State()
    return state
end
function P.Preview()
    return list and list.preview or nil
end
P.OnDragStart = nil
function P.UseOld()
    local r = ns.Profile and ns.Profile.Root and ns.Profile.Root()
    return r ~= nil and r.oldPicker == true
end
function P.SetUseOld(on)
    local r = ns.Profile and ns.Profile.Root and ns.Profile.Root()
    if not r then return end
    r.oldPicker = on and true or nil
    if on and ns.PickerLib then ns.PickerLib.Close() elseif not on then P.Close() end
end
function P.OpenPlus(anchor, target, x, y)
    if not P.UseOld() and ns.PickerLib then
        ns.PickerLib.Open(anchor, target, x, y)
    else
        P.Open(anchor, target, x, y)
    end
end
ns.Blocks.OnPlus(function(key, fr, x, y) P.OpenPlus(fr, key, x, y) end)
function P.DropItem(key, x, y)
    local kind, id, link = GetCursorInfo()
    if kind ~= "item" or not id then return false, "none" end
    ClearCursor()
    local ok, why = ns.Catalog.Place(ns.Catalog.ItemHit(id, link), key, x, y)
    return ok, why
end
ns.Blocks.OnItemDrop(function(key, x, y) P.DropItem(key, x, y) end)
ns.pickerLoaded = true
