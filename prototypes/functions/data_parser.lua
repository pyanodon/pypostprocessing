local fz_graph = require("prototypes.functions.fuzzy_graph")
local config = require("prototypes.config")
local py_utils = require("prototypes.functions.utils")
local graph = require("luagraphs.data.graph")
local breadth_firt_search = require("luagraphs.search.BreadthFirstSearch")
local table = require("__stdlib__/stdlib/utils/table")
local string = require("__stdlib__/stdlib/utils/string")

local data_parser = {}
data_parser.__index = data_parser

local FUEL_FLUID = "fluid"

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

    return d
end


function data_parser:run()
    self:pre_process()

    local fg = fz_graph.create()

    

    return fg
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
