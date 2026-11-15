local _, ns = ...
local Pool = {}
Pool.__index = Pool
function ns.NewPool(factory, reset, cap)
    return setmetatable({ items = {}, cap = cap or 100, next = 1, factory = factory, reset = reset }, Pool)
end
function Pool:Acquire()
    local it
    for i = 1, #self.items do
        if not self.items[i]:IsShown() then it = self.items[i]; break end
    end
    if not it and #self.items < self.cap then
        it = self.factory(self)
        self.items[#self.items + 1] = it
    end
    if not it then
        it = self.items[self.next]
        self.next = (self.next % #self.items) + 1
    end
    if self.reset then self.reset(it, self) end
    it:Show()
    return it
end
function Pool:Size()
    return #self.items
end
ns.poolLoaded = true
