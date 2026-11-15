local _, ns = ...
ns.Widget = {}
local CELL = 32
local GAP = 2
local defs = {}
local names = {}
function ns.Widget.Register(name, def)
    def.name = name
    if not defs[name] then names[#names + 1] = name end
    defs[name] = def
    return def
end
function ns.Widget.Get(name)
    return defs[name]
end
function ns.Widget.List()
    local out = {}
    for i, n in ipairs(names) do out[i] = n end
    return out
end
function ns.Widget.Avail(name)
    local d = defs[name]
    if not d then return false end
    if not d.avail then return true end
    return d.avail() and true or false
end
local function orderOf(d)
    if type(d.order) == "function" then return d.order() end
    return d.order
end
function ns.Widget.ViewOf(name, view)
    local d = defs[name]
    if not d then return nil end
    if d.alias then view = d.alias(view) end
    if view and d.views[view] then return view end
    return d.view
end
function ns.Widget.Size(name, view, opt)
    local d = defs[name]
    if not d then return 1, 1 end
    local v = d.views[ns.Widget.ViewOf(name, view)]
    if type(v) == "function" then return v(opt or {}) end
    return v.w, v.h
end
function ns.Widget.Views(name)
    local d = defs[name]
    local out = {}
    for i, v in ipairs(d and orderOf(d) or {}) do out[i] = v end
    return out
end
function ns.Widget.NextView(name, view)
    local d = defs[name]
    local order = d and orderOf(d)
    if not order or #order < 2 then return nil end
    view = ns.Widget.ViewOf(name, view)
    for i, v in ipairs(order) do
        if v == view then return order[(i % #order) + 1] end
    end
    return order[1]
end
local function skinOrderOf(d)
    if d.skinOrder then return d.skinOrder end
    local out = {}
    for k in pairs(d.skins or {}) do out[#out + 1] = k end
    table.sort(out)
    return out
end
function ns.Widget.Skins(name)
    local d = defs[name]
    local out = {}
    for i, k in ipairs(d and d.skins and skinOrderOf(d) or {}) do out[i] = k end
    return out
end
function ns.Widget.SkinOf(name, opt)
    local d = defs[name]
    if not (d and d.skins) then return nil end
    local k = opt and opt.skin
    if k and d.skins[k] then return k end
    if d.skin and d.skins[d.skin] then return d.skin end
    return skinOrderOf(d)[1]
end
local function skinOpt(d)
    if not d.skins then return nil end
    if d.skinOpt then return d.skinOpt end
    local order = skinOrderOf(d)
    if #order < 2 then return nil end
    local def = ns.Widget.SkinOf(d.name, nil)
    local values = {}
    for _, k in ipairs(order) do
        values[#values + 1] = { v = k ~= def and k or nil, label = d.skins[k].label }
    end
    d.skinOpt = { key = "skin", kind = "menu", label = "card.skin", values = values }
    return d.skinOpt
end
function ns.Widget.Opts(name, item)
    local d = defs[name]
    local out = {}
    local sk = d and skinOpt(d)
    if sk then out[1] = sk end
    for _, o in ipairs(d and d.opts or {}) do
        if not o.when or o.when(item or {}) then out[#out + 1] = o end
    end
    return out
end
function ns.Widget.OptValues(o, item)
    if type(o.values) == "function" then return o.values(item or {}) end
    return o.values
end
function ns.WidgetLabel(name)
    if ns.L["catalog.widget." .. name] then return ns.T("catalog.widget." .. name) end
    if ns.L["widget." .. name] then return ns.T("widget." .. name) end
    return tostring(name)
end
function ns.Widget.NameOf(k)
    return k and k:match("^widget:(.+)$") or nil
end
function ns.Widget.Split(item)
    local name = ns.Widget.NameOf(item and item.k)
    local d = name and defs[name]
    if not d or not d.Split then return nil end
    local out = d.Split(item)
    for i, p in ipairs(out) do
        p.wid = name
        p.x = (item.x or 1) + i - 1
        p.y = item.y or 1
    end
    return out
end
function ns.Widget.Merge(items, name)
    local first
    local rest = {}
    for _, it in ipairs(items or {}) do
        if it.wid and (name == nil or it.wid == name) and defs[it.wid] then
            name = it.wid
            if not first or (it.y or 1) < (first.y or 1) or ((it.y or 1) == (first.y or 1) and (it.x or 1) < (first.x or 1)) then
                first = it
            end
        else
            rest[#rest + 1] = it
        end
    end
    if not first then return nil, rest end
    local view = defs[name].view
    local w, h = ns.Widget.Size(name, view)
    return { k = "widget:" .. name, x = first.x or 1, y = first.y or 1, w = w, h = h, view = view }, rest
end
local hosts = {}
local nextId = 0
local spareHosts = {}
local spare = { [""] = {} }
local made = 0
local drag
local DIM = 0.3
local NONE = {}
local TIP_INK = { 1, 1, 1 }
local driverHook
local ev = CreateFrame("Frame")
ev:Hide()
local function over(f)
    if MouseIsOver then return MouseIsOver(f) and true or false end
    return f.IsMouseOver and f:IsMouseOver() and true or false
end
local closeFly
local function skinTag(host)
    local sk = ns.Widget.SkinOf(host.name, host.opt)
    return sk and ("#" .. sk) or ""
end
local function layerOf(host)
    local w, h = ns.Widget.Size(host.name, host.view, host.opt)
    local pw, ph = w * host.cell + (w - 1) * host.gap, h * host.cell + (h - 1) * host.gapY
    return host.fr and host.layers[host.view .. "@" .. pw .. "x" .. ph .. "/" .. host.gap .. "," .. host.gapY .. skinTag(host)]
end
local function flyOpen(host)
    local layer = layerOf(host)
    return layer and layer.fly and layer.fly:IsShown() and true or false
end
local function openFly(host)
    local layer = layerOf(host)
    if not (layer and layer.fly) or host.edit or not host.mouse or InCombatLockdown() then return end
    if layer.fly:IsShown() then return end
    layer.fly:Show()
    for _, b in ipairs(host.fly) do b:Show() end
    layer.fly:SetScript("OnUpdate", function()
        if not (over(host.fr) or over(layer.fly)) then closeFly(host) end
    end)
end
function closeFly(host)
    local layer = layerOf(host)
    if not (layer and layer.fly) then return end
    layer.fly:SetScript("OnUpdate", nil)
    layer.fly:Hide()
    ns.DeferKey("wg.fly." .. host.id, function()
        for _, b in ipairs(host.fly) do b:Hide() end
    end)
end
local function poolOf(c)
    local k = (c and c.wrap) or ""
    spare[k] = spare[k] or {}
    return spare[k]
end
local function acquireButton(host, c)
    local pool = poolOf(c)
    local b = table.remove(pool)
    if not b then
        made = made + 1
        b = CreateFrame("Button", "LazyBuffBarCell" .. made, host.parent, "SecureActionButtonTemplate")
        if c and c.wrap and SecureHandlerWrapScript then
            SecureHandlerWrapScript(b, "OnClick", b, c.wrap.pre, c.wrap.post)
        end
        b:SetScript("PostClick", function(self, button)
            local cell, h = self.cell, self.host
            if cell and cell.post and h then cell.post(self, button, h.st, h.opt) end
        end)
        b:SetScript("OnEnter", function(self)
            local h = self.host
            local d = h and h.def
            if not (d and h.st) then return end
            if d.flyout then openFly(h) end
            if not d.Tip then return end
            local now = not (ns.buffbar and ns.buffbar.IconTipsNow) or ns.buffbar:IconTipsNow()
            if not now and not (d.tipFight and d.tipFight(self.index, h.st, h.view)) then return end
            local title, line, rows = d.Tip(self.index, h.st, h.view, self.isFly, self)
            if not title then return end
            GameTooltip:SetOwner(self, d.flyout and "ANCHOR_RIGHT" or "ANCHOR_TOP")
            GameTooltip:AddLine(title, 1, 0.82, 0)
            if line then GameTooltip:AddLine(line, 1, 1, 1, true) end
            for _, row in ipairs(rows or NONE) do
                local lc = row.lc or TIP_INK
                local rc = row.rc or lc
                if row.r then
                    GameTooltip:AddDoubleLine(row.l, row.r, lc[1], lc[2], lc[3], rc[1], rc[2], rc[3])
                else
                    GameTooltip:AddLine(row.l, lc[1], lc[2], lc[3], true)
                end
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        b:SetScript("OnDragStart", function(self)
            local h = self.host
            if not (self.cell and self.cell.drop and h and not h.edit and IsAltKeyDown() and not InCombatLockdown()) then return end
            drag = self
        end)
        b:SetScript("OnDragStop", function(self)
            local from, h = drag, self.host
            drag = nil
            if from ~= self or not (h and self.cell and self.cell.drop) or InCombatLockdown() then return end
            for i, o in ipairs(h.buttons) do
                if o ~= self and o:IsShown() and over(o) then
                    self.cell.drop(h, self.index, i)
                    return
                end
            end
        end)
    end
    b:SetParent(host.parent)
    b:RegisterForClicks(c and c.clicks or "LeftButtonUp")
    if c and c.drop then b:RegisterForDrag("LeftButton") else b:RegisterForDrag() end
    b.attrs, b.pool, b.cell = {}, pool, c
    b:EnableMouse(true)
    b:Show()
    return b
end
local GATE_ON = "show"
local GATE_OFF = "[combat] show; hide"
local function gate(b, on)
    local m = on and GATE_ON or GATE_OFF
    if b.gate == m then return end
    b.gate = m
    RegisterStateDriver(b, "visibility", m)
end
local function releaseButton(b)
    if b.gate then
        UnregisterStateDriver(b, "visibility")
        b.gate = nil
    end
    for k in pairs(b.attrs or {}) do b:SetAttribute(k, nil) end
    b.attrs, b.host, b.index, b.isFly, b.cell = nil, nil, nil, nil, nil
    b:ClearAllPoints()
    b:Hide()
    local pool = b.pool or spare[""]
    pool[#pool + 1] = b
end
local function cellsOf(host)
    local d = host.def
    if host.demo then return NONE, NONE end
    return d.cells and d.cells(host.view, host.opt) or NONE, d.flyout and d.flyout(host.view) or NONE
end
local function pixels(host)
    local w, h = ns.Widget.Size(host.name, host.view, host.opt)
    return w * host.cell + (w - 1) * host.gap, h * host.cell + (h - 1) * host.gapY
end
local function layerKey(host)
    local w, h = pixels(host)
    return host.view .. "@" .. w .. "x" .. h .. "/" .. host.gap .. "," .. host.gapY .. skinTag(host)
end
local function armList(cells, buttons, host)
    for i, c in ipairs(cells) do
        local b = buttons[i]
        if b and c.attrs then
            local want = c.attrs(host.st, host.opt) or {}
            local changed = false
            for k in pairs(b.attrs) do
                if want[k] == nil then
                    b:SetAttribute(k, nil)
                    b.attrs[k] = nil
                    changed = true
                end
            end
            for k, v in pairs(want) do
                if b.attrs[k] ~= v then
                    b:SetAttribute(k, v)
                    b.attrs[k] = v
                    changed = true
                end
            end
            if c.armed then c.armed(b, host.st, host.opt, changed) end
        end
    end
end
local function arm(host)
    if InCombatLockdown() or not host.st then return end
    local cells, fly = cellsOf(host)
    armList(cells, host.buttons, host)
    armList(fly, host.fly, host)
end
local function staleList(cells, buttons, host)
    for i, c in ipairs(cells) do
        local b = buttons[i]
        if b and c.attrs then
            local want = c.attrs(host.st, host.opt) or {}
            for k, v in pairs(want) do if b.attrs[k] ~= v then return true end end
            for k in pairs(b.attrs) do if want[k] == nil then return true end end
        end
    end
    return false
end
local function stale(host)
    local cells, fly = cellsOf(host)
    return staleList(cells, host.buttons, host) or staleList(fly, host.fly, host)
end
local function gatedOf(host)
    if host.demo or not host.def.active then return false end
    for _, c in ipairs((cellsOf(host))) do
        if c.attrs then return true end
    end
    return false
end
local function setMouse(host)
    local on = host.mouse
    ns.DeferKey("wg.mouse." .. host.id, function()
        for _, b in ipairs(host.buttons) do
            if b.gate then gate(b, on) else b:EnableMouse(on) end
        end
        for _, b in ipairs(host.fly) do b:EnableMouse(on) end
    end)
end
local function driveBy(host, st)
    local d = host.def.driver
    local drv = d and d(st, host.opt) or nil
    if drv == host.drv then return end
    host.drv = drv
    if driverHook and host.live then driverHook(host) end
end
local function tickOf(host)
    local t = host.def.tick
    if type(t) == "function" then return host.st and t(host.st) or nil end
    return t
end
local function paint(host)
    local layer = host.fr and host.layers[layerKey(host)]
    if not layer then return end
    host.st = host.def.State(host.opt)
    if type(host.def.tick) == "function" and tickOf(host) then ev:Show() end
    driveBy(host, host.st)
    layer.panel = host.panel
    layer.buttons = host.buttons
    host.def.Paint(layer, host.st, host.view)
    local on = true
    if host.def.active then on = host.def.active(host.st, host.opt, host.view) and true or false end
    ns.Widget.Alpha(host.fr, on and 1 or (host.edit and DIM or 0))
    if on ~= host.mouse then
        host.mouse = on
        setMouse(host)
        if not on then closeFly(host) end
    end
    if (#host.buttons > 0 or #host.fly > 0) and stale(host) then
        ns.DeferKey("wg.arm." .. host.id, function() arm(host) end)
    end
end
local function placeCell(host, c, b)
    local w, h = pixels(host)
    b:ClearAllPoints()
    if c.cx then
        b:SetPoint("TOPLEFT", host.fr, "TOPLEFT", c.cx * (host.cell + host.gap), -c.cy * (host.cell + host.gapY))
        b:SetWidth(host.cell)
        b:SetHeight(host.cell)
    else
        b:SetPoint("TOPLEFT", host.fr, "TOPLEFT", c.l * w, -c.t * h)
        b:SetWidth((c.r - c.l) * w)
        b:SetHeight((c.b - c.t) * h)
    end
end
local function placeButtons(host)
    for _, b in ipairs(host.buttons) do releaseButton(b) end
    for _, b in ipairs(host.fly) do releaseButton(b) end
    host.buttons, host.fly = {}, {}
    local cells, fly = cellsOf(host)
    local gated = gatedOf(host)
    for i, c in ipairs(cells) do
        local b = acquireButton(host, c)
        b.host, b.index = host, i
        placeCell(host, c, b)
        if host.btnLevel then b:SetFrameLevel(host.btnLevel) end
        if gated then gate(b, host.mouse) else b:EnableMouse(host.mouse) end
        host.buttons[i] = b
    end
    for i, c in ipairs(fly) do
        local b = acquireButton(host, c)
        b.host, b.index, b.isFly = host, i, true
        placeCell(host, c, b)
        b:SetFrameLevel((host.btnLevel or host.fr:GetFrameLevel()) + 3)
        b:EnableMouse(host.mouse)
        b:Hide()
        host.fly[i] = b
    end
end
local function build(host)
    if not host.live then return end
    if not host.fr then
        host.fr = CreateFrame("Frame", nil, host.parent)
        host.layers = {}
    elseif host.fr:GetParent() ~= host.parent then
        host.fr:SetParent(host.parent)
    end
    if host.level then host.fr:SetFrameLevel(host.level) end
    host.fr:Show()
    local w, h = pixels(host)
    host.fr:SetWidth(w)
    host.fr:SetHeight(h)
    local key = layerKey(host)
    local layer = host.layers[key]
    if not layer then
        layer = CreateFrame("Frame", nil, host.fr)
        layer:SetAllPoints(host.fr)
        layer.w, layer.h = w, h
        layer.cell, layer.gap, layer.gapY = host.cell, host.gap, host.gapY
        host.def.Build(layer, host.view, host.opt)
        host.layers[key] = layer
        if layer.fly then layer.fly:Hide() end
    end
    for k, l in pairs(host.layers) do
        if host.level then l:SetFrameLevel(host.level + 1) end
        if l.fly then
            l.fly:SetFrameLevel((host.btnLevel or host.fr:GetFrameLevel()) + 2)
            if k ~= key then l.fly:Hide() end
        end
        if k == key then l:Show() else l:Hide() end
    end
    placeButtons(host)
    paint(host)
    arm(host)
end
local function listen(host)
    for event in pairs(host.def.events or {}) do ev:RegisterEvent(event) end
    if host.def.tick then ev:Show() end
end
local function wake(host, sec)
    host.wake = GetTime() + sec
    ev:Show()
end
ev:SetScript("OnEvent", function(_, event, unit)
    for _, host in ipairs(hosts) do
        local f = host.def.events and host.def.events[event]
        if f == true or (f and f == unit) or (type(f) == "table" and f[unit]) then
            paint(host)
            local d = host.def.delay and host.def.delay[event]
            if d then wake(host, d) end
        end
    end
end)
ev:SetScript("OnUpdate", function(self, elapsed)
    local any = false
    local now = GetTime()
    for _, host in ipairs(hosts) do
        local t = tickOf(host)
        if t then
            any = true
            host.acc = host.acc + (elapsed or 0)
            if host.acc >= t then
                host.acc = 0
                paint(host)
            end
        end
        if host.wake then
            if host.wake <= now then
                host.wake = nil
                paint(host)
            else
                any = true
            end
        end
    end
    if not any then self:Hide() end
end)
function ns.Widget.Poke(name, sec)
    for _, host in ipairs(hosts) do
        if host.name == name then
            if sec then wake(host, sec) else paint(host) end
        end
    end
end
function ns.Widget.Mount(name, parent, view, opt, mount)
    local d = defs[name]
    if not d then return nil end
    opt = opt or {}
    mount = mount or {}
    local host = table.remove(spareHosts[name] or {})
    if not host then
        nextId = nextId + 1
        host = { id = nextId, name = name, def = d, layers = {}, buttons = {}, fly = {} }
    end
    host.parent, host.view, host.opt = parent, ns.Widget.ViewOf(name, view), opt
    host.cell, host.gap = mount.cell or opt.cell or CELL, mount.gap or opt.gap or GAP
    host.gapY = mount.gapY or host.gap
    host.level, host.btnLevel = mount.level, mount.btnLevel
    host.acc, host.live, host.st, host.wake, host.addr, host.panel = 0, true, nil, nil, nil, nil
    host.edit, host.mouse = mount.edit and true or false, true
    host.drv = d.driver and d.driver(d.State(opt), opt) or nil
    hosts[#hosts + 1] = host
    listen(host)
    ns.DeferKey("wg.build." .. host.id, function() build(host) end)
    return host
end
function ns.Widget.Driver(host)
    return host.drv
end
function ns.Widget.OnDriver(fn)
    driverHook = fn
end
function ns.Widget.SetOpt(host, opt)
    local key0, cells0 = layerKey(host), cellsOf(host)
    host.opt = opt or {}
    if host.fr and host.live and (layerKey(host) ~= key0 or cellsOf(host) ~= cells0) then
        closeFly(host)
        ns.DeferKey("wg.build." .. host.id, function() build(host) end)
        return
    end
    if not (host.fr and host.layers[layerKey(host)]) then
        driveBy(host, host.def.State(host.opt))
        return
    end
    paint(host)
end
function ns.Widget.SetView(host, view)
    view = ns.Widget.ViewOf(host.name, view)
    if view == host.view then return end
    closeFly(host)
    host.view = view
    ns.DeferKey("wg.build." .. host.id, function() build(host) end)
end
function ns.Widget.SetEdit(host, edit)
    edit = edit and true or false
    if host.edit == edit then return end
    host.edit = edit
    closeFly(host)
    paint(host)
end
function ns.Widget.OpenFly(host)
    openFly(host)
end
function ns.Widget.CloseFly(host)
    closeFly(host)
end
function ns.Widget.FlyOpen(host)
    return flyOpen(host)
end
function ns.Widget.FlyButtons(host)
    return host.fly
end
function ns.Widget.Refresh(host)
    paint(host)
end
function ns.Widget.Unmount(host)
    if not host.live then return end
    host.live = false
    for i = #hosts, 1, -1 do
        if hosts[i] == host then table.remove(hosts, i) end
    end
    closeFly(host)
    ns.DeferKey("wg.build." .. host.id, function()
        for _, b in ipairs(host.buttons) do releaseButton(b) end
        for _, b in ipairs(host.fly) do releaseButton(b) end
        host.buttons, host.fly = {}, {}
        if host.fr then host.fr:Hide() end
        spareHosts[host.name] = spareHosts[host.name] or {}
        local list = spareHosts[host.name]
        list[#list + 1] = host
    end)
end
function ns.Widget.Frame(host)
    return host.fr
end
function ns.Widget.Layer(host)
    return host.fr and host.layers[layerKey(host)]
end
function ns.Widget.Hosts()
    local out = {}
    for i, h in ipairs(hosts) do out[i] = h end
    return out
end
function ns.Widget.Buttons(host)
    return host.buttons
end
function ns.Widget.State(host)
    return host.st
end
function ns.Widget.Text(fs, s)
    s = s or ""
    if fs.lbbText == s then return end
    fs.lbbText = s
    fs:SetText(s)
end
function ns.Widget.Color(r, c)
    if r.lbbColor == c then return end
    r.lbbColor = c
    if r.SetTextColor and r:GetObjectType() == "FontString" then
        r:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    else
        r:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
    end
end
function ns.Widget.Alpha(r, a)
    if r.lbbAlpha == a then return end
    r.lbbAlpha = a
    r:SetAlpha(a)
end
function ns.Widget.Tex(t, path, desat)
    if t.lbbTex ~= path then
        t.lbbTex = path
        t:SetTexture(path)
        t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    desat = desat and true or false
    if t.lbbDesat ~= desat then
        t.lbbDesat = desat
        t:SetDesaturated(desat)
    end
end
function ns.Widget.Left(sec)
    if not sec or sec <= 0 then return "" end
    if sec >= 60 then return ns.T("time.minutes", math.floor(sec / 60 + 0.5)) end
    return ns.T("time.seconds", math.floor(sec + 0.5))
end
local spareDemos = {}
local function hideTexts(fr)
    for _, r in ipairs({ fr:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "FontString" then r:Hide() end
    end
    for _, c in ipairs({ fr:GetChildren() }) do hideTexts(c) end
end
local function demoPaint(host, scene)
    local info = host.def.info
    if not (info and info.demo) then return end
    local w, h = pixels(host)
    host.fr:SetWidth(w)
    host.fr:SetHeight(h)
    local key = layerKey(host)
    local layer = host.layers[key]
    if not layer then
        layer = CreateFrame("Frame", nil, host.fr)
        layer:SetAllPoints(host.fr)
        layer.w, layer.h = w, h
        layer.cell, layer.gap, layer.gapY = host.cell, host.gap, host.gapY
        host.def.Build(layer, host.view, host.opt)
        host.layers[key] = layer
        if layer.fly then layer.fly:Hide() end
    end
    for k, l in pairs(host.layers) do
        if k == key then l:Show() else l:Hide() end
    end
    host.st = info.demo(scene)
    host.def.Paint(layer, host.st, host.view)
    local on = true
    if host.def.active then on = host.def.active(host.st, host.opt, host.view) and true or false end
    ns.Widget.Alpha(host.fr, on and 1 or DIM)
end
function ns.Widget.Demo(name, scene, parent, mount)
    local d = defs[name]
    if not (d and d.info and d.info.demo) then return nil end
    mount = mount or {}
    local host = table.remove(spareDemos[name] or {})
    if not host then
        nextId = nextId + 1
        host = { id = nextId, name = name, def = d, layers = {}, buttons = {}, fly = {}, demo = true }
        host.fr = CreateFrame("Frame", nil, parent)
    elseif host.fr:GetParent() ~= parent then
        host.fr:SetParent(parent)
    end
    host.parent, host.view, host.opt = parent, ns.Widget.ViewOf(name, scene.view), scene.opt or {}
    host.cell, host.gap = mount.cell or CELL, mount.gap or GAP
    host.gapY = mount.gapY or host.gap
    host.bare = mount.bare and true or nil
    host.live, host.edit, host.mouse = true, false, false
    host.fr:Show()
    demoPaint(host, scene)
    if host.bare then hideTexts(host.fr) end
    return host
end
function ns.Widget.DemoPaint(host, scene)
    if not (host and host.demo and host.live) then return end
    host.view, host.opt = ns.Widget.ViewOf(host.name, scene.view), scene.opt or {}
    demoPaint(host, scene)
    if host.bare then hideTexts(host.fr) end
end
function ns.Widget.DemoDrop(host)
    if not (host and host.demo and host.live) then return end
    host.live = false
    host.fr:Hide()
    spareDemos[host.name] = spareDemos[host.name] or {}
    local list = spareDemos[host.name]
    list[#list + 1] = host
end
ns.widgetLoaded = true
