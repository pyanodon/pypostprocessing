---@diagnostic disable-next-line: unresolved-require
local collision_mask_util = require "__core__/lualib/collision-mask-util"
local log = py.log.init("ENTITY")

---@diagnostic disable-next-line: missing-fields
---@type pYdata.EntityPrototype
local metas = {}

local metatable = {
    __index = function(self, index) return metas[index] or self.prototype[index] end,
    __newindex = function(self, index, value) self.prototype[index] = value end
}

---@class pYdata.EntityPrototype:pYdata.AnyPrototype,data.EntityPrototype
---@field collision_mask data.CollisionMaskConnector
---@operator call(string|pYdata.EntityPrototype|data.EntityPrototype): pYdata.EntityPrototype
---@field public standardize fun(self: pYdata.EntityPrototype): pYdata.EntityPrototype
---@field public add_flag fun(self: pYdata.EntityPrototype, flag: string): pYdata.EntityPrototype, boolean
---@field public remove_flag fun(self: pYdata.EntityPrototype, flag: string): pYdata.EntityPrototype, boolean
---@field public has_flag fun(self: pYdata.EntityPrototype, flag: string): boolean
ENTITY = setmetatable({}, {
    __call = function(_, object)
        local type = type(object)
        if type == "string" then
            for _, pdata in py.iter_prototype_categories("entity") do
                local result = pdata[object]
                if result then
                    return setmetatable({prototype = result}, metatable):standardize()
                end
            end
            error("Entity " .. object .. " does not exist")
        elseif type == "table" and getmetatable(object) == metatable then
            return object:standardize()
        elseif type == "table" then
            if not object.type then error("Tried to extend an entity " .. object.name .. " without providing a type") end
            if not defines.prototypes.entity[object.type] then error("Tried to use ENTITY{} on a non-entity: " .. object.name) end
            local old_object = data.raw[object.type][object.name]
            if old_object then
                local info = debug.getinfo(2) ---@cast info -?
                local callsite = info.source .. ":" .. info.currentline
                log.warning("overwriting existing entity: " .. object.name .. " at " .. callsite)
            end
            data:extend {object}
            return setmetatable({prototype = object}, metatable):standardize()
        end
    end
})

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
