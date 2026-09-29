---@diagnostic disable-next-line: missing-fields
---@type pYdata.TilePrototype
local metas = {}

---@class pYdata.TilePrototype:pYdata.AnyPrototype,data.TilePrototype
---@operator call(string|pYdata.TilePrototype|data.TilePrototype): pYdata.TilePrototype
TILE = setmetatable(data.raw.tile, {
    __call = function(self, tile)
        local ftype = type(tile)
        if ftype == "string" then
            if not self[tile] then error("Tile " .. tostring(tile) .. " does not exist") end
            tile = self[tile]
            tile = setmetatable(tile, {__index = metas})
        elseif ftype == "table" then
            tile.type = "tile"
            tile = setmetatable(tile, {__index = metas})
            data:extend {tile}
        else
            error("Invalid type " .. ftype)
        end
        return tile
    end
})

return metas
