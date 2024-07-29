local configuration = {
    verbose_logging = settings.startup["pypp-verbose-logging"].value,
}

local deque = require "prototypes.new_auto_tech.data.deque"

local node_types = require "prototypes.new_auto_tech.node_types"

local ammo_category_node = require "prototypes.new_auto_tech.ammo_category_node"
local electricity_node = require "prototypes.new_auto_tech.electricity_node"
local entity_node = require "prototypes.new_auto_tech.entity_node"
local equipment_grid_node = require "prototypes.new_auto_tech.equipment_grid_node"
local fluid_fuel_node = require "prototypes.new_auto_tech.fluid_fuel_node"
local fluid_node = require "prototypes.new_auto_tech.fluid_node"
local fuel_category_node = require "prototypes.new_auto_tech.fuel_category_node"
local item_node = require "prototypes.new_auto_tech.item_node"
local recipe_category_node = require "prototypes.new_auto_tech.recipe_category_node"
local recipe_node = require "prototypes.new_auto_tech.recipe_node"
local resource_category_node = require "prototypes.new_auto_tech.resource_category_node"
local start_node = require "prototypes.new_auto_tech.start_node"
local technology_node = require "prototypes.new_auto_tech.technology_node"

local auto_tech = {}
auto_tech.__index = auto_tech

function auto_tech.create()
    local a = {}
    setmetatable(a, auto_tech)

    a.nodes_per_node_type = {}

    return a
end

function auto_tech:run_phase(phase_function, phase_name)
    log("Starting " .. phase_name)
    phase_function(self)
    log("Finished " .. phase_name)
end

function auto_tech:run()
    -- TODO:
    -- armor and gun stuff, military entities
    -- ignore soot results
    -- miner with fluidbox
    -- resources on map
    -- fluid boxes on crafting entities
    -- modules on crafting entities
    -- robots and roboports
    -- heat
    -- labs
    -- temperatures for fluids, boilers
    -- techs enabled at start

    -- nodes to finish:
    -- tech

    -- nodes finished:
    -- recipe
    -- item
    -- fluid
    -- resource

    self:run_phase(function()
        self:run_phase(self.create_nodes, "recipe graph node creation")
        self:run_phase(self.link_nodes, "recipe graph link creation")
        self:run_phase(self.linearise_recipe_graph, "recipe graph linearisation")
        self:run_phase(self.verify_end_tech_reachable, "verify end tech reachable")
        self:run_phase(self.construct_tech_graph, "constructing tech graph")
        self:run_phase(self.linearise_tech_graph, "tech graph linearisation")
        self:run_phase(self.calculate_transitive_reduction, "transitive reduction calculation")
        self:run_phase(self.adapt_tech_links, "adapting tech links")
        self:run_phase(self.set_tech_costs, "tech cost setting")
    end, "autotech")
end

function auto_tech:create_nodes()
    for _, node_type in pairs(node_types) do
        self.nodes_per_node_type[node_type] = {}
    end

    start_node:create(self.nodes_per_node_type, configuration)
    electricity_node:create(self.nodes_per_node_type, configuration)
    fluid_fuel_node:create(self.nodes_per_node_type, configuration)

    local function process_type(table, node_type)
        for _, object in pairs(table) do
            node_type:create(object, self.nodes_per_node_type, configuration)
        end
    end

    process_type(data.raw["ammo-category"], ammo_category_node)
    process_type(data.raw["equipment-grid"], equipment_grid_node)
    process_type(data.raw["fluid"], fluid_node)
    process_type(data.raw["fuel-category"], fuel_category_node)
    process_type(data.raw["recipe-category"], recipe_category_node)
    process_type(data.raw["recipe"], recipe_node)
    process_type(data.raw["resource-category"], resource_category_node)
    process_type(data.raw["resource"], entity_node)
    process_type(data.raw["technology"], technology_node)

    process_type(data.raw["armor"], item_node)
    process_type(data.raw["ammo"], item_node)
    process_type(data.raw["capsule"], item_node)
    process_type(data.raw["gun"], item_node)
    process_type(data.raw["item"], item_node)
    process_type(data.raw["item-with-entity-data"], item_node)
    process_type(data.raw["item-with-inventory"], item_node)
    process_type(data.raw["item-with-label"], item_node)
    process_type(data.raw["item-with-tags"], item_node)
    process_type(data.raw["mining-tool"], item_node)
    process_type(data.raw["module"], item_node)
    process_type(data.raw["spidertron-remote"], item_node)
    process_type(data.raw["rail-planner"], item_node)
    process_type(data.raw["repair-tool"], item_node)
    process_type(data.raw["tool"], item_node)

    for entity_name, _ in pairs(defines.prototypes.entity) do
        for _, value in pairs(data.raw[entity_name]) do
            entity_node:create(value, self.nodes_per_node_type, configuration)
        end
    end
end

function auto_tech:link_nodes()
    for _, node_type in pairs(self.nodes_per_node_type) do
        for _, node in pairs(node_type) do
            node:register_dependencies(self.nodes_per_node_type)
        end
    end
end

function auto_tech:linearise_recipe_graph()
    local verbose_logging = configuration.verbose_logging
    local q = deque.new()
    for _, node_type in pairs(self.nodes_per_node_type) do
        for _, node in pairs(node_type) do
            if node:has_no_more_dependencies() then
                q:push_right(node)
                if verbose_logging then
                   log("Node " .. node.printable_name .. " starts with no dependencies.") 
                end
            end
        end
    end

    while (not q:is_empty()) do
        local next = q:pop_left()
        if verbose_logging then
           log("Node " .. next.printable_name .. " is next in the linearisation.") 
        end

        local newly_independent_nodes = next:release_dependents()
        for _, node in pairs(newly_independent_nodes) do
            q:push_right(node)
        end
    end

    for _, node_type in pairs(self.nodes_per_node_type) do
        for _, node in pairs(node_type) do
            if not node:has_no_more_dependencies() then
                log("Node " .. node.printable_name .. " still has unresolved dependencies: " .. node:print_dependencies()) 
            end
        end
    end
end

function auto_tech:verify_end_tech_reachable()
    
end

function auto_tech:calculate_transitive_reduction()
    
end

function auto_tech:construct_tech_graph()
    
end

function auto_tech:linearise_tech_graph()
    
end

function auto_tech:adapt_tech_links()
    
end

function auto_tech:set_tech_costs()
    
end

return auto_tech
