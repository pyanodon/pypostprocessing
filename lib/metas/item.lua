---@class data.ItemPrototype
---@field public add_flag fun(self: data.ItemPrototype, flag: string): data.ItemPrototype
---@field public remove_flag fun(self: data.ItemPrototype, flag: string): data.ItemPrototype
---@field public has_flag fun(self: data.ItemPrototype, flag: string): boolean

local item_prototypes = defines.prototypes.item
ITEM = setmetatable({}, {
    ---@param item data.ItemPrototype
    __call = function(self, item)
        local itype = type(item)
        if itype == 'string' then
            for ptype in pairs(defines.prototypes.item) do
                --TODO:FIX this better. 
                if ptype ~= "item-with-inventory" and ptype ~= "item-with-label" and ptype ~= "item-with-tags" and ptype ~= "space-platform-starter-pack" then
                local result = data.raw[ptype][item]
                if result then return result end
                end
            end
        elseif itype == 'table' then
            if not item.type then error('Tried to extend an item ' .. item.name .. ' without providing a type') end
            if not item_prototypes[item.type] then error('Tried to use ITEM{} on a non-item: ' .. item.name) end

            data:extend{item}
            return item
        else error('Invalid type ' .. itype) end
        error('Item ' .. tostring(item) .. ' does not exist')
    end,
    __index = function(self, item_name)
        for ptype in pairs(defines.prototypes.item) do
            local result = data.raw[ptype][item_name]
            if result then return result end
        end
        return nil
    end
})

local metas = {}

metas.add_flag = function(self, flag)
    if not self.flags then self.flags = {} end
    table.insert(self.flags, flag)
    return self
end

metas.remove_flag = function(self, flag)
    if not self.flags then return self end
    for i, f in pairs(self.flags) do
        if f == flag then table.remove(self.flags, i) end
    end
    return self
end

metas.has_flag = function(self, flag)
    if not self.flags then return false end
    for _, f in pairs(self.flags) do
        if f == flag then return true end
    end
    return false
end

return metas