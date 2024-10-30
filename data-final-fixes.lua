require "prototypes.quality"

local dev_mode = settings.startup["pypp-dev-mode"].value
local create_cache_mode = settings.startup["pypp-create-cache"].value
local config = require "prototypes.config"

for _, recipe in pairs(data.raw.recipe) do
    recipe.always_show_products = true
    recipe.always_show_made_in = true
    if not recipe.maximum_productivity then recipe.maximum_productivity = 1000000 end -- Disable the max productivity cap

    if recipe.results then
        -- fallback for localised names
        if not recipe.localised_name and not recipe.hidden then
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

--------------------------------------------------
-- AUTOTECH
--------------------------------------------------
if dev_mode then
    -- correct tech dependencies before autotech happens
    for _, tech in pairs(data.raw.technology) do
        local science_packs = {}
        local function add_science_pack_dep(t, science_pack, dep_pack)
            if science_packs[science_pack] and not science_packs[dep_pack] then
                TECHNOLOGY(t):add_pack(dep_pack)
                science_packs[dep_pack] = true
            end
        end

        for _, pack in pairs(tech.unit and tech.unit.ingredients or {}) do
            science_packs[pack.name or pack[1]] = true
        end

        if mods.pystellarexpedition then
            for i = 1, #config.SCIENCE_PACKS - 1 do
                local pack = config.SCIENCE_PACKS[i]
                local next = config.SCIENCE_PACKS[i + 1]
                add_science_pack_dep(tech, next, pack)
            end
        else
            add_science_pack_dep(tech, "utility-science-pack", "military-science-pack")

            if mods["pyalienlife"] then
                add_science_pack_dep(tech, "utility-science-pack", "py-science-pack-4")
                add_science_pack_dep(tech, "production-science-pack", "py-science-pack-3")
                add_science_pack_dep(tech, "chemical-science-pack", "py-science-pack-2")
                add_science_pack_dep(tech, "logistic-science-pack", "py-science-pack-1")
                add_science_pack_dep(tech, "py-science-pack-4", "military-science-pack")
            end

            if mods["pyalternativeenergy"] then
                add_science_pack_dep(tech, "production-science-pack", "military-science-pack")
            end
        end
    end

    log("AUTOTECH START")
    local at = require "prototypes.functions.auto_tech".create()
    at:run()
    if create_cache_mode then
        at:create_cachefile_code()
    end
    log("AUTOTECH END")
else
    require "cached-configs.run"

    -- some quick and dirty manual fixes until quintuples autotech rewrite is finished
    data.raw.technology["follower-robot-count-5"].unit.count = nil
    for _, t in pairs(data.raw.technology) do
        local new_prereqs = {}
        for _, prereq in pairs(t.prerequisites or {}) do
            if data.raw.technology[prereq] then
                new_prereqs[#new_prereqs + 1] = prereq
            end
        end
        t.prerequisites = new_prereqs
    end

    local starting_techs = {
        "automation",
        "coal-processing-1",
        "gun-turret",
        "soil-washing",
        "stone-wall",
    }

    for _, t in pairs(starting_techs) do
        t = data.raw.technology[t]
        if t then t.prerequisites = {"automation-science-pack"} end
        ::continue::
    end

    data.raw.technology["automation-science-pack"].prerequisites = {"steam-power"}
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
    table.sort(lab.inputs, function(i1, i2) return data.raw.tool[i1].order < data.raw.tool[i2].order end)
end

if mods["pycoalprocessing"] then
    for _, subgroup in pairs(data.raw["item-subgroup"]) do
        if subgroup.group == "intermediate-products" then
            subgroup.group = "coal-processing"
            subgroup.order = "b"
        end
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
    if drill.wet_mining_graphics_set then
        drill.wet_mining_graphics_set.max_animation_progress = drill.wet_mining_graphics_set.animation_progress or 1
        drill.wet_mining_graphics_set.min_animation_progress = drill.wet_mining_graphics_set.animation_progress or 1
    end
    if drill.graphics_set then
        drill.graphics_set.max_animation_progress = drill.graphics_set.animation_progress or 1
        drill.graphics_set.min_animation_progress = drill.graphics_set.animation_progress or 1
    elseif drill.animations then
        drill.graphics_set = {
            animation = drill.animations,
            max_animation_progress = 1,
            min_animation_progress = 1
        }
        if not drill.wet_mining_graphics_set then
            drill.wet_mining_graphics_set = drill.graphics_set
        end
        drill.animations = nil
    end
end

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

-- remove for logging unused attributes
for _, category in pairs(data.raw) do
    for _, prototype in pairs(category) do
        prototype.dependencies = nil
        prototype.ignore_for_dependencies = nil
    end
end

for _, vehicle_prototype in pairs {"car", "locomotive", "spider-vehicle"} do
    for _, vehicle in pairs(data.raw[vehicle_prototype]) do
        vehicle.allow_remote_driving = true
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

if dev_mode then require "tests.data" end
