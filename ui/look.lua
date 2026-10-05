local _, ns = ...
ns.Look = {}
ns.Look.BAR = {
    alpha = { def = 1,    min = 0.1, max = 1,  step = 0.1,  pct = true },
    idle  = { def = 1,    min = 0,   max = 1,  step = 0.1,  pct = true },
    fight = { def = 1,    min = 0,   max = 1,  step = 0.1,  pct = true },
    plate = { def = 0.35, min = 0,   max = 1,  step = 0.05, pct = true },
    pad   = { def = 6,    min = 0,   max = 16, step = 1 },
    gap   = { def = 4,    min = 0,   max = 16, step = 1 },
}
ns.Look.BAR_ORDER = { "alpha", "idle", "fight", "plate", "pad", "gap" }
ns.Look.ALL = {
    edge   = { def = "square", list = { "square", "thin", "round" } },
    plate  = { def = "flat",   list = { "flat", "soft", "round" } },
    absent = { def = 1,        list = { 1, 0.7, 0.4, 0.2 } },
    digits = { def = "own",    list = { "own", "omnicc" } },
    tint   = { def = true },
    snap   = { def = true },
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
function ns.Look.Bar(i, key)
    local k = ns.Look.BAR[key]
    local bc = db().bars and db().bars[i]
    local v = bc and bc[key]
    if type(v) ~= "number" then return k.def end
    return v
end
function ns.Look.SetBar(i, key, v)
    local k = ns.Look.BAR[key]
    local bc = db().bars and db().bars[i]
    if not (k and bc) then return k and k.def or 0 end
    v = clamp(tonumber(v) or k.def, k)
    if math.abs(v - k.def) < 0.001 then bc[key] = nil else bc[key] = v end
    ns.Look.Changed()
    return v
end
function ns.Look.ResetBar(i)
    local bc = db().bars and db().bars[i]
    if not bc then return end
    for key in pairs(ns.Look.BAR) do bc[key] = nil end
    ns.Look.Changed()
end
function ns.Look.Get(key)
    local k = ns.Look.ALL[key]
    local look = db().look
    local v = look and look[key]
    if v == nil then return k.def end
    return v
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
    if ns.BarMenu and ns.BarMenu.Refresh then ns.BarMenu.Refresh() end
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
function ns.Look.StyleIcon(f)
    local style = ns.Look.Get("edge")
    if f._edge == style then return end
    f._edge = style
    local e = f.edge
    if style == "round" then
        e:ClearAllPoints()
        e:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
        e:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
        e:SetBackdrop(ROUND)
        e:SetBackdropBorderColor(0, 0, 0, 1)
        f.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        e:Show()
    elseif style == "thin" then
        e:ClearAllPoints()
        e:SetAllPoints(f)
        e:SetBackdrop(THIN)
        e:SetBackdropBorderColor(0, 0, 0, 1)
        f.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        e:Show()
    else
        e:SetBackdrop(nil)
        f.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        e:Hide()
    end
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
function ns.Look.PlateEdge(plate)
    local e = PLATE_EDGE[ns.Look.Get("plate")]
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
