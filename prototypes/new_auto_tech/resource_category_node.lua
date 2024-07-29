local object_node_base = require "prototypes.new_auto_tech.object_node_base"
local node_types = require "prototypes.new_auto_tech.node_types"

local resource_category_node = object_node_base:create_object_class("resource category", node_types.resource_category_node)

function resource_category_node:register_dependencies(nodes)
end

return resource_category_node
