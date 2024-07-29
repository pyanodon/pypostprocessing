local object_node_base = require "prototypes.new_auto_tech.object_node_base"
local node_types = require "prototypes.new_auto_tech.node_types"
local fluid_fuel_verbs = require "prototypes.new_auto_tech.fluid_fuel_verbs"

local fluid_node = object_node_base:create_object_class("fluid", node_types.fluid_node)

function fluid_node:register_dependencies(nodes)
    local fluid = self.object
    if fluid.fuel_value ~= nil then
        self:add_disjunctive_dependent(nodes, node_types.fluid_fuel_node, 1, "fuel value", fluid_fuel_verbs.instantiate)
    end
end

return fluid_node
