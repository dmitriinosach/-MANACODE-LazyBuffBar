local _, ns = ...
local NAME_COLOR = "|cffffd100"
local function paint(name)
    return NAME_COLOR .. name .. "|r"
end
local function spellName(id)
    local name = GetSpellInfo(id)
    return paint(name or ns.T("note.spell", id))
end
local function itemName(id)
    local name = GetItemInfo(id)
    return paint(name or ns.T("note.item", id))
end
local function expandTag(kind, id)
    local n = tonumber(id)
    if kind == "s" then return spellName(n) end
    return itemName(n)
end
function ns.NoteExpand(text)
    local out = text:gsub("%{([si]):(%d+)%}", expandTag)
    return out
end
function ns.NoteText(entry)
    if not entry then return nil end
    local text = entry.note
    if ns.CurrentLocale() ~= "ruRU" and entry.noteEn then text = entry.noteEn end
    if not text or text == "" then return nil end
    return ns.NoteExpand(text)
end
ns.noteLoaded = true
