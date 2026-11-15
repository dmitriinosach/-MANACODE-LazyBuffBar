local _, ns = ...
ns.CondRules = {}
local R = ns.CondRules
local ROW_H = 22
local ROW_GAP = 4
local SEG_GAP = 6
local SEG_PAD = 12
local STEP_W = 16
local VALUE_W = 32
local CLOSE_SZ = 16
local LABEL_GAP = 6
local function segWidth(seg)
    local w = 0
    for i = 1, #seg.options do
        local b = seg.buttons[i]
        local tw = b and b.text:GetStringWidth() or 0
        if tw > w then w = tw end
    end
    return #seg.options * (w + SEG_PAD)
end
local function seg(parent, keys, prefix, tips, onPick)
    local opts = {}
    for i, k in ipairs(keys) do
        opts[i] = { key = k, label = prefix and ns.T(prefix .. k) or k, tip = tips and tips[k] or nil }
    end
    local s = ns.MakeSegments(parent, opts)
    s.onPick = onPick
    s:SetWidth(segWidth(s))
    s:Layout()
    return s
end
local function stepped(v, dir)
    local C = ns.Cond
    local s = C.RULE_STEP
    local n
    if dir > 0 then n = math.floor(v / s) * s + s else n = math.ceil(v / s) * s - s end
    if n < C.RULE_MIN then n = C.RULE_MIN end
    if n > C.RULE_MAX then n = C.RULE_MAX end
    return n
end
local function edit(ed, i, field, v)
    if ed.off then return end
    local cur = ed.rules and ed.rules[i]
    if not cur then return end
    local r = { u = cur.u, t = cur.t, op = cur.op, v = cur.v }
    r[field] = v
    ed.onChange(ns.Cond.WithRule(ed.rules, i, r))
end
local function row(ed, i)
    local r = ed.rows[i]
    if r then return r end
    local f = CreateFrame("Frame", nil, ed.frame)
    f:SetHeight(ROW_H)
    f:EnableMouseWheel(true)
    r = { frame = f, index = i }
    local C = ns.Cond
    r.who = seg(f, C.RULE_UNITS, "cond.u_", { tank = ns.T("cond.u_tank_tip") }, function(k) edit(ed, r.index, "u", k) end)
    r.what = seg(f, C.RULE_TYPES, "cond.t_", { power = ns.T("cond.t_power_tip") }, function(k) edit(ed, r.index, "t", k) end)
    r.op = seg(f, C.RULE_OPS, nil, nil, function(k) edit(ed, r.index, "op", k) end)
    r.who:SetPoint("LEFT", f, "LEFT", 0, 0)
    r.what:SetPoint("LEFT", r.who, "RIGHT", SEG_GAP, 0)
    r.op:SetPoint("LEFT", r.what, "RIGHT", SEG_GAP, 0)
    local x = r.who:GetWidth() + r.what:GetWidth() + r.op:GetWidth() + 3 * SEG_GAP
    local function nudge(dir)
        local cur = ed.rules and ed.rules[r.index]
        if cur then edit(ed, r.index, "v", stepped(cur.v, dir)) end
    end
    r.step = ns.MakeStepper(f, x, STEP_W, VALUE_W, nudge)
    r.step.less:SetHeight(ROW_H - 2)
    r.step.more:SetHeight(ROW_H - 2)
    f:SetScript("OnMouseWheel", function(_, delta) nudge(delta > 0 and 1 or -1) end)
    r.close = ns.MakeCloseX(f)
    r.close:SetWidth(CLOSE_SZ)
    r.close:SetHeight(CLOSE_SZ)
    r.close:SetPoint("LEFT", r.step.more, "RIGHT", SEG_GAP, 0)
    r.close.tipTitle = ns.T("cond.remove_tip")
    r.close.onClick = function()
        if ed.off then return end
        ed.onChange(ns.Cond.WithRule(ed.rules, r.index, nil))
    end
    r.width = x + 2 * STEP_W + VALUE_W + 8 + SEG_GAP + CLOSE_SZ
    f:SetWidth(r.width)
    ed.rows[i] = r
    return r
end
local function fillRow(r, rule, off)
    r.who:SetValue(rule.u)
    r.what:SetValue(rule.t)
    r.op:SetValue(rule.op)
    local C = ns.Cond
    r.step:Set(("%d%%"):format(rule.v), not off and rule.v > C.RULE_MIN, not off and rule.v < C.RULE_MAX)
    for _, s in ipairs({ r.who, r.what, r.op }) do
        if off then s:Disable() else s:Enable() end
    end
    if off then r.close:Disable() else r.close:Enable() end
end
local function set(self, rules, off)
    self.rules, self.off = rules, off and true or false
    local list = rules or {}
    if self.off or #list >= ns.Cond.RULE_LIMIT then self.add:Disable() else self.add:Enable() end
    local w = self.labelW + (self.add:GetWidth() or 0)
    for i, rule in ipairs(list) do
        local r = row(self, i)
        r.index = i
        fillRow(r, rule, self.off)
        r.frame:ClearAllPoints()
        r.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -i * (ROW_H + ROW_GAP))
        r.frame:Show()
        if r.width > w then w = r.width end
    end
    for i = #list + 1, #self.rows do self.rows[i].frame:Hide() end
    self.frame:SetWidth(w)
    self.frame:SetHeight(ROW_H + #list * (ROW_H + ROW_GAP))
end
local function restyle(self)
    if self.label then ns.Ink(self.label, ns.EDIT.mute) end
end
function R.New(parent, spec)
    local f = CreateFrame("Frame", nil, parent)
    local ed = { frame = f, rows = {}, labelW = 0, onChange = spec.onChange, Set = set, Restyle = restyle }
    if spec.label then
        ed.label = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        ed.label:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(ROW_H - 12) / 2)
        ed.label:SetText(spec.label)
        ed.label:SetWidth(ed.label:GetStringWidth() + 2)
        ed.labelW = ed.label:GetWidth() + LABEL_GAP
    end
    ed.add = ns.MakeButton(f)
    ed.add:SetHeight(ROW_H - 2)
    ed.add:SetLabel(ns.T("cond.add"))
    ed.add:SetPoint("TOPLEFT", f, "TOPLEFT", ed.labelW, -1)
    ed.add.tipTitle = ns.T("cond.add")
    ed.add.tip = spec.tip
    ed.add.onClick = function()
        if ed.off then return end
        local list = ed.rules or {}
        if #list >= ns.Cond.RULE_LIMIT then return end
        ed.onChange(ns.Cond.WithRule(list, nil, ns.Cond.NewRule()))
    end
    set(ed, nil, false)
    restyle(ed)
    return ed
end
ns.condRulesLoaded = true
