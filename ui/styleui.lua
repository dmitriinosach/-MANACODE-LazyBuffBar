local _, ns = ...
ns.StyleUI = {}
local U = ns.StyleUI
local ROW_H = 20
local LABEL_W = 92
local DOT = 6
local RESET_SZ = 14
local SIDE = 4
local COL_GAP = 16
local THEME_W = 96
local RESET_TEX = "Interface\\Buttons\\UI-RefreshButton"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local made = {}
local function same(a, b)
    if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 0.001 end
    return a == b
end
function U.Label(key, v)
    if type(v) == "number" then return ("%d%%"):format(math.floor(v * 100 + 0.5)) end
    return ns.T("style.o." .. key .. "." .. tostring(v))
end
local function optTip(key, v)
    local o = ns.Style.Opt(key, v)
    local d = type(v) == "string" and ns.L["style.d." .. key .. "." .. v] or nil
    local code = o and ns.T("style.code", o.code) or nil
    if d and code then return d .. "\n" .. code end
    return d or code
end
local function swatchOf(key, v)
    if key ~= "edgeColor" then return nil end
    if v == "class" then
        local _, class = UnitClass("player")
        local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c then return { c.r, c.g, c.b } end
        return nil
    end
    return ns.Style.COLORS[v]
end
function U.Items(key, level, cur, own, inherit, set)
    local out = { { text = ns.T("style." .. key), isTitle = true } }
    if inherit then
        out[#out + 1] = { text = inherit .. " (" .. U.Label(key, cur) .. ")", checked = not own,
                          tip = ns.T("style.inherit_tip"), func = function() set(nil) end }
    end
    for _, o in ipairs(ns.Style.Options(key, level)) do
        local v = o.key
        out[#out + 1] = {
            text = U.Label(key, v), note = o.code, tip = optTip(key, v), swatch = swatchOf(key, v),
            checked = (own or not inherit) and same(cur, v) or false,
            func = function() set(v) end,
        }
    end
    return out
end
local function label(parent, w)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", parent, "LEFT", 0, 0)
    fs:SetWidth(w)
    fs:SetJustifyH("LEFT")
    if ns.Ink and ns.EDIT then ns.Ink(fs, ns.EDIT.mute) end
    return fs
end
local function makeRow(parent, w, text, tip)
    local row = { frame = CreateFrame("Frame", nil, parent) }
    local f = row.frame
    f:SetWidth(w)
    f:SetHeight(ROW_H)
    row.label = label(f, LABEL_W)
    row.label:SetText(text)
    row.btn = ns.MakeButton(f)
    row.btn:SetPoint("LEFT", f, "LEFT", LABEL_W, 0)
    row.btn.tipTitle = text
    row.btn.tip = tip
    row.btn.bw = w - LABEL_W - RESET_SZ - SIDE * 2
    row.dot = f:CreateTexture(nil, "OVERLAY")
    row.dot:SetTexture(WHITE)
    row.dot:SetWidth(DOT)
    row.dot:SetHeight(DOT)
    row.dot:SetPoint("RIGHT", f, "LEFT", LABEL_W - SIDE, 0)
    row.dot:Hide()
    row.reset = CreateFrame("Button", nil, f)
    row.reset:SetWidth(RESET_SZ)
    row.reset:SetHeight(RESET_SZ)
    row.reset:SetPoint("LEFT", row.btn, "RIGHT", SIDE, 0)
    row.reset:SetNormalTexture(RESET_TEX)
    row.reset:SetScript("OnEnter", function(self) ns.TipShow(self) end)
    row.reset:SetScript("OnLeave", function() ns.TipHide() end)
    row.reset:Hide()
    return row
end
local function setValue(row, text)
    row.btn:SetLabel(text)
    row.btn:SetWidth(row.btn.bw)
end
local function setOwn(row, own)
    if own then
        row.dot:Show()
        row.reset:Show()
    else
        row.dot:Hide()
        row.reset:Hide()
    end
end
local function restyle(self)
    local c = ns.EDIT and ns.EDIT.gold or { 1, 0.82, 0 }
    local all = {}
    for _, r in ipairs(self.rows) do all[#all + 1] = r end
    if self.theme then all[#all + 1] = self.theme end
    for _, r in ipairs(all) do
        r.dot:SetVertexColor(c[1], c[2], c[3], 1)
        if ns.Ink and ns.EDIT then ns.Ink(r.label, ns.EDIT.mute) end
    end
end
local function arm(row, combat)
    if combat then
        row.btn:Disable()
        row.reset:Disable()
    else
        row.btn:Enable()
        row.reset:Enable()
    end
end
local function setRows(self, i, combat)
    self.i = i
    local bar = self.scope == "bar"
    for _, row in ipairs(self.rows) do
        local key = row.key
        local cur, own
        if bar then
            cur, own = ns.Style.Bar(i, key), ns.Style.OwnBar(i, key)
        else
            cur, own = ns.Style.Global(key), ns.Style.OwnGlobal(key)
        end
        setValue(row, U.Label(key, cur))
        setOwn(row, own)
        arm(row, combat)
    end
    if self.theme then
        local t = i and ns.Style.ThemeOf(i)
        setValue(self.theme, t and ns.T("style.themes." .. t) or ns.T("style.theme_none"))
        local b = i and ns.Preset.Blocks()[i]
        setOwn(self.theme, b ~= nil and b.style ~= nil)
        arm(self.theme, combat)
    end
end
local function openRow(self, row)
    local key = row.key
    local bar = self.scope == "bar"
    local i = self.i
    if bar and not i then return end
    local cur, own, inherit, set
    if bar then
        cur, own = ns.Style.Bar(i, key), ns.Style.OwnBar(i, key)
        inherit = ns.T("style.inherit_all")
        set = function(v) ns.Style.SetBar(i, key, v) end
    else
        cur, own = ns.Style.Global(key), true
        set = function(v) ns.Style.SetGlobal(key, v) end
    end
    ns.MakeMenu(U.Items(key, bar and "bar" or "all", cur, own, inherit, function(v)
        set(v)
        if self.onChange then self.onChange() end
    end), row.btn)
end
local function openTheme(self)
    local i = self.i
    if not i then return end
    local cur = ns.Style.ThemeOf(i)
    local items = { { text = ns.T("style.theme"), isTitle = true } }
    for _, name in ipairs(ns.Style.THEME_ORDER) do
        items[#items + 1] = { text = ns.T("style.themes." .. name), note = name, checked = cur == name,
                              tip = ns.T("style.themes." .. name .. "_tip"),
                              func = function()
                                  ns.Style.ApplyTheme(i, name)
                                  if self.onChange then self.onChange() end
                              end }
    end
    items[#items + 1] = { text = ns.T("style.theme_reset"), tip = ns.T("style.theme_reset_tip"),
                          func = function()
                              ns.Style.ApplyTheme(i, nil)
                              if self.onChange then self.onChange() end
                          end }
    ns.MakeMenu(items, self.theme.btn)
end
function U.Rows(parent, spec)
    local self = { frame = CreateFrame("Frame", nil, parent), scope = spec.scope, rows = {}, onChange = spec.onChange }
    local cols = spec.cols or 2
    local colW = (spec.width - COL_GAP * (cols - 1)) / cols
    local level = spec.scope
    local keys = {}
    for _, key in ipairs(ns.Style.ORDER) do
        local k = ns.Style.KNOBS[key]
        if k and k[level] then keys[#keys + 1] = key end
    end
    local all = {}
    if level == "bar" then
        local t = makeRow(self.frame, colW, ns.T("style.theme"), ns.T("style.theme_tip"))
        t.reset.tipTitle = ns.T("style.theme_reset")
        t.reset.tip = ns.T("style.theme_reset_tip")
        t.btn.onClick = function() openTheme(self) end
        t.reset:SetScript("OnClick", function()
            if self.i then ns.Style.ApplyTheme(self.i, nil) end
            if self.onChange then self.onChange() end
        end)
        self.theme = t
        all[#all + 1] = t
    end
    for _, key in ipairs(keys) do
        local row = makeRow(self.frame, colW, ns.T("style." .. key), ns.T("style." .. key .. "_tip"))
        row.key = key
        row.reset.tipTitle = ns.T(level == "bar" and "style.reset" or "style.reset_all")
        row.reset.tip = ns.T("style.own_tip")
        row.btn.onClick = function() openRow(self, row) end
        row.reset:SetScript("OnClick", function()
            if level == "bar" then
                if self.i then ns.Style.SetBar(self.i, key, nil) end
            else
                ns.Style.SetGlobal(key, nil)
            end
            if self.onChange then self.onChange() end
        end)
        self.rows[#self.rows + 1] = row
        all[#all + 1] = row
    end
    local perCol = math.ceil(#all / cols)
    for n, row in ipairs(all) do
        local c = math.floor((n - 1) / perCol)
        local r = (n - 1) % perCol
        row.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", c * (colW + COL_GAP), -r * ROW_H)
    end
    self.frame:SetWidth(spec.width)
    self.frame:SetHeight(perCol * ROW_H)
    self.Set = setRows
    self.Restyle = restyle
    restyle(self)
    made[#made + 1] = self
    return self
end
local ITEM_KNOBS = {}
for _, key in ipairs(ns.Style.ORDER) do
    local k = ns.Style.KNOBS[key]
    if k and k.item then ITEM_KNOBS[#ITEM_KNOBS + 1] = key end
end
function U.ItemMenu(self)
    local key, x, y = self.key, self.x, self.y
    local out = { { text = ns.T("style.button"), isTitle = true } }
    for _, knob in ipairs(ITEM_KNOBS) do
        local cur = ns.Style.Item(key, x, y, knob)
        local own = ns.Style.OwnItem(key, x, y, knob)
        local sub = U.Items(knob, "item", cur, own, ns.T("style.inherit_bar"), function(v)
            ns.Style.SetItem(key, x, y, knob, v)
            if self.onChange then self.onChange() end
        end)
        table.remove(sub, 1)
        out[#out + 1] = { text = ns.T("style." .. knob), note = U.Label(knob, cur), checked = own,
                          tip = ns.T("style." .. knob .. "_tip"), submenu = sub }
    end
    return out
end
local function setItem(self, key, x, y, combat)
    self.key, self.x, self.y = key, x, y
    local own = false
    for _, knob in ipairs(ITEM_KNOBS) do
        if ns.Style.OwnItem(key, x, y, knob) then own = true end
    end
    self.btn:SetActive(own)
    if combat then self.btn:Disable() else self.btn:Enable() end
end
function U.ItemButton(parent)
    local self = { btn = ns.MakeButton(parent) }
    self.btn:SetLabel(ns.T("style.button"))
    self.btn.tipTitle = ns.T("style.button")
    self.btn.tip = ns.T("style.button_tip")
    self.btn.onClick = function()
        if not self.key then return end
        ns.MakeMenu(U.ItemMenu(self), self.btn)
    end
    self.Set = setItem
    made[#made + 1] = self
    return self
end
local BAR_KNOBS = {}
for _, key in ipairs(ns.Style.ORDER) do
    local k = ns.Style.KNOBS[key]
    if k and k.bar then BAR_KNOBS[#BAR_KNOBS + 1] = key end
end
function U.BarMenu(self)
    local i = self.i
    local out = { { text = ns.T("style.knobs"), isTitle = true } }
    for _, knob in ipairs(BAR_KNOBS) do
        local cur, own = ns.Style.Bar(i, knob), ns.Style.OwnBar(i, knob)
        local sub = U.Items(knob, "bar", cur, own, ns.T("style.inherit_all"), function(v)
            ns.Style.SetBar(i, knob, v)
            if self.onChange then self.onChange() end
        end)
        table.remove(sub, 1)
        out[#out + 1] = { text = ns.T("style." .. knob), note = U.Label(knob, cur), checked = own,
                          tip = ns.T("style." .. knob .. "_tip"), submenu = sub }
    end
    out[#out + 1] = { text = ns.T("style.theme_reset"), tip = ns.T("style.theme_reset_tip"),
                      func = function()
                          ns.Style.ApplyTheme(i, nil)
                          if self.onChange then self.onChange() end
                      end }
    return out
end
function U.ThemeMenu(self)
    local i = self.i
    local cur = ns.Style.ThemeOf(i)
    local items = { { text = ns.T("style.theme"), isTitle = true } }
    for _, name in ipairs(ns.Style.THEME_ORDER) do
        items[#items + 1] = { text = ns.T("style.themes." .. name), note = name, checked = cur == name,
                              tip = ns.T("style.themes." .. name .. "_tip"),
                              func = function()
                                  ns.Style.ApplyTheme(i, name)
                                  if self.onChange then self.onChange() end
                              end }
    end
    return items
end
local function setBarRow(self, i, combat)
    self.i = i
    local t = ns.Style.ThemeOf(i)
    self.theme:SetLabel(t and ns.T("style.themes." .. t) or ns.T("style.theme_none"))
    self.theme:SetWidth(THEME_W)
    local b = ns.Preset.Blocks()[i]
    self.knobs:SetActive(b ~= nil and b.style ~= nil)
    for _, btn in ipairs({ self.theme, self.knobs }) do
        if combat then btn:Disable() else btn:Enable() end
    end
end
local function restyleBarRow(self)
    if ns.Ink and ns.EDIT then ns.Ink(self.label, ns.EDIT.mute) end
end
function U.BarRow(parent, labelW, text)
    local self = { frame = CreateFrame("Frame", nil, parent) }
    self.frame:SetHeight(ROW_H)
    self.label = label(self.frame, labelW)
    self.label:SetText(text)
    self.theme = ns.MakeButton(self.frame)
    self.theme:SetPoint("LEFT", self.frame, "LEFT", labelW, 0)
    self.theme.tipTitle = ns.T("style.theme")
    self.theme.tip = ns.T("style.theme_tip")
    self.theme.onClick = function()
        if self.i then ns.MakeMenu(U.ThemeMenu(self), self.theme) end
    end
    self.knobs = ns.MakeButton(self.frame)
    self.knobs:SetLabel(ns.T("style.knobs"))
    self.knobs:SetPoint("LEFT", self.theme, "RIGHT", SIDE, 0)
    self.knobs.tipTitle = ns.T("style.knobs")
    self.knobs.tip = ns.T("style.knobs_tip")
    self.knobs.onClick = function()
        if self.i then ns.MakeMenu(U.BarMenu(self), self.knobs) end
    end
    self.Set = setBarRow
    self.Restyle = restyleBarRow
    restyleBarRow(self)
    made[#made + 1] = self
    return self
end
function U.Holding(btn)
    local st = ns.MenuState and ns.MenuState()
    return (st and st.anchor ~= nil and st.anchor == btn) and true or false
end
function U.Made()
    return made
end
ns.styleUiLoaded = true
