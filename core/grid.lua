local _, ns = ...
ns.Grid = {}
local G = ns.Grid
G.ICON = 32
G.MAX_COLS = 16
G.MAX_ROWS = 8
function G.Size(it)
    return it.w or 1, it.h or 1
end
function G.Occupy(block)
    local out = {}
    local cols = block.cols
    for _, it in ipairs(block.items or {}) do
        local w, h = G.Size(it)
        for y = it.y, it.y + h - 1 do
            for x = it.x, it.x + w - 1 do out[(y - 1) * cols + x] = it end
        end
    end
    return out
end
function G.ItemAt(block, x, y)
    for _, it in ipairs(block.items or {}) do
        local w, h = G.Size(it)
        if x >= it.x and x < it.x + w and y >= it.y and y < it.y + h then return it end
    end
    return nil
end
function G.Fits(block, x, y, w, h, skip, skip2)
    w, h = w or 1, h or 1
    if x < 1 or y < 1 or x + w - 1 > block.cols or y + h - 1 > block.rows then return false end
    for _, it in ipairs(block.items or {}) do
        if it ~= skip and it ~= skip2 then
            local iw, ih = G.Size(it)
            if x < it.x + iw and it.x < x + w and y < it.y + ih and it.y < y + h then return false end
        end
    end
    return true
end
function G.Blockers(block, x, y, w, h, skip, skip2)
    w, h = w or 1, h or 1
    local out = x < 1 or y < 1 or x + w - 1 > block.cols or y + h - 1 > block.rows
    local busy = {}
    for _, it in ipairs(block.items or {}) do
        if it ~= skip and it ~= skip2 then
            local iw, ih = G.Size(it)
            for cy = math.max(y, it.y), math.min(y + h - 1, it.y + ih - 1) do
                for cx = math.max(x, it.x), math.min(x + w - 1, it.x + iw - 1) do
                    busy[#busy + 1] = { x = cx, y = cy }
                end
            end
        end
    end
    return out, busy
end
function G.FreeCell(block, w, h)
    w, h = w or 1, h or 1
    for y = 1, block.rows - h + 1 do
        for x = 1, block.cols - w + 1 do
            if G.Fits(block, x, y, w, h) then return x, y end
        end
    end
    return nil
end
function G.MinSize(block)
    local cols, rows = 1, 1
    for _, it in ipairs(block.items or {}) do
        local w, h = G.Size(it)
        if it.x + w - 1 > cols then cols = it.x + w - 1 end
        if it.y + h - 1 > rows then rows = it.y + h - 1 end
    end
    return cols, rows
end
function G.Pack(items, cols)
    local widest = 1
    local total = 0
    for _, it in ipairs(items) do
        local w = G.Size(it)
        total = total + w
        if w > widest then widest = w end
    end
    if not cols or cols < 1 then cols = math.min(total, G.MAX_COLS) end
    if cols < widest then cols = widest end
    local x, y, rows = 1, 1, 1
    for _, it in ipairs(items) do
        local w, h = G.Size(it)
        if x + w - 1 > cols then x, y = 1, rows + 1 end
        it.x, it.y = x, y
        if y + h - 1 > rows then rows = y + h - 1 end
        x = x + w
    end
    if #items == 0 then cols = 1 end
    return cols, rows
end
function G.Geo(pad, gap)
    return { pad = pad, gap = gap, icon = G.ICON, dx = G.ICON + gap, dy = G.ICON + gap + 2 }
end
local function spreadAt(t, i)
    if not t or i <= 1 then return 0 end
    return t[i] or t[#t] or 0
end
function G.CellXY(geo, x, y)
    return geo.pad + (x - 1) * geo.dx + spreadAt(geo.xs, x), geo.pad + (y - 1) * geo.dy + spreadAt(geo.ys, y)
end
local function axisAt(p, pad, step, t)
    local i = math.floor((p - pad) / step) + 1
    if t then
        while i > 1 and p < pad + (i - 1) * step + spreadAt(t, i) do i = i - 1 end
    end
    if i < 1 then i = 1 end
    return i
end
function G.CellAt(geo, px, py)
    return axisAt(px, geo.pad, geo.dx, geo.xs), axisAt(py, geo.pad, geo.dy, geo.ys)
end
function G.Pixels(geo, cols, rows)
    return 2 * geo.pad + cols * geo.icon + (cols - 1) * geo.gap + spreadAt(geo.xs, cols),
           2 * geo.pad + rows * geo.icon + (rows - 1) * (geo.gap + 2) + spreadAt(geo.ys, rows)
end
function G.Span(geo, x, y, w, h)
    w, h = w or 1, h or 1
    local lx, ty = G.CellXY(geo, x, y)
    local rx, by = G.CellXY(geo, x + w - 1, y + h - 1)
    return rx - lx + geo.icon, by - ty + geo.icon
end
function G.Seps(block, classOf)
    local out = {}
    local cols, rows = block.cols, block.rows
    local occ = G.Occupy(block)
    local cls = {}
    for _, it in ipairs(block.items or {}) do cls[it] = classOf(it) or false end
    local function differ(a, b)
        if not (a and b) or a == b then return false end
        local ca, cb = cls[a], cls[b]
        return (ca and cb and ca ~= cb) and true or false
    end
    for y = 1, rows do
        for x = 1, cols do
            local it = occ[(y - 1) * cols + x]
            if it then
                if x < cols and differ(it, occ[(y - 1) * cols + x + 1]) then out[#out + 1] = { x = x, y = y, v = true } end
                if y < rows and differ(it, occ[y * cols + x]) then out[#out + 1] = { x = x, y = y, v = false } end
            end
        end
    end
    return out
end
local function crossed(block, x, y)
    for _, it in ipairs(block.items or {}) do
        local w, h = G.Size(it)
        if x and it.x <= x and it.x + w - 1 > x then return true end
        if y and it.y <= y and it.y + h - 1 > y then return true end
    end
    return false
end
local function spreadAxis(n, wide, add, block, isX)
    if add <= 0 or not next(wide) then return nil end
    local t, acc = { 0 }, 0
    for i = 1, n - 1 do
        if wide[i] and not crossed(block, isX and i or nil, (not isX) and i or nil) then acc = acc + add end
        t[i + 1] = acc
    end
    return acc > 0 and t or nil
end
function G.Spread(geo, block, seps, space)
    local wideX, wideY = {}, {}
    for _, s in ipairs(seps) do
        if s.v then wideX[s.x] = true else wideY[s.y] = true end
    end
    local out = {}
    for k, v in pairs(geo) do out[k] = v end
    out.xs = spreadAxis(block.cols, wideX, math.max(0, space - geo.gap), block, true)
    out.ys = spreadAxis(block.rows, wideY, math.max(0, space - (geo.dy - geo.icon)), block, false)
    return out
end
function G.SepLine(geo, s, inset, thick)
    local px, py = G.CellXY(geo, s.x, s.y)
    local len = geo.icon - 2 * inset
    if s.v then
        local nx = G.CellXY(geo, s.x + 1, s.y)
        local mid = (px + geo.icon + nx) / 2
        return math.floor(mid - thick / 2 + 0.5), py + inset, thick, len
    end
    local _, ny = G.CellXY(geo, s.x, s.y + 1)
    local mid = (py + geo.icon + ny) / 2
    return px + inset, math.floor(mid - thick / 2 + 0.5), len, thick
end
function G.Overlap(a, b)
    return a.l < b.r and b.l < a.r and a.b < b.t and b.b < a.t
end
function G.Shift(r, dx, dy)
    return { l = r.l + dx, t = r.t + dy, r = r.r + dx, b = r.b + dy }
end
local function sameRows(a, b)
    return a.b < b.t and b.b < a.t
end
local function sameCols(a, b)
    return a.l < b.r and b.l < a.r
end
function G.Push(from, to, others)
    local dx, dy = to.l - from.l, to.t - from.t
    local cur = G.Shift(from, 0, 0)
    if dx > 0 then
        for _, o in ipairs(others) do
            if sameRows(cur, o) and o.l >= cur.r and o.l - cur.r < dx then dx = o.l - cur.r end
        end
    elseif dx < 0 then
        for _, o in ipairs(others) do
            if sameRows(cur, o) and o.r <= cur.l and o.r - cur.l > dx then dx = o.r - cur.l end
        end
    end
    cur = G.Shift(cur, dx, 0)
    if dy < 0 then
        for _, o in ipairs(others) do
            if sameCols(cur, o) and o.t <= cur.b and o.t - cur.b > dy then dy = o.t - cur.b end
        end
    elseif dy > 0 then
        for _, o in ipairs(others) do
            if sameCols(cur, o) and o.b >= cur.t and o.b - cur.t < dy then dy = o.b - cur.t end
        end
    end
    return G.Shift(cur, 0, dy)
end
local function clamp(r, bounds)
    if not bounds then return r end
    local dx, dy = 0, 0
    if r.r > bounds.r then dx = bounds.r - r.r end
    if r.l + dx < bounds.l then dx = bounds.l - r.l end
    if r.t > bounds.t then dy = bounds.t - r.t end
    if r.b + dy < bounds.b then dy = bounds.b - r.b end
    return G.Shift(r, dx, dy)
end
local function clear(r, others)
    for _, o in ipairs(others) do
        if G.Overlap(r, o) then return false end
    end
    return true
end
function G.FreeSpot(rect, others, bounds)
    rect = clamp(rect, bounds)
    if clear(rect, others) then return rect end
    local w, h = rect.r - rect.l, rect.t - rect.b
    local best, bestD
    local function try(l, t)
        local c = clamp({ l = l, t = t, r = l + w, b = t - h }, bounds)
        if not clear(c, others) then return end
        local d = math.abs(c.l - rect.l) + math.abs(c.t - rect.t)
        if not best or d < bestD then best, bestD = c, d end
    end
    for _, o in ipairs(others) do
        if G.Overlap(rect, o) then
            try(o.l - w, rect.t)
            try(o.r, rect.t)
            try(rect.l, o.t + h)
            try(rect.l, o.b)
            try(o.l - w, o.t)
            try(o.r, o.t)
            try(o.l, o.t + h)
            try(o.l, o.b)
        end
    end
    return best or rect
end
function G.Room(rect, others, bounds)
    local maxW = bounds and (bounds.r - rect.l) or math.huge
    local maxH = bounds and (rect.t - bounds.b) or math.huge
    local upH = bounds and (bounds.t - rect.b) or math.huge
    for _, o in ipairs(others) do
        if sameRows(rect, o) and o.l >= rect.r and o.l - rect.l < maxW then maxW = o.l - rect.l end
        if sameCols(rect, o) then
            if o.t <= rect.b and rect.t - o.t < maxH then maxH = rect.t - o.t end
            if o.b >= rect.t and o.b - rect.b < upH then upH = o.b - rect.b end
        end
    end
    return maxW, maxH, upH
end
local function fx(point)
    if point:find("LEFT") then return 0 elseif point:find("RIGHT") then return 1 end
    return 0.5
end
local function fy(point)
    if point:find("BOTTOM") then return 0 elseif point:find("TOP") then return 1 end
    return 0.5
end
function G.Anchor(point, w, h, s, uiW, uiH)
    local ax = fx(point[2]) * uiW + (point[3] or 0) * s
    local ay = fy(point[2]) * uiH + (point[4] or 0) * s
    local l = ax - fx(point[1]) * w * s
    local b = ay - fy(point[1]) * h * s
    return { l = l, t = b + h * s, r = l + w * s, b = b }
end
function G.PointFor(rect, s)
    return { "TOPLEFT", "BOTTOMLEFT", rect.l / s, rect.t / s }
end
ns.gridLoaded = true
