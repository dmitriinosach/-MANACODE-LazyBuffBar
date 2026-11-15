local _, ns = ...
ns.Reorder = {}
local R = ns.Reorder
local THRESHOLD = 4
local NEAR = 24
local GHOST_ALPHA = 0.85
local SOURCE_ALPHA = 0.4
local BACK = 0.18
local UNDO_SECS = 10
local UNDO_GAP = 4
local MAX_CELLS = 128
local MARK_EDGE = 2
local SWAP_TEX = "Interface\\Buttons\\UI-RotationRight-Button-Up"
local SWAP_SZ = 20
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CROP = { 0.07, 0.93, 0.07, 0.93 }
local C_FIT = { 0.3, 1, 0.3 }
local C_BLOCK = { 1, 0.25, 0.25 }
local NEW_ALPHA = 0.6
local driver, ghost, mark, undoBtn
local drag
local back
local undo
local said = false
local function ui()
    return UIParent:GetEffectiveScale()
end
local function cursor()
    local x, y = GetCursorPosition()
    local u = ui()
    return x / u, y / u
end
local function screen()
    return { l = 0, b = 0, r = UIParent:GetWidth(), t = UIParent:GetHeight() }
end
local function blockGeo(key)
    local fr = ns.Blocks.Frame(key)
    if not fr then return nil end
    local geo, rect = ns.Blocks.Geo(key), ns.Blocks.Rect(key)
    if not (geo and rect) then return nil end
    return fr, geo, rect, fr:GetEffectiveScale() / ui()
end
local function cellsPx(geo, w, h)
    return w * geo.icon + (w - 1) * geo.gap, h * geo.icon + (h - 1) * (geo.gap + 2)
end
local function cellsRect(key, x, y, w, h)
    local fr, geo, rect, k = blockGeo(key)
    if not fr then return nil end
    local px, py = ns.Grid.CellXY(geo, x, y)
    local cw, ch = ns.Grid.Span(geo, x, y, w, h)
    local l, t = rect.l + px * k, rect.t - py * k
    return { l = l, t = t, r = l + cw * k, b = t - ch * k }
end
local function defaultGeo()
    local b = ns.Preset.Blocks()[1]
    if b then
        local fr, geo, _, k = blockGeo(b.key)
        if fr then return geo, k end
    end
    local pad = ns.Look and ns.Look.BAR.pad.def or 1
    local gap = ns.Look and ns.Look.BAR.gap.def or 4
    return ns.Grid.Geo(pad, gap), 1
end
local function fromBlock(key, x, y)
    if not (key and x and y) then return nil end
    local b = ns.Blocks.Block(key)
    local it = b and ns.Grid.ItemAt(b, x, y)
    if not it then return nil end
    local fr, geo, rect, k = blockGeo(key)
    if not fr then return nil end
    local w, h = ns.Grid.Size(it)
    local texes = {}
    local wname = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(it.k)
    for j = 0, h - 1 do
        for i = 0, w - 1 do
            local f = ns.buffbar:IconAt(key, it.x + i, it.y + j)
            texes[#texes + 1] = (f and f.tex and f.tex:GetTexture()) or false
        end
    end
    if wname then
        local d = ns.Widget.Get(wname)
        local icon = d and type(d.icon) == "number" and (select(3, GetSpellInfo(d.icon))) or (d and d.icon) or false
        for i = 1, w * h do texes[i] = icon end
    end
    local px, py = ns.Grid.CellXY(geo, it.x, it.y)
    local l, t = rect.l + px * k, rect.t - py * k
    local cx, cy = cursor()
    return { from = "block", key = key, x = it.x, y = it.y, item = it, w = w, h = h, texes = texes, geo = geo, scale = k,
             home = { l = l, t = t }, blockRect = rect, dcx = x - it.x, dcy = y - it.y, ox = cx - l, oy = t - cy }
end
local function fromPicker(hit, row)
    if not (hit and ns.Catalog and ns.Catalog.Item) then return nil end
    local where = ns.Catalog.Where(hit)
    if where and where.placed then
        ns.say(ns.T("picker.msg.already", hit.name))
        return nil
    end
    local item = ns.Catalog.Item(hit)
    if not item then return nil end
    local w, h = hit.w or 1, hit.h or 1
    if w > 1 then item.w = w end
    if h > 1 then item.h = h end
    local geo, k = defaultGeo()
    local dcx, dcy = math.floor((w - 1) / 2), math.floor((h - 1) / 2)
    local texes = {}
    for i = 1, w * h do texes[i] = hit.icon or ns.QMARK end
    local home
    if row and row.GetLeft and row:GetLeft() then
        local q = row:GetEffectiveScale() / ui()
        home = { l = row:GetLeft() * q, t = row:GetTop() * q }
    end
    return { from = "picker", hit = hit, item = item, w = w, h = h, texes = texes, geo = geo, scale = k, home = home,
             dcx = dcx, dcy = dcy, ox = (dcx * geo.dx + geo.icon / 2) * k, oy = (dcy * geo.dy + geo.icon / 2) * k }
end
local function fromLibrary(e, row)
    if not (e and e.block and ns.Library) then return nil end
    local b = e.block
    local w, h = math.max(1, b.cols or 1), math.max(1, b.rows or 1)
    local pad = b.pad or (ns.Look and ns.Look.BAR.pad.def) or 1
    local gap = b.gap or (ns.Look and ns.Look.BAR.gap.def) or 4
    local geo = ns.Grid.Geo(pad, gap)
    local k = b.scale or (ns.buffbar and ns.buffbar:GetScale()) or 1
    local texes = {}
    for i = 1, w * h do texes[i] = false end
    for _, ic in ipairs(ns.Library.Icons(b)) do
        for j = 0, ic.h - 1 do
            for i = 0, ic.w - 1 do
                local x, y = ic.x + i, ic.y + j
                if x <= w and y <= h then texes[(y - 1) * w + x] = ic.tex or ns.QMARK end
            end
        end
    end
    local dcx, dcy = math.floor((w - 1) / 2), math.floor((h - 1) / 2)
    local home
    if row and row.GetLeft and row:GetLeft() then
        local q = row:GetEffectiveScale() / ui()
        home = { l = row:GetLeft() * q, t = row:GetTop() * q }
    end
    return { from = "library", entry = e, w = w, h = h, texes = texes, geo = geo, scale = k, home = home,
             dcx = dcx, dcy = dcy, ox = (dcx * geo.dx + geo.icon / 2) * k, oy = (dcy * geo.dy + geo.icon / 2) * k }
end
local function makeGhost()
    local g = CreateFrame("Frame", nil, UIParent)
    ns.Layer(g, "drag")
    g:SetFrameLevel(ns.LAYER.drag.level + 2)
    g:SetAlpha(GHOST_ALPHA)
    g.cells = {}
    g:Hide()
    return g
end
local function ghostCell(g, n)
    local t = g.cells[n]
    if not t then
        t = g:CreateTexture(nil, "ARTWORK")
        g.cells[n] = t
    end
    return t
end
local function makeMark()
    local m = CreateFrame("Frame", nil, UIParent)
    ns.Layer(m, "drag")
    m:SetFrameLevel(ns.LAYER.drag.level + 1)
    m:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = MARK_EDGE })
    m:SetBackdropColor(1, 1, 1, 0.06)
    m.swap = m:CreateTexture(nil, "OVERLAY")
    m.swap:SetTexture(SWAP_TEX)
    m.swap:SetWidth(SWAP_SZ)
    m.swap:SetHeight(SWAP_SZ)
    m.swap:SetPoint("CENTER", m, "CENTER", 0, 0)
    m.label = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    m.label:SetPoint("TOP", m, "BOTTOM", 0, -2)
    m.label:SetText(ns.T("reorder.new_panel"))
    m:Hide()
    return m
end
local function hideUndo()
    undo = nil
    if undoBtn then undoBtn:Hide() end
end
local function undoNow(u)
    if InCombatLockdown() then
        if ns.say then ns.say(ns.T("bar.combat")) end
        return false
    end
    hideUndo()
    local s = u.src
    if s.from == "picker" then
        ns.Preset.Remove(u.key, 1, 1, true)
        return true
    end
    if s.from == "library" then
        ns.Preset.TakeBlock(u.key, true)
        return true
    end
    if ns.Preset.Block(s.key) and ns.Preset.Move(u.key, 1, 1, s.key, s.x, s.y) then return true end
    local rect = s.blockRect and { l = s.blockRect.l, t = s.blockRect.t } or nil
    ns.Preset.NewBlock(nil, rect, { key = u.key, x = 1, y = 1 })
    return true
end
local function undoStale(u)
    if GetTime() - u.at > UNDO_SECS then return true end
    if ns.Preset.Edits() ~= u.edits or ns.Preset.Id() ~= u.id then return true end
    return ns.buffbar and ns.buffbar.IsLocked and ns.buffbar:IsLocked() and true or false
end
local function undoTick(b)
    local u = undo
    if not u then b:Hide(); return end
    local fr = ns.Blocks.Frame(u.key)
    if not fr or undoStale(u) then hideUndo(); return end
    if b.anchor ~= fr then
        b.anchor = fr
        b:ClearAllPoints()
        b:SetPoint("TOPRIGHT", fr, "TOPLEFT", -UNDO_GAP, 0)
    end
end
local function makeUndo()
    local b = ns.MakeButton(UIParent)
    ns.Layer(b, "undo")
    b:SetLabel(ns.T("reorder.undo"))
    b.tipTitle = ns.T("reorder.undo_tip")
    b.onClick = function()
        if undo then undoNow(undo) end
    end
    b:SetScript("OnUpdate", undoTick)
    b:Hide()
    return b
end
local function showUndo(key, s)
    undo = { key = key, src = s, at = GetTime(), edits = ns.Preset.Edits(), id = ns.Preset.Id() }
    undoBtn.anchor = nil
    undoTick(undoBtn)
    if undo then undoBtn:Show() end
end
local function restoreAlpha(d)
    for _, e in ipairs(d.dim) do
        local f = e.f
        if f._key == e.key and f._cx == e.x and f._cy == e.y and not f._anim then f:SetAlpha(e.a) end
    end
end
local function dimSource(d)
    local s = d.src
    if s.from ~= "block" then return end
    if #d.dim == 0 then
        for j = 0, s.h - 1 do
            for i = 0, s.w - 1 do
                local f = ns.buffbar:IconAt(s.key, s.x + i, s.y + j)
                if f then d.dim[#d.dim + 1] = { f = f, a = f:GetAlpha(), key = s.key, x = s.x + i, y = s.y + j } end
            end
        end
    end
    for _, e in ipairs(d.dim) do
        local f = e.f
        if f._key == e.key and f._cx == e.x and f._cy == e.y and f:GetAlpha() > SOURCE_ALPHA then f:SetAlpha(SOURCE_ALPHA) end
    end
end
local function arm(d)
    local s = d.src
    d.armed = true
    local geo, k = s.geo, s.scale
    local cw, ch = cellsPx(geo, s.w, s.h)
    ghost:SetWidth(cw * k)
    ghost:SetHeight(ch * k)
    local n = 0
    for j = 0, s.h - 1 do
        for i = 0, s.w - 1 do
            n = n + 1
            if n > MAX_CELLS then break end
            local t = ghostCell(ghost, n)
            local tex = s.texes[n]
            if tex or s.from ~= "library" then
                t:SetTexture(tex or ns.QMARK)
                t:SetTexCoord(CROP[1], CROP[2], CROP[3], CROP[4])
                t:ClearAllPoints()
                t:SetPoint("TOPLEFT", ghost, "TOPLEFT", i * geo.dx * k, -j * geo.dy * k)
                t:SetWidth(geo.icon * k)
                t:SetHeight(geo.icon * k)
                t:Show()
            else
                t:Hide()
            end
        end
    end
    for i = n + 1, #ghost.cells do ghost.cells[i]:Hide() end
    ghost:Show()
    dimSource(d)
end
local function placeGhost(l, t)
    ghost:ClearAllPoints()
    ghost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
    ghost.l, ghost.t = l, t
end
local function sameTarget(a, b)
    if a == nil or b == nil then return a == b end
    if a.kind ~= b.kind or a.key ~= b.key or a.x ~= b.x or a.y ~= b.y then return false end
    if a.kind ~= "new" then return true end
    return math.abs(a.rect.l - b.rect.l) < 0.5 and math.abs(a.rect.t - b.rect.t) < 0.5
end
local function paintMark(t)
    if not t or t.kind == "same" or not t.rect then mark:Hide(); return end
    local r = t.rect
    mark:ClearAllPoints()
    mark:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", r.l, r.t)
    mark:SetWidth(math.max(1, r.r - r.l))
    mark:SetHeight(math.max(1, r.t - r.b))
    local c, a = C_FIT, 1
    if t.kind == "blocked" then
        c = C_BLOCK
    elseif t.kind == "new" then
        c, a = { ns.Edge() }, NEW_ALPHA
    elseif t.kind == "grow" then
        c = ns.EDIT.gold
    end
    mark:SetBackdropBorderColor(c[1], c[2], c[3], a)
    mark:SetBackdropColor(c[1], c[2], c[3], t.kind == "blocked" and 0.1 or 0.06)
    if t.kind == "swap" then mark.swap:Show() else mark.swap:Hide() end
    if t.kind == "new" then mark.label:Show() else mark.label:Hide() end
    mark:Show()
end
local PROBE_KIND = { same = "same", fits = "cell", grow = "grow", swap = "swap", blocked = "blocked" }
local function classify(key, tx, ty)
    local s = drag.src
    local kind
    if s.from == "block" then
        kind = ns.Preset.Probe(s.key, s.x, s.y, key, tx, ty)
    else
        kind = ns.Preset.ProbeAdd(key, tx, ty, s.w, s.h)
    end
    kind = PROBE_KIND[kind] or "blocked"
    return { kind = kind, key = key, x = tx, y = ty, rect = cellsRect(key, tx, ty, s.w, s.h) }
end
local function nearAny(cx, cy, rects)
    for _, r in ipairs(rects) do
        if cx >= r.l - NEAR and cx <= r.r + NEAR and cy >= r.b - NEAR and cy <= r.t + NEAR then return true end
    end
    return false
end
local function aimAt(cx, cy)
    local s = drag.src
    local key, x, y = ns.Blocks.Under()
    if key then
        if x and y and s.from ~= "library" then return classify(key, x - s.dcx, y - s.dcy) end
        return { kind = "blocked", key = key, rect = ns.Blocks.Rect(key) }
    end
    if s.alt then return nil end
    local rects = ns.Blocks.Rects()
    if nearAny(cx, cy, rects) then return nil end
    local gl, gt = cx - drag.ox, cy + drag.oy
    local pw, ph = ns.Grid.Pixels(s.geo, s.w, s.h)
    local pad = s.geo.pad * s.scale
    local want = { l = gl - pad, t = gt + pad, r = gl - pad + pw * s.scale, b = gt + pad - ph * s.scale }
    return { kind = "new", rect = ns.Grid.FreeSpot(want, rects, screen()) }
end
local function snapshot()
    local out = {}
    local u = ui()
    for _, b in ipairs(ns.Preset.Blocks()) do
        for _, it in ipairs(b.items or {}) do
            local w, h = ns.Grid.Size(it)
            for j = 0, h - 1 do
                for i = 0, w - 1 do
                    local f = ns.buffbar:IconAt(b.key, it.x + i, it.y + j)
                    local l = f and f:GetLeft()
                    if l then
                        local q = f:GetEffectiveScale() / u
                        out[b.key .. ":" .. (it.x + i) .. "," .. (it.y + j)] = { l = l * q, t = f:GetTop() * q }
                    end
                end
            end
        end
    end
    return out
end
local function slideFrom(f, l, t)
    local nl, nt = f:GetLeft(), f:GetTop()
    if not nl then return end
    local q = f:GetEffectiveScale() / ui()
    ns.buffbar.StartSlide(f, (l - nl * q) / q, (nt * q - t) / q, false)
end
local function slideAll(s, dest, gl, gt, old, swapped)
    local seen = {}
    for j = 0, s.h - 1 do
        for i = 0, s.w - 1 do
            local f = ns.buffbar:IconAt(dest.key, dest.x + i, dest.y + j)
            if f and not seen[f] then
                seen[f] = true
                slideFrom(f, gl + i * s.geo.dx * s.scale, gt - j * s.geo.dy * s.scale)
            end
        end
    end
    if not swapped then return end
    local b = ns.Preset.Block(s.key)
    local o = b and ns.Grid.ItemAt(b, s.x, s.y)
    if not o or o == s.item then return end
    local ow, oh = ns.Grid.Size(o)
    for j = 0, oh - 1 do
        for i = 0, ow - 1 do
            local f = ns.buffbar:IconAt(s.key, o.x + i, o.y + j)
            local from = old[dest.key .. ":" .. (dest.x + i) .. "," .. (dest.y + j)]
            if f and from and not seen[f] then
                seen[f] = true
                slideFrom(f, from.l, from.t)
            end
        end
    end
end
local function markPicker(s)
    if s.list and s.list.MarkDone then
        s.list.MarkDone(s.hit)
        return
    end
    local P = ns.Picker
    if not (P and P.State) then return end
    P.State().done[s.hit.key] = true
    if P.IsShown() then P.Refresh(true) end
end
local function finish(d)
    drag = nil
    driver:EnableKeyboard(false)
    mark:Hide()
    ghost:Hide()
    restoreAlpha(d)
    if not back then driver:Hide() end
end
function R.Cancel()
    local d = drag
    if not d then return false end
    local home = d.src.home
    if not d.armed or not home or not ghost.l or ns.FX.Level() == "off" then
        finish(d)
        return true
    end
    drag = nil
    driver:EnableKeyboard(false)
    mark:Hide()
    back = { d = d, t = 0, fl = ghost.l, ft = ghost.t, tl = home.l, tt = home.t }
    return true
end
local function stepBack(elapsed)
    local b = back
    b.t = b.t + elapsed
    local k = math.min(1, b.t / BACK)
    placeGhost(b.fl + (b.tl - b.fl) * k, b.ft + (b.tt - b.ft) * k)
    if k < 1 then return end
    back = nil
    ghost:Hide()
    restoreAlpha(b.d)
    if not drag then driver:Hide() end
end
local function drop(d)
    local t = d.target
    local s = d.src
    if not t or t.kind == "blocked" or t.kind == "same" or InCombatLockdown() then
        R.Cancel()
        return
    end
    local old = snapshot()
    local gl, gt = ghost.l, ghost.t
    local ok, newKey
    if t.kind == "new" then
        local rect = { l = t.rect.l, t = t.rect.t }
        if s.from == "block" then
            newKey = ns.Preset.NewBlock(nil, rect, { key = s.key, x = s.x, y = s.y })
        elseif s.from == "library" then
            newKey = ns.Library.Put(s.entry.id, rect)
        else
            newKey = ns.Preset.NewBlock(s.item, rect)
        end
        ok = newKey and true or false
    elseif s.from == "block" then
        ok = ns.Preset.Move(s.key, s.x, s.y, t.key, t.x, t.y) and true or false
    else
        ok = ns.Preset.Add(t.key, s.item, t.x, t.y) ~= nil
    end
    if not ok then
        R.Cancel()
        return
    end
    finish(d)
    local dest = newKey and { key = newKey, x = 1, y = 1 } or { key = t.key, x = t.x, y = t.y }
    slideAll(s, dest, gl, gt, old, t.kind == "swap")
    if newKey then showUndo(newKey, s) end
    if s.from == "picker" then
        ns.Catalog.NotePut(s.hit)
        markPicker(s)
    end
end
local function tick(_, elapsed)
    if back then stepBack(elapsed) end
    local d = drag
    if not d then
        if not back then driver:Hide() end
        return
    end
    if InCombatLockdown() or IsMouseButtonDown("RightButton") then
        R.Cancel()
        return
    end
    local cx, cy = cursor()
    if not d.armed then
        local u = ui()
        if math.abs(cx - d.sx) * u < THRESHOLD and math.abs(cy - d.sy) * u < THRESHOLD then
            if not IsMouseButtonDown("LeftButton") then finish(d) end
            return
        end
        arm(d)
    else
        dimSource(d)
    end
    placeGhost(cx - d.ox, cy + d.oy)
    local t = aimAt(cx, cy)
    if not sameTarget(t, d.target) then
        d.target = t
        paintMark(t)
    end
    if not IsMouseButtonDown("LeftButton") then drop(d) end
end
local function build()
    if driver then return end
    driver = CreateFrame("Frame", "LazyBuffBarReorder", UIParent)
    ns.Layer(driver, "drag")
    driver:SetScript("OnUpdate", tick)
    driver:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then R.Cancel() end
    end)
    driver:RegisterEvent("PLAYER_REGEN_DISABLED")
    driver:RegisterEvent("PLAYER_REGEN_ENABLED")
    driver:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if drag then R.Cancel() end
            if back then stepBack(BACK) end
        else
            said = false
        end
    end)
    driver:Hide()
    ghost = makeGhost()
    mark = makeMark()
    undoBtn = makeUndo()
end
function R.Grab(src, row)
    if drag then return true end
    local s
    if src.from == "picker" then
        s = fromPicker(src.hit, row)
        if s then s.list = src.list end
    elseif src.from == "library" then
        s = fromLibrary(src.entry, row)
    else
        if IsAltKeyDown() and not src.alt then return false end
        s = fromBlock(src.key, src.x, src.y)
        if s then s.alt = src.alt end
    end
    if not s then return false end
    if InCombatLockdown() then
        if not said then
            said = true
            ns.say(ns.T("bar.combat"))
        end
        return true
    end
    build()
    GameTooltip:Hide()
    if ns.EntryCard and ns.EntryCard.Close then ns.EntryCard.Close() end
    local cx, cy = cursor()
    if back then stepBack(BACK) end
    drag = { src = s, sx = cx, sy = cy, ox = s.ox, oy = s.oy, armed = false, target = nil, dim = {} }
    driver:EnableKeyboard(true)
    driver:Show()
    return true
end
function R.Active()
    return drag ~= nil
end
function R.State()
    return drag, undo, driver and { ghost = ghost, mark = mark, undo = undoBtn, driver = driver } or nil
end
function R.Undo()
    if not undo then return false end
    return undoNow(undo)
end
ns.Blocks.OnGrab(function(key, x, y, alt)
    return R.Grab({ key = key, x = x, y = y, alt = alt })
end)
if ns.Picker then
    ns.Picker.OnDragStart = function(hit, row, list)
        R.Grab({ hit = hit, from = "picker", list = list }, row)
    end
end
ns.reorderLoaded = true
