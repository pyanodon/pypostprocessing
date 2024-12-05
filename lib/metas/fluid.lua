FLUID = setmetatable(data.raw.fluid, {
    ---@param tech data.FluidPrototype
    __call = function(self, fluid)
        local ftype = type(fluid)
        if ftype == "string" then
            if not self[fluid] then error("Fluid " .. tostring(fluid) .. " does not exist") end
            fluid = self[fluid]
        elseif ftype == "table" then
            fluid.type = "fluid"
            data:extend {fluid}
        else
            error("Invalid type " .. ftype)
        end
        return fluid
    end
})

local metas = {}

return metas
