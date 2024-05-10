local table = require "__stdlib__.stdlib.utils.table"
local string = require "__stdlib__.stdlib.utils.string"

local config = require "prototypes.config"
local fz_graph = require "prototypes.functions.fuzzy_graph"
local py_utils = require "prototypes.functions.utils"

local data_parser = {}
data_parser.__index = data_parser

local FUEL_FLUID = "fluid"
local FUEL_ELECTRICITY = "electricity"
local FUEL_HEAT = "heat"

local RECIPE_PREFIX_START = "start:"
local RECIPE_PREFIX_BURNT = "burnt:"
local RECIPE_PREFIX_BOILER = "boiler:"
local RECIPE_PREFIX_GENERATOR = "generator:"
local RECIPE_PREFIX_OFFSHORE = "offshore:"
local RECIPE_PREFIX_REACTOR = "reactor:"
local RECIPE_PREFIX_MINING = "mining:"
local RECIPE_PREFIX_ROCKET = "rocket-product:"

local LABEL_RECIPE_RESULT = "__recipe_result__"
local LABEL_MODULE = "__module__"
local LABEL_FUEL = "__fuel__"
local LABEL_RAIL = "__rail__"
local LABEL_LOCO = "__locomotive__"
local LABEL_PUMP = "__pump__"
local LABEL_TRAINSTOP = "__trainstop__"
local LABEL_CRAFTING_MACHINE = "__crafting__"
local LABEL_BONUS = "__bonus__"
local LABEL_GRID = "__grid__"
local LABEL_UNLOCK_RECIPE = "__unlock_recipe__"
local LABEL_TECH_FINISH = "__tech_finish__"


function data_parser.create()
    local d = {}
    setmetatable(d, data_parser)

    d.techs = {}
    d.recipes = {}
    d.items = {}
    d.fluids = {}
    d.entities = {}
    d.science_packs = {}
    d.mining_categories = {}
    d.crafting_categories = {}
    d.module_categories = {}
    d.fuel_categories = {}
    d.fuel_burners = {}
    d.heat_temps = {}
    d.placed_by = {}
    d.place_result = {}
    d.items_with_grid = {}
    d.entities_with_grid = {}
    d.processed_recipes = {}
    d.processed_items = {}
    d.processed_fluids = {}
    d.processed_techs = {}

    return d
end


function data_parser:run()
    self:pre_process()

    self.fg = fz_graph.create()

    -- electricity
    self.fg:add_node(FUEL_ELECTRICITY, fz_graph.NT_ITEM, { virtual = true })
    py_utils.insert_double_lookup(self.fuel_categories, FUEL_ELECTRICITY, FUEL_ELECTRICITY)

    -- heat
    for _, temp in pairs(self.heat_temps) do
        local node = self:parse_fluid(FUEL_HEAT, temp, { virtual = true })
        py_utils.insert_double_lookup(self.fuel_categories, FUEL_HEAT, node.name)
    end

    -- starting entities
    for _, entity_name in pairs(config.STARTING_ENTITIES:enumerate()) do
        local entity = py_utils.get_prototype("entity", entity_name, true)

        if entity and self.placed_by[entity_name] then
            for item_name, _ in pairs(self.placed_by[entity_name]) do
                config.STARTING_ITEMS:add(item_name)

                if not py_utils.get_prototype("item", item_name, true) then
                    self.fg:add_node(item_name, fz_graph.NT_ITEM, { virtual = true })
                end
            end
        end
    end

    -- starting items
    for _, item_name in pairs(config.STARTING_ITEMS:enumerate()) do
        local item = py_utils.get_prototype("item", item_name, true)

        if item or self.fg:node_exists(item_name, fz_graph.NT_ITEM) then
            local recipe = {
                name = RECIPE_PREFIX_START .. item_name,
                ingredients = {},
                results = {{ type = "item", name = item_name, amount = 1 }}
            }

            local node = self:parse_recipe(fz_graph.START_NODE_NAME, recipe, true)
            self.fg:add_link(self.fg.start_node, node, LABEL_UNLOCK_RECIPE)
        end
    end

    -- starting recipes
    for _, recipe in pairs(data.raw.recipe) do
        if (recipe.normal and (recipe.normal.enabled == nil or recipe.normal.enabled == true)) or (not recipe.normal and (recipe.enabled == nil or recipe.enabled == true)) then
            local node = self:parse_recipe(not recipe.ignore_for_dependencies and fz_graph.START_NODE_NAME or nil, recipe)

            if not recipe.ignore_for_dependencies then
                self.fg:add_link(self.fg.start_node, node, LABEL_UNLOCK_RECIPE)
            end
        end
    end

    -- minable entities
    for _, entity in py_utils.iter_prototypes("entity") do
        if (entity.script_autoplace or entity.autoplace) and entity.minable and (entity.minable.result or entity.minable.results) then
            self:add_mining_recipe(entity)
        end
    end

    -- technologies
    for _, tech in pairs(data.raw.technology) do
        if tech.enabled ~= false and not tech.hidden then
            self:parse_tech(tech)
        end
    end

    return self.fg
end


function data_parser:parse_recipe(tech_name, recipe, no_crafting)
    local name = (tech_name and (tech_name .. " / ") or "") .. recipe.name
    local node = self.fg:add_node(name, fz_graph.NT_RECIPE,
        { tech_name = tech_name, factorio_name = (not recipe.virtual and recipe.name), virtual = recipe.virtual })

    if self.processed_recipes[name] then
        return node
    else
        self.processed_recipes[name] = true
    end

    node.ignore_for_dependencies = (not self.recipes[recipe.name] or node.virtual or recipe.ignore_for_dependencies or false)

    local ing_count = 0
    local fluid_in = 0
    local fluid_out = 0
    local ingredients = {}

    local recipe_data = (type(recipe.normal) == "table" and recipe.normal or recipe)

    for _, ing in pairs(py_utils.standardize_products(recipe_data.ingredients)) do
        if ing.type == "item" then
            local item = py_utils.get_prototype("item", ing.name)
            local node_item = self:parse_item(item)
            self.fg:add_link(node_item, node, ing.name)
            ing_count = ing_count + 1
            ingredients[ing.name] = true
        else
            local fluid = data.raw.fluid[ing.name]

            if fluid then
                ingredients[ing.name] = {}
                node:add_label(ing.name)

                for temp, _ in pairs(self.fluids[ing.name] or { data.raw.fluid[ing.name].default_temperature }) do
                    if (not ing.temperature or ing.temperature == temp)
                        and (not ing.min_temperature or ing.min_temperature <= temp)
                        and (not ing.max_temperature or ing.max_temperature >= temp)
                    then
                        local node_fluid = self:parse_fluid(ing.name, temp)
                        self.fg:add_link(node_fluid, node, ing.name)
                        ingredients[ing.name][temp] = true
                    end
                end

                fluid_in = fluid_in + 1
            end
       end
    end

    if (recipe.unlock_results ~= false) and not recipe.ignore_in_pypp then
        for _, res in pairs(py_utils.standardize_products(recipe_data.results, nil, recipe_data.result, recipe_data.result_count)) do
            if res.type == "item" then
                self:add_recipe_result_item(res.name, recipe.name, node, ingredients)
            elseif res.type == "fluid" then
                local fluid = data.raw.fluid[res.name]
                local temp = res.temperature or (fluid and fluid.default_temperature)

                if not ingredients[res.name] or table.any(ingredients[res.name], function (_, t) return t ~= temp end) then
                    local node_fluid

                    if fluid or (res.temperature and self.fg:node_exists(data_parser.get_fluid_name(res.name, res.temperature), fz_graph.NT_FLUID)) then
                        node_fluid = self:parse_fluid(res.name, res.temperature)
                    end

                    if node_fluid then
                        if ingredients[res.name] and ingredients[res.name][temp] then
                            self.fg:remove_link(node_fluid, node)
                        end

                        self.fg:add_link(node, node_fluid, LABEL_RECIPE_RESULT)

                        if not node_fluid.virtual then
                            fluid_out = fluid_out + 1
                        end

                        node_fluid:inherit_ignore_for_dependencies(node)
                    end
                end
            end
        end
    end

    if not no_crafting then
        local category = recipe.category or "crafting"
        local found = false

        if self.crafting_categories[category] then
            for _, craft in pairs(self.crafting_categories[category]) do
                if craft.ingredient_count >= ing_count and craft.fluidboxes_in >= fluid_in and craft.fluidboxes_out >= fluid_out then
                    self:add_crafting_machine_link(node, craft.entity_name)
                    found = true
                end
            end
        end

        if not found and not recipe.ignore_for_dependencies then
            error("\n\nERROR: Missing crafting category: " .. category .. " (ingredients: " .. ing_count .. ", fluids in: " .. fluid_in .. ", fluids out:" .. fluid_out .. "), for " .. name .. "\n", 0)
        end
    end

    self:add_module_dependencies(node, recipe)

    return node
end


function data_parser:add_recipe_result_item(item_name, recipe_name, recipe_node, ingredients)
    if not ingredients[item_name]
        and (not config.PRIMARY_PRODUCTION_RECIPE[item_name] or config.PRIMARY_PRODUCTION_RECIPE[item_name] == recipe_name)
    then
        local node_item = self.fg:add_node(item_name, fz_graph.NT_ITEM)
        local item

        if not node_item.virtual then
            item = py_utils.get_prototype("item", item_name)
            node_item = self:parse_item(item)
        end

        self.fg:add_link(recipe_node, node_item, LABEL_RECIPE_RESULT)

        for entity_name, _ in pairs(self.place_result[item_name] or {}) do
            local entity  = py_utils.get_prototype("entity", entity_name)
            self:add_entity_dependencies(entity, recipe_node, recipe_name, item, ingredients)
        end

        if item and (item.rocket_launch_products or item.rocket_launch_product) then
            self:add_rocket_product_recipe(item)
        end

        node_item:inherit_ignore_for_dependencies(recipe_node)
    end
end


function data_parser:parse_tech(tech)
    local node = self.fg:add_node(tech.name, fz_graph.NT_TECH_HEAD, { tech_name = tech.name, factorio_name = tech.name })

    if self.processed_techs[tech.name] then
        return node
    else
       self.processed_techs[tech.name] = true
    end

    if not self.techs[tech.name] then
        node.ignore_for_dependencies = true
        return node
    end

    node.ignore_for_dependencies = tech.ignore_for_dependencies

    -- Hard coded dependencies
    -- for _, dep in pairs(tech.dependencies or {}) do
    --     if data.raw.technology[dep] then
    --         local n_parent = self.fg:add_node(dep, fz_graph.NT_TECH_TAIL)
    --         self.fg:add_link(n_parent, node)
    --     else
    --         error("\n\nInvalid tech dependency: " .. dep .. "\nSource: " .. tech.name .. "\n")
    --     end
    -- end

    local packs = {}
    -- Science packs
    for _, ing in pairs(py_utils.standardize_products(tech.unit.ingredients)) do
        local item = py_utils.get_prototype(fz_graph.NT_ITEM, ing.name)
        local n_item = self:parse_item(item)
        self.fg:add_link(n_item, node, ing.name)
        table.insert(packs, ing.name)
        py_utils.insert_double_lookup(self.science_packs, ing.name, tech.name)
    end

    node:add_label(LABEL_CRAFTING_MACHINE)
    local found_lab = false

    for _, lab in pairs(data.raw.lab) do
        local inputs = table.array_to_dictionary(lab.inputs)

        if table.all(packs, function(p) return inputs[p] end) then
            for item, _ in pairs(self.placed_by[lab.name] or {}) do
                local item_node = self.fg:add_node(item, fz_graph.NT_ITEM)
                self.fg:add_link(item_node, node, LABEL_CRAFTING_MACHINE)
                found_lab = true
            end
        end
    end

    if not found_lab then
        error("\n\nNo suitable lab found to research tech: " .. node.name .. "\n", 0)
    end

    -- Recipes
    for _, effect in pairs(tech.effects or {}) do
        if effect.type == "unlock-recipe" then
            local recipe = data.raw.recipe[effect.recipe]

            if recipe then
                local n_recipe = self:parse_recipe(not recipe.ignore_for_dependencies and tech.name or nil, recipe)

                if not recipe.ignore_for_dependencies then
                    self.fg:add_link(node, n_recipe, LABEL_UNLOCK_RECIPE)
                end
            end
        -- Bonuses require at least on entity where they can be applied
        elseif effect.type == "inserter-stack-size-bonus" then
            self:add_bonus_dependencies(node, effect, "inserter", function(e) return not e.stack end)
        elseif effect.type == "stack-inserter-capacity-bonus" then
            self:add_bonus_dependencies(node, effect, "inserter", function(e) return e.stack end)
        elseif effect.type == "laboratory-speed" or effect.type == "laboratory-productivity" then
            self:add_bonus_dependencies(node, effect, "lab")
        elseif effect.type == "mining-drill-productivity-bonus" then
            self:add_bonus_dependencies(node, effect, "mining-drill")
        elseif effect.type == "train-braking-force-bonus" then
            self:add_bonus_dependencies(node, effect, "locomotive")
        elseif effect.type == "maximum-following-robots-count" or effect.type == "follower-robot-lifetime" then
            self:add_bonus_dependencies(node, effect, "combat-robot", function(e) return e.follows_player end)
        elseif effect.type == "worker-robot-speed" or effect.type == "worker-robot-storage" or effect.type == "worker-robot-battery" then
            self:add_bonus_dependencies(node, effect, "construction-robot")
            self:add_bonus_dependencies(node, effect, "logistic-robot")
        elseif effect.type == "character-logistic-requests" or effect.type == "character-logistic-trash-slots" then
            self:add_bonus_dependencies(node, effect, "logistic-robot")
        elseif effect.type == "artillery-range" then
            self:add_bonus_dependencies(node, effect, "artillery-turret")
            self:add_bonus_dependencies(node, effect, "artillery-wagon")
        elseif effect.type == "turret-attack" then
            self:add_bonus_dependencies(node, effect, "ammo-turret", function(e) return e.name == effect.turret_id end, false, effect.turret_id)
            self:add_bonus_dependencies(node, effect, "electric-turret", function(e) return e.name == effect.turret_id end, false, effect.turret_id)
            self:add_bonus_dependencies(node, effect, "fluid-turret", function(e) return e.name == effect.turret_id end, false, effect.turret_id)
        elseif effect.type == "ammo-damage" or effect.type == "gun-speed" then
            self:add_bonus_dependencies(node, effect, "ammo", function (i) return
                (i.ammo_type.category and i.ammo_type.category == effect.ammo_category)
                or not i.ammo_type.category and table.any(i.ammo_type, function (at) return at.category == effect.ammo_category end)
            end, true, effect.ammo_category)
            self:add_bonus_dependencies(node, effect, "capsule", function (i) return
                i.capsule_action.attack_parameters and
                ((i.capsule_action.attack_parameters.ammo_type.category and i.capsule_action.attack_parameters.ammo_type.category == effect.ammo_category)
                or not i.capsule_action.attack_parameters.ammo_type.category and table.any(i.capsule_action.attack_parameters.ammo_type, function (at) return at.category == effect.ammo_category end))
            end, true, effect.ammo_category)
            self:add_bonus_dependencies(node, effect, "electric-turret", function (e) return
                (e.attack_parameters.ammo_type.category and e.attack_parameters.ammo_type.category == effect.ammo_category)
                or not e.attack_parameters.ammo_type.category and table.any(e.attack_parameters.ammo_type, function (at) return at.category == effect.ammo_category end)
            end, false, effect.ammo_category)
            self:add_bonus_dependencies(node, effect, "land-mine", function (e) return ((e.ammo_category or "") == effect.ammo_category) end, false, effect.ammo_category)
        end
    end
end


function data_parser.get_fluid_name(fluid_name, temperature)
    if not temperature then
        temperature = data.raw.fluid[fluid_name].default_temperature
    end

    return fluid_name .. "(" .. temperature .. ")"
end


function data_parser:parse_fluid(fluid_name, temperature, properties)
    local fluid = data.raw.fluid[fluid_name]

    if fluid then
        if not properties then
            properties = {}
        end

        properties.factorio_name = fluid_name
    end

    local name = data_parser.get_fluid_name(fluid_name, temperature)
    local node = self.fg:add_node(name, fz_graph.NT_FLUID, properties)

    if self.processed_fluids[name] then
        return node
    else
        self.processed_fluids[name] = true
    end

    if not self.fluids[fluid_name] then
        node.ignore_for_dependencies = true
    else
        node.ignore_for_dependencies = fluid and fluid.ignore_for_dependencies
    end

    return node
end


function data_parser:parse_item(item)
    local node = self.fg:add_node(item.name, fz_graph.NT_ITEM, { factorio_name = item.name })

    if self.processed_items[item.name] then
        return node
    else
        self.processed_items[item.name] = true
    end

    if not self.items[item.name] then
        node.ignore_for_dependencies = true
    else
        node.ignore_for_dependencies = item.ignore_for_dependencies
    end

    if item.fuel_category and item.burnt_result then
        self:add_burnt_result_recipe(item)
    end

    if item.place_result then
        local entity = py_utils.get_prototype("entity", item.place_result)

        if entity.type == "boiler" then
            self:add_boiler_recipe(entity)
        elseif entity.type == "generator" then
            self:add_generator_recipe(entity)
        elseif entity.type == "burner-generator" then
            self:add_simple_generator_recipe(entity)
        elseif entity.type == "electric-energy-interface" and entity.energy_production and util.parse_energy(entity.energy_production) > 0 then
            self:add_simple_generator_recipe(entity)
        elseif entity.type == "offshore-pump" then
            self:add_offhsore_pump_recipe(entity)
        elseif entity.type == "reactor" then
            self:add_reactor_recipe(entity)
        end
    end

    return node
end


function data_parser:add_module_dependencies(node, recipe)
    local category = data.raw["recipe-category"][recipe.category or "crafting"]

    if category.modules_required and category.allowed_module_categories then
        node:add_label(LABEL_MODULE)

        for _, mod_cat in pairs(category.allowed_module_categories) do
            for module, _ in pairs(self.module_categories[mod_cat]) do
                local node_module = self.fg:add_node(module, fz_graph.NT_ITEM)
                self.fg:add_link(node_module, node, LABEL_MODULE)
            end
        end
    end
end


function data_parser:add_entity_dependencies(entity, recipe_node, recipe_name, item, ingredients)
    -- Fuel dependencies
    local energy_source = entity.burner or entity.energy_source

    if energy_source then
        if energy_source.type == "burner" then
            recipe_node:add_label(LABEL_FUEL)

            for _, category in pairs(energy_source.fuel_categories or { (energy_source.fuel_category or "chemical") }) do
                for fuel, _ in pairs(self.fuel_categories[category] or {}) do
                    local fuel_node = self.fg:add_node(fuel, fz_graph.NT_ITEM)
                    self.fg:add_link(fuel_node, recipe_node, LABEL_FUEL)
                end
            end
        elseif energy_source.type == "fluid" and energy_source.fluid_box.filter ~= "void" then
            recipe_node:add_label(LABEL_FUEL)

            local fluid_name = energy_source.fluid_box.filter
            local fluids = energy_source.burns_fluid and self.fuel_categories[FUEL_FLUID] or self.fluids

            for fluid, _ in pairs(fluids) do
                if not fluid_name or fluid == fluid_name then
                    for temp, _ in pairs(self.fluids[fluid]) do
                        if temp >= (energy_source.fluid_box.minimum_temperature or temp) and temp <= (energy_source.fluid_box.minimum_temperature or temp) then
                            local fuel_node = self:parse_fluid(fluid, temp)
                            self.fg:add_link(fuel_node, recipe_node, LABEL_FUEL)
                        end
                    end
                end
            end
        end
    end

    -- Fixed recipe
    if entity.fixed_recipe and recipe_node.tech_name then
        local fixed_recipe = data.raw.recipe[entity.fixed_recipe]
        if fixed_recipe then
            local fixed_node = self:parse_recipe(recipe_node.tech_name, fixed_recipe)
            local tech = self.fg:get_node(recipe_node.tech_name, fz_graph.NT_TECH_HEAD)
            self.fg:add_link(tech, fixed_node, LABEL_UNLOCK_RECIPE)
        end
    end

    if entity.minable then
        for _, res in pairs(py_utils.standardize_products(entity.minable.results, nil, entity.minable.result, entity.minable.count)) do
            if res.type == "item" and res.name ~= nil and res.name ~= item.name then
                self:add_recipe_result_item(res.name, recipe_name, recipe_node, ingredients)
            end
        end
    end

    -- Rail stuff need rails
    if entity.type == "locomotive"
        or entity.type == "cargo-wagon"
        or entity.type == "fluid-wagon"
        or entity.type == "artillery-wagon"
        or entity.type == "train-stop"
        or entity.type == "rail-signal"
        or entity.type == "rail-chain-signal"
    then
        recipe_node:add_label(LABEL_RAIL)

        for i, _ in pairs(data.raw["rail-planner"] or {}) do
            if self.items[i] then
                local r = self.fg:add_node(i, fz_graph.NT_ITEM)
                self.fg:add_link(r, recipe_node, LABEL_RAIL)
            end
        end
    end

    -- Wagons need loco
    if entity.type == "cargo-wagon" or entity.type == "fluid-wagon" or entity.type == "artillery-wagon" then
        recipe_node:add_label(LABEL_LOCO)

        for loco, _ in pairs(data.raw.locomotive or {}) do
            if self.entities[loco] then
                for i, _ in pairs(self.placed_by[loco] or {}) do
                    local l = self.fg:add_node(i, fz_graph.NT_ITEM)
                    self.fg:add_link(l, recipe_node, LABEL_LOCO)
                end
            end
        end
    end

    -- Fluid wagons need pumps
    if entity.type == "fluid-wagon" then
        recipe_node:add_label(LABEL_PUMP)

        for pump, _ in pairs(data.raw.pump or {}) do
            if self.entities[pump] then
                for i, _ in pairs(self.placed_by[pump] or {}) do
                    local l = self.fg:add_node(i, fz_graph.NT_ITEM)
                    self.fg:add_link(l, recipe_node, LABEL_PUMP)
                end
            end
        end
    end

    -- Signals need stations
    if entity.type == "rail-signal" or entity.type == "rail-chain-signal" then
        recipe_node:add_label(LABEL_TRAINSTOP)

        for ts, _ in pairs(data.raw["train-stop"] or {}) do
            if self.entities[ts] then
                for i, _ in pairs(self.placed_by[ts] or {}) do
                    local l = self.fg:add_node(i, fz_graph.NT_ITEM)
                    self.fg:add_link(l, recipe_node, LABEL_TRAINSTOP)
                end
            end
        end
    end
end


function data_parser:add_burnt_result_recipe(item)
    local recipe = {
        name = RECIPE_PREFIX_BURNT .. item.name,
        ingredients = {{ type = fz_graph.NT_ITEM, name = item.name, amount = 1 }},
        results = {{ type = fz_graph.NT_ITEM, name = item.burnt_result, amount = 1 }},
        ignore_for_dependencies = true,
        virtual = true
    }

    local node = self:parse_recipe(nil, recipe, true)
    node:add_label(LABEL_CRAFTING_MACHINE)

    for entity_name, _ in pairs(self.fuel_burners[item.fuel_category] or {}) do
        local burner = py_utils.get_prototype("entity", entity_name)
        local energy_source = burner.burner or burner.energy_source

        if energy_source and (energy_source.burnt_inventory_size or 0) > 0 then
            self:add_crafting_machine_link(node, entity_name)
        end
    end

    return node
end


function data_parser:add_crafting_machine_link(recipe_node, entity_name)
    for item, _ in pairs(self.placed_by[entity_name] or {}) do
        local crafter_node = self.fg:add_node(item, fz_graph.NT_ITEM)
        self.fg:add_link(crafter_node, recipe_node, LABEL_CRAFTING_MACHINE)
    end
end


function data_parser:add_boiler_recipe(boiler)
    if (boiler.mode or "heat-water-inside") == "output-to-separate-pipe" then
        local out_fluid = boiler.output_fluid_box and boiler.output_fluid_box.filter or boiler.fluid_box.filter
        local in_fluid = boiler.fluid_box.filter

        if out_fluid and in_fluid then
            local recipe = {
                name = RECIPE_PREFIX_BOILER .. boiler.name,
                ingredients = {{ type = "fluid", name = in_fluid, amount = 1, minimum_temperature = boiler.fluid_box.minimum_temperature, maximum_temperature = boiler.fluid_box.maximum_temperature }},
                results = {{ type = "fluid", name = out_fluid, amount = 1, temperature = boiler.target_temperature }},
                virtual = true
            }

            local node = self:parse_recipe(nil, recipe, true)
            self:add_crafting_machine_link(node, boiler.name)

            return node
        else
            error("ERROR: Unsupported feature: Unfiltered boiler")
        end
    else
        local fluid = boiler.fluid_box.filter

        if fluid then
            local recipe = {
                name = RECIPE_PREFIX_BOILER .. boiler.name,
                ingredients = {{
                    type = "fluid",
                    name = fluid, amount = 1,
                    minimum_temperature = boiler.fluid_box.minimum_temperature,
                    maximum_temperature = math.min (boiler.fluid_box.maximum_temperature or data.raw.fluid[fluid].max_temperature, data.raw.fluid[fluid].max_temperature - 1) }},
                results = {{ type = "fluid", name = fluid, amount = 1, temperature = data.raw.fluid[fluid].max_temperature }},
                virtual = true
            }

            local node = self:parse_recipe(nil, recipe, true)
            self:add_crafting_machine_link(node, boiler.name)

            return node
        else
            error("ERROR: Unsupported feature: Unfiltered boiler")
        end
    end
end


function data_parser:add_generator_recipe(generator)
    local in_fluid = generator.fluid_box.filter
    local node

    local recipe = {
        name = RECIPE_PREFIX_GENERATOR .. generator.name,
        ingredients = {},
        results = {{ type = "item", name = FUEL_ELECTRICITY, amount = 1 }},
        virtual = true
    }

    if not generator.burns_fluid then
        recipe.ingredients = {{ type = "fluid", name = in_fluid, amount = 1, minimum_temperature = generator.fluid_box.minimum_temperature, maximum_temperature = generator.fluid_box.maximum_temperature }}
    end

    node = self:parse_recipe(nil, recipe, true)

    if generator.burns_fluid then
        self:add_fluid_fuels(node, in_fluid)
    end

    self:add_crafting_machine_link(node, generator.name)
end


function data_parser:add_offhsore_pump_recipe(pump)
    local recipe = {
        name = RECIPE_PREFIX_OFFSHORE .. pump.name,
        ingredients = {},
        results = {{ type = "fluid", name = pump.fluid, amount = pump.pumping_speed }},
        virtual = true
    }

    local node = self:parse_recipe(nil, recipe, true)
    self:add_crafting_machine_link(node, pump.name)

    return node
end


function data_parser:add_simple_generator_recipe(generator)
    local recipe = {
        name = RECIPE_PREFIX_GENERATOR .. generator.name,
        ingredients = {},
        results = {{ type = "item", name = FUEL_ELECTRICITY, amount = 1 }},
        virtual = true
    }

    local node = self:parse_recipe(nil, recipe, true)
    self:add_crafting_machine_link(node, generator.name)
end


function data_parser:add_reactor_recipe(reactor)
    local recipe = {
        name = RECIPE_PREFIX_REACTOR .. reactor.name,
        ingredients = {},
        results = {{ type = "fluid", name = FUEL_HEAT, amount = 1, temperature = reactor.heat_buffer.max_temperature }},
        virtual = true
    }

    local node = self:parse_recipe(nil, recipe, true)
    self:add_crafting_machine_link(node, reactor.name)
end


function data_parser:add_mining_recipe(entity)
    local recipe = {
        name = RECIPE_PREFIX_MINING .. entity.name,
        ingredients = entity.minable.required_fluid and {{ type = "fluid", name = entity.minable.required_fluid, amount = entity.minable.fluid_amount }} or {},
        results = entity.minable.results,
        result = entity.minable.result,
        result_count = entity.minable.count
    }

    local node = self:parse_recipe(nil, recipe, true)

    if entity.type == "resource" then
        local category = (entity.category or "basic-solid") .. (entity.minable.required_fluid and "+fluid" or "")

        if self.mining_categories[category] then
            for miner, _ in pairs(self.mining_categories[category]) do
                self:add_crafting_machine_link(node, miner)
            end
        end
    else
        self:add_crafting_machine_link(node, "character")
    end

    return node
end


function data_parser:add_bonus_dependencies(tech_node, effect, entity_type, condition, is_item, suffix)
    local recipe = { name = effect.type .. (suffix or ""), ingredients = {}, results = {}, virtual = true }
    local recipe_node = self:parse_recipe(tech_node.name, recipe, true)
    self.fg:add_link(tech_node, recipe_node, LABEL_UNLOCK_RECIPE)

    if entity_type then
        for _, entity in pairs(data.raw[entity_type] or {}) do
            if condition == nil or condition(entity) then
                if not is_item and self.entities[entity.name] then
                    for i, _ in pairs(self.placed_by[entity.name]) do
                        local item = self.fg:add_node(i, fz_graph.NT_ITEM)
                        self.fg:add_link(item, recipe_node, LABEL_BONUS)
                    end
                elseif self.items[entity.name] then
                    local item = self.fg:add_node(entity.name, fz_graph.NT_ITEM)
                    self.fg:add_link(item, recipe_node, LABEL_BONUS)
                end
            end
        end
    end
end


function data_parser:add_rocket_product_recipe(item)
    local recipe = {
        name = RECIPE_PREFIX_ROCKET .. item.name,
        ingredients = {{ type = "item", name = item.name, amount = 1 }},
        results = item.rocket_launch_products or { item.rocket_launch_product },
        virtual = true
    }

    local node = self:parse_recipe(nil, recipe, true)
    -- local tech_node = self.fg:add_node(tech_name or fz_graph.START_NODE_NAME, fz_graph.NT_TECH_HEAD)
    -- self.fg:add_link(tech_node, node)
    node:add_label(LABEL_CRAFTING_MACHINE)

    for _, entity in pairs(data.raw["rocket-silo"]) do
        if (entity.rocket_result_inventory_size or 0) > 0 and entity.fixed_recipe then
            local rocket = data.raw["rocket-silo-rocket"][entity.rocket_entity]

            if rocket and rocket.inventory_size > 0 then
                self:add_crafting_machine_link(node, entity.name)
            end
        end
    end

    return node
end


function data_parser:pre_process()
    -- Starter entities
    for _, e in pairs(config.STARTING_ENTITIES:enumerate()) do
        local entity = py_utils.get_prototype("entity", e, true)

        if entity then
            py_utils.insert_double_lookup(self.placed_by, entity.name, entity.name)
            self:pre_process_entity(entity)
        end
    end

    -- Starter items
    for _, i in pairs(config.STARTING_ITEMS:enumerate()) do
        local item = py_utils.get_prototype("item", i, true)

        if item then
            self:pre_process_item(item)
        end
    end

    -- Starter recipes
    for _, recipe in pairs(data.raw.recipe) do
        if (recipe.normal and recipe.normal.enabled ~= false) or (not recipe.normal and recipe.enabled ~= false) then
            self:pre_process_recipe(recipe)
        end
    end

    -- Minables
    for _, entity in py_utils.iter_prototypes("entity") do
        if (entity.script_autoplace or entity.autoplace) and entity.minable and (entity.minable.result or entity.minable.results) then
            self:pre_process_entity(entity)
        end
    end

    -- Techs
    self:pre_process_techs()
end


function data_parser:pre_process_techs()
    for _, tech in pairs(data.raw.technology) do
        if tech.enabled ~= false and not tech.hidden then
            -- log("Pre-processing tech: " .. tech.name)
            self.techs[tech.name] = true

            for _, effect in pairs(tech.effects or {}) do
                if effect.type == "unlock-recipe" then
                    local recipe = data.raw.recipe[effect.recipe]

                    if recipe then
                        self:pre_process_recipe(recipe)
                    end
                end
            end

            -- Add dependencies for tech names ending in numbers to the prev tier
            local split = string.split(tech.name, "-")
            local last = table.last(split)

            if string.is_digit(last) and tonumber(last) > 1 then
                split[#split] = tostring(tonumber(last) - 1)
                local prev_tech = string.join("-", split)

                if data.raw.technology[prev_tech] then
                    if not tech.dependencies then
                        tech.dependencies = {}
                    end

                    table.insert(tech.dependencies, prev_tech)
                end
            end

            -- for _, pre in pairs(tech.prerequisites or {}) do
            --     local pre_tech = data.raw.technology[pre]

            --     if pre_tech and not py_utils.is_py_or_base_tech(pre_tech) then
            --         if not tech.dependencies then
            --             tech.dependencies = {}
            --         end

            --         table.insert(tech.dependencies, pre)
            --     end
            -- end
        end
    end
end


function data_parser:pre_process_entity(entity)
    if self.entities[entity.name] then
        return
    end

    self.entities[entity.name] = entity

    if table.any(entity.flags or {}, function(v) return v == "hidden" end) and not config.STARTING_ENTITIES:contains(entity.name) then
        return
    end

    if entity.minable and (entity.minable.result or entity.minable.results) then
        for _, res in pairs(py_utils.standardize_products(entity.minable.results, nil, entity.minable.result, entity.minable.count)) do
            if res.type == "fluid" then
                local fluid = data.raw.fluid[res.name]

                if fluid then
                    self:pre_process_fluid(fluid, res.temperature)
                end
            else
                local item = py_utils.get_prototype("item", res.name)
                self:pre_process_item(item)
            end
        end
    end

    local fb_in = 0
    local fb_out = 0

    for _, fb in pairs(entity.fluid_boxes or {}) do
        if type(fb) == "table" then
            if fb.production_type == "input" or fb.production_type == "input-output" then
                fb_in = fb_in + 1
            elseif fb.production_type == "output" then
                fb_out = fb_out + 1
            end
        end
    end
    
    -- If handcraft is disabled, we fudge it by adding "crafting" to the real list
    local category_list
    if (entity.type == "character" 
        and entity.crafting_categories 
        and not table.invert(entity.crafting_categories)["crafting"])
    then
        category_list = table.array_combine(entity.crafting_categories, {"crafting"})
    else
        category_list = entity.crafting_categories or {}
    end

    for _, c in pairs(category_list) do
        if not self.crafting_categories[c] then
            self.crafting_categories[c] = {}
        end

        local craft = {}
        craft.crafting_category = c
        craft.ingredient_count = entity.ingredient_count or 255
        craft.fluidboxes_in = fb_in
        craft.fluidboxes_out = fb_out
        craft.entity_name = entity.name

        table.insert(self.crafting_categories[c], craft)
    end

    if entity.equipment_grid then
        self.entities_with_grid[entity.name] = data.raw["equipment-grid"][entity.equipment_grid]
    end

    local energy_source = entity.burner or entity.energy_source

    if energy_source and (entity.burner or energy_source.type == "burner") then
        for _, category in pairs(energy_source.fuel_categories or { (energy_source.fuel_category or "chemical") }) do
            py_utils.insert_double_lookup(self.fuel_burners, category, entity.name)
        end
    end

    if entity.type == "boiler" then
        local filter
        local temp

        if (entity.mode or "heat-water-inside") == "output-to-separate-pipe" then
            filter = entity.output_fluid_box.filter or entity.fluid_box.filter
            temp = entity.target_temperature
        else
            filter = entity.fluid_box.filter
            temp = data.raw.fluid[filter].max_temperature
        end

        if filter then
            local fluid = data.raw.fluid[filter]
            self:pre_process_fluid(fluid, temp)
        else
            error("ERROR: Unsupported feature: Unfiltered boiler")
        end
    elseif entity.type == "mining-drill" then
        for _, category in pairs(entity.resource_categories or {}) do
            py_utils.insert_double_lookup(self.mining_categories, category, entity.name)

            if entity.input_fluid_box then
                py_utils.insert_double_lookup(self.mining_categories, category .. "+fluid", entity.name)
            end
        end
    elseif entity.type == "character" then
        py_utils.insert_double_lookup(self.placed_by, entity.name, entity.name)

        for _, category in pairs(entity.mining_categories or {}) do
            py_utils.insert_double_lookup(self.mining_categories, category, entity.name)
        end
    elseif entity.type == "reactor" or entity.type == "heat-interface" then
        table.insert(self.heat_temps, entity.heat_buffer.max_temperature)
    end
end


function data_parser:pre_process_fluid(fluid, temperature)
    py_utils.insert_double_lookup(self.fluids, fluid.name, temperature or fluid.default_temperature)

    if fluid.fuel_value and util.parse_energy(fluid.fuel_value) > 0 then
        py_utils.insert_double_lookup(self.fuel_categories, FUEL_FLUID, fluid.name)
    end
end


function data_parser:pre_process_item(item)
    if self.items[item.name] then
        return
    end

    self.items[item.name] = item

    if item.fuel_category and item.fuel_value and util.parse_energy(item.fuel_value) > 0
        and not table.any(item.flags or {}, function(v) return v == "hidden" end)
    then
        py_utils.insert_double_lookup(self.fuel_categories, item.fuel_category, item.name)
    end

    if item.place_result then
        py_utils.insert_double_lookup(self.placed_by, item.place_result, item.name)
        py_utils.insert_double_lookup(self.place_result, item.name, item.place_result)
        self:pre_process_entity(py_utils.get_prototype("entity", item.place_result))
    end

    for _, entity_name in pairs(config.ENTITY_SCRIPT_UNLOCKS[item.name] or {}) do
        py_utils.insert_double_lookup(self.placed_by, entity_name, item.name)
        py_utils.insert_double_lookup(self.place_result, item.name, entity_name)
        self:pre_process_entity(py_utils.get_prototype("entity", entity_name))
    end

    if item.placed_as_equipment_result then
        py_utils.insert_double_lookup(self.placed_by, item.placed_as_equipment_result, item.name)
    end

    if item.type == "module" then
        py_utils.insert_double_lookup(self.module_categories, item.category, item.name)
    end

    -- Fucking capsules
    if item.type == "capsule" and item.capsule_action.type == "throw" then
        local ap = item.capsule_action.attack_parameters

        if ap.ammo_type and ap.ammo_type.action then
            local action = ap.ammo_type.action
            if action.type then action = { action } end

            for _, a in pairs(action) do
                local ad = a.action_delivery
                if ad.type then ad = { ad } end

                for _, d in pairs(ad) do
                    if d.type == "projectile" then
                        local pr_action = data.raw.projectile[d.projectile].action
                        if pr_action and pr_action.type then pr_action = { pr_action } end

                        for _, pr_a in pairs(pr_action or {}) do
                            local pr_ad = pr_a.action_delivery
                            if pr_ad.type then pr_ad = { pr_ad } end

                            for _, pr_d in pairs(pr_ad or {}) do
                                local te = pr_d.target_effects

                                if te then
                                    if te.type then te = { te } end

                                    for _, tee in pairs(te) do
                                        if tee.type == "create-entity" then
                                            py_utils.insert_double_lookup(self.placed_by, tee.entity_name, item.name)
                                            self:pre_process_entity(py_utils.get_prototype("entity", tee.entity_name))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if item.equipment_grid then
        self.items_with_grid[item.name] = data.raw["equipment-grid"][item.equipment_grid]
    end
end


function data_parser:pre_process_recipe(recipe)
    if self.recipes[recipe.name] then
        return
    end

    self.recipes[recipe.name] = recipe

    local r = recipe.normal or recipe

    if (recipe.unlock_results ~= false) and not recipe.ignore_in_pypp then
        for _, res in pairs(py_utils.standardize_products(r.results, nil, r.result, r.result_count)) do
            if res.type == "fluid" then
                local fluid = data.raw.fluid[res.name]

                if fluid then
                    self:pre_process_fluid(fluid, res.temperature)
                end
            else
                local item = py_utils.get_prototype("item", res.name)
                self:pre_process_item(item)
            end
        end
    end
end


return data_parser
