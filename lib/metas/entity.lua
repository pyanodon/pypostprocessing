---@diagnostic disable-next-line: unresolved-require
local collision_mask_util = require "__core__/lualib/collision-mask-util"

local entity_types = defines.prototypes.entity

---@class pYdata.EntityPrototype:pYdata.AnyPrototype,data.EntityPrototype
---@operator call(string|pYdata.EntityPrototype|data.EntityPrototype): pYdata.EntityPrototype
---@field public standardize fun(self: pYdata.EntityPrototype): pYdata.EntityPrototype
---@field public add_flag fun(self: pYdata.EntityPrototype, flag: string): pYdata.EntityPrototype, boolean
---@field public remove_flag fun(self: pYdata.EntityPrototype, flag: string): pYdata.EntityPrototype, boolean
---@field public has_flag fun(self: pYdata.EntityPrototype, flag: string): boolean
ENTITY = setmetatable({}, {
    __call = function(self, entity)
        local etype = type(entity)
        if etype == "string" then
            ---@cast entity any somehow this works but string doesnt
            for _, pdata in py.iter_prototype_categories("entity") do
                local result = pdata[entity]
                if result then return result:standardize() end
            end
        elseif etype == "table" then
            if not entity.type then error("Tried to extend an entity " .. entity.name .. " without providing a type") end
            if not entity_types[entity.type] then error("Tried to use ENTITY{} on a non-entity: " .. entity.name) end

            data:extend {entity}
            return entity:standardize()
        else
            error("Invalid type " .. etype)
        end
        error("Entity " .. tostring(entity) .. " does not exist")
    end,
    __index = function(self, entity_name)
        for _, pdata in py.iter_prototype_categories("entity") do
            local result = pdata[entity_name]
            if result then return result:standardize() end
        end
        return nil
    end
})

---@diagnostic disable-next-line: missing-fields
---@type pYdata.EntityPrototype
local metas = {}

metas.standardize = function(self)
    local minable = self.minable
    if minable then
        if minable.results and type(minable.results) == "table" then
            -- nothing to do
        elseif minable.result then
            minable.results = {{type = "item", name = minable.result, amount = minable.count or 1}}
        else
            minable.results = {}
        end
        minable.result = nil
        minable.count = nil
    end

    self.collision_mask = self.collision_mask or collision_mask_util.get_mask(self)

    return self
end

metas.add_flag = function(self, flag)
    self.flags = self.flags or {}  
    for _, f in pairs(self.flags) do
        if f == flag then
            return self, false -- flag already exists
        end
    end
    table.insert(self.flags, flag)
    return self, true -- flag added
end

metas.remove_flag = function(self, flag)
    if not self.flags then return self, false end
    for i, f in pairs(self.flags) do
        if f == flag then
            table.remove(self.flags, i)
            return self, true -- flag found and removed
        end
    end
    return self, false -- could not find flag
end

metas.has_flag = function(self, flag)
    if not self.flags then return false end
    for _, f in pairs(self.flags) do
        if f == flag then return true end
    end
    return false
end

return metas
