local object_node_base = require "prototypes.new_auto_tech.object_node_base"
local node_types = require "prototypes.new_auto_tech.node_types"

local electricity_node = object_node_base:create_unique_class("electricity", node_types.electricity_node)

function electricity_node:register_dependencies(nodes)
end

return electricity_node
