local _, ns = ...
local O = ns.Options
local ROWS = 11
local TOP_H = 22
local PAGE_W = 560
local state = { q = "", tags = {}, offset = 0, flat = {}, done = {}, pending = {} }
local page
local list
local height = 0
function O.CatalogAdd(hit)
    if not list then return false, "none" end
    return list.Add(hit)
end
function O.CatalogRestore(g)
    if not list then return false end
    return list.Restore(g)
end
function O.CatalogRefresh(keep)
    if list then list.Refresh(keep) end
end
function O.CatalogQuery(text)
    if list then list.SetQuery(text) end
end
function O.CatalogTag(tag)
    if list then list.ToggleTag(tag) end
end
function O.CatalogCat(cat)
    if list then list.SetCat(cat) end
end
function O.CatalogScroll(delta)
    if list then list.Scroll(delta) end
end
function O.CatalogSelected()
    return list and list.Selected() or nil
end
local openBtn
local oldCheck
local function build(p)
    page = p
    openBtn = ns.MakeButton(page)
    openBtn:SetHeight(TOP_H)
    openBtn:SetLabel(ns.T("picker.lib.open"))
    openBtn:SetPoint("TOPLEFT", page, "TOPLEFT", 12, 0)
    openBtn.tip = ns.T("picker.lib.open_tip")
    openBtn.onClick = function()
        if ns.Picker.UseOld() then ns.Picker.Open(nil, nil) else ns.PickerLib.Open(nil, nil) end
    end
    oldCheck = ns.MakeCheck(page)
    oldCheck:SetLabel(ns.T("picker.lib.old"))
    oldCheck:SetPoint("LEFT", openBtn, "RIGHT", 16, 0)
    oldCheck.onToggle = function(on) ns.Picker.SetUseOld(on) end
    local onEnter = oldCheck:GetScript("OnEnter")
    oldCheck:SetScript("OnEnter", function(self)
        self.tip = ns.T("picker.lib.old_tip")
        if onEnter then onEnter(self) end
    end)
    list = ns.CatalogList({
        host = page, top = TOP_H + 8, rows = ROWS, gone = true, foot = "options.catalog_note", state = state,
        width = function() return page:GetWidth() or PAGE_W end,
        onEsc = function() list.field.box:ClearFocus() end,
        onLayout = function(h)
            height = h
            if list then O.SetPageHeight("catalog", h) end
        end,
    })
    list.place = function(hit) return ns.Catalog.Place(hit, nil) end
    page:SetScript("OnHide", function() list.field.box:ClearFocus() end)
    return height
end
local function refresh()
    ns.Catalog.Ensure()
    if oldCheck then oldCheck:SetChecked(ns.Picker.UseOld()) end
    O.CatalogRefresh(true)
end
O.AddTab("catalog", build, refresh)
function O.CatalogState()
    return state
end
function O.CatalogField()
    return list and list.field or nil
end
function O.CatalogTop()
    return openBtn, oldCheck
end
function O.CatalogRows()
    return list and list.rows or {}
end
