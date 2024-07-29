local object_node_base = require "prototypes.new_auto_tech.object_node_base"
local node_types = require "prototypes.new_auto_tech.node_types"
local entity_verbs = require "prototypes.new_auto_tech.entity_verbs"
local item_verbs = require "prototypes.new_auto_tech.item_verbs"
local fuel_category_verbs = require "prototypes.new_auto_tech.fuel_category_verbs"

local item_node = object_node_base:create_object_class("item", node_types.item_node)

function item_node:register_dependencies(nodes)
    local item = self.object
    self:add_disjunctive_dependent(nodes, node_types.entity_node, item.place_result, "place result", entity_verbs.instantiate)
    --placed_as_equipment_result optional 	:: EquipmentID 
    self:add_disjunctive_dependent(nodes, node_types.fuel_category_node, item.fuel_category, "fuel category", fuel_category_verbs.instantiate)
    self:add_disjunctive_dependent(nodes, node_types.item_node, item.burnt_result, "burnt result", item_verbs.create)
    self:add_productlike_disjunctive_dependent(nodes, item.rocket_launch_product, item.rocket_launch_products, "rocket launch product")

    --AmmoItemPrototype - 'ammo' 
    --GunPrototype - 'gun' 
    --ArmorPrototype - 'armor' 
end

return item_node
