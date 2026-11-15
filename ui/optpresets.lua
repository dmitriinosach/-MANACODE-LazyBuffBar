local _, ns = ...
local O = ns.Options
local PAD = 14
local ROW_H = 22
local GAP = 4
local SEC_GAP = 10
local LABEL_W = 190
local NAME_W = 170
local SPEC_W = 110
local BTN_GAP = 4
local ARROW = "Interface\\ChatFrame\\ChatFrameExpandArrow"
local C_LIVE = "|cffffd100"
local POP_COPY = "LAZYBUFFBAR_PROFILE_COPY"
local POP_DELETE = "LAZYBUFFBAR_PROFILE_DELETE"
local POP_RESET = "LAZYBUFFBAR_PROFILE_RESET"
local page
local secs = {}
local slotRows = {}
local variantRow
local variantBtns = {}
local savedList
local savedRows = {}
local savedEmpty
local profRows = {}
local deleteBtn
local noteFs
local function specName(s)
    local class, v = tostring(s):match("^(.-)/(.*)$")
    if not class then return tostring(s) end
    return ns.LocalName(ns.SpecInfo(class, v)) or v
end
local function menuLabel(b, label)
    b:SetLabel(label .. "     ")
    if not b.arrow then
        b.arrow = b:CreateTexture(nil, "OVERLAY")
        b.arrow:SetWidth(12)
        b.arrow:SetHeight(12)
        b.arrow:SetTexture(ARROW)
        b.arrow:SetPoint("RIGHT", b, "RIGHT", -6, 0)
    end
end
local function slotText(slot)
    if ns.SlotCount() < slot then return ns.T("options.slot_fmt", slot, ns.T("profile.slot_none")) end
    local text = ns.T("options.slot_fmt", slot, specName(ns.Preset.SpecOf(slot)))
    if slot == ns.ActiveSlot() then text = C_LIVE .. text .. " " .. ns.T("options.slot_now") .. "|r" end
    return text
end
local function makeSlotRow(sec, slot)
    local row = CreateFrame("Frame", nil, sec)
    row:SetHeight(ROW_H)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetWidth(LABEL_W)
    row.label:SetJustifyH("LEFT")
    row.btn = ns.MakeButton(row)
    row.btn:SetPoint("LEFT", row, "LEFT", LABEL_W, 0)
    row.btn.tip = ns.T("options.bind_tip")
    row.btn.onClick = function(self) ns.EditBar.OpenMenu(slot, self) end
    row.reset = ns.MakeButton(row)
    row.reset:SetLabel(ns.T("options.reset_factory"))
    row.reset:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.reset.tip = ns.T("presets.reset_tip")
    row.reset.onClick = function() ns.EditBar.Reset(slot) end
    sec:Add(row, ROW_H)
    slotRows[slot] = row
end
local function refreshSlots()
    for slot, r in ipairs(slotRows) do
        r.label:SetText(slotText(slot))
        local known = ns.SlotCount() >= slot
        local id = ns.Preset.Bound(slot)
        menuLabel(r.btn, ns.EditBar.PresetLabel(id))
        if known then r.btn:Enable() else r.btn:Disable() end
        if known and ns.Preset.StateOf(id) == "edited" then r.reset:Enable() else r.reset:Disable() end
    end
end
local function pickVariant(key)
    local _, why = ns.SetVariant(key)
    if why == "later" then ns.say(ns.T("bar.later")) end
    O.Refresh()
end
local function refreshVariant()
    local class = ns.PlayerClass()
    local tab = ns.CurrentTab()
    local list = ns.BranchVariants(class, tab)
    if #list < 2 then
        variantRow:Hide()
        return
    end
    variantRow:Show()
    local keys = { "auto" }
    for _, key in ipairs(list) do keys[#keys + 1] = key end
    local cur = ns.VariantChoice() or "auto"
    local x = LABEL_W
    for i, key in ipairs(keys) do
        local b = variantBtns[i]
        if not b then
            b = ns.MakeButton(variantRow)
            variantBtns[i] = b
        end
        if key == "auto" then
            b:SetLabel(ns.T("settings.variant_auto"))
            b.tip = ns.T("settings.variant_auto_tip", ns.LocalName(ns.SpecInfo(class, ns.DefaultVariant(class, tab))) or "")
        else
            b:SetLabel(ns.LocalName(ns.SpecInfo(class, key)) or key)
            b.tip = ns.T("settings.variant_tip")
        end
        b.onClick = function() pickVariant(key) end
        b:SetActive(key == cur)
        b:ClearAllPoints()
        b:SetPoint("LEFT", variantRow, "LEFT", x, 0)
        x = x + b:GetWidth() + BTN_GAP
        b:Show()
    end
    for i = #keys + 1, #variantBtns do variantBtns[i]:Hide() end
end
local function savedRow(n)
    local r = savedRows[n]
    if r then return r end
    r = CreateFrame("Frame", nil, savedList)
    r:SetHeight(ROW_H)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.name:SetWidth(NAME_W)
    r.name:SetJustifyH("LEFT")
    r.spec = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.spec:SetPoint("LEFT", r, "LEFT", NAME_W, 0)
    r.spec:SetWidth(SPEC_W)
    r.spec:SetJustifyH("LEFT")
    r.export = ns.MakeButton(r)
    r.export:SetLabel(ns.T("options.export"))
    r.export:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    r.export.tipTitle = ns.T("options.export_later")
    r.export:Disable()
    r.delete = ns.MakeButton(r)
    r.delete:SetLabel(ns.T("presets.delete"))
    r.delete:SetPoint("RIGHT", r.export, "LEFT", -BTN_GAP, 0)
    r.delete.tip = ns.T("presets.delete_tip")
    r.delete.onClick = function() ns.EditBar.Delete(r.id) end
    r.rename = ns.MakeButton(r)
    r.rename:SetLabel(ns.T("presets.rename"))
    r.rename:SetPoint("RIGHT", r.delete, "LEFT", -BTN_GAP, 0)
    r.rename.onClick = function(self) ns.EditBar.Rename(r.id, self) end
    savedRows[n] = r
    return r
end
local layout
local function refreshSaved()
    local class = ns.PlayerClass()
    local n = 0
    for _, e in ipairs(ns.Preset.List(class)) do
        if e.own then
            n = n + 1
            local r = savedRow(n)
            r.id = e.id
            r.name:SetText(e.label)
            r.spec:SetText(specName(class .. "/" .. e.spec))
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", savedList, "TOPLEFT", 0, -(n - 1) * (ROW_H + GAP))
            r:SetPoint("TOPRIGHT", savedList, "TOPRIGHT", 0, -(n - 1) * (ROW_H + GAP))
            r:Show()
        end
    end
    for i = n + 1, #savedRows do savedRows[i]:Hide() end
    if n == 0 then
        savedEmpty:Show()
        savedList:SetHeight(ROW_H)
    else
        savedEmpty:Hide()
        savedList:SetHeight(n * (ROW_H + GAP) - GAP)
    end
    layout()
end
local function popup(key, def)
    if StaticPopupDialogs[key] then return end
    def.timeout, def.whileDead, def.hideOnEscape = 0, 1, 1
    StaticPopupDialogs[key] = def
end
local function menuText(e)
    if #e.users == 0 then return e.label end
    return e.label .. "  |cff999999" .. table.concat(e.users, ", ") .. "|r"
end
local function openProfileMenu(slot, anchor)
    local cur = ns.Profile.For(slot)
    local items = { { text = ns.T("profile.slot_title" .. slot), isTitle = true } }
    for _, e in ipairs(ns.Profile.List()) do
        local name = e.name
        items[#items + 1] = { text = menuText(e), checked = name == cur,
                              func = function() ns.Profile.Assign(slot, name); O.Refresh() end }
    end
    ns.MakeMenu(items, anchor)
end
local function askCopy(name)
    popup(POP_COPY, {
        text = ns.T("profile.copy_ask"),
        button1 = YES,
        button2 = NO,
        OnAccept = function(_, data)
            if data and ns.Profile.CopyFrom(data) then ns.say(ns.T("profile.copied", ns.Profile.Label(data))) end
            O.Refresh()
        end,
    })
    StaticPopup_Show(POP_COPY, ns.Profile.Label(ns.Profile.Current()), ns.Profile.Label(name), name)
end
local function openTakeMenu(anchor)
    local cur = ns.Profile.Current()
    local items = { { text = ns.T("profile.take_title", ns.Profile.Label(cur)), isTitle = true } }
    for _, e in ipairs(ns.Profile.List()) do
        local name = e.name
        if name ~= cur then
            items[#items + 1] = { text = menuText(e), func = function() askCopy(name) end }
        end
    end
    ns.MakeMenu(items, anchor)
end
local function askNew(anchor)
    ns.AskName(anchor, {
        title = ns.T("profile.new_ask"), ok = ns.T("presets.save"), cancel = ns.T("presets.cancel"),
        onCommit = function(text)
            local ok, why = ns.Profile.New(text)
            if ok then ns.say(ns.T("profile.created", text)) elseif why then ns.say(ns.T("profile.new_" .. why)) end
            O.Refresh()
        end,
    })
end
local function askDelete()
    local name = ns.Profile.Current()
    popup(POP_DELETE, {
        text = ns.T("profile.delete_ask"),
        button1 = YES,
        button2 = NO,
        OnAccept = function(_, data)
            if data and ns.Profile.Delete(data) then ns.say(ns.T("profile.deleted", ns.Profile.Label(data))) end
            O.Refresh()
        end,
    })
    StaticPopup_Show(POP_DELETE, ns.Profile.Label(name), nil, name)
end
local function askReset()
    popup(POP_RESET, {
        text = ns.T("profile.reset_ask"),
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            if ns.Profile.Reset() then ns.say(ns.T("profile.reset_done", ns.Profile.Label(ns.Profile.Current()))) end
            O.Refresh()
        end,
    })
    StaticPopup_Show(POP_RESET, ns.Profile.Label(ns.Profile.Current()))
end
local function slotSpec(slot)
    if ns.SlotCount() < slot then return ns.T("profile.slot_none") end
    if (select(5, ns.GetSpec(slot)) or 0) == 0 then return ns.T("profile.slot_empty") end
    return ns.LocalName(ns.SpecInfo(ns.PlayerClass(), ns.CurrentVariant(slot))) or tostring(ns.CurrentVariant(slot))
end
local function refreshProfile()
    local live = ns.ActiveSlot()
    for slot, r in ipairs(profRows) do
        local text = ns.T("profile.spec_line", ns.T("profile.slot_title" .. slot), slotSpec(slot))
        if slot == live then text = C_LIVE .. text .. "|r" end
        r.label:SetText(text)
        menuLabel(r.btn, ns.Profile.Label(ns.Profile.For(slot)))
    end
    if ns.Profile.Current() == ns.Profile.Default() then deleteBtn:Disable() else deleteBtn:Enable() end
end
local function buildProfile(sec)
    for slot = 1, 2 do
        local row = CreateFrame("Frame", nil, sec)
        row:SetHeight(ROW_H)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.label:SetWidth(LABEL_W)
        row.label:SetJustifyH("LEFT")
        row.btn = ns.MakeButton(row)
        row.btn:SetPoint("LEFT", row, "LEFT", LABEL_W, 0)
        row.btn.tip = ns.T("profile.pick_tip")
        row.btn.onClick = function(self) openProfileMenu(slot, self) end
        sec:Add(row, ROW_H)
        profRows[slot] = row
    end
    local row = CreateFrame("Frame", nil, sec)
    row:SetHeight(ROW_H)
    local x = 0
    local defs = {
        { label = ns.T("profile.new"), tip = ns.T("profile.new_tip"), onClick = function(self) askNew(self) end },
        { label = ns.T("profile.take"), tip = ns.T("profile.take_tip"), onClick = function(self) openTakeMenu(self) end, menu = true },
        { label = ns.T("profile.reset"), tip = ns.T("profile.reset_tip"), onClick = askReset },
        { label = ns.T("profile.delete"), tip = ns.T("profile.delete_tip"), onClick = askDelete },
    }
    for _, d in ipairs(defs) do
        local b = ns.MakeButton(row)
        if d.menu then menuLabel(b, d.label) else b:SetLabel(d.label) end
        b.tip = d.tip
        b.onClick = d.onClick
        b:SetPoint("LEFT", row, "LEFT", x, 0)
        x = x + b:GetWidth() + BTN_GAP
        if d.label == ns.T("profile.delete") then deleteBtn = b end
    end
    sec:Add(row, ROW_H)
end
layout = function()
    local y = 0
    local prev
    for _, sec in ipairs(secs) do
        sec:ClearAllPoints()
        if prev then y = y + SEC_GAP end
        sec:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, -y)
        sec:SetPoint("TOPRIGHT", page, "TOPRIGHT", -PAD, -y)
        if sec == secs[2] then sec:SetHeight(16 + GAP + (savedList:GetHeight() or ROW_H)) end
        y = y + (sec:GetHeight() or 0)
        prev = sec
    end
    noteFs:ClearAllPoints()
    noteFs:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, -(y + SEC_GAP))
    noteFs:SetWidth(O.Window() and (O.Window():GetWidth() - PAD * 2) or 500)
    y = y + SEC_GAP + ns.TextHeight(noteFs, noteFs:GetWidth() or 500)
    O.SetPageHeight("presets", y)
    return y
end
local function build(p)
    page = p
    local sec = ns.MakeSection(page, ns.T("options.bind_head"))
    secs[1] = sec
    for slot = 1, 2 do makeSlotRow(sec, slot) end
    variantRow = CreateFrame("Frame", nil, sec)
    variantRow:SetHeight(ROW_H)
    variantRow.label = variantRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    variantRow.label:SetPoint("LEFT", variantRow, "LEFT", 0, 0)
    variantRow.label:SetWidth(LABEL_W)
    variantRow.label:SetJustifyH("LEFT")
    variantRow.label:SetText(ns.T("settings.variant"))
    sec:Add(variantRow, ROW_H)
    sec = ns.MakeSection(page, ns.T("options.saved_head"))
    secs[2] = sec
    savedList = CreateFrame("Frame", nil, sec)
    savedList:SetHeight(ROW_H)
    savedEmpty = savedList:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    savedEmpty:SetPoint("LEFT", savedList, "LEFT", 0, 0)
    savedEmpty:SetText(ns.T("options.saved_empty"))
    sec:Add(savedList, ROW_H)
    sec = ns.MakeSection(page, ns.T("profile.title"))
    secs[3] = sec
    buildProfile(sec)
    noteFs = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    noteFs:SetJustifyH("LEFT")
    noteFs:SetText(ns.T("options.preset_note"))
    return layout()
end
local function refresh()
    refreshSlots()
    refreshVariant()
    refreshSaved()
    refreshProfile()
end
O.AddTab("presets", build, refresh)
function O.PresetsRows()
    return { slots = slotRows, variants = variantBtns, saved = savedRows, profiles = profRows }
end
