FLUID = setmetatable(data.raw.fluid, {
    ---@param tech data.FluidPrototype
    __call = function(self, fluid)
        local ftype = type(fluid)
        if ftype == 'string' then
            fluid = data.raw.fluid[fluid]
            if not fluid then error('Fluid ' .. fluid .. ' does not exist') end
        elseif ftype == 'table' then
            fluid.type = 'fluid'
            data:extend{fluid}
        else error('Invalid type ' .. ftype) end
        return fluid
    end
})

local metas = {}

return metas