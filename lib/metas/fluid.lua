---@class pYdata.FluidPrototype:pYdata.AnyPrototype,data.FluidPrototype
---@operator call(string|pYdata.FluidPrototype|data.FluidPrototype): pYdata.FluidPrototype
FLUID = setmetatable(data.raw.fluid, {
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

---@diagnostic disable-next-line: missing-fields
---@type pYdata.FluidPrototype
local metas = {}

return metas
