local log = py.log.init("FLUID")

---@diagnostic disable-next-line: missing-fields
---@type pYdata.FluidPrototype
local metas = {}

local metatable = {
    __index = function(self, index) return metas[index] or self.prototype[index] end,
    __newindex = function(self, index, value) self.prototype[index] = value end
}

---@class pYdata.FluidPrototype:pYdata.AnyPrototype,data.FluidPrototype
---@operator call(string|pYdata.FluidPrototype|data.FluidPrototype): pYdata.FluidPrototype
FLUID = setmetatable({}, {
    __call = function(_, object)
        local type = type(object)
        if type == "string" then
            object = assert(data.raw.fluid[object], "Fluid " .. object .. " does not exist")
            return setmetatable({prototype = object}, metatable)
        elseif type == "table" and getmetatable(object) == metatable then
            return object
        elseif type == "table" then
            local old_object = data.raw.fluid[object.name]
            if old_object then
                local info = debug.getinfo(2) ---@cast info -?
                local callsite = info.source .. ":" .. info.currentline
                log.warning("overwriting existing fluid: " .. object.name .. " at " .. callsite)
            end
            object.type = "fluid"
            data:extend {object}
            return setmetatable({prototype = object}, metatable)
        end
    end
})

return metas
