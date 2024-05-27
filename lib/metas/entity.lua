local collision_mask_util = require '__core__/lualib/collision-mask-util'

---@class data.EntityPrototype
---@field public standardize fun(self: data.EntityPrototype): data.EntityPrototype
---@field public add_flag fun(self: data.EntityPrototype, flag: string): data.EntityPrototype
---@field public remove_flag fun(self: data.EntityPrototype, flag: string): data.EntityPrototype
---@field public has_flag fun(self: data.EntityPrototype, flag: string): boolean

local entity_types = defines.prototypes.entity
ENTITY = setmetatable({}, {
    ---@param entity data.EntityPrototype
    __call = function(self, entity)
        local etype = type(entity)
        if etype == 'string' then
            for ptype in pairs(defines.prototypes.entity) do
                local result = data.raw[ptype][entity]
                if result then return result:standardize() end
            end
        elseif etype == 'table' then
            if not entity.type then error('Tried to extend an entity ' .. entity.name .. ' without providing a type') end
            if not entity_types[entity.type] then error('Tried to use ENTITY{} on a non-entity: ' .. entity.name) end

            data:extend{entity}
            return entity:standardize()
        else error('Invalid type ' .. etype) end
        error('Entity ' .. tostring(entity) .. ' does not exist')
    end,
    __index = function(self, entity_name)
        for ptype in pairs(defines.prototypes.entity) do
            local result = data.raw[ptype][entity_name]
            if result then return result:standardize() end
        end
        return nil
    end
})

local metas = {}

metas.standardize = function(self)
    local minable = self.minable
    if minable then
        if minable.results and type(minable.results) == 'table' then
            minable.result = nil
            minable.count = nil
        elseif minable.result then
            minable.results = {{type = 'item', name = minable.result, amount = minable.count or 1}}
        else
            minable.results = {}
        end

        for k, p in pairs(minable.results) do
            minable.results[k] = py.standardize_product(p)
        end
    end

    self.selection_box = self.selection_box or self.collision_box
    self.collision_mask = self.collision_mask or collision_mask_util.get_mask(self)

    return self
end

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