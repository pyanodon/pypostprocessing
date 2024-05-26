TILE = setmetatable(data.raw.tile, {
    ---@param tech data.TilePrototype
    __call = function(self, tile)
        local ftype = type(tile)
        if ftype == 'string' then
            tile = data.raw.tile[tile]
            if not tile then error('Tile ' .. tile .. ' does not exist') end
        elseif ftype == 'table' then
            tile.type = 'tile'
            data:extend{tile}
        else error('Invalid type ' .. ftype) end
        return tile
    end
})

local metas = {}

return metas