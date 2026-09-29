---@diagnostic disable-next-line: missing-fields
---@type pYdata.FluidPrototype
local metas = {}

---@class pYdata.FluidPrototype:pYdata.AnyPrototype,data.FluidPrototype
---@operator call(string|pYdata.FluidPrototype|data.FluidPrototype): pYdata.FluidPrototype
FLUID = setmetatable(data.raw.fluid, {
    __call = function(self, fluid)
        local ftype = type(fluid)
        if ftype == "string" then
            if not self[fluid] then error("Fluid " .. tostring(fluid) .. " does not exist") end
            fluid = self[fluid]
            fluid = setmetatable(fluid, {__index = metas})
        elseif ftype == "table" then
            fluid.type = "fluid"
            fluid = setmetatable(fluid, {__index = metas})
            data:extend {fluid}
        else
            error("Invalid type " .. ftype)
        end
        return fluid
    end
})

return metas
