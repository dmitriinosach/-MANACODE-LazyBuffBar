local _, ns = ...
local O = ns.Options
local PAD = 14
local ROW_H = 44
local ROWS = 7
local GAP = 4
local TOP_H = 22
local SEC_GAP = 10
local PREVIEW_W = 150
local PREVIEW_H = 38
local CELL_MAX = 11
local CELL_MIN = 3
local CELL_GAP = 1
local NAME_X = PREVIEW_W + 10
local BTN_GAP = 4
local MAX_TILES = 64
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CROP = { 0.07, 0.93, 0.07, 0.93 }
local POP_DELETE = "LAZYBUFFBAR_LIBRARY_DELETE"
local state = { section = "mine", offset = 0 }
local page, seg, listFrame, emptyFs, countFs, noteFs
local rows = {}
local shown = {}
local function entries()
    if state.section == "factory" then return ns.Library.Factory() end
    return ns.Library.List()
end
local function tile(r, n)
    local t = r.tiles[n]
    if not t then
        t = r.plate:CreateTexture(nil, "ARTWORK")
        r.tiles[n] = t
    end
    return t
end
local function paintPreview(r, block)
    local cols, rows_ = math.max(1, block.cols or 1), math.max(1, block.rows or 1)
    local cell = math.min(CELL_MAX, math.floor((PREVIEW_W - 4 - (cols - 1) * CELL_GAP) / cols),
                          math.floor((PREVIEW_H - 4 - (rows_ - 1) * CELL_GAP) / rows_))
    cell = math.max(CELL_MIN, cell)
    local w = cols * cell + (cols - 1) * CELL_GAP + 4
    local h = rows_ * cell + (rows_ - 1) * CELL_GAP + 4
    r.plate:SetWidth(math.min(w, PREVIEW_W))
    r.plate:SetHeight(math.min(h, PREVIEW_H))
    local n = 0
    for _, ic in ipairs(ns.Library.Icons(block)) do
        n = n + 1
        if n > MAX_TILES then break end
        local t = tile(r, n)
        t:SetTexture(ic.tex or ns.QMARK)
        t:SetTexCoord(CROP[1], CROP[2], CROP[3], CROP[4])
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", r.plate, "TOPLEFT", 2 + (ic.x - 1) * (cell + CELL_GAP), -(2 + (ic.y - 1) * (cell + CELL_GAP)))
        t:SetWidth(ic.w * cell + (ic.w - 1) * CELL_GAP)
        t:SetHeight(ic.h * cell + (ic.h - 1) * CELL_GAP)
        t:Show()
    end
    for i = n + 1, #r.tiles do r.tiles[i]:Hide() end
    r.cells = n
end
local function put(e, anchor)
    local key = ns.Library.Put(e.id)
    if key then ns.say(ns.T("library.placed", e.name)) end
    O.Refresh()
end
local function rename(e, anchor)
    ns.AskName(anchor, {
        title = ns.T("library.rename_ask"), text = e.name, ghost = ns.T("presets.name_ghost"),
        ok = ns.T("presets.save"), cancel = ns.T("presets.cancel"),
        onCommit = function(name)
            ns.Library.Rename(e.id, name)
            O.Refresh()
        end,
    })
end
local function delete(e)
    if InCombatLockdown() then return end
    if not StaticPopupDialogs[POP_DELETE] then
        StaticPopupDialogs[POP_DELETE] = {
            text = ns.T("library.delete_ask"),
            button1 = YES,
            button2 = NO,
            timeout = 0, whileDead = 1, hideOnEscape = 1,
            OnAccept = function(_, id)
                local x = id and ns.Library.Get(id)
                if x and ns.Library.Delete(id) then ns.say(ns.T("library.deleted", x.name)) end
                O.Refresh()
            end,
        }
    end
    StaticPopup_Show(POP_DELETE, e.name, nil, e.id)
end
local function rowEnter(self)
    local e = self.entry
    if not e then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(e.name, 1, 1, 1, 1, true)
    GameTooltip:AddLine(ns.Library.Where(e), 1, 0.82, 0, true)
    GameTooltip:AddLine(ns.T("pcard.summary", e.block.cols or 1, e.block.rows or 1, #(e.block.items or {})), 1, 1, 1, true)
    GameTooltip:Show()
end
local function makeRow(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, listFrame)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -(i - 1) * (ROW_H + GAP))
    r:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", 0, -(i - 1) * (ROW_H + GAP))
    r:RegisterForDrag("LeftButton")
    r.hl = r:CreateTexture(nil, "HIGHLIGHT")
    r.hl:SetAllPoints(r)
    r.hl:SetTexture(WHITE)
    r.hl:SetVertexColor(1, 1, 1, 0.06)
    r.box = CreateFrame("Frame", nil, r)
    r.box:SetWidth(PREVIEW_W)
    r.box:SetHeight(PREVIEW_H)
    r.box:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.plate = CreateFrame("Frame", nil, r.box)
    r.plate:SetPoint("CENTER", r.box, "CENTER", 0, 0)
    r.plate:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    r.plate:SetBackdropColor(0, 0, 0, 0.5)
    r.plate:SetBackdropBorderColor(ns.EDIT.line[1], ns.EDIT.line[2], ns.EDIT.line[3], 1)
    r.tiles = {}
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetPoint("TOPLEFT", r, "TOPLEFT", NAME_X, -7)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.sub:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", NAME_X, 7)
    r.sub:SetJustifyH("LEFT")
    r.sub:SetWordWrap(false)
    r.put = ns.MakeButton(r)
    r.put:SetLabel(ns.T("library.put"))
    r.put:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    r.put.tipTitle = ns.T("library.put")
    r.put.tip = ns.T("library.put_tip")
    r.put.onClick = function(self) if r.entry then put(r.entry, self) end end
    r.delete = ns.MakeButton(r)
    r.delete:SetLabel(ns.T("presets.delete"))
    r.delete:SetPoint("RIGHT", r.put, "LEFT", -BTN_GAP, 0)
    r.delete.tipTitle = ns.T("presets.delete")
    r.delete.tip = ns.T("library.delete_tip")
    r.delete.onClick = function() if r.entry then delete(r.entry) end end
    r.rename = ns.MakeButton(r)
    r.rename:SetLabel(ns.T("presets.rename"))
    r.rename:SetPoint("RIGHT", r.delete, "LEFT", -BTN_GAP, 0)
    r.rename.onClick = function(self) if r.entry then rename(r.entry, self) end end
    r.name:SetPoint("RIGHT", r.rename, "LEFT", -6, 0)
    r.sub:SetPoint("RIGHT", r.rename, "LEFT", -6, 0)
    r:SetScript("OnEnter", rowEnter)
    r:SetScript("OnLeave", ns.TipHide)
    r:SetScript("OnDragStart", function(self)
        if self.entry and ns.Reorder then
            GameTooltip:Hide()
            ns.Reorder.Grab({ from = "library", entry = self.entry }, self)
        end
    end)
    r:Hide()
    rows[i] = r
    return r
end
local function fillRow(r, e, combat)
    r.entry = e
    r.name:SetText(e.name)
    r.sub:SetText(ns.Library.Where(e))
    paintPreview(r, e.block)
    if combat then r.put:Disable() else r.put:Enable() end
    if e.factory then
        r.rename:Hide()
        r.delete:Hide()
        r.name:SetPoint("RIGHT", r.put, "LEFT", -6, 0)
        r.sub:SetPoint("RIGHT", r.put, "LEFT", -6, 0)
    else
        r.rename:Show()
        r.delete:Show()
        r.name:SetPoint("RIGHT", r.rename, "LEFT", -6, 0)
        r.sub:SetPoint("RIGHT", r.rename, "LEFT", -6, 0)
        if combat then r.rename:Disable() else r.rename:Enable() end
        if combat then r.delete:Disable() else r.delete:Enable() end
    end
    r:Show()
end
local function refresh()
    shown = entries()
    local n = #shown
    local maxOff = math.max(0, n - ROWS)
    if state.offset > maxOff then state.offset = maxOff end
    if state.offset < 0 then state.offset = 0 end
    local combat = InCombatLockdown() and true or false
    for i = 1, ROWS do
        local e = shown[state.offset + i]
        local r = makeRow(i)
        if e then fillRow(r, e, combat) else r.entry = nil r:Hide() end
    end
    if n == 0 then
        emptyFs:SetText(ns.T(state.section == "factory" and "library.empty_factory" or "library.empty"))
        emptyFs:Show()
    else
        emptyFs:Hide()
    end
    if n > ROWS then
        countFs:SetText(ns.T("library.count", state.offset + 1, math.min(n, state.offset + ROWS), n))
        countFs:Show()
    else
        countFs:Hide()
    end
    if seg:GetValue() ~= state.section then seg:SetValue(state.section) end
    seg:Layout()
end
local function build(p)
    page = p
    local top = CreateFrame("Frame", nil, page)
    top:SetHeight(TOP_H)
    top:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, 0)
    top:SetPoint("TOPRIGHT", page, "TOPRIGHT", -PAD, 0)
    seg = ns.MakeSegments(top, {
        { key = "mine", label = ns.T("library.mine"), tip = ns.T("library.mine_tip") },
        { key = "factory", label = ns.T("library.factory"), tip = ns.T("library.factory_tip") },
    })
    seg:SetPoint("LEFT", top, "LEFT", 0, 0)
    seg:SetWidth(220)
    seg:SetHeight(TOP_H)
    seg.onPick = function(v)
        state.section, state.offset = v, 0
        refresh()
    end
    countFs = top:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    countFs:SetPoint("RIGHT", top, "RIGHT", 0, 0)
    countFs:SetJustifyH("RIGHT")
    listFrame = CreateFrame("Frame", nil, page)
    listFrame:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, -SEC_GAP)
    listFrame:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT", 0, -SEC_GAP)
    listFrame:SetHeight(ROWS * (ROW_H + GAP) - GAP)
    listFrame:EnableMouseWheel(true)
    listFrame:SetScript("OnMouseWheel", function(_, delta)
        state.offset = state.offset - (delta > 0 and 1 or -1)
        refresh()
    end)
    emptyFs = listFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emptyFs:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -4)
    emptyFs:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", 0, -4)
    emptyFs:SetJustifyH("LEFT")
    noteFs = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    noteFs:SetPoint("TOPLEFT", listFrame, "BOTTOMLEFT", 0, -SEC_GAP)
    noteFs:SetPoint("TOPRIGHT", listFrame, "BOTTOMRIGHT", 0, -SEC_GAP)
    noteFs:SetJustifyH("LEFT")
    noteFs:SetText(ns.T("library.note"))
    page:RegisterEvent("PLAYER_REGEN_DISABLED")
    page:RegisterEvent("PLAYER_REGEN_ENABLED")
    page:SetScript("OnEvent", function(self)
        if self:IsShown() then refresh() end
    end)
    return TOP_H + SEC_GAP + (ROWS * (ROW_H + GAP) - GAP) + SEC_GAP + ns.TextHeight(noteFs, 560 - PAD * 2)
end
O.AddTab("panels", build, refresh)
function O.LibraryState()
    return state
end
function O.LibraryRows()
    return rows, shown
end
function O.LibraryControls()
    return seg
end
function O.LibraryScroll(delta)
    state.offset = state.offset + delta
    refresh()
end
