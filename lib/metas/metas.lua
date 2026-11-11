-- A drop-in replacement for stdlib. Adds global tables for RECIPE TECHNOLOGY ENTITY and ITEM.

local lib = {
    recipe = require "recipe",
    technology = require "technology",
    entity = require "entity",
    item = require "item",
    fluid = require "fluid",
    tile = require "tile"
}

---@class pYdata.AnyPrototype:data.AnyPrototype
---@field public copy fun<T>(self: T, new_name: (string | fun(self: T): string)?): T
---@field public subgroup_order fun<T>(self: T, subgroup: string, order: string): T
---@field public set_fields fun<T>(self: T, fields: table): T
---@field public set fun<T>(self: T, field: string, value: any): T
---@field public extend fun<T>(self: T): T
---@field public delete fun<T>(self: T)
---@field public hide fun<T>(self: T): T
---@field public unhide fun<T>(self: T): T

for _, meta in pairs(lib) do
    meta.copy = function(self, new_name)
        local copy = table.deepcopy(self)
        if new_name then
            if type(new_name) == "function" then new_name = new_name(copy) end
            copy.name = new_name
        end
        return copy
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

    meta.extend = function(self)
        data.raw[self.type][self.name] = rawget(self, "prototype")
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
