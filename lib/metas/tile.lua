local log = py.log.init("TILE")

---@diagnostic disable-next-line: missing-fields
---@type pYdata.TilePrototype
local metas = {}

local metatable = {
    __index = function(self, index) return metas[index] or self.prototype[index] end,
    __newindex = function(self, index, value) self.prototype[index] = value end
}

---@class pYdata.TilePrototype:pYdata.AnyPrototype,data.TilePrototype
---@operator call(string|pYdata.TilePrototype|data.TilePrototype): pYdata.TilePrototype
TILE = setmetatable({}, {
    __call = function(_, object)
        local type = type(object)
        if type == "string" then
            object = assert(data.raw.tile[object], "Tile " .. object .. " does not exist")
            return setmetatable({prototype = object}, metatable)
        elseif type == "table" and getmetatable(object) == metatable then
            return object
        elseif type == "table" then
            local old_object = data.raw.tile[object.name]
            if old_object then
                local info = debug.getinfo(2) ---@cast info -?
                local callsite = info.source .. ":" .. info.currentline
                log.warning("overwriting existing tile: " .. object.name .. " at " .. callsite)
            end
            object.type = "tile"
            data:extend {object}
            return setmetatable({prototype = object}, metatable)
        end
    end
})

return metas
