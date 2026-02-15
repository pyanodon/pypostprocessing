-- A drop-in replacement for stdlib. Adds global tables for RECIPE TECHNOLOGY ENTITY and ITEM.

local lib = {
    recipe = require "recipe",
    technology = require "technology",
    entity = require "entity",
    item = require "item",
    fluid = require "fluid",
    tile = require "tile"
}

---@class data.AnyPrototype
---@field public copy fun(self: data.AnyPrototype, new_name: (string | fun(self: data.AnyPrototype): string)?): data.AnyPrototype
---@field public subgroup_order fun(self: data.AnyPrototype, subgroup: string, order: string): data.AnyPrototype
---@field public set_fields fun(self: data.AnyPrototype, fields: table): data.AnyPrototype
---@field public set fun(self: data.AnyPrototype, field: string, value: any): data.AnyPrototype
---@field public delete fun(self: data.AnyPrototype)
---@field public hide fun(self: data.AnyPrototype): data.AnyPrototype
---@field public unhide fun(self: data.AnyPrototype): data.AnyPrototype

for _, meta in pairs(lib) do
    meta.copy = function(self, new_name)
        local copy = table.deepcopy(self)
        if new_name then
            if type(new_name) == "function" then new_name = new_name(copy) end
            copy.name = new_name
            data:extend {copy}
        end
        return setmetatable(copy, getmetatable(self))
    end

    meta.subgroup_order = function(self, subgroup, order)
        self.subgroup = subgroup
        self.order = order
        return self
    end

    meta.set_fields = function(self, fields)
        for k, v in pairs(fields) do
            if type(k) ~= "string" then error("Field name must be a string") end
            self[k] = v
        end
        return self
    end

    meta.set = function(self, field, value)
        if type(field) ~= "string" then error("Field name must be a string") end
        self[field] = value
        return self
    end

    meta.delete = function(self)
        data.raw[self.type][self.name] = nil
    end

    meta.hide = function(self)
        self.hidden = true
        self.hidden_in_factoriopedia = true
        return self
    end

    meta.unhide = function(self)
        self.hidden = nil
        self.hidden_in_factoriopedia = nil
        return self
    end
end

local metas = {}
metas.recipe = {__index = lib.recipe}
metas.technology = {__index = lib.technology}
for ptype in pairs(defines.prototypes.entity) do
    metas[ptype] = {__index = lib.entity}
end
for ptype in pairs(defines.prototypes.item) do
    metas[ptype] = {__index = lib.item}
end
metas.fluid = {__index = lib.fluid}
metas.tile = {__index = lib.tile}

for ptype, prototypes in pairs(data.raw) do
    local meta = metas[ptype]
    if meta then
        for _, prototype in pairs(prototypes) do
            setmetatable(prototype, meta)
        end
    end
end

local extend = data.extend
data.extend = function(self, prototypes)
    -- Wube made it so data:extend and data.extend are the same
    if self ~= prototypes and prototypes == nil then
        prototypes = self
    end
    extend(self, prototypes)
    for _, prototype in pairs(prototypes) do
        local meta = metas[prototype.type]
        if meta then
            setmetatable(prototype, meta)
        end
    end
end
