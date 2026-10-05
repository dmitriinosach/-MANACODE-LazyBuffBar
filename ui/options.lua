local ADDON, ns = ...
local PAD = 16
local ROW = 30
local panel
local refreshing = false
local checkCount = 0
local function check(parent, label, x, y, get, set)
    checkCount = checkCount + 1
    local c = CreateFrame("CheckButton", "LazyBuffBarCheck" .. checkCount, parent,
        "InterfaceOptionsCheckButtonTemplate")
    c:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    _G[c:GetName() .. "Text"]:SetText(label)
    c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    c.refresh = function() c:SetChecked(get()) end
    return c
end
local function slider(parent, x, y, min, max, step, format, get, set)
    local s = CreateFrame("Slider", "LazyBuffBarSlider" .. tostring(x) .. tostring(-y), parent,
        "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    s:SetWidth(200)
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    _G[s:GetName() .. "Low"]:SetText(format(min))
    _G[s:GetName() .. "High"]:SetText(format(max))
    s.caption = _G[s:GetName() .. "Text"]
    s:SetScript("OnValueChanged", function(self, v)
        v = floor(v / step + 0.5) * step
        self.caption:SetText(format(v))
        if refreshing then return end
        set(v)
    end)
    s.refresh = function()
        local v = get()
        s:SetValue(v)
        s.caption:SetText(format(v))
    end
    return s
end
local function rebuffKnob()
    for _, w in ipairs(ns.Watchers()) do
        if w.id == "rebuff" then return w.knobs and w.knobs[1] end
    end
    return nil
end
local controls = {}
local function refresh()
    refreshing = true
    for _, c in ipairs(controls) do c.refresh() end
    refreshing = false
end
local function build()
    panel = CreateFrame("Frame", "LazyBuffBarOptionsPanel", UIParent)
    panel.name = ns.T("options.title")
    panel:Hide()
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -PAD)
    title:SetText(ns.T("options.title"))
    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetWidth(520)
    sub:SetJustifyH("LEFT")
    sub:SetText(ns.T("options.note"))
    local y = -72
    controls[#controls + 1] = check(panel, ns.T("options.show"), PAD, y,
        function() return ns.buffbar:IsShown() end,
        function(on) ns.buffbar:SetShown(on); refresh() end)
    y = y - ROW
    controls[#controls + 1] = check(panel, ns.T("options.lock"), PAD, y,
        function() return ns.buffbar:IsLocked() end,
        function(on) ns.buffbar:SetLocked(on); refresh() end)
    y = y - ROW - 10
    controls[#controls + 1] = slider(panel, PAD + 6, y, 50, 250, 5,
        function(v) return ns.T("options.scale", v) end,
        function() return floor((ns.buffbar:GetScale() or ns.buffbar:GetScale(1)) * 100 + 0.5) end,
        function(v)
            local got = ns.buffbar:SetScale(v / 100)
            if got and floor(got * 100 + 0.5) ~= v then refresh() end
        end)
    y = y - ROW - 18
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetWidth(180)
    reset:SetHeight(22)
    reset:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
    reset:SetText(ns.T("options.reset"))
    reset:SetScript("OnClick", function() ns.buffbar:ResetBars() end)
    y = y - ROW - 14
    local head = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    head:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
    head:SetText(ns.T("options.rebuff"))
    y = y - ROW
    controls[#controls + 1] = check(panel, ns.T("notify.watch.rebuff.check"), PAD, y,
        function() return ns.WatchEnabled("rebuff") end,
        function(on) ns.SetWatchEnabled("rebuff", on) end)
    y = y - ROW - 10
    local knob = rebuffKnob()
    if knob then
        controls[#controls + 1] = slider(panel, PAD + 6, y, knob.min, knob.max, knob.step,
            function(v) return ns.T("notify.watch.rebuff.every", v) end,
            knob.get, knob.set)
    end
    panel.refresh = refresh
    InterfaceOptions_AddCategory(panel)
end
function ns.OpenOptions()
    if not panel then return end
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
end
function ns.BuildOptions()
    if panel then return end
    build()
end
ns.optionsLoaded = true
