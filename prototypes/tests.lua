local function test_entity_graphics()
    local graphics_locations = {
        ["accumulator"] = {"chargable_graphics"},
        ["boiler"] = {"pictures"},
        ["burner-generator"] = {"animation"},
        ["car"] = {"animation"},
    }
    local excluded_types = {
        ["arithmetic-combinator"] = true,
        ["arrow"] = true,
        ["artillery-flare"] = true,
        ["artillery-projectile"] = true,
        ["artillery-turret"] = true,
        ["artillery-wagon"] = true,
        ["cargo-pod"] = true,
        ["constant-combinator"] = true,
        ["corpse"] = true,
        ["decider-combinator"] = true,
        ["deconstructible-tile-proxy"] = true,
        ["display-panel"] = true,
        ["entity-ghost"] = true,
        ["explosion"] = true,
        ["fire"] = true,
        ["highlight-box"] = true,
        ["infinity-container"] = true,
        ["infinity-pipe"] = true,
        ["item-entity"] = true,
        ["item-request-proxy"] = true,
        ["market"] = true,
        ["rail-remnants"] = true,
        ["selector-combinator"] = true,
        ["sticker"] = true,
        ["stream"] = true,
        ["temporary-container"] = true,
        ["tile-ghost"] = true,
    }
    local excluded_entities = {
        ["bitumen-seep-mk01-base"] = true,
        ["bitumen-seep-mk02-base"] = true,
        ["bitumen-seep-mk03-base"] = true,
        ["bitumen-seep-mk04-base"] = true,
        ["tar-seep-mk01-base"] = true,
        ["natural-gas-seep-mk01-base"] = true,
        ["hidden-beacon"] = true,
        ["hidden-beacon-turd"] = true,
    }
    for entity_type, _ in pairs(defines.prototypes.entity) do
        for name, entity in pairs((excluded_types[entity_type] and {}) or (data.raw[entity_type] or {})) do
            if not excluded_entities[name] then
                local graphics_exist = true
                for _, field in pairs(graphics_locations[entity_type] or {"graphics_set"}) do
                    if not entity[field] then graphics_exist = false end
                end
                if not graphics_exist then
                    log("WARNING: entity type " .. entity_type .. ", name: " .. name .. " is missing required graphics")
                end
            end
        end
    end
end

local function scan_for_cages()
    for recipe_name, recipe in pairs(data.raw.recipe) do
        if recipe_name:find('%-pyvoid$') or recipe_name:find('^biomass%-') then
            goto NEXT_RECIPE_CAGECHECK
        end
        if not recipe.ingredients then
            goto NEXT_RECIPE_CAGECHECK
        end
        local cage_input = false
        local cage_output = false
        for i, ingredient in pairs(recipe.ingredients) do
            local item_name = ingredient[1] or ingredient.name
            if item_name:find('caged') then
                cage_input = true
                break
            end
        end
        if not cage_input then
            goto NEXT_RECIPE_CAGECHECK
        end
        if not recipe.results then
            -- Don't log, probably a voiding recipe
            goto NEXT_RECIPE_CAGECHECK
        end
        for i, result in pairs(recipe.results) do
            local item_name = result[1] or result.name
            if item_name:find('cage') then -- could be the same caged animal or an empty cage
                cage_output = true
                break
            end
        end
        if cage_input and not cage_output then
            log(string.format('Recipe \'%s\' takes a caged animal as input but does not return a cage', recipe_name))
        end
        ::NEXT_RECIPE_CAGECHECK::
    end
end

test_entity_graphics()
scan_for_cages()