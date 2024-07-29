local object_node_base = require "prototypes.new_auto_tech.object_node_base"
local node_types = require "prototypes.new_auto_tech.node_types"

local fluid_fuel_node = object_node_base:create_unique_class("fluid fuel", node_types.fluid_fuel_node)

function fluid_fuel_node:register_dependencies(nodes)
end

return fluid_fuel_node
