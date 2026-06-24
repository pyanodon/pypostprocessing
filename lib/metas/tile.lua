---@class pYdata.TilePrototype:pYdata.AnyPrototype,data.TilePrototype
---@operator call(string|pYdata.TilePrototype|data.TilePrototype): pYdata.TilePrototype
TILE = setmetatable(data.raw.tile, {
    __call = function(self, tile)
        local ftype = type(tile)
        if ftype == "string" then
            if not self[tile] then error("Tile " .. tostring(tile) .. " does not exist") end
            tile = self[tile]
        elseif ftype == "table" then
            tile.type = "tile"
            data:extend {tile}
        else
            error("Invalid type " .. ftype)
        end
        return tile
    end
})

---@diagnostic disable-next-line: missing-fields
---@type pYdata.TilePrototype
local metas = {}

return metas
