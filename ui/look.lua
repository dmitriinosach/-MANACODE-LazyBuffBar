local _, ns = ...
ns.Look = {}
ns.Look.BAR = {
    alpha = { def = 1,    min = 0.1, max = 1,  step = 0.1,  pct = true },
    idle  = { def = 1,    min = 0,   max = 1,  step = 0.1,  pct = true },
    fight = { def = 1,    min = 0,   max = 1,  step = 0.1,  pct = true },
    plate = { def = 0,    min = 0,   max = 1,  step = 0.05, pct = true },
    pad   = { def = 1,    min = 0,   max = 16, step = 1 },
    gap   = { def = 4,    min = 0,   max = 16, step = 1 },
    round = { def = 0,    min = 0,   max = 8,  step = 1 },
    plateRound = { def = 0, min = 0, max = 16, step = 1 },
    absent = { def = 0.7, min = 0.1, max = 1, step = 0.05, pct = true, look = true },
}
ns.Look.BAR_ORDER = { "alpha", "idle", "fight", "plate", "pad", "gap", "round", "plateRound", "absent" }
ns.Look.ALL = {
    edge   = { def = "square", list = { "square", "thin", "round", "soft" } },
    plate  = { def = "flat",   list = { "none", "flat", "soft", "round" } },
    absent = { def = 0.7,      list = { 1, 0.7, 0.4, 0.2 } },
    sweep  = { def = 1,        list = { 1, 0.7, 0.5, 0.3 } },
    digits = { def = "own",    list = { "own", "omnicc" } },
    font   = { def = "normal", list = { "small", "normal", "large" } },
    stack  = { def = "normal", list = { "small", "normal", "large" } },
    tint   = { def = true },
    snap   = { def = true },
    fx     = { def = "full",   list = { "full", "plain", "off" } },
    novice = { def = false },
}
local function db()
    LazyBuffBarDB = LazyBuffBarDB or {}
    return LazyBuffBarDB
end
local function clamp(v, k)
    if k.step then v = math.floor(v / k.step + 0.5) * k.step end
    if k.min and v < k.min then v = k.min end
    if k.max and v > k.max then v = k.max end
    return v
end
local function blockAt(i)
    return ns.Preset and ns.Preset.Blocks and ns.Preset.Blocks()[i] or nil
end
function ns.Look.General(key)
    local k = ns.Look.BAR[key]
    if k.look then
        local v = ns.Look.Get(key)
        if type(v) ~= "number" then return k.def end
        return v
    end
    local g = db().bar
    local v = g and g[key]
    if type(v) ~= "number" then return k.def end
    return v
end
function ns.Look.SetGeneral(key, v)
    local k = ns.Look.BAR[key]
    if not k then return 0 end
    v = clamp(tonumber(v) or k.def, k)
    if k.look then
        ns.Look.Set(key, v)
        return v
    end
    local d = db()
    d.bar = d.bar or {}
    local own = v
    if math.abs(v - k.def) < 0.001 then own = nil end
    d.bar[key] = own
    if not next(d.bar) then d.bar = nil end
    ns.Look.Changed()
    return v
end
function ns.Look.Bar(i, key)
    local b = blockAt(i)
    local v = b and b[key]
    if type(v) ~= "number" then return ns.Look.General(key) end
    return v
end
function ns.Look.Own(i, key)
    local b = blockAt(i)
    local v = b and b[key]
    if type(v) ~= "number" then return false end
    return math.abs(v - ns.Look.General(key)) > 0.001
end
function ns.Look.SetBar(i, key, v)
    local k = ns.Look.BAR[key]
    local b = blockAt(i)
    if not (k and b) then return k and k.def or 0 end
    v = clamp(tonumber(v) or k.def, k)
    local own = v
    if math.abs(v - ns.Look.General(key)) < 0.001 then own = nil end
    ns.Preset.SetBlock(b.key, key, own)
    ns.Look.Changed()
    return v
end
function ns.Look.ClearBar(i, key)
    local b = blockAt(i)
    if not (b and ns.Look.BAR[key]) then return end
    if b[key] ~= nil then ns.Preset.SetBlock(b.key, key, nil) end
    ns.Look.Changed()
end
function ns.Look.ResetBar(i)
    local b = blockAt(i)
    if not b then return end
    for key in pairs(ns.Look.BAR) do
        if b[key] ~= nil then ns.Preset.SetBlock(b.key, key, nil) end
    end
    if b.digits ~= nil then ns.Preset.SetBlock(b.key, "digits", nil) end
    if b.style ~= nil then ns.Preset.SetBlock(b.key, "style", nil) end
    ns.Look.Changed()
end
function ns.Look.Absent(f)
    local v = f and f._absent
    if type(v) == "number" then return v end
    return ns.Look.General("absent")
end
function ns.Look.Get(key)
    local k = ns.Look.ALL[key]
    local look = db().look
    local v = look and look[key]
    if v == nil then return k.def end
    return v
end
local FONT_SCALE = { small = 0.85, normal = 1, large = 1.2 }
function ns.Look.FontScale(role)
    return FONT_SCALE[ns.Look.Get(role == "stack" and "stack" or "font")] or 1
end
function ns.Look.Set(key, v)
    local k = ns.Look.ALL[key]
    if not k then return end
    local d = db()
    d.look = d.look or {}
    if v == k.def then d.look[key] = nil else d.look[key] = v end
    if not next(d.look) then d.look = nil end
    ns.Look.Changed()
end
function ns.Look.Format(key, v)
    local k = ns.Look.BAR[key]
    if k and k.pct then return ("%d%%"):format(math.floor(v * 100 + 0.5)) end
    return tostring(v)
end
function ns.Look.Changed()
    if ns.PanelCard and ns.PanelCard.Refresh then ns.PanelCard.Refresh() end
    if not ns.buffbar then return end
    if ns.buffbar.ApplyTheme then ns.buffbar:ApplyTheme() end
    if ns.buffbar.Update then ns.buffbar:Update() end
end
local ROUND = {
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8,
}
local THIN = {
    edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
}
local SOFT = {
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8,
}
local SOFT_COLOR = { 0.75, 0.75, 0.75, 0.9 }
local function edgeOf(f)
    if ns.Style and ns.Style.Of then return ns.Style.Of(f, "edge") end
    return ns.Look.Get("edge")
end
function ns.Look.Crop(f)
    local style = edgeOf(f)
    local spec = ns.Style and ns.Style.EdgeSpec(style)
    local r = tonumber(f._round) or 0
    local c
    if r > 0 then
        c = 0.07 + r * 0.01
    elseif spec then
        c = spec.crop
    elseif style == "round" then
        c = 0.1
    elseif style == "soft" then
        c = 0.08
    else
        c = 0.07
    end
    f.tex:SetTexCoord(c, 1 - c, c, 1 - c)
end
function ns.Look.StyleIcon(f)
    local style = edgeOf(f)
    local spec = ns.Style and ns.Style.EdgeSpec(style)
    local r = tonumber(f._round) or 0
    local key = (spec and ns.Style.EdgeKey(f, style) or style) .. ":" .. r
    if f._edge == key then return end
    f._edge = key
    local e = f.edge
    if ns.Style then ns.Style.PaintEdge(f, (r == 0 and spec) and style or nil) end
    if r > 0 then
        local out = math.ceil(r / 2)
        e:ClearAllPoints()
        e:SetPoint("TOPLEFT", f, "TOPLEFT", -out, out)
        e:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", out, -out)
        e:SetBackdrop({ edgeFile = ROUND.edgeFile, edgeSize = 6 + r * 2 })
        e:SetBackdropBorderColor(0, 0, 0, 1)
        e:Show()
    elseif spec then
        ns.Look.Crop(f)
        return
    elseif style == "soft" then
        e:ClearAllPoints()
        e:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
        e:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
        e:SetBackdrop(SOFT)
        e:SetBackdropBorderColor(SOFT_COLOR[1], SOFT_COLOR[2], SOFT_COLOR[3], SOFT_COLOR[4])
        e:Show()
    elseif style == "round" then
        e:ClearAllPoints()
        e:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
        e:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
        e:SetBackdrop(ROUND)
        e:SetBackdropBorderColor(0, 0, 0, 1)
        e:Show()
    elseif style == "thin" then
        e:ClearAllPoints()
        e:SetAllPoints(f)
        e:SetBackdrop(THIN)
        e:SetBackdropBorderColor(0, 0, 0, 1)
        e:Show()
    else
        e:SetBackdrop(nil)
        e:Hide()
    end
    if ns.Style then
        local base = (r > 0 or style == "thin" or style == "round") and ns.Style.COLORS.black
            or (style == "soft" and SOFT_COLOR) or nil
        e._rgb, e._ec = base, base
        ns.Style.EdgeTint(f)
    end
    ns.Look.Crop(f)
end
function ns.Look.AttachEdge(f)
    f.edge = CreateFrame("Frame", nil, f)
    f.edge:SetFrameLevel(f:GetFrameLevel() + 4)
    f.edge:Hide()
    ns.Look.StyleIcon(f)
end
local PLATE_EDGE = {
    flat  = nil,
    soft  = { file = "Interface\\Tooltips\\UI-Tooltip-Border", size = 10, inset = 2 },
    round = { file = "Interface\\Tooltips\\UI-Tooltip-Border", size = 16, inset = 4 },
}
function ns.Look.PlateEdge(plate, round)
    local e = PLATE_EDGE[ns.Look.Get("plate")]
    local r = tonumber(round) or 0
    if r > 0 then e = { file = ROUND.edgeFile, size = 8 + r, inset = math.floor((8 + r) / 3) } end
    local ins = plate.insets
    if e then
        plate.edgeFile, plate.edgeSize = e.file, e.size
        ins.left, ins.right, ins.top, ins.bottom = e.inset, e.inset, e.inset, e.inset
        return true
    end
    plate.edgeFile, plate.edgeSize = nil, nil
    ins.left, ins.right, ins.top, ins.bottom = 0, 0, 0, 0
    return false
end
ns.lookLoaded = true
