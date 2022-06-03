local table = require "__stdlib__.stdlib.utils.table"
local string = require "__stdlib__.stdlib.utils.string"

local graph = require "luagraphs.data.graph"
local breadth_firt_search = require "luagraphs.search.BreadthFirstSearch"

local config = require "prototypes.config"
local fz_graph = require "prototypes.functions.fuzzy_graph"
local py_utils = require "prototypes.functions.utils"


local data_parser = {}
data_parser.__index = data_parser

local FUEL_FLUID = "fluid"
local FUEL_ELECTRICITY = "electricity"
local FUEL_HEAT = "heat"

local RECIPE_PREFIX_START = "start:"

local LABEL_RECIPE_RESULT = "__recipe_result__"
local LABEL_MODULE = "__module__"

function data_parser.create()
    local d = {}
    setmetatable(d, data_parser)

    d.techs = {}
    d.recipes = {}
    d.items = {}
    d.fluids = {}
    d.entities = {}
    d.mining_categories = {}
    d.crafting_categories = {}
    d.module_categories = {}
    d.fuel_categories = {}
    d.fuel_burners = {}
    d.heat_temps = {}
    d.placed_by = {}
    d.items_with_grid = {}
    d.entities_with_grid = {}
    d.processed_recipes = {}
    d.processed_items = {}
    d.processed_fluids = {}

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

        if entity then
            local node = self.fg:add_node(entity_name, fz_graph.NT_ITEM, { factorio_name = entity_name })
            self.fg:add_link(self.fg.start_node, node)
        end
    end

    -- starting items
    for _, item_name in pairs(config.STARTING_ITEMS:enumerate()) do
        local item = py_utils.get_prototype("item", item_name, true)

        if item then
            local recipe = {
                name = RECIPE_PREFIX_START .. item_name,
                ingredients = {},
                results = {{ type = "item", name = item_name, amount = 1 }}
            }

            local node = self:parse_recipe(nil, recipe, true)
            self.fg:add_link(self.fg.start_node, node)
        end
    end

    -- starting recipes
    for _, recipe in pairs(data.raw.recipe) do
        if (recipe.normal and recipe.normal.enabled ~= false) or (not recipe.normal and recipe.enabled ~= false) then
            self:parse_recipe(nil, recipe)
        end
    end

    -- minable entities
    for _, entity in py_utils.iter_prototypes("entity") do
        if entity.autoplace and entity.minable and (entity.minable.result or entity.minable.results) then
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
    local node = self.fg:add_node(name, fz_graph.NT_RECIPE, { group = tech_name, factorio_name = recipe.name })

    if self.processed_recipes[name] then
        return node
    else
        self.processed_recipes[name] = true
    end

    node.ignore_for_dependencies = (not self.recipes[recipe.name] or recipe.ignore_for_dependencies or false)

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

                for temp, _ in pairs(self.fluids[ing.name] or { data.raw.fluidd[ing.name].default_temperature }) do
                    if (not ing.temperature or ing.temperature == temp)
                        and (not ing.min_temperature or ing.min_temperature <= temp)
                        and (not ing.max_temperature or ing.max_temperature >= temp)
                    then
                        local node_fluid = self:parse_fluid(ing.name, temp)
                        self.fg.fg_add_link(node_fluid, node, ing.name)
                        ingredients[ing.name][temp] = true
                    end
                end

                fluid_in = fluid_in + 1
            end
       end
    end

    for _, res in pairs(py_utils.standardize_products(recipe_data.results, nil, recipe_data.result, recipe_data.result_count)) do
        if res.type == "item" and not ingredients[res.name] then
            local node_item = self.fg:add_node(res.name, fz_graph.NT_ITEM)
            local item

            if not node_item.virtual then
                item = py_utils.get_prototype("item", res.name)
                node_item = self:parse_item(item)
            end

            self.fg:add_link(node, node_item, LABEL_RECIPE_RESULT)

            if item and item.place_result then
                self:add_entity_dependencies(node, item)
            end

            if item and item.placed_as_equipment_result then
                self:add_equipment_dependencies(node, item)
            end

            if item and (item.rocket_launch_products or item.rocket_launch_product) then
                self:add_rocket_product_recipe(item, tech_name)
            end

            node_item:inherit_ignore_for_dependencies(node)
        elseif res.type == "fluid" then
            local fluid = data.raw.fluid[res.name]
            local temp = res.temperature or (fluid and fluid.default_temperature)

            if not ingredients[res.name] or table.any(ingredients[res.name], function (t) return t ~= temp end) then
                local node_fluid

                if fluid or (res.temperature and self.fg:node_exists(self.get_fluid_name(res.name, res.temperature), fz_graph.NT_FLUID)) then
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


function data_parser:parse_fluid(fluid_name, temperature, properties)
    local fluid = data.raw.fluid[fluid_name]

    if fluid then
        if not properties then
            properties = {}
        end

        properties.factorio_name = fluid_name
    end

    local name = fluid_name .. "(" .. (temperature or fluid.default_temperature) .. ")"
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



function data_parser:pre_process()
    -- Starter entities
    for _, e in pairs(config.STARTING_ENTITIES:enumerate()) do
        local entity = py_utils.get_prototype("entity", e, true)

        if entity then
            py_utils.insert_double_lookup(self.placed_by, entity, entity)
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
    for et, _ in pairs(defines.prototypes["entity"]) do
        for _, entity in pairs(data.raw[et]) do
            if entity.autoplace and entity.minable and (entity.minable.result or entity.minable.results) then
                self:pre_process_entity(entity)
            end
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

            if not py_utils.is_py_or_base_tech(tech) then
                for _, pre in pairs(tech.prerequisites or {}) do
                    local pre_tech = data.raw.technology[pre]

                    if pre_tech and not py_utils.is_py_or_base_tech(pre_tech) then
                        if not tech.dependencies then
                            tech.dependencies = {}
                        end

                        table.insert(tech.dependencies, pre)
                    end
                end
            end
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

    for _, c in pairs(entity.crafting_categories or {}) do
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
        self:pre_process_entity(py_utils.get_prototype("entity", item.place_result))
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
            for _, a in pairs(ap.ammo_type.action) do
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


return data_parser
