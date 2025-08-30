TILE = setmetatable(data.raw.tile, {
    ---@param tile data.TilePrototype
    __call = function(self, tile)
        local ftype = type(tile)
        if ftype == "string" then
            if not self[ tile ] then error("Tile " .. tostring(tile) .. " does not exist") end
            tile = self[ tile ]
        elseif ftype == "table" then
            tile.type = "tile"
            data:extend({ tile })
        else
            error("Invalid type " .. ftype)
        end
        return tile
    end
})

local metas = {}

return metas
