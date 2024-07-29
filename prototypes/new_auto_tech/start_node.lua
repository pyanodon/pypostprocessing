local object_node_base = require "prototypes.new_auto_tech.object_node_base"
local node_types = require "prototypes.new_auto_tech.node_types"

local start_node = object_node_base:create_unique_class("start", node_types.start_node)

function start_node:register_dependencies(nodes)
end

return start_node
