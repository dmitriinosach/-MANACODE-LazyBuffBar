local _, ns = ...
local NAME = "raidbuffs"
local VIEW = "buffs"
local LINES = 8
local GREY = "|cff808080"
local WHITE_C = ns.STATE.text
local WARN_C = ns.STATE.soon
local BAD_C = ns.STATE.none
local GLOW = { none = { 1, 0.15, 0.15 }, soon = { WARN_C[1], WARN_C[2], WARN_C[3] } }
local FACE_STATE = { ok = "up", soon = "soon", none = "miss", off = "off" }
local function watchOf(opt)
    local C = ns.Cover
    local out, seen = {}, {}
    local w = opt and opt.watch
    if type(w) == "table" then
        for _, k in ipairs(w) do
            if C.Get(k) and not seen[k] then
                seen[k] = true
                out[#out + 1] = k
            end
        end
    end
    if #out > 0 then return out end
    for _, b in ipairs(C.Buffs()) do
        local g, s = C.Known(b)
        if b.watch and (g or s) then out[#out + 1] = b.key end
    end
    if #out > 0 then return out end
    for _, b in ipairs(C.Buffs()) do
        if b.watch then out[#out + 1] = b.key end
    end
    if #out == 0 and C.Buffs()[1] then out[1] = C.Buffs()[1].key end
    return out
end
local function dims(n, lay)
    if n < 1 then n = 1 end
    if lay == "col" then return 1, n end
    if lay == "sq" then
        if n == 1 then return 1, 1 end
        if n == 2 then return 2, 1 end
        return 2, 2
    end
    return n, 1
end
local function numsOf(opt)
    return { can = opt.n_can ~= false, cnt = opt.n_cnt ~= false, min = opt.n_min ~= false, me = opt.n_me == true,
             cand = opt.n_cand == true }
end
local function state(opt)
    opt = opt or {}
    local C = ns.Cover
    C.Touch()
    local now = GetTime()
    local st = { cells = {}, nums = numsOf(opt), need = false, raid = C.InRaid(), solo = #C.Roster() <= 1 }
    local sopt = { cast = opt.cast, soon = opt.soon, lines = LINES }
    for i, k in ipairs(watchOf(opt)) do
        local b = C.Get(k)
        local s = C.Summary(b, sopt, now)
        local items, sum = C.Reagents(b)
        local v = s.verdict
        if v == "none" and s.can == 0 then v = s.lowN > 0 and "soon" or "ok" end
        if v == "none" or v == "soon" then st.need = true end
        st.cells[i] = { key = k, b = b, s = s, verdict = v, cand = b.reagent and sum or nil, items = items }
    end
    return st
end
local function vis(r, on)
    on = on and true or false
    if r.lbbVis == on then return end
    r.lbbVis = on
    if on then r:Show() else r:Hide() end
end
local function build(layer)
    local F = ns.buffbar.Face
    local s = layer.cell or layer.h
    local gap, gapY = layer.gap or 2, layer.gapY or 2
    local cols = math.max(1, math.floor((layer.w + gap) / (s + gap) + 0.5))
    local rows = math.max(1, math.floor((layer.h + gapY) / (s + gapY) + 0.5))
    layer.tiles = {}
    for i = 1, cols * rows do
        local cx, cy = (i - 1) % cols, math.floor((i - 1) / cols)
        local f = F.Make(layer, s)
        f:SetPoint("TOPLEFT", layer, "TOPLEFT", cx * (s + gap), -cy * (s + gapY))
        f.can = f.txt:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        f.can:Hide()
        f.digits[#f.digits + 1] = f.can
        layer.tiles[i] = f
    end
end
local function digit(fs, f, spot, text)
    if not text then
        vis(fs, false)
        return
    end
    ns.buffbar.Face.Put(fs, f, spot)
    ns.Widget.Text(fs, text)
    vis(fs, true)
end
local function paintFace(f, c, st, panel)
    local F, W = ns.buffbar.Face, ns.Widget
    vis(f, true)
    F.Dress(f, panel)
    local spot = F.Spots(f)
    local s, v, nums = c.s, c.verdict, st.nums
    local icon = c.s.icon or ns.QMARK
    if f.lbbIcon ~= icon then
        f.lbbIcon = icon
        f.tex:SetTexture(icon)
        ns.Look.Crop(f)
    end
    local has = v ~= "off" and s.me ~= false
    if f.lbbGrey ~= (not has) then
        f.lbbGrey = not has
        f.tex:SetDesaturated(not has)
    end
    local a = has and 1 or F.Absent(f)
    if f.lbbA ~= a then
        f.lbbA = a
        f.tex:SetAlpha(a)
    end
    local g = GLOW[v]
    if f.lbbGlow ~= g then
        f.lbbGlow = g
        if g then f.glow:SetBackdropBorderColor(g[1], g[2], g[3], 1) end
    end
    vis(f.glow, g ~= nil)
    ns.Style.State(f, FACE_STATE[v] or "off")
    vis(f.mark, false)
    local group = v ~= "off" and not st.solo and s.total > 1
    local mine = ((nums.me or st.solo) and type(s.me) == "number" and s.me > 0) and s.me or nil
    digit(f.left, f, spot.time, mine and ns.Style.Fmt(f, mine) or nil)
    if mine then ns.Style.Time(f, f.left, mine, true) end
    digit(f.rn, f, spot.group, (nums.cnt and group) and (s.n .. "/" .. s.total) or nil)
    local min = (nums.min and group and s.min) and s.min or nil
    digit(f.rmin, f, spot.gtime, min and ns.Style.Fmt(f, min) or nil)
    if min then W.Color(f.rmin, v == "soon" and WARN_C or WHITE_C) end
    local cand = (nums.cand and v ~= "off") and c.cand or nil
    digit(f.count, f, spot.count, cand and tostring(cand) or nil)
    if cand then W.Color(f.count, cand > 0 and WHITE_C or BAD_C) end
    local can = (nums.can and group and s.can > 0) and s.can or nil
    digit(f.can, f, spot.warn, can and tostring(can) or nil)
    if can then W.Color(f.can, BAD_C) end
end
local function paint(layer, st)
    for i, f in ipairs(layer.tiles) do
        local c = st.cells[i]
        if c then paintFace(f, c, st, layer.panel) else vis(f, false) end
    end
end
local CELLS = {}
local function cellsFor(n, cols)
    local k = n .. "x" .. cols
    local list = CELLS[k]
    if list then return list end
    list = {}
    for i = 1, n do
        list[i] = {
            cx = (i - 1) % cols, cy = math.floor((i - 1) / cols),
            attrs = function(st)
                local c = st.cells[i]
                local s = c and c.s
                if not (s and s.next and s.spell) then return {} end
                return { type = "spell", spell = s.spell, unit = s.next.click }
            end,
        }
    end
    CELLS[k] = list
    return list
end
local hexes = {}
local function colored(m)
    local hex = hexes[m.class]
    if not hex then
        local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[m.class]
        hex = cc and ("|cff%02x%02x%02x"):format(cc.r * 255, cc.g * 255, cc.b * 255) or "|cffffffff"
        hexes[m.class] = hex
    end
    return hex .. m.name .. "|r"
end
local function names(list, from, to, total, left)
    local out = {}
    for i = from, to do
        local m = list[i]
        if not m then break end
        local extra = left and left(m)
        out[#out + 1] = colored(m) .. (extra and (" " .. extra) or "")
    end
    local s = table.concat(out, ", ")
    if total > #out then s = s .. " " .. ns.T("widget.rb_more", total - #out) end
    return s
end
local function itemName(id)
    local n = GetItemInfo(id)
    return n or ns.T("widget.rb_item_" .. id)
end
local function tip(i, st)
    local T, W = ns.T, ns.Widget
    local c = st.cells[i]
    if not c then return nil end
    local s, b = c.s, c.b
    local title = b.gname or b.sname or "?"
    if s.verdict == "off" then return title, T("widget.cv_off") end
    local now = GetTime()
    local lines = {}
    if not st.solo then
        lines[#lines + 1] = T("widget.rb_cnt", s.n, s.total)
        if s.can > 0 then
            lines[#lines + 1] = T("widget.rb_can", s.can)
            lines[#lines + 1] = T("widget.rb_miss", names(s.list, 1, math.min(s.can, #s.list), s.can))
        end
        if s.farN > 0 then lines[#lines + 1] = GREY .. T("widget.rb_gone", names(s.gone, 1, #s.gone, s.farN)) .. "|r" end
        if s.lowN > 0 then
            lines[#lines + 1] = T("widget.rb_low", names(s.low, 1, #s.low, s.lowN, function(m)
                local e = ns.Raid.End(m, b.list)
                return e and e > 0 and ("(" .. W.Left(e - now) .. ")") or nil
            end))
        elseif s.min and s.minWho then
            lines[#lines + 1] = T("widget.rb_min", W.Left(s.min), colored(s.minWho))
        end
    end
    if s.me == false then lines[#lines + 1] = T("widget.rb_me_none")
    elseif s.me == 0 then lines[#lines + 1] = T("widget.rb_me_on")
    elseif s.me then lines[#lines + 1] = T("widget.rb_me", W.Left(s.me)) end
    for _, it in ipairs(c.items) do lines[#lines + 1] = T("widget.rb_item", itemName(it.id), it.n) end
    if s.next then
        if s.group and st.raid then lines[#lines + 1] = T("widget.cv_click_sub", s.spell, s.next.sub, s.next.name)
        else lines[#lines + 1] = T("widget.cv_click", s.spell, s.next.name) end
    end
    return title, table.concat(lines, "\n")
end
local function copy(t)
    local out = {}
    for k, v in pairs(t or {}) do out[k] = v end
    return out
end
local function several()
    return #ns.Cover.Buffs() > 1
end
local function iconId()
    local list = ns.widgetData.cover.classes
    local _, class = UnitClass("player")
    local e = list[class or ""] and list[class][1]
    return e and (e.group or e.single) or 48162
end
ns.Widget.Register(NAME, {
    icon = iconId(),
    label = "widget.raidbuffs",
    many = true,
    views = { [VIEW] = function(opt) return dims(#watchOf(opt), opt and opt.lay) end },
    order = { VIEW },
    view = VIEW,
    seed = function(item)
        if item.opt and type(item.opt.watch) == "table" and #item.opt.watch > 0 then return end
        local opt = copy(item.opt)
        opt.watch = watchOf(nil)
        item.opt = opt
    end,
    avail = function() return ns.Cover.Avail() end,
    events = { SPELLS_CHANGED = true, RAID_ROSTER_UPDATE = true, PARTY_MEMBERS_CHANGED = true, PLAYER_REGEN_ENABLED = true,
               BAG_UPDATE = true },
    tick = 1,
    State = state,
    active = function(st, opt)
        if opt and opt.when == "need" then return st.need end
        return true
    end,
    Build = build,
    Paint = paint,
    cells = function(_, opt)
        local w = watchOf(opt)
        local cols = dims(#w, opt and opt.lay)
        return cellsFor(#w, cols)
    end,
    Tip = tip,
    opts = {
        { key = "watch", label = "widget.cv_watch", kind = "order", when = several,
          items = function()
              local out = {}
              for i, b in ipairs(ns.Cover.Buffs()) do
                  out[i] = { v = b.key, text = ns.T("widget.cvb_" .. b.key), icon = b.icon }
              end
              return out
          end,
          chosen = function(item) return watchOf(item.opt) end },
        { key = "lay", label = "widget.bless_lay", when = function(item) return #watchOf(item.opt) > 1 end,
          values = function(item)
              local n = #watchOf(item.opt)
              local out = {}
              for i, v in ipairs({ { nil, "row" }, { "col", "col" }, { "sq", "sq" } }) do
                  local w, h = dims(n, v[1])
                  out[i] = { v = v[1], text = ns.T("card.vsize", ns.T("widget.bless_lay_" .. v[2]), w, h) }
              end
              return out
          end },
        { key = "nums", label = "widget.rb_nums", kind = "checks", checks = {
            { key = "n_can", def = true, label = "widget.rb_n_can" },
            { key = "n_cnt", def = true, label = "widget.rb_n_cnt" },
            { key = "n_min", def = true, label = "widget.rb_n_min" },
            { key = "n_me", def = false, label = "widget.rb_n_me" },
            { key = "n_cand", def = false, label = "widget.rb_n_cand" },
        } },
        { key = "cast", label = "widget.cv_cast", values = {
            { v = nil, label = "widget.cv_cast_auto" }, { v = "group", label = "widget.cv_cast_group" },
            { v = "single", label = "widget.cv_cast_single" },
        } },
        { key = "soon", label = "widget.cv_soon", values = {
            { v = 120, label = "widget.cv_soon_2" }, { v = nil, label = "widget.cv_soon_5" }, { v = 600, label = "widget.cv_soon_10" },
        } },
        { key = "when", label = "widget.cv_when", values = {
            { v = nil, label = "widget.cv_when_always" }, { v = "need", label = "widget.cv_when_need" },
        } },
    },
})
ns.raidbuffsWidgetLoaded = true
