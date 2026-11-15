local _, ns = ...
ns.PickerLib = {}
local B = ns.PickerLib
local W = 900
local H = 620
local PAD = 12
local TOP = 40
local GAP = 10
local TREE_W = 196
local PREV_W = 260
local TREE_ROW = 20
local TREE_INDENT = 12
local SEG_H = 22
local TILE_COLS = 3
local TILE_ROWS = 4
local LIST_ROWS = 16
local CARD_GAP = 6
local ICON = 32
local LIST_ICON = 22
local MINI_CELL = 14
local MINI_GAP = 1
local BOX_H = 150
local DEMO_CELL = 40
local DEMO_GAP = 2
local BARE_BELOW = 30
local STATE_ICON = 36
local SEARCH_W = 240
local HEAD_GAP = 2
local FIELD_DROP = 3
local LAYOUT_W = 110
local PAGER_H = 22
local HEAD_H = 20
local SMALL_UI = 0.85
local CLAMP_KEEP = 120
local WHITE = "Interface\\Buttons\\WHITE8X8"
local C_SRC = "|cffc9a85c"
local C_MUTE = "|cff9b9eae"
local C_WARN = "|cffff9933"
local C_NOTE = { 1, 0.6, 0.2 }
local MSG_KEYS = { added = true, on = true, already = true, later = true, grid = true, full = true }
local CD_ROLES = { cd = true, gear = true }
local OPEN_DEFAULT = { my = true, widgets = true }
local state = { q = "", scope = "mine", layout = "list", sec = "my", open = {}, treeOff = 0, page = 1, pages = {},
                all = {}, cards = {}, hidden = 0, views = {}, done = {}, pending = {} }
for k in pairs(OPEN_DEFAULT) do state.open[k] = true end
local win, body, foldBtn, grip
local tree, cardsFr, prev
local field, clearBtn, scopeSeg, layoutSeg, pagerText, prevBtn, nextBtn, allBtn, emptyFs
local treeRows = {}
local tiles = {}
local rows = {}
local heads = {}
local tileW, tileH, rowH, cardsH = 1, 1, 1, 1
local makeHead
local minis = {}
local demo
local visibleTree = {}
local paint
local function ink(fs, c)
    fs:SetTextColor(c[1], c[2], c[3])
end
local function root()
    return ns.Profile and ns.Profile.Root and ns.Profile.Root() or nil
end
local function remember(key, v)
    local r = root()
    if r then r[key] = v end
end
local CATALOG_REV = 2
local function migrate(r)
    if (r.catalogRev or 0) >= CATALOG_REV then return end
    if r.catalogFilter == nil and r.catalogScope ~= nil then
        r.catalogFilter = (r.catalogScope == "all") and "all" or "mine"
    end
    r.catalogScope = nil
    r.catalogLayout = "list"
    r.catalogRev = CATALOG_REV
end
local function widgetName(hit)
    if hit.role ~= "widget" then return nil end
    local name = ns.Widget and ns.Widget.NameOf and ns.Widget.NameOf(hit.ref)
    if name and ns.Widget.Get(name) then return name end
    return nil
end
local function soon(hit)
    if hit.warn == "grid" then return true end
    return ns.Catalog.Item(hit) == nil
end
local function isPending(hit)
    return ns.DeferHas(ns.Catalog.DeferKey(hit))
end
local function secLabel(key)
    local s = state.sections and state.sections.byKey[key]
    if s and s.boss then return ns.Encounter.Name(s.boss) end
    if s and s.raid then return ns.Encounter.RaidName(s.raid) end
    if key == "widgets.mine" then
        local name = UnitClass("player")
        if name then return name end
    end
    return ns.T("picker.lib.sec." .. key:gsub("%.", "_"))
end
local function applyView(hit)
    local v = state.views[hit.key]
    local name = v and widgetName(hit)
    if not name then return end
    hit.view = v
    hit.w, hit.h = ns.Widget.Size(name, v)
end
local function pages()
    return math.max(1, #state.pages)
end
local function grouped()
    if state.q ~= "" or not state.sections then return nil end
    local s = state.sections.byKey[state.sec]
    if s and s.groups and #s.groups > 0 then return s end
    return nil
end
local function folded(g)
    return g.fold == true and not state.open[g.key]
end
local function sequence()
    local out = {}
    local s = grouped()
    if not s then
        for _, h in ipairs(state.cards) do out[#out + 1] = { hit = h } end
        return out
    end
    for _, g in ipairs(s.groups) do
        if g.n > 0 then
            out[#out + 1] = { head = g }
            if not folded(g) then
                for _, h in ipairs(g.hits) do out[#out + 1] = { hit = h } end
            end
        end
    end
    return out
end
local function paginate()
    local list = state.layout == "list"
    local cols = list and 1 or TILE_COLS
    local ch = list and rowH or tileH
    local gap = list and 0 or CARD_GAP
    local hh = list and rowH or HEAD_H
    local room = list and (LIST_ROWS * rowH) or cardsH
    local cap = list and LIST_ROWS or TILE_COLS * TILE_ROWS
    local out, page = {}, {}
    local y, col, n, head = 0, 0, 0, nil
    local function newPage()
        out[#out + 1] = page
        page, y, col, n = {}, 0, 0, 0
    end
    for _, e in ipairs(sequence()) do
        if e.head then
            if col > 0 then y, col = y + ch + gap, 0 end
            local need = hh + ((folded(e.head) or e.head.n == 0) and 0 or ch)
            if #page > 0 and (y + need > room) then newPage() end
            page[#page + 1] = { head = e.head, x = 0, y = y }
            y, head = y + hh, e.head
        else
            if col == 0 and ((y + ch > room) or n >= cap) then
                newPage()
                if head then
                    page[#page + 1] = { head = head, more = true, x = 0, y = 0 }
                    y = hh
                end
            end
            page[#page + 1] = { hit = e.hit, x = list and 0 or col * (tileW + gap), y = y }
            n = n + 1
            col = col + 1
            if col >= cols then y, col = y + ch + gap, 0 end
        end
    end
    if #page > 0 or #out == 0 then out[#out + 1] = page end
    return out
end
local function firstOn(p)
    for _, slot in ipairs(state.pages[p] or {}) do
        if slot.hit then return slot.hit end
    end
    return nil
end
local function selected()
    for _, h in ipairs(state.cards) do
        if h.key == state.selKey then return h end
    end
    return nil
end
local function flatten(res)
    local out = {}
    for _, g in ipairs(res.groups) do
        for _, h in ipairs(g.rows) do out[#out + 1] = h end
    end
    return out
end
local function pickCards()
    if state.q ~= "" then
        local found = flatten(ns.Catalog.Search(state.q, nil, { scope = "all", flat = true }))
        local cards, hidden = {}, 0
        for _, h in ipairs(found) do
            if ns.Catalog.PassScope(h.level, state.scope) then cards[#cards + 1] = h else hidden = hidden + 1 end
        end
        state.cards, state.hidden = cards, hidden
    else
        local s = state.sections and (state.sections.byKey[state.sec] or state.sections.byKey.my)
        state.cards, state.hidden = s and s.hits or {}, 0
        if s and s.groups and #s.groups > 0 then
            local cards = {}
            for _, g in ipairs(s.groups) do
                for _, h in ipairs(g.hits) do cards[#cards + 1] = h end
            end
            state.cards = cards
        end
    end
    for _, h in ipairs(state.cards) do applyView(h) end
    state.pages = paginate()
    if state.page > pages() then state.page = pages() end
    if state.page < 1 then state.page = 1 end
    if not selected() then
        local first = firstOn(state.page)
        state.selKey = first and first.key or nil
    end
end
local function reload(full)
    if full or not state.sections then
        if full or #state.all == 0 then
            state.all = flatten(ns.Catalog.Search("", nil, { scope = "all", flat = true }))
        end
        state.sections = ns.Catalog.Sections(state.all, { scope = state.scope, raids = ns.Encounter.Raids() })
    end
    pickCards()
end
local function treeList()
    local out = {}
    if not state.sections then return out end
    for _, s in ipairs(state.sections.list) do
        local p, shown = s.parent, true
        while p do
            if not state.open[p] then shown = false; break end
            p = state.sections.byKey[p].parent
        end
        if shown then out[#out + 1] = s end
    end
    return out
end
local function fillTreeRow(r, s)
    local e = ns.EDIT
    r.sec = s
    local mark = ""
    if #s.kids > 0 then mark = state.open[s.key] and "- " or "+ " end
    r.text:SetText(mark .. secLabel(s.key))
    r.text:SetPoint("LEFT", r, "LEFT", 4 + s.depth * TREE_INDENT, 0)
    local active = state.q == "" and state.sec == s.key
    local dim = s.n == 0
    if s.n > 0 then
        r.count:SetText(tostring(s.n))
    elseif s.all > 0 then
        r.count:SetText(ns.T("picker.lib.only_all", s.all))
    else
        r.count:SetText("0")
    end
    ink(r.text, active and e.gold or (dim and e.mute or e.text))
    ink(r.count, dim and e.mute or e.gold2)
    r.tip = (dim and s.all > 0 and not s.anyScope) and ns.T("picker.lib.dim_tip") or nil
    if active then r.sel:Show() else r.sel:Hide() end
end
local function paintTree()
    visibleTree = treeList()
    local n = #treeRows
    local most = math.max(0, #visibleTree - n)
    if state.treeOff > most then state.treeOff = most end
    if state.treeOff < 0 then state.treeOff = 0 end
    for i = 1, n do
        local s = visibleTree[state.treeOff + i]
        local r = treeRows[i]
        if s then
            fillTreeRow(r, s)
            r:Show()
        else
            r.sec = nil
            r:Hide()
        end
    end
end
local function dropMinis()
    for i = #minis, 1, -1 do
        ns.Widget.DemoDrop(minis[i])
        minis[i] = nil
    end
end
local function sceneOf(name, view)
    local _, class = UnitClass("player")
    return { size = "raid", fight = false, t = 0, opt = {}, view = view, class = class or "WARRIOR" }
end
local function hasDemo(hit)
    local name = widgetName(hit)
    local d = name and ns.Widget.Get(name)
    return d ~= nil and d.info ~= nil and d.info.demo ~= nil
end
local function fillCard(c, hit, tile)
    c.hit = hit
    c.icon:SetTexture(hit.icon or ns.QMARK)
    c.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    c.icon:SetAlpha(hit.warn and 0.55 or 1)
    c.icon:Show()
    local sub = hit.roleText
    if hit.src then sub = sub .. ", " .. C_SRC .. hit.src .. "|r" end
    local notes = {}
    if hit.role == "widget" then notes[#notes + 1] = ns.T("picker.lib.size", hit.w or 1, hit.h or 1) end
    if soon(hit) then
        notes[#notes + 1] = ns.T("picker.soon")
    elseif isPending(hit) then
        notes[#notes + 1] = C_WARN .. ns.T("picker.later") .. "|r"
    end
    if state.q ~= "" and state.sections then
        local at = ns.Catalog.SectionOf(state.sections, hit)
        if at then notes[#notes + 1] = ns.T("picker.lib.search_in", secLabel(at)) end
    end
    local note = table.concat(notes, ", ")
    if tile then
        c.name:SetText(hit.name)
        c.sub:SetText(sub)
        c.note:SetText(note ~= "" and (C_MUTE .. note .. "|r") or "")
    else
        local text = hit.name .. "  " .. C_MUTE .. sub .. "|r"
        if note ~= "" then text = text .. "  " .. C_MUTE .. note .. "|r" end
        c.name:SetText(text)
    end
    if hit.warn then
        c.warn.warnText = ns.T("catalog.warn." .. hit.warn)
        c.warn:Show()
    else
        c.warn.warnText = nil
        c.warn:Hide()
    end
    if not soon(hit) and (state.done[hit.key] or hit.onBlock) then c.check:Show() else c.check:Hide() end
    if hit.key == state.selKey then c.sel:Show() else c.sel:Hide() end
    if tile and hasDemo(hit) then
        local name = widgetName(hit)
        local host = ns.Widget.Demo(name, sceneOf(name, hit.view), c, { cell = MINI_CELL, gap = MINI_GAP, bare = true })
        if host then
            local fr = ns.Widget.Frame(host)
            fr:ClearAllPoints()
            fr:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 6, 6)
            minis[#minis + 1] = host
        end
    end
end
local function fillHead(r, slot)
    local g = slot.head
    r.sec = g
    local mark = g.fold and (folded(g) and "+ " or "- ") or ""
    r.text:SetText(mark .. secLabel(g.key))
    r.count:SetText(tostring(g.n))
    ink(r.text, ns.EDIT.gold)
    ink(r.count, ns.EDIT.mute)
    r.tip = g.fold and ns.T(folded(g) and "picker.lib.unfold_tip" or "picker.lib.fold_tip") or nil
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", cardsFr, "TOPLEFT", 0, -slot.y)
    r:SetPoint("TOPRIGHT", cardsFr, "TOPRIGHT", 0, -slot.y)
    r:SetHeight(state.layout == "list" and rowH or HEAD_H)
    r:Show()
end
local function paintCards()
    dropMinis()
    local tile = state.layout ~= "list"
    local page = state.pages[state.page] or {}
    local ti, ri, hi = 0, 0, 0
    for _, slot in ipairs(page) do
        if slot.head then
            hi = hi + 1
            heads[hi] = heads[hi] or makeHead()
            fillHead(heads[hi], slot)
        elseif tile then
            ti = ti + 1
            local c = tiles[ti]
            if c then
                c:ClearAllPoints()
                c:SetPoint("TOPLEFT", cardsFr, "TOPLEFT", slot.x, -slot.y)
                fillCard(c, slot.hit, true)
                c:Show()
            end
        else
            ri = ri + 1
            local c = rows[ri]
            if c then
                c:ClearAllPoints()
                c:SetPoint("TOPLEFT", cardsFr, "TOPLEFT", 0, -slot.y)
                fillCard(c, slot.hit, false)
                c:Show()
            end
        end
    end
    for i = ti + 1, #tiles do tiles[i].hit = nil; tiles[i]:Hide() end
    for i = ri + 1, #rows do rows[i].hit = nil; rows[i]:Hide() end
    for i = hi + 1, #heads do heads[i].sec = nil; heads[i]:Hide() end
    pagerText:SetText(ns.T("picker.lib.page", state.page, pages()))
    if state.page > 1 then prevBtn:Enable() else prevBtn:Disable() end
    if state.page < pages() then nextBtn:Enable() else nextBtn:Disable() end
    if state.hidden > 0 and state.scope ~= "all" then
        allBtn:SetLabel(ns.T("picker.lib.in_all", state.hidden))
        allBtn:Show()
    else
        allBtn:Hide()
    end
    if #state.cards == 0 then
        local s = state.q == "" and state.sections and state.sections.byKey[state.sec]
        if s and s.all > 0 and state.scope ~= "all" then
            emptyFs:SetText(ns.T("picker.lib.empty_all", s.all))
        else
            emptyFs:SetText(ns.T(state.q ~= "" and "picker.empty" or "picker.lib.empty"))
        end
        emptyFs:Show()
    else
        emptyFs:Hide()
    end
end
local function statesOf(hit)
    if hit.role == "cd" and hit.id and ns.Catalog.UpId(hit.id) then return { "ready", "up", "cd" } end
    if CD_ROLES[hit.role] then return { "ready", "cd" } end
    if ns.Catalog.Perm(hit) then return { "on", "none" } end
    return { "ok", "none", "soon" }
end
local LOOK = {
    ok    = { edge = "ok", text = 300 },
    none  = { edge = "none", desat = true, alpha = 0.5 },
    soon  = { edge = "soon", text = 3 },
    ready = { edge = "ok" },
    on    = { edge = "ok" },
    up    = { edge = "ok", text = 6 },
    cd    = { edge = "off", desat = true, shade = true, text = 20 },
}
local function paintStates(hit)
    local list = statesOf(hit)
    local n = #list
    local step = STATE_ICON + 24
    local x0 = math.floor((PREV_W - 2 * PAD - (n * step - 24)) / 2)
    local fx = hit.row and ns.Facts and ns.Facts.Of and ns.Facts.Of(hit.row) or {}
    local real = { ok = fx.dur, up = fx.dur, cd = fx.cd }
    for i, b in ipairs(prev.states) do
        local key = list[i]
        if key then
            local look = LOOK[key]
            local c = ns.STATE[look.edge] or ns.STATE.ok
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", prev.box, "TOPLEFT", x0 + (i - 1) * step, -40)
            b.icon:SetTexture(hit.icon or ns.QMARK)
            b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            b.icon:SetDesaturated(look.desat and true or false)
            b.icon:SetAlpha(look.alpha or 1)
            b:SetBackdropBorderColor(c[1], c[2], c[3], 1)
            if look.shade then b.shade:Show() else b.shade:Hide() end
            local text = look.text and (real[key] or look.text)
            b.value:SetText(text and ns.Widget.Left(text) or "")
            b.cap:SetText(ns.T("picker.lib.st." .. key))
            b:Show()
        else
            b:Hide()
        end
    end
end
local function paintDemo(hit)
    if demo then
        ns.Widget.DemoDrop(demo)
        demo = nil
    end
    local name = widgetName(hit)
    if not (name and hasDemo(hit)) then return false end
    local w = math.max(1, hit.w or 1)
    local h = math.max(1, hit.h or 1)
    local room = PREV_W - 2 * PAD - 12
    local cell = math.min(DEMO_CELL, math.floor((room - (w - 1) * DEMO_GAP) / w),
        math.floor((BOX_H - 12 - (h - 1) * DEMO_GAP) / h))
    demo = ns.Widget.Demo(name, sceneOf(name, hit.view), prev.box, { cell = cell, gap = DEMO_GAP, bare = cell < BARE_BELOW })
    if not demo then return false end
    local fr = ns.Widget.Frame(demo)
    fr:ClearAllPoints()
    fr:SetPoint("CENTER", prev.box, "CENTER", 0, 0)
    return true
end
local function paintViews(hit)
    local name = widgetName(hit)
    local views = name and ns.Widget.Views(name) or {}
    if #views < 2 then
        prev.view:Hide()
        return
    end
    local opts = {}
    for i, v in ipairs(views) do
        local key = "widget." .. name .. "_" .. v
        opts[i] = { key = v, label = ns.L[key] and ns.T(key) or v }
    end
    prev.view.hit = hit
    prev.view:SetOptions(opts)
    prev.view:SetValue(ns.Widget.ViewOf(name, hit.view))
    prev.view:Show()
end
local function details(hit)
    local lines = {}
    if hit.level and hit.level ~= "boss" then
        if ns.Catalog.PassScope(hit.level, "mine") then
            lines[#lines + 1] = ns.T("picker.lib.yours")
        else
            local why = (hit.level == "char") and ((hit.row and hit.row.srcKind == "S") and "set" or "branch") or "all"
            lines[#lines + 1] = ns.T("picker.lib.not_yours", ns.T("picker.lib.why." .. why))
        end
    end
    if hit.warn then lines[#lines + 1] = C_WARN .. ns.T("catalog.warn." .. hit.warn) .. "|r" end
    if hit.twins then lines[#lines + 1] = ns.T("picker.lib.twins", table.concat(hit.twins, ", ")) end
    if soon(hit) then
        lines[#lines + 1] = ns.T("picker.nogrid")
    else
        local wh = ns.Catalog.Where(hit, state.target)
        if wh then lines[#lines + 1] = ns.T(wh.placed and "picker.placed" or "picker.lands", wh.barName or "?") end
    end
    if hit.boss then lines[#lines + 1] = ns.T("picker.boss_tip") end
    if isPending(hit) then lines[#lines + 1] = C_WARN .. ns.T("picker.lib.after_tip") .. "|r" end
    return table.concat(lines, "\n")
end
local function coverOf(hit)
    if hit.role == "widget" then return nil end
    local other
    for _, w in ipairs(state.all) do
        if w.role == "widget" and w.covers and w.covers[hit.ref] then
            if ns.Catalog.WidgetSec(w) ~= "widgets.other" then return w end
            other = other or w
        end
    end
    return other
end
local function paintPreview()
    local hit = selected()
    prev.hit = hit
    if not hit then
        prev.widget:Hide()
        if demo then ns.Widget.DemoDrop(demo); demo = nil end
        for _, b in ipairs(prev.states) do b:Hide() end
        prev.view:Hide()
        prev.empty:SetText(ns.T("picker.lib.pick"))
        prev.empty:Show()
        prev.name:SetText("")
        prev.sub:SetText("")
        prev.text:SetText("")
        prev.add:Hide()
        prev.info:Hide()
        prev.drag:Hide()
        return
    end
    prev.empty:Hide()
    if hit.role == "widget" then
        for _, b in ipairs(prev.states) do b:Hide() end
        if not paintDemo(hit) then
            prev.empty:SetText(ns.T("picker.lib.no_demo"))
            prev.empty:Show()
        end
    else
        if demo then ns.Widget.DemoDrop(demo); demo = nil end
        paintStates(hit)
    end
    paintViews(hit)
    prev.name:SetText(hit.name)
    local sub = hit.roleText
    if hit.src then sub = sub .. ", " .. C_SRC .. hit.src .. "|r" end
    if hit.role == "widget" then sub = sub .. ", " .. ns.T("picker.lib.size", hit.w or 1, hit.h or 1) end
    prev.sub:SetText(sub)
    prev.text:SetText(details(hit))
    local cover = coverOf(hit)
    prev.widget.hit = cover
    if cover then
        prev.widget.text:SetText(ns.T("picker.lib.has_widget", cover.name))
        prev.widget.tip = ns.T("picker.lib.has_widget_tip")
        prev.widget:Show()
    else
        prev.widget:Hide()
    end
    local later = soon(hit)
    if later then
        prev.add:Hide()
        prev.drag:Hide()
    else
        local fight = InCombatLockdown()
        prev.add:SetLabel(ns.T(fight and "picker.lib.after" or "picker.lib.to_bar"))
        prev.add:SetWidth(prev.add:GetWidth() + (fight and 0 or 14))
        if fight then prev.arrow:Hide() else prev.arrow:Show() end
        prev.add.tip = ns.T(fight and "picker.lib.after_tip" or "picker.lib.to_bar_tip")
        prev.add:Show()
        prev.drag:Show()
    end
    local name = widgetName(hit)
    local d = name and ns.Widget.Get(name)
    if d and d.info and ns.WidgetInfo then prev.info:Show() else prev.info:Hide() end
end
paint = function()
    if not win then return end
    paintTree()
    paintCards()
    paintPreview()
    scopeSeg:SetValue(state.scope)
    layoutSeg:SetValue(state.layout)
    if state.q == "" then clearBtn:Hide() else clearBtn:Show() end
end
local function after(hit, ok, why)
    if why == "later" then state.pending[hit.key] = hit end
    if ok or why == "already" then state.done[hit.key] = true end
    if MSG_KEYS[why] and ns.say then ns.say(ns.T("picker.msg." .. why, hit.name)) end
    if win and win:IsShown() then
        reload(true)
        paint()
    end
end
function B.Add(hit, key)
    if not hit then return false, "none" end
    local target = key or state.target
    local cell = state.cell
    local cx, cy
    if cell and target == state.target then cx, cy = cell.x, cell.y end
    local ok, why = ns.Catalog.Place(hit, target, cx, cy)
    if ok or why == "later" then state.cell = nil end
    after(hit, ok, why)
    return ok, why
end
function B.NewPanel(hit)
    if not hit then return false, "none" end
    local ok, why, key
    if InCombatLockdown() then
        ns.DeferKey(ns.Catalog.DeferKey(hit), function() B.NewPanel(hit) end)
        ok, why = false, "later"
    else
        local wh = ns.Catalog.Where(hit)
        local item = ns.Catalog.Item(hit)
        if wh and wh.placed then
            ok, why = false, "already"
        elseif not item then
            ok, why = false, "grid"
        else
            key = ns.Preset.NewBlock(item, nil)
            ok = key and true or false
            why = ok and "added" or "full"
            if ok then ns.Catalog.NotePut(hit) end
        end
    end
    after(hit, ok, why)
    return ok, why, key
end
function B.Menu(hit, anchor)
    if not hit or soon(hit) then return end
    if InCombatLockdown() then
        B.Add(hit)
        return
    end
    local wh = ns.Catalog.Where(hit, state.target)
    local items = { { text = ns.T("picker.lib.menu"), isTitle = true } }
    for i, b in ipairs(ns.Preset.Blocks()) do
        local key = b.key
        items[#items + 1] = { text = ns.Preset.BlockName(b, i), checked = wh ~= nil and wh.block == key,
                              func = function() B.Add(hit, key) end }
    end
    items[#items + 1] = { text = ns.T("picker.lib.new_panel"), tip = ns.T("picker.lib.new_tip"),
                          func = function() B.NewPanel(hit) end }
    ns.MakeMenu(items, anchor)
end
function B.SetSection(key)
    local s = state.sections and state.sections.byKey[key]
    if not s then return end
    if #s.kids > 0 and state.sec == key and state.q == "" then
        state.open[key] = not state.open[key]
    elseif #s.kids > 0 then
        state.open[key] = true
    end
    state.sec, state.page, state.selKey = key, 1, nil
    if state.q ~= "" then
        state.q = ""
        if field then field:SetText("") end
    end
    if s.n == 0 and s.all > 0 and not s.anyScope and state.scope ~= "all" then
        B.SetScope("all")
        return
    end
    pickCards()
    paint()
end
function B.SetScope(scope)
    if scope ~= "all" then scope = "mine" end
    state.scope = scope
    remember("catalogFilter", scope)
    state.page, state.selKey = 1, nil
    state.sections = nil
    reload(false)
    paint()
end
function B.SetLayout(layout)
    if layout ~= "list" then layout = "tile" end
    local first = firstOn(state.page)
    state.layout = layout
    remember("catalogLayout", layout)
    state.pages = paginate()
    state.page = 1
    for p = 1, #state.pages do
        for _, slot in ipairs(state.pages[p]) do
            if first and slot.hit == first then state.page = p; break end
        end
        if state.page ~= 1 then break end
    end
    pickCards()
    paint()
end
function B.ToggleGroup(key)
    state.open[key] = not state.open[key]
    pickCards()
    paint()
end
function B.SetQuery(text)
    state.q = text or ""
    state.page, state.selKey = 1, nil
    pickCards()
    paint()
end
function B.Page(delta)
    local p = math.max(1, math.min(pages(), state.page + delta))
    if p == state.page then return end
    state.page = p
    paint()
end
function B.Select(hit)
    state.selKey = hit and hit.key or nil
    paint()
end
function B.SetView(view)
    local hit = selected()
    local name = hit and widgetName(hit)
    if not name then return end
    state.views[hit.key] = view
    applyView(hit)
    paint()
end
function B.MarkDone(hit)
    state.done[hit.key] = true
    if win and win:IsShown() then
        reload(true)
        paint()
    end
end
local function warnEnter(tip)
    if not tip.warnText then return end
    GameTooltip:SetOwner(tip, "ANCHOR_RIGHT")
    GameTooltip:SetText(tip.warnText, C_NOTE[1], C_NOTE[2], C_NOTE[3], 1, true)
    GameTooltip:Show()
end
local function cardScripts(c)
    c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    c:RegisterForDrag("LeftButton")
    c:SetScript("OnClick", function(self, button)
        if not self.hit then return end
        B.Select(self.hit)
        if button == "RightButton" then B.Menu(self.hit, nil) end
    end)
    c:SetScript("OnDoubleClick", function(self)
        if self.hit and not soon(self.hit) then B.Add(self.hit) end
    end)
    c:SetScript("OnDragStart", function(self)
        local P = ns.Picker
        if self.hit and P and P.OnDragStart then P.OnDragStart(self.hit, self, B) end
    end)
end
local function cardBadges(c)
    c.warn = CreateFrame("Button", nil, c)
    c.warn:SetWidth(14)
    c.warn:SetHeight(18)
    c.warn.text = c.warn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    c.warn.text:SetPoint("CENTER", c.warn, "CENTER", 0, 0)
    c.warn.text:SetText("!")
    ink(c.warn.text, C_NOTE)
    c.warn:SetScript("OnEnter", warnEnter)
    c.warn:SetScript("OnLeave", ns.TipHide)
    c.warn:Hide()
    c.check = c:CreateTexture(nil, "OVERLAY")
    c.check:SetWidth(18)
    c.check:SetHeight(18)
    c.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    c.check:Hide()
end
local function cardBack(c)
    c.sel = c:CreateTexture(nil, "BACKGROUND")
    c.sel:SetAllPoints(c)
    c.sel:SetTexture(WHITE)
    c.sel:SetVertexColor(1, 0.82, 0, 0.15)
    c.sel:Hide()
    c.hl = c:CreateTexture(nil, "HIGHLIGHT")
    c.hl:SetAllPoints(c)
    c.hl:SetTexture(WHITE)
    c.hl:SetVertexColor(1, 1, 1, 0.06)
end
local function makeTile(i, tw, th)
    local c = CreateFrame("Button", nil, cardsFr)
    c:SetWidth(tw)
    c:SetHeight(th)
    local col = (i - 1) % TILE_COLS
    local row = math.floor((i - 1) / TILE_COLS)
    c:SetPoint("TOPLEFT", cardsFr, "TOPLEFT", col * (tw + CARD_GAP), -row * (th + CARD_GAP))
    c:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    c:SetBackdropBorderColor(ns.EDIT.line[1], ns.EDIT.line[2], ns.EDIT.line[3], 1)
    cardBack(c)
    c.icon = c:CreateTexture(nil, "ARTWORK")
    c.icon:SetWidth(ICON)
    c.icon:SetHeight(ICON)
    c.icon:SetPoint("TOPLEFT", c, "TOPLEFT", 6, -6)
    cardBadges(c)
    c.warn:SetPoint("TOPRIGHT", c, "TOPRIGHT", -2, -4)
    c.check:SetPoint("TOPRIGHT", c, "TOPRIGHT", -2, -4)
    c.name = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c.name:SetPoint("TOPLEFT", c.icon, "TOPRIGHT", 6, 0)
    c.name:SetWidth(tw - ICON - 34)
    c.name:SetHeight(ICON)
    c.name:SetJustifyH("LEFT")
    c.name:SetJustifyV("TOP")
    c.sub = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c.sub:SetPoint("TOPLEFT", c.icon, "BOTTOMLEFT", 0, -4)
    c.sub:SetWidth(tw - 12)
    c.sub:SetHeight(26)
    c.sub:SetJustifyH("LEFT")
    c.sub:SetJustifyV("TOP")
    ink(c.sub, ns.EDIT.mute)
    c.note = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c.note:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -6, 6)
    c.note:SetJustifyH("RIGHT")
    cardScripts(c)
    c:Hide()
    return c
end
local function makeRow(i, rw, rh)
    local c = CreateFrame("Button", nil, cardsFr)
    c:SetWidth(rw)
    c:SetHeight(rh)
    c:SetPoint("TOPLEFT", cardsFr, "TOPLEFT", 0, -(i - 1) * rh)
    cardBack(c)
    c.icon = c:CreateTexture(nil, "ARTWORK")
    c.icon:SetWidth(LIST_ICON)
    c.icon:SetHeight(LIST_ICON)
    c.icon:SetPoint("LEFT", c, "LEFT", 2, 0)
    cardBadges(c)
    c.check:SetPoint("RIGHT", c, "RIGHT", -2, 0)
    c.warn:SetPoint("RIGHT", c.check, "LEFT", -2, 0)
    c.name = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c.name:SetPoint("LEFT", c.icon, "RIGHT", 6, 0)
    c.name:SetPoint("RIGHT", c.warn, "LEFT", -2, 0)
    c.name:SetHeight(rh)
    c.name:SetJustifyH("LEFT")
    c.name:SetWordWrap(false)
    cardScripts(c)
    c:Hide()
    return c
end
makeHead = function()
    local r = CreateFrame("Button", nil, cardsFr)
    r:SetHeight(HEAD_H)
    r.line = r:CreateTexture(nil, "ARTWORK")
    r.line:SetTexture(WHITE)
    r.line:SetVertexColor(ns.EDIT.line[1], ns.EDIT.line[2], ns.EDIT.line[3], 1)
    r.line:SetHeight(1)
    r.line:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 2)
    r.line:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", 0, 2)
    r.count = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.count:SetPoint("RIGHT", r, "RIGHT", -4, 1)
    r.count:SetJustifyH("RIGHT")
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.text:SetPoint("LEFT", r, "LEFT", 2, 1)
    r.text:SetPoint("RIGHT", r.count, "LEFT", -6, 1)
    r.text:SetJustifyH("LEFT")
    r.text:SetWordWrap(false)
    r:SetScript("OnClick", function(self)
        if self.sec and self.sec.fold then B.ToggleGroup(self.sec.key) end
    end)
    r:SetScript("OnEnter", function(self) if self.tip then ns.TipShow(self) end end)
    r:SetScript("OnLeave", ns.TipHide)
    r:Hide()
    return r
end
local function makeTreeRow(i)
    local r = CreateFrame("Button", nil, tree)
    r:SetHeight(TREE_ROW)
    r:SetPoint("TOPLEFT", tree, "TOPLEFT", 0, -(i - 1) * TREE_ROW)
    r:SetPoint("TOPRIGHT", tree, "TOPRIGHT", 0, -(i - 1) * TREE_ROW)
    r.sel = r:CreateTexture(nil, "BACKGROUND")
    r.sel:SetAllPoints(r)
    r.sel:SetTexture(WHITE)
    r.sel:SetVertexColor(1, 0.82, 0, 0.12)
    r.sel:Hide()
    r.hl = r:CreateTexture(nil, "HIGHLIGHT")
    r.hl:SetAllPoints(r)
    r.hl:SetTexture(WHITE)
    r.hl:SetVertexColor(1, 1, 1, 0.06)
    r.count = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.count:SetPoint("RIGHT", r, "RIGHT", -4, 0)
    r.count:SetJustifyH("RIGHT")
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.text:SetPoint("LEFT", r, "LEFT", 4, 0)
    r.text:SetPoint("RIGHT", r.count, "LEFT", -4, 0)
    r.text:SetJustifyH("LEFT")
    r.text:SetWordWrap(false)
    r:SetScript("OnClick", function(self) if self.sec then B.SetSection(self.sec.key) end end)
    r:SetScript("OnEnter", function(self) if self.tip then ns.TipShow(self) end end)
    r:SetScript("OnLeave", ns.TipHide)
    r:Hide()
    return r
end
local function makeState()
    local b = CreateFrame("Frame", nil, prev.box)
    b:SetWidth(STATE_ICON)
    b:SetHeight(STATE_ICON)
    b:SetBackdrop({ edgeFile = WHITE, edgeSize = 2 })
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    b.shade = b:CreateTexture(nil, "OVERLAY")
    b.shade:SetAllPoints(b.icon)
    b.shade:SetTexture(WHITE)
    b.shade:SetVertexColor(0, 0, 0, 0.55)
    b.value = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.value:SetPoint("BOTTOM", b, "BOTTOM", 0, 3)
    b.cap = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.cap:SetPoint("TOP", b, "BOTTOM", 0, -4)
    ink(b.cap, ns.EDIT.mute)
    b:Hide()
    return b
end
local function buildPreview(x)
    prev = CreateFrame("Frame", nil, body)
    prev:SetPoint("TOPLEFT", win, "TOPLEFT", x, -TOP)
    prev:SetWidth(PREV_W)
    prev:SetHeight(H - TOP - PAD)
    local inner = PREV_W - 2 * PAD
    prev.head = prev:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prev.head:SetPoint("TOPLEFT", prev, "TOPLEFT", PAD, -4)
    prev.head:SetText(ns.T("picker.lib.head"))
    ink(prev.head, ns.EDIT.gold)
    prev.box = CreateFrame("Frame", nil, prev)
    prev.box:SetPoint("TOPLEFT", prev, "TOPLEFT", PAD, -SEG_H)
    prev.box:SetWidth(inner)
    prev.box:SetHeight(BOX_H)
    prev.box:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
                           insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    prev.box:SetBackdropColor(1, 1, 1, 0.04)
    prev.box:SetBackdropBorderColor(ns.EDIT.line[1], ns.EDIT.line[2], ns.EDIT.line[3], 1)
    prev.empty = prev.box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    prev.empty:SetPoint("CENTER", prev.box, "CENTER", 0, 0)
    prev.empty:SetWidth(inner - 16)
    ink(prev.empty, ns.EDIT.mute)
    prev.states = {}
    for i = 1, 3 do prev.states[i] = makeState() end
    prev.view = ns.MakeSegments(prev, {}, { label = ns.T("card.view"), labelW = 30 })
    prev.view:SetPoint("TOPLEFT", prev.box, "BOTTOMLEFT", 0, -6)
    prev.view:SetWidth(inner)
    prev.view.body:SetWidth(inner - 36)
    ink(prev.view.label, ns.EDIT.mute)
    prev.view.onPick = function(k) B.SetView(k) end
    prev.view:Hide()
    prev.name = prev:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    prev.name:SetPoint("TOPLEFT", prev.box, "BOTTOMLEFT", 0, -(SEG_H + 14))
    prev.name:SetWidth(inner)
    prev.name:SetJustifyH("LEFT")
    prev.sub = prev:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    prev.sub:SetPoint("TOPLEFT", prev.name, "BOTTOMLEFT", 0, -3)
    prev.sub:SetWidth(inner)
    prev.sub:SetJustifyH("LEFT")
    ink(prev.sub, ns.EDIT.mute)
    prev.text = prev:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    prev.text:SetPoint("TOPLEFT", prev.sub, "BOTTOMLEFT", 0, -8)
    prev.text:SetWidth(inner)
    prev.text:SetJustifyH("LEFT")
    prev.text:SetJustifyV("TOP")
    prev.widget = CreateFrame("Button", nil, prev)
    prev.widget:SetPoint("TOPLEFT", prev.text, "BOTTOMLEFT", 0, -8)
    prev.widget:SetWidth(inner)
    prev.widget:SetHeight(16)
    prev.widget.text = prev.widget:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    prev.widget.text:SetPoint("LEFT", prev.widget, "LEFT", 0, 0)
    prev.widget.text:SetJustifyH("LEFT")
    ink(prev.widget.text, ns.EDIT.gold)
    prev.widget.line = prev.widget:CreateTexture(nil, "ARTWORK")
    prev.widget.line:SetTexture(WHITE)
    prev.widget.line:SetVertexColor(ns.EDIT.gold[1], ns.EDIT.gold[2], ns.EDIT.gold[3], 0.6)
    prev.widget.line:SetHeight(1)
    prev.widget.line:SetPoint("TOPLEFT", prev.widget.text, "BOTTOMLEFT", 0, -1)
    prev.widget.line:SetPoint("TOPRIGHT", prev.widget.text, "BOTTOMRIGHT", 0, -1)
    prev.widget:SetScript("OnEnter", function(self)
        ink(self.text, ns.EDIT.white)
        ns.TipShow(self)
    end)
    prev.widget:SetScript("OnLeave", function(self)
        ink(self.text, ns.EDIT.gold)
        ns.TipHide()
    end)
    prev.widget:SetScript("OnClick", function(self)
        local w = self.hit
        if w then B.OpenAt(ns.Catalog.WidgetSec(w), w.key, state.target) end
    end)
    prev.widget:Hide()
    prev.drag = prev:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    prev.drag:SetPoint("BOTTOMLEFT", prev, "BOTTOMLEFT", PAD, 4)
    prev.drag:SetWidth(inner)
    prev.drag:SetJustifyH("LEFT")
    prev.drag:SetText(ns.T("picker.lib.drag"))
    ink(prev.drag, ns.EDIT.mute)
    prev.add = ns.MakeButton(prev)
    prev.add:SetHeight(SEG_H)
    prev.add:SetPoint("BOTTOMLEFT", prev.drag, "TOPLEFT", 0, 6)
    prev.add:SetLabel(ns.T("picker.lib.to_bar"))
    prev.add.onClick = function(self)
        if prev.hit then B.Menu(prev.hit, self) end
    end
    prev.arrow = prev.add:CreateTexture(nil, "OVERLAY")
    prev.arrow:SetWidth(12)
    prev.arrow:SetHeight(12)
    prev.arrow:SetPoint("RIGHT", prev.add, "RIGHT", -4, 0)
    prev.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    prev.info = ns.MakeButton(prev)
    prev.info:SetHeight(SEG_H)
    prev.info:SetLabel("i")
    prev.info:SetWidth(SEG_H)
    prev.info:SetPoint("LEFT", prev.add, "RIGHT", 6, 0)
    prev.info.tipTitle = ns.T("picker.lib.info_tip")
    prev.info.onClick = function()
        local hit = prev.hit
        local name = hit and widgetName(hit)
        if name then ns.WidgetInfo.Open(name, { view = hit.view }) end
    end
    prev.info:Hide()
end
local function fold(on)
    state.folded = on and true or false
    if on then body:Hide() else body:Show() end
    if on then grip:Hide() else grip:Show() end
    win:SetHeight(on and TOP or H)
    win:SetClampRectInsets(W - CLAMP_KEEP, -(W - CLAMP_KEEP), 0, (on and TOP or H) - TOP)
    foldBtn.text:SetText(on and "+" or "-")
    foldBtn.tipTitle = ns.T(on and "picker.lib.win_unfold" or "picker.lib.win_fold")
end
local function savePlace()
    local l, t = win:GetLeft(), win:GetTop()
    if not (l and t) then return end
    remember("catalogWinX", l)
    remember("catalogWinY", t)
end
local function fitScale()
    local ui = UIParent:GetEffectiveScale() or 1
    local want = 1
    if ui > 0 and ui < SMALL_UI then want = SMALL_UI / ui end
    local sw, sh = UIParent:GetWidth() or W, UIParent:GetHeight() or H
    local fit = math.min(sw * 0.96 / W, sh * 0.94 / H)
    return math.max(0.5, math.min(want, fit))
end
local function build()
    if win then return end
    win = ns.MakeEditFrame("LazyBuffBarLibrary", "window")
    win:SetWidth(W)
    win:SetHeight(H)
    win.title = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    win.title:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -PAD)
    win.title:SetText(ns.T("picker.lib.title"))
    ink(win.title, ns.EDIT.gold)
    body = CreateFrame("Frame", nil, win)
    body:SetPoint("TOPLEFT", win, "TOPLEFT", 0, -TOP)
    body:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0, 0)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePlace()
    end)
    foldBtn = ns.MakeCloseX(win, "-")
    foldBtn:SetPoint("RIGHT", win.close, "LEFT", -HEAD_GAP, 0)
    foldBtn.onClick = function() B.Fold(not state.folded) end
    grip = ns.AddScaleGrip(win, function() return win:GetScale() end, function(s)
        remember("catalogWinScale", s)
        savePlace()
    end)
    fold(false)
    field = ns.MakeField(win, { ghost = ns.T("picker.lib.ghost"), maxLetters = 255 })
    field:SetWidth(SEARCH_W)
    field:SetPoint("TOPRIGHT", foldBtn, "TOPLEFT", -GAP, -FIELD_DROP)
    local box = field.box
    box:SetScript("OnTextChanged", function(self)
        field:Restyle()
        local text = self:GetText() or ""
        if text ~= state.q then B.SetQuery(text) end
    end)
    box:SetScript("OnEnterPressed", function() B.Add(selected()) end)
    box:SetScript("OnEscapePressed", function(self)
        if (self:GetText() or "") ~= "" then
            field:SetText("")
            B.SetQuery("")
        else
            self:ClearFocus()
            win:Hide()
        end
    end)
    clearBtn = ns.MakeCloseX(field)
    clearBtn:SetPoint("RIGHT", field, "RIGHT", -4, 0)
    clearBtn:SetFrameLevel(field:GetFrameLevel() + 5)
    clearBtn.onClick = function()
        field:SetText("")
        B.SetQuery("")
    end
    clearBtn:Hide()
    tree = CreateFrame("Frame", nil, body)
    tree:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -TOP)
    tree:SetWidth(TREE_W)
    tree:SetHeight(H - TOP - PAD)
    tree:EnableMouseWheel(true)
    tree:SetScript("OnMouseWheel", function(_, delta)
        state.treeOff = state.treeOff - delta * 3
        paintTree()
    end)
    local n = math.floor((H - TOP - PAD) / TREE_ROW)
    for i = 1, n do treeRows[i] = makeTreeRow(i) end
    local line = body:CreateTexture(nil, "ARTWORK")
    line:SetTexture(WHITE)
    line:SetVertexColor(ns.EDIT.line[1], ns.EDIT.line[2], ns.EDIT.line[3], 1)
    line:SetWidth(1)
    line:SetPoint("TOPLEFT", win, "TOPLEFT", PAD + TREE_W + GAP / 2, -TOP)
    line:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", PAD + TREE_W + GAP / 2, PAD)
    local cx = PAD + TREE_W + GAP
    local cw = W - cx - GAP - PREV_W
    local scopes = {}
    for i, s in ipairs(ns.Catalog.FILTERS) do
        scopes[i] = { key = s, label = ns.T("picker.filter." .. s), tip = ns.T("picker.filter_tip." .. s) }
    end
    scopeSeg = ns.MakeSegments(body, scopes)
    scopeSeg:SetHeight(SEG_H)
    scopeSeg:SetWidth(cw - LAYOUT_W - GAP)
    scopeSeg:SetPoint("TOPLEFT", win, "TOPLEFT", cx, -TOP)
    scopeSeg.onPick = function(k) B.SetScope(k) end
    layoutSeg = ns.MakeSegments(body, { { key = "tile", label = ns.T("picker.lib.tile") },
                                       { key = "list", label = ns.T("picker.lib.list") } })
    layoutSeg:SetHeight(SEG_H)
    layoutSeg:SetWidth(LAYOUT_W)
    layoutSeg:SetPoint("TOPLEFT", win, "TOPLEFT", cx + cw - LAYOUT_W, -TOP)
    layoutSeg.onPick = function(k) B.SetLayout(k) end
    scopeSeg.body:SetWidth(cw - LAYOUT_W - GAP)
    layoutSeg.body:SetWidth(LAYOUT_W)
    scopeSeg:Layout()
    layoutSeg:Layout()
    local ctop = TOP + SEG_H + GAP
    local ch = H - ctop - PAD - PAGER_H - GAP
    cardsFr = CreateFrame("Frame", nil, body)
    cardsFr:SetPoint("TOPLEFT", win, "TOPLEFT", cx, -ctop)
    cardsFr:SetWidth(cw)
    cardsFr:SetHeight(ch)
    cardsFr:EnableMouseWheel(true)
    cardsFr:SetScript("OnMouseWheel", function(_, delta) B.Page(-delta) end)
    local tw = math.floor((cw - (TILE_COLS - 1) * CARD_GAP) / TILE_COLS)
    local th = math.floor((ch - (TILE_ROWS - 1) * CARD_GAP) / TILE_ROWS)
    for i = 1, TILE_COLS * TILE_ROWS do tiles[i] = makeTile(i, tw, th) end
    local rh = math.floor(ch / LIST_ROWS)
    for i = 1, LIST_ROWS do rows[i] = makeRow(i, cw, rh) end
    tileW, tileH, rowH, cardsH = tw, th, rh, ch
    emptyFs = cardsFr:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyFs:SetPoint("TOPLEFT", cardsFr, "TOPLEFT", 4, -6)
    ink(emptyFs, ns.EDIT.mute)
    prevBtn = ns.MakeButton(body)
    prevBtn:SetHeight(PAGER_H)
    prevBtn:SetLabel("<")
    prevBtn:SetWidth(PAGER_H + 6)
    prevBtn.tipTitle = ns.T("picker.lib.prev_tip")
    prevBtn.onClick = function() B.Page(-1) end
    nextBtn = ns.MakeButton(body)
    nextBtn:SetHeight(PAGER_H)
    nextBtn:SetLabel(">")
    nextBtn:SetWidth(PAGER_H + 6)
    nextBtn.tipTitle = ns.T("picker.lib.next_tip")
    nextBtn.onClick = function() B.Page(1) end
    pagerText = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pagerText:SetWidth(60)
    pagerText:SetJustifyH("CENTER")
    pagerText:SetPoint("BOTTOM", win, "BOTTOMLEFT", cx + cw - 50, PAD + 5)
    prevBtn:SetPoint("RIGHT", pagerText, "LEFT", -2, 0)
    nextBtn:SetPoint("LEFT", pagerText, "RIGHT", 2, 0)
    allBtn = ns.MakeButton(body)
    allBtn:SetHeight(PAGER_H)
    allBtn:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", cx, PAD)
    allBtn.tip = ns.T("picker.lib.in_all_tip")
    allBtn.onClick = function() B.SetScope("all") end
    allBtn:Hide()
    buildPreview(W - PREV_W)
    local regen = CreateFrame("Frame", nil, win)
    regen:RegisterEvent("PLAYER_REGEN_ENABLED")
    regen:RegisterEvent("PLAYER_REGEN_DISABLED")
    regen:SetScript("OnEvent", function()
        for key, hit in pairs(state.pending) do
            if not isPending(hit) then
                state.pending[key] = nil
                state.done[key] = true
            end
        end
        if win:IsShown() then
            reload(true)
            paint()
        end
    end)
    if hooksecurefunc then
        hooksecurefunc("ChatEdit_InsertLink", function(link)
            if win:IsVisible() and box:HasFocus() and link and box.Insert then box:Insert(link) end
        end)
    end
    win:SetScript("OnHide", function()
        box:ClearFocus()
        ns.TipHide()
        dropMinis()
        if demo then
            ns.Widget.DemoDrop(demo)
            demo = nil
        end
    end)
end
function B.Open(anchor, target, x, y)
    build()
    ns.Catalog.Ensure()
    local r = root()
    if r then migrate(r) end
    state.scope = (r and r.catalogFilter == "all") and "all" or "mine"
    state.layout = (r and r.catalogLayout == "tile") and "tile" or "list"
    state.target = target
    state.cell = (target and x and y) and { x = x, y = y } or nil
    state.done, state.page, state.selKey = {}, 1, nil
    state.q = ""
    field:SetText("")
    fold(false)
    local wx, wy = r and r.catalogWinX, r and r.catalogWinY
    win:SetScale((r and r.catalogWinScale) or fitScale())
    win:ClearAllPoints()
    if wx and wy then
        win:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", wx, wy)
    else
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    reload(true)
    win:Show()
    paint()
end
function B.OpenAt(sec, key, target)
    B.Open(nil, target)
    local function has()
        local s = state.sections and state.sections.byKey[sec]
        if not s then return false end
        if not key then return s.n > 0 end
        for _, h in ipairs(s.hits) do
            if h.key == key then return true end
        end
        return false
    end
    if not has() and state.scope ~= "all" then
        state.scope = "all"
        state.sections = nil
        reload(false)
    end
    local s = state.sections and state.sections.byKey[sec]
    if not s then
        paint()
        return false
    end
    local up = s.parent
    while up do
        state.open[up] = true
        up = state.sections.byKey[up] and state.sections.byKey[up].parent
    end
    state.sec, state.page, state.selKey = sec, 1, nil
    pickCards()
    for p, page in ipairs(state.pages) do
        for _, slot in ipairs(page) do
            if key and slot.hit and slot.hit.key == key then state.page, state.selKey = p, key end
        end
    end
    paint()
    return true
end
function B.Fold(on)
    if not win then return end
    local l, t = win:GetLeft(), win:GetTop()
    fold(on)
    if l and t then
        win:ClearAllPoints()
        win:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
    end
    if not on then paint() end
end
function B.Close()
    if win then win:Hide() end
end
function B.IsShown()
    return win ~= nil and win:IsShown() and true or false
end
function B.State()
    return state
end
function B.Frames()
    return { win = win, treeRows = treeRows, tiles = tiles, rows = rows, heads = heads, prev = prev, field = field,
             scope = scopeSeg, layout = layoutSeg, all = allBtn, minis = minis, body = body, fold = foldBtn, grip = grip }
end
function B.Selected()
    return selected()
end
ns.pickerLibLoaded = true
