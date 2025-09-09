if not py.has_any_py_mods() then
    return
end

require "prototypes.quality"

local config = require "prototypes.config"
local signal_recipes = {
}
local create_signal_mode = settings.startup["pypp-extended-recipe-signals"].value

for _, recipe in pairs(data.raw.recipe) do
    recipe.always_show_products = true
    recipe.always_show_made_in = true
    if not recipe.maximum_productivity then recipe.maximum_productivity = 1000000 end -- Disable the max productivity cap

    if recipe.results then
        -- fallback for localised names
        if not recipe.localised_name then
            local fallback = recipe.main_product or (#recipe.results == 1 and recipe.results[1].name)
            if fallback and fallback ~= "" then
                local product_type = data.raw.fluid[fallback] and "fluid" or "item"
                local localised_name = {"?", {"recipe-name." .. recipe.name}}
                if product_type == "item" then
                    local product = ITEM(fallback)
                    table.insert(localised_name, product.localised_name or {"item-name." .. product.name})
                    if product.place_result then
                        table.insert(localised_name, ENTITY(product.place_result).localised_name or {"entity-name." .. product.place_result})
                    end
                    if product.place_as_tile then
                        table.insert(localised_name, TILE(product.place_as_tile.result).localised_name or {"tile-name." .. product.place_as_tile.result})
                    end
                    if product.place_as_equipment_result then table.insert(localised_name, {"equipment-name." .. product.place_as_equipment_result}) end
                else
                    local product = FLUID(fallback)
                    table.insert(localised_name, product.localised_name or {"fluid-name." .. product.name})
                end
                recipe.localised_name = localised_name
            end
        end

        -- Skip if recipe only produces the item, not uses it as a catalyst, or if it does not allow prod
        if #recipe.results == 1 or not recipe.allow_productivity then
            goto NEXT_RECIPE
        end
        for i, result in pairs(recipe.results) do
            local name = result.name or result[1]
            local amount = result.amount or result[2]
            if not name or not config.NON_PRODDABLE_ITEMS[name] or result.ignored_by_productivity then
                goto NEXT_RESULT
            end
            -- Convert to an explicitly long-form result format
            if result[1] then
                recipe.results[i] = {
                    type = result.type or "item",
                    name = name,
                    amount = amount,
                    ignored_by_stats = amount,
                    ignored_by_productivity = amount,
                    [1] = nil,
                    [2] = nil
                }
            else -- Just set the catalyst amount
                result.ignored_by_stats = amount
                result.ignored_by_productivity = amount
            end
            ::NEXT_RESULT::
        end
    end
    ::NEXT_RECIPE::

    -- Build table of recipes that may need signals
    if create_signal_mode and recipe.results then
        local product = (recipe.main_product or (#recipe.results == 1 and recipe.results[1].name))
        if product and product ~= "" and recipe.localised_name then
            if signal_recipes[product] == nil then
                signal_recipes[product] = {recipe}
            else
                table.insert(signal_recipes[product], recipe)
            end
        end
    end
end

-------------------------------------------
-- Recipe signals --
-------------------------------------------

if create_signal_mode then
    for _, alternatives in pairs(signal_recipes) do
        if #alternatives > 1 then
            for _, recipe in pairs(alternatives) do
                -- Skip recipe categories where signals aren't useful for any recipe
                if (recipe.category and (recipe.category.name == "compost" or recipe.category.name == "py-barreling")) then
                    break
                end
                -- Determine amount of main product to display in signal name
                amt = 0
                for _, result in pairs(recipe.results) do
                    if result.name then
                        local is_main_product = recipe.main_product and result.name == recipe.main_product
                        if is_main_product and result.probability and result.probability < 1 then
                            amt = result.probability
                            break
                        elseif is_main_product and result.amount_min and result.amount_max then
                            amt = (result.amount_min + result.amount_max) / 2
                            break
                        elseif result.amount then
                            if is_main_product then
                                amt = result.amount
                                break
                            end
                            -- Fallback that determines main product based on highest output
                            amt = math.max(amt, result.amount)
                        end
                    end
                end
                -- Inject recipe output into each localised name parameter, since native output display is not consistently shown
                if recipe.localised_name[1] == "?" then
                    recipe.show_amount_in_title = false
                    for i, name in pairs(recipe.localised_name) do
                        if i > 1 and amt ~= 1 then
                            recipe.localised_name[i] = {"recipe-name.recipe-amount", tostring(amt), name}
                        end
                    end
                end
                recipe.hide_from_signal_gui = false
            end
        end
    end
end

-------------------------------------------
-- Resource category locale builder --
-------------------------------------------

-- List below only includes py resource category names
local category_data = {
    --borax = {'raw-borax', 'ore-quartz'}
    ["borax"] = {""},
    ["niobium"] = {""},
    ["volcanic-pipe"] = {""},
    ["molybdenum"] = {""},
    ["regolite"] = {""},
    ["ore-quartz"] = {""},
    ["salt-rock"] = {""},
    ["phosphate-rock-02"] = {""},
    ["iron-rock"] = {""},
    ["coal-rock"] = {""},
    ["lead-rock"] = {""},
    ["quartz-rock"] = {""},
    ["aluminium-rock"] = {""},
    ["chromium-rock"] = {""},
    ["copper-rock"] = {""},
    ["nexelit-rock"] = {""},
    ["nickel-rock"] = {""},
    ["tin-rock"] = {""},
    ["titanium-rock"] = {""},
    ["uranium-rock"] = {""},
    ["zinc-rock"] = {""},
    ["phosphate"] = {""},
    ["rare-earth"] = {""},
    ["oil-sand"] = {""},
    ["oil-mk01"] = {""},
    ["oil-mk02"] = {""},
    ["tar-patch"] = {""},
    ["sulfur-patch"] = {""},
    ["oil-mk03"] = {""},
    ["oil-mk04"] = {""},
    ["bitumen-seep"] = {""},
    ["natural-gas"] = {""},
    ["ralesia-flowers"] = {""},
    ["tuuphra-tuber"] = {""},
    ["rennea-flowers"] = {""},
    ["grod-flower"] = {""},
    ["yotoi-tree"] = {""},
    ["yotoi-tree-fruit"] = {""},
    ["kicalk-tree"] = {""},
    ["arum"] = {""},
    ["ore-bioreserve"] = {""},
    ["ore-nexelit"] = {""},
    ["geothermal-crack"] = {""},
    ["ree"] = {""},
    ["antimonium"] = {""},
    ["mova"] = {""}
}
for resource, proto in pairs(data.raw.resource) do
    local category_name = proto.category or "basic-solid"
    local entry = category_data[category_name]
    if entry then
        -- Add our autoplace control name which helpfully has the icon
        entry[#entry + 1] = {
            "?",
            {
                "",
                #entry > 1 and ", " or "",
                {
                    "?",
                    {
                        "autoplace-control-names." .. resource
                    },
                    {
                        "",
                        "[img=entity." .. resource .. "]",
                        {"entity-name." .. resource}
                    }
                }
            }
        }
    end
end
for category_name, proto in pairs(data.raw["resource-category"]) do
    local resource_list = category_data[category_name]
    if resource_list then
        -- Just one entry besides the string concat
        if #resource_list == 2 then
            -- resource name, not autoplace - no icon. absolutely cursed indexing.
            local ore_locale = resource_list[2][2][3][3][3][1]
            -- {'!'} here just functions to tell '?' to skip the entry
            proto.localised_name = {"?", proto.localised_name or {"!"}, {ore_locale}}
            -- resource description just transposed here
            ore_locale = ore_locale:gsub("%-name%.", "-description.")
            proto.localised_description = {"?", proto.localised_description or {"!"}, {ore_locale}}
        else
            proto.localised_description = {
                "?",
                {
                    "",
                    proto.localised_description or {"resource-category-description." .. category_name},
                    "\n",
                    resource_list
                },
                resource_list
            }
        end
    end
end
-- End resource category locale builder

if mods.pycoalprocessing and not mods["extended-descriptions"] then
    for _, recipe in pairs(data.raw.recipe) do
        if recipe.allow_productivity then
            py.add_to_description("recipe", recipe, {"recipe-description.affected-by-productivity"})
        end
    end
end

----------------------------------------------------
-- THIRD PARTY COMPATIBILITY
----------------------------------------------------
require "prototypes/functions/compatibility"

----------------------------------------------------
-- TECHNOLOGY CHANGES
----------------------------------------------------

for _, tech in pairs(data.raw.technology) do
    if tech.unit == nil then
        goto continue
    end

    -- Holds the final ingredients for the current tech
    local tech_ingredients_to_use = {}

    local add_military_science = false
    local highest_science_pack = "automation-science-pack"
    -- Add the current ingredients for the technology
    for _, ingredient in pairs(tech.unit and tech.unit.ingredients or {}) do
        local pack = ingredient.name or ingredient[1]
        if pack == "military-science-pack" and not config.TC_MIL_SCIENCE_IS_PROGRESSION_PACK then
            add_military_science = true
        elseif config.SCIENCE_PACK_INDEX[pack] then
            if config.SCIENCE_PACK_INDEX[highest_science_pack] < config.SCIENCE_PACK_INDEX[pack] then
                highest_science_pack = pack
            end
        else -- not one of ours, sir
            tech_ingredients_to_use[pack] = ingredient.amount or ingredient[2]
        end
    end

    -- Add any missing ingredients that we want present
    for _, ingredient in pairs(config.TC_TECH_INGREDIENTS_PER_LEVEL[highest_science_pack]) do
        tech_ingredients_to_use[ingredient.name or ingredient[1]] = ingredient.amount or ingredient[2]
    end
    -- Add military ingredients if applicable
    if add_military_science then
        tech_ingredients_to_use["military-science-pack"] = config.TC_MIL_SCIENCE_PACK_COUNT_PER_LEVEL[highest_science_pack]
    end
    -- Push a copy of our final list to .ingredients
    tech.unit.ingredients = {}
    for pack_name, pack_amount in pairs(tech_ingredients_to_use) do
        tech.unit.ingredients[#tech.unit.ingredients + 1] = {pack_name, pack_amount}
    end
    ::continue::
end


for _, lab in pairs(data.raw.lab) do
    table.sort(lab.inputs, function(i1, i2)
        local science_pack_a = data.raw.tool[i1]
        if not science_pack_a then error("Missing science pack prototype " .. i1 .. " in lab " .. lab.name) end
        local science_pack_b = data.raw.tool[i2]
        if not science_pack_b then error("Missing science pack prototype " .. i2 .. " in lab " .. lab.name) end
        return science_pack_a.order < science_pack_b.order
    end)
end

if mods["pycoalprocessing"] then
    for _, subgroup in pairs(data.raw["item-subgroup"]) do
        if subgroup.group == "intermediate-products" then
            subgroup.group = "coal-processing"
            subgroup.order = "b"
        end
    end
end

-- move barrels below everything else in intermediate tab
-- https://github.com/pyanodon/pybugreports/issues/865
data.raw["item-subgroup"]["fill-barrel"].order = "y"
data.raw["item-subgroup"]["barrel"].order = "z"

-- Move recipes to the end of the list in signal selection ui
-- https://github.com/pyanodon/pypostprocessing/pull/67
if create_signal_mode then
    for _, recipe in pairs(data.raw["recipe"]) do
        if (not recipe.results or not recipe.results[1]) and not recipe.subgroup then
            log("WARNING: recipe without a subgroup \"" .. recipe.name .. "\"")
            goto continue
        end
        local old_subgroup = recipe.subgroup
        if not old_subgroup then
            local product
            if recipe.main_product then
                product = recipe.main_product
            else
                product = recipe.results[1].name
            end
            local types = defines.prototypes.item
            types["fluid"] = 0
            for ttype, _ in pairs(types) do
                if data.raw[ttype] and data.raw[ttype][product] then
                    old_subgroup = data.raw[ttype][product].subgroup
                    break
                end
            end
        end
        if data.raw["item-subgroup"][old_subgroup] then
            local new_subgroup = "recipe-" .. (old_subgroup)
            if not data.raw["item-subgroup"][new_subgroup] then
                data:extend {{
                    type = "item-subgroup",
                    name = new_subgroup,
                    group = data.raw["item-subgroup"][old_subgroup].group,
                    order = "zz-" .. (data.raw["item-subgroup"][old_subgroup].order or "")
                }}
            end
            recipe.subgroup = new_subgroup
        end

        ::continue::
    end
end

for _, type in pairs {"furnace", "assembling-machine"} do
    for _, prototype in pairs(data.raw[type]) do
        prototype.match_animation_speed_to_activity = false
    end
end

-- infrastructure times scale with tiers, makes pasting to requester chests and buffering inside assemblers better
for _, type in pairs {"furnace", "assembling-machine", "mining-drill", "lab"} do
    for _, prototype in pairs(data.raw[type]) do
        local name = prototype.name
        local tier = tonumber(string.sub(name, -1)) or 1
        if data.raw.recipe[name] and data.raw.recipe[name].energy_required == .5 then
            data.raw.recipe[name].energy_required = math.max(tier, 1)
        end
    end
end

-- YAFC
if type(data.data_crawler) == "string" and string.sub(data.data_crawler, 1, 5) == "yafc " then
    require "prototypes/yafc"
end

-- force mining drill speed to not increase with speed modules
for _, drill in pairs(data.raw["mining-drill"]) do
    drill.perceived_performance = drill.perceived_performance or {maximum = 1.5, performance_to_activity_rate = 0.2}
end

require "prototypes.fancy-module-slots"

if not data.raw["module-category"]["quality"] then
    data:extend {{
        type = "module-category",
        name = "quality"
    }}
end

local default_mods = {"productivity", "speed", "efficiency", "quality"}
for _, value in pairs {"furnace", "assembling-machine", "mining-drill", "lab", "beacon", "rocket-silo"} do
    for _, prototype in pairs(data.raw[value]) do
        prototype.allowed_module_categories = prototype.allowed_module_categories or default_mods
    end
end

for _, vehicle_prototype in pairs {"car", "locomotive", "spider-vehicle"} do
    for _, vehicle in pairs(data.raw[vehicle_prototype]) do
        if not vehicle.hidden then
            vehicle.allow_remote_driving = true
        end
    end
end

-- add circuit connections to machines
for _, crafting_machine_prototype in pairs {"assembling-machine", "rocket-silo", "furnace"} do
    for _, crafting_machine in pairs(data.raw[crafting_machine_prototype]) do
        if crafting_machine.hidden then goto continue end
        if crafting_machine.circuit_connector then goto continue end

        crafting_machine.circuit_connector = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"].circuit_connector)
        crafting_machine.circuit_wire_max_distance = crafting_machine.circuit_wire_max_distance or 14

        ::continue::
    end
end

-- fix render layers for construction and logistic bots alt-mode icons
for _, bot_type in pairs {"construction-robot", "logistic-robot"} do
    for _, bot in pairs(data.raw[bot_type]) do
        bot.icon_draw_specification = bot.icon_draw_specification or {shift = {0, -0.2}, scale = 0.8, render_layer = "air-entity-info-icon"}
    end
end

-- Skip check if user has [declutter](https://mods.factorio.com/mod/declutter) mod which hides arbitrary techs
-- Also skip check if user has autotech mod, since autotech runs after this check.
if not (mods.declutter or mods.autotech) then
    for _, technology in pairs(data.raw.technology) do
        if not technology.hidden and technology.prerequisites then
            for _, prerequisite in pairs(technology.prerequisites) do
                local prerequisite = data.raw.technology[prerequisite]
                if prerequisite and prerequisite.hidden then
                    error("\n\nERROR! Pyanodon detected an impossible-to-research technology.\n" .. technology.name .. " has hidden prerequisite " .. prerequisite.name .. "\nPlease report this on the pY bug tracker. https://github.com/pyanodon/pybugreports/issues\n\n")
                end
            end
        end
    end
end

if settings.startup["pypp-tests"].value then require "tests.data" end
