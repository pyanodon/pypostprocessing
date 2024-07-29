local object_node_base = require "prototypes.new_auto_tech.object_node_base"
local node_types = require "prototypes.new_auto_tech.node_types"
local item_verbs = require "prototypes.new_auto_tech.item_verbs"
local recipe_verbs = require "prototypes.new_auto_tech.recipe_verbs"

local technology_node = object_node_base:create_object_class("technology", node_types.technology_node)

function technology_node:register_dependencies(nodes)
    local tech = self.object
    local tech_data = (type(tech.normal) == "table" and (tech.normal or tech.expensive) or tech)

    self:add_dependency(nodes, node_types.technology_node, tech_data.prerequisites, "prerequisite", "enable")

    for _, modifier in pairs(tech_data.effects or {}) do
        if modifier.type == "give-item" then
            self:add_disjunctive_dependent(nodes, node_types.item_node, modifier.item, "given by tech", item_verbs.create)
        elseif modifier.type == "unlock-recipe" then
            self:add_disjunctive_dependent(nodes, node_types.recipe_node, modifier.recipe, "enabled by tech", recipe_verbs.enable)
        end
    end
end

return technology_node
