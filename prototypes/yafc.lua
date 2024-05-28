if mods['pyalienlife'] then
    log('Fix Automated smartfarm')
    -- Add the replicator as proper ingredient
    -- Smartfarm recipe produces fluid that is used for mining

    -- Create copy of bioreserve for farming
    local bioreserve_copy = table.deepcopy(data.raw['resource']['ore-bioreserve'])
    bioreserve_copy.name = 'ore-bioreserve-farming'
    bioreserve_copy.localised_name = {'entity-name.ore-bioreserve'}
    data:extend{bioreserve_copy}

    local function use_bioreserve_copy(farm)
        farm.crop = 'ore-bioreserve-farming'
        return farm
    end

    -- List of all available smartfarming
    local farms = {
        require '__pyalienlife__/scripts/smart-farm/farm-ralesia',
        require '__pyalienlife__/scripts/smart-farm/farm-rennea',
        require '__pyalienlife__/scripts/smart-farm/farm-tuuphra',
        require '__pyalienlife__/scripts/smart-farm/farm-grod',
        require '__pyalienlife__/scripts/smart-farm/farm-yotoi',
        require '__pyalienlife__/scripts/smart-farm/farm-kicalk',
        require '__pyalienlife__/scripts/smart-farm/farm-arum',
        require '__pyalienlife__/scripts/smart-farm/farm-yotoi-fruit',
        use_bioreserve_copy(require '__pyalienlife__/scripts/smart-farm/farm-bioreserve')
    }

    if mods['pyalternativeenergy'] then
        farms[#farms+1] = require '__pyalternativeenergy__/scripts/crops/farm-mova'
    end

    for _, farm in ipairs(farms) do
        local fluid_name = farm.crop .. '-farming-fluid'
        local resource = data.raw['resource'][farm.crop]
        local fluid = FLUID {
            type = 'fluid',
            name = fluid_name,
            localised_name = {'', 'Smart farming with ', {'item-name.' .. farm.seed}},
            icon = resource.icon,
            icon_size = resource.icon_size,
            default_temperature = 15,
            base_color = {1, 1, 1},
            flow_color = {1, 1, 1}
        }
        resource.minable.required_fluid = fluid_name
        resource.minable.fluid_amount = 10
        resource.autoplace = {}

        for _, recipe_data in ipairs(farm.recipes) do
            local recipe = RECIPE(recipe_data.recipe_name)
            recipe:add_ingredient {farm.seed, 1}
            recipe.results[1] = {type = 'fluid', name = fluid_name, amount = math.floor(recipe_data.crop_output) * 529}
        end
    end

    -- Collector and harvester need a fluid box - an empty table is enough for YAFC
    data.raw['mining-drill']['harvester'].input_fluid_box = {}
    data.raw['mining-drill']['collector'].input_fluid_box = {}

    -- No rocket launches in farm, make it a normal assembling machine
    data.raw['rocket-silo']['mega-farm'].type = 'assembling-machine'
    data.raw['assembling-machine']['mega-farm'] = data.raw['rocket-silo']['mega-farm']
    data.raw['rocket-silo']['mega-farm'] = nil

    log('Fix animal module dependencies')
    -- Needed to make the milestones work properly and lock normal production after the bootstrapping recipe

    local mod_buildings = {
        -- {required_module, locked_building}
        {'antelope', 'antelope-enclosure-mk01'},
        {'arqad', 'arqad-hive-mk01'},
        {'auog', 'auog-paddock-mk01'},
        {'cridren', 'cridren-enclosure-mk01'},
        {'arthurian', 'arthurian-pen-mk01'},
        {'bhoddos', 'bhoddos-culture-mk01'},
        {'cadaveric-arum', 'cadaveric-arum-mk01'},
        {'cottongut-mk01', 'prandium-lab-mk01'},
        {'dingrits', 'dingrits-pack-mk01'},
        {'dhilmos', 'dhilmos-pool-mk01'},
        {'fish', 'fish-farm-mk01'},
        {'grod', 'grods-swamp-mk01'},
        {'guar', 'guar-gum-plantation'},
        {'kicalk', 'kicalk-plantation-mk01'},
        {'kmauts', 'kmauts-enclosure-mk01'},
        {'korlex', 'ez-ranch-mk01'},
        {'fawogae', 'fawogae-plantation-mk01'},
        {'moondrop', 'moondrop-greenhouse-mk01'},
        {'moss', 'moss-farm-mk01'},
        {'mukmoux', 'mukmoux-pasture-mk01'},
        {'sap-tree', 'sap-extractor-mk01'},
        {'navens', 'navens-culture-mk01'},
        {'phagnot', 'phagnot-corral-mk01'},
        {'phadai', 'phadai-enclosure-mk01'},
        {'ralesias', 'ralesia-plantation-mk01'},
        {'rennea', 'rennea-plantation-mk01'},
        {'seaweed', 'seaweed-crop-mk01'},
        {'sea-sponge', 'sponge-culture-mk01'},
        {'scrondrix', 'scrondrix-pen-mk01'},
        {'tuuphra', 'tuuphra-plantation-mk01'},
        {'tree-mk01', 'fwf-mk01'},
        {'trits', 'trits-reef-mk01'},
        {'ulric', 'ulric-corral-mk01'},
        {'vonix', 'vonix-den-mk01'},
        {'vrauks', 'vrauks-paddock-mk01'},
        {'xyhiphoe', 'xyhiphoe-pool-mk01'},
        {'xeno', 'xenopen-mk01'},
        {'simik', 'simik-den-mk01'},
        {'yotoi', 'yotoi-aloe-orchard-mk01'},
        {'yaedols', 'yaedols-culture-mk01'},
        {'zipir1', 'zipir-reef-mk01'}
    }

    if mods['pyalternativeenergy'] then
        mod_buildings[#mod_buildings+1] = {'zungror', 'zungror-lair-mk01'}
        mod_buildings[#mod_buildings+1] = {'numal', 'numal-reef-mk01'}
    end

    if mods['pystellarexpedition'] then
        mod_buildings[#mod_buildings+1] = {'kakkalakki-m', 'kakkalakki-habitat-mk01'}
    end

    for _, x in ipairs(mod_buildings) do
        table.insert(RECIPE(x[2]).ingredients, {type = 'item', name = x[1], amount = 1})
    end

    log('Fix dig-site')

    data.raw.recipe['digosaurus-hidden-recipe'].results = {}
    data.raw['assembling-machine']['dino-dig-site'].fixed_recipe = nil

    local dig_creatures = {
        -- {creature, amount, time_taken_to_mine, attack_cooldown_ticks}
        {'digosaurus', 1, 15, 30},
        {'thikat', 2, 4, 49 * 2},
        {'work-o-dile', 3, 8, 49 * 2}
    }

    Digosaurus = {}
    require '__pyalienlife__/scripts/digosaurus/digosaurus-prototypes'
    for food_name, food_bonus in pairs(Digosaurus.favorite_foods) do
        for _, y in ipairs(dig_creatures) do
            -- The creature is looped in the recipe to make it only available after the creature is available
            RECIPE {
                type = 'recipe',
                name = 'nexelit-from-' .. food_name .. '-' .. y[1],
                energy_required = y[3] * y[4] / 60,
                ingredients = {
                    {type = 'item', name = food_name, amount = 4},
                    {type = 'item', name = y[1], amount = 4}
                },
                results = {
                    {type = 'item', name = 'nexelit-ore', amount = food_bonus * y[2] * 4},
                    {type = 'item', name = y[1], amount = 4}
                },
                main_product = 'nexelit-ore',
                category = 'dino-dig-site'
            }
        end
    end

    log('Fix guano')

    data.raw.recipe['bioport-hidden-recipe'].results = {}
    data.raw['assembling-machine']['bioport'].fixed_recipe = nil

    Biofluid = {}
    require '__pyalienlife__/scripts/biofluid/biofluid-prototypes'
    for food_name, food_bonus in pairs(Biofluid.favorite_foods) do
        for creature_name, poop_amount in pairs(Biofluid.taco_bell) do
            RECIPE {
                type = 'recipe',
                name = 'guano-from-' .. food_name .. '-' .. creature_name,
                energy_required = food_bonus * 2.38,
                ingredients = {
                    {type = 'item', name = food_name, amount = 1},
                    {type = 'item', name = creature_name, amount = 1}
                },
                results = {
                    {type = 'item', name = 'guano', amount = food_bonus * poop_amount},
                    {type = 'item', name = creature_name, amount = 1}
                },
                main_product = 'guano',
                category = 'biofluid'
            }
        end
    end

    log('Improve TURD selection')

    ITEM {
        type = 'item',
        name = 'hidden-beacon-turd',
        icon = data.raw['beacon']['hidden-beacon-turd'].icon,
        icon_size = data.raw['beacon']['hidden-beacon-turd'].icon_size,
        place_result = 'hidden-beacon-turd'
    }
    RECIPE {
        type = 'recipe',
        name = 'hidden-beacon-turd',
        ingredients = {},
        result = 'hidden-beacon-turd'
    }

    _G.yafc_turd_integration = true
    local tech_upgrades, farm_building_tiers = table.unpack(require '__pyalienlife__/prototypes/upgrades/tech-upgrades')
    for _, tech_upgrade in pairs(tech_upgrades) do
        local master_tech = tech_upgrade.master_tech
        for _, tech in pairs(tech_upgrade.sub_techs) do
            local effects = {}
            for _, effect in pairs(tech.effects) do
                if effect.type == 'module-effects' then
                    local modules = {}
                    if data.raw.module[tech.name .. '-module'] then
                        table.insert(modules, tech.name .. '-module')
                    else
                        for i, entity in pairs(tech_upgrade.affected_entities or {}) do
                            table.insert(modules, tech.name .. '-module-mk0' .. i)
                        end
                    end
                    for _, module in pairs(modules) do
                        RECIPE {
                            type = 'recipe',
                            name = module,
                            enabled = false,
                            ingredients = {},
                            result = module
                        }
                        table.insert(effects, {
                            type = 'unlock-recipe',
                            recipe = module
                        })
                    end
                elseif effect.type == 'unlock-recipe' then
                    table.insert(effects, {
                        type = 'unlock-recipe',
                        recipe = effect.recipe
                    })
                elseif effect.type == 'recipe-replacement' then
                    table.insert(effects, {
                        type = 'unlock-recipe',
                        recipe = effect.new
                    })
                end
            end
            TECHNOLOGY {
                type = 'technology',
                name = 'turd-select-' .. tech.name,
                localised_name = {'', {'turd.select'}, ' ', {'technology-name.' .. tech.name}},
                icon = tech.icon,
                icon_size = tech.icon_size,
                order = tech.order,
                prerequisites = {},
                effects = {},
                enabled = false,
                unit = {
                    count = 1,
                    ingredients = {},
                    time = 60
                }
            }
            TECHNOLOGY {
                type = 'technology',
                name = tech.name,
                icon = tech.icon,
                icon_size = tech.icon_size,
                order = tech.order,
                prerequisites = {master_tech.name, 'turd-select-' .. tech.name},
                effects = effects,
                unit = {
                    count = 1,
                    ingredients = {},
                    time = 60
                }
            }
        end
    end
end

if mods['pyalternativeenergy'] then
    log('Fix placer entities')
    -- Needed to make some buildings available

    data.raw['item']['numal-reef-mk01'].place_result = 'numal-reef-mk01'
    data.raw['item']['numal-reef-mk02'].place_result = 'numal-reef-mk02'
    data.raw['item']['numal-reef-mk03'].place_result = 'numal-reef-mk03'
    data.raw['item']['numal-reef-mk04'].place_result = 'numal-reef-mk04'
end

if mods['pypetroleumhandling'] then
    log('Fix bitumen seeps')

    local changed_seeps = {
        'tar-patch',
        'natural-gas-mk01',
        'natural-gas-mk02',
        'natural-gas-mk03',
        'natural-gas-mk04',
        'oil-mk01',
        'oil-mk02',
        'oil-mk03',
        'oil-mk04'
    }

    for _, resource in ipairs(changed_seeps) do
        data.raw['resource'][resource].autoplace = data.raw['resource']['bitumen-seep'].autoplace
    end
end