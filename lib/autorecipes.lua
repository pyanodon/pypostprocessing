local function ensure_contiguous(tbl)
    if not tbl or type(tbl) ~= 'table' then return tbl end
    local contiguous_table = {}
    for _, v in pairs(tbl) do
        if v ~= nil then
            contiguous_table[#contiguous_table+1] = v
        end
    end
    return contiguous_table
end

local function modify_recipe_tables(item, items_table, previous_item_names, result_table) -- TODO: this is spaghetti. needs a refactor
    local barrel
    if string.match(item.name, '%-barrel') and string.match(item.name, 'empty-barrel') == nil or string.match(item.name, 'empty-milk-barrel') then
        barrel = string.gsub(item.name, '%-barrel', '')
    end

    local name
    if data.raw.item[item.name] or data.raw.module[item.name] or data.raw.fluid[item.name] then
        name = item.name
    elseif type(item.fallback) == 'string' then
        name = item.fallback
        item.name = name
    elseif type(item.fallback) == 'table' and item.fallback.name then
        name = item.fallback.name
        item.name = name
        if item.fallback.amount then
            item.amount = item.fallback.amount
        end
    elseif data.raw.fluid[barrel] then
        name = item.name
    end

    if previous_item_names[name] ~= true then
        local item_type
        if data.raw.item[name] or data.raw.module[name] then
            item_type = 'item'
        elseif data.raw.fluid[name] then
            item_type = 'fluid'
        end
        item.type = item_type

        if item.amount and type(item.amount) == 'number' then
            table.insert(items_table, item)
        elseif item.amount_min and item.amount_max then
            table.insert(items_table, item)
        end
    elseif previous_item_names[name] == true then
        if item.remove_item and item.remove_item == true then
            for p, pre in pairs(items_table) do
                if pre.name == name then
                    if string.match(item.name, '%-barrel') and string.match(item.name, 'empty%-barrel') == nil or string.match(item.name, 'empty%-milk%-barrel') == nil then
                        local barrel_name
                        if string.match(item.name, 'barrel') then
                            barrel_name = 'empty-barrel'
                        elseif string.match(item.name, 'canister') then
                            barrel_name = 'empty-fuel-canister'
                        end
                        local amount = items_table[p].amount
                        if result_table and next(result_table) then
                            if result_table.no_returns == nil or result_table.no_returns and result_table.no_returns[item.name] ~= true then
                                for _, result in pairs(result_table) do
                                    if result.name == barrel_name then
                                        result.amount = result.amount - amount
                                    end
                                end
                            end
                        end
                    end
                    items_table[p] = nil
                    previous_item_names[name] = nil
                end
            end
        elseif item.amount == nil then
            if item.add_amount then
                for _, pre in pairs(items_table) do
                    if pre.name == name then
                        if pre.amount then
                        pre.amount = item.add_amount + pre.amount
                        elseif pre.amount_min and pre.amount_max then
                            pre.amount_min = pre.amount_min + item.add_amount
                            pre.amount_max = pre.amount_max + item.add_amount
                        end
                    end
                end
            elseif item.amount_min and item.amount_max then
                for _, pre in pairs(items_table) do
                    if pre.name == name then
                        pre.amount_min = item.amount_min
                        pre.amount_max = item.amount_max
                    end
                end
            elseif item.subtract_amount then
                for _, pre in pairs(items_table) do
                    if pre.name == name then
                        pre.amount = pre.amount - item.subtract_amount
                    end
                end
            end
        elseif item.amount then
            for _, pre in pairs(items_table) do
                if pre.name == name then
                    pre.amount = item.amount
                end
            end
        end
    end

    --add return item to results if it exists
    local return_item
    if item.return_item then
        local item_type
        local name = item.return_item.name
        local amount = item.return_item.amount or item.amount or item.add_amount
        if data.raw.item[name] or data.raw.module[name] then
            item_type = 'item'
        elseif data.raw.fluid[name] then
            item_type = 'fluid'
        end
        return_item = {type = item_type, name = name, amount = amount}
        table.insert(result_table, return_item)
    end

    local return_barrel
    if item.return_barrel and item.return_barrel == true then
        local item_type = 'item'
        local name
        if string.match(item.name, 'barrel') then
            name = 'empty-barrel'
        elseif string.match(item.name, 'canister') then
            name = 'empty-fuel-canister'
        end
        local amount = item.amount or item.add_amount
        return_barrel = {type = item_type, name = name, amount = amount}
        if next(result_table) then
            local has_barrel = false
            for _, result in pairs(result_table) do
                if result.name == name then
                    result.amount = result.amount + amount
                    has_barrel = true
                end
            end
            if has_barrel == false then
                table.insert(result_table, return_barrel)
            end
        else
            table.insert(result_table, return_barrel)
        end
    end
end

--handles all adjustments for each ingredient and result changes in autorecipe
local function recipe_item_builder(ingredients,results,previous_ingredients,previous_results)
    local ing_table = table.deepcopy(previous_ingredients)
    local result_table = table.deepcopy(previous_results)

    local previous_ingredient_names = {}
    for _, pre in pairs(previous_ingredients) do
        previous_ingredient_names[pre.name] = true
    end

    local previous_result_names = {}
    for _, pre in pairs(previous_results) do
        previous_result_names[pre.name] = true
    end

    for _, ing in pairs(ingredients) do
        modify_recipe_tables(ing, ing_table, previous_ingredient_names, result_table)
    end

    for _, result in pairs(results) do
        modify_recipe_tables(result, result_table, previous_result_names)
    end

    return ensure_contiguous(ing_table), ensure_contiguous(result_table)
end

---Provides an interface to quickly build tiered recipes. See recipes-auto-brains.lua for an example
---@param params table
py.autorecipes = function(params)
    local previous_ingredients = {}
    local previous_results = {}

    for _, tier in pairs(params.mats) do
        local fixed_ingredients, fixed_results = recipe_item_builder(tier.ingredients, tier.results, previous_ingredients, previous_results)
        previous_ingredients = fixed_ingredients
        previous_results = fixed_results

        local i, numbered_name = 0, nil
        repeat
            i = i + 1
            numbered_name = params.name .. '-' .. i
        until not data.raw.recipe[numbered_name]

        local recipe_name = tier.name or numbered_name

        local recipe = RECIPE {
            type = 'recipe',
            name = recipe_name,
            category = params.category,
            enabled = tier.tech == nil,
            energy_required = tier.crafting_speed or params.crafting_speed,
            ingredients = fixed_ingredients,
            results = fixed_results,
            subgroup = params.subgroup,
            order = params.order,
            allowed_module_categories = params.allowed_module_categories,
            icons = tier.icons,
            main_product = tier.main_product or params.main_product
        }
        if tier.tech then recipe:add_unlock(tier.tech) end

        if tier.icon then
            data.raw.recipe[recipe_name].icon = tier.icon
            if tier.icon_size then
                data.raw.recipe[recipe_name].icon_size = tier.icon_size
            else
                data.raw.recipe[recipe_name].icon_size = 32
            end
        end
    end
end