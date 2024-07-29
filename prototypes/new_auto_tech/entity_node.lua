local object_node_base = require "prototypes.new_auto_tech.object_node_base"
local node_types = require "prototypes.new_auto_tech.node_types"
local entity_verbs = require "prototypes.new_auto_tech.entity_verbs"
local resource_category_verbs = require "prototypes.new_auto_tech.resource_category_verbs"
local recipe_category_verbs = require "prototypes.new_auto_tech.recipe_category_verbs"
local item_verbs = require "prototypes.new_auto_tech.item_verbs"
local fluid_verbs = require "prototypes.new_auto_tech.fluid_verbs"
local electricity_verbs = require "prototypes.new_auto_tech.electricity_verbs"

local entity_node = object_node_base:create_object_class("entity", node_types.entity_node)

function entity_node:register_dependencies(nodes)
    local entity = self.object

    if entity.type == "resource" then
        self:add_dependency(nodes, node_types.resource_category_node, entity.category or "basic-solid", "resource category", "mine")
    elseif entity.type == "mining-drill" then
        self:add_disjunctive_dependent(nodes, node_types.resource_category_node, entity.resource_categories, "can mine", resource_category_verbs.instantiate)
    elseif entity.type == "offshore-pump" then
        self:add_disjunctive_dependent(nodes, node_types.fluid_node, entity.fluid, "pumps", fluid_verbs.create)
    end
    local minable = entity.minable
    if minable ~= nil then
        self:add_dependency(nodes, node_types.fluid_node, minable.required_fluid, "required fluid", "mine")
        self:add_productlike_disjunctive_dependent(nodes, minable.result, minable.results, "mining result")
    end
    self:add_disjunctive_dependent(nodes, node_types.entity_node, entity.remains_when_mined, "remains when mined", entity_verbs.instantiate)
    self:add_disjunctive_dependency(nodes, node_types.item_node, entity.placeable_by, "placeable by", entity_verbs.instantiate, "item")
    self:add_disjunctive_dependent(nodes, node_types.item_node, entity.loot, "loot", item_verbs.create, "item")
    self:add_disjunctive_dependent(nodes, node_types.entity_node, entity.corpse, "corpse", entity_verbs.instantiate)
    if entity.energy_usage then
        self:add_dependency(nodes, node_types.electricity_node, 1, "requires electricity", "power")
    end
    if entity.energy_source then
        local energy_source = entity.energy_source
        local type = energy_source.type
        if type == "electric" then
            self:add_disjunctive_dependent(nodes, node_types.electricity_node, 1, "generates electricity", electricity_verbs.generate)
        elseif type == "burner" then
            self:add_disjunctive_dependency(nodes, node_types.fuel_category_node, energy_source.fuel_category, "requires fuel", entity_verbs.fuel)
            self:add_disjunctive_dependency(nodes, node_types.fuel_category_node, energy_source.fuel_categories, "requires fuel", entity_verbs.fuel)
        elseif type == "heat" then
        elseif type == "fluid" then
        else
            assert(type == "void", "Unknown energy source type")
        end
    end
    self:add_disjunctive_dependency(nodes, node_types.fuel_category_node, entity.burner, "requires fuel", entity_verbs.fuel, "fuel_category")
    self:add_disjunctive_dependent(nodes, node_types.recipe_category_node, entity.crafting_categories, "can craft", recipe_category_verbs.instantiate)
    --fluid_boxes
    --allowed_effects, module_specification
    --inputs (labs)
end

return entity_node
