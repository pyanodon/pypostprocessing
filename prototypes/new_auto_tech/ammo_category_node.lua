local object_node_base = require "prototypes.new_auto_tech.object_node_base"
local node_types = require "prototypes.new_auto_tech.node_types"

local ammo_category_node = object_node_base:create_object_class("ammo category", node_types.ammo_category_node)

function ammo_category_node:register_dependencies(nodes)
end

return ammo_category_node
