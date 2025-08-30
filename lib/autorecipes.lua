--((single mode example))--
--[[
py.autorecipes { -- is a function call can be many per file is the same as RECIPE{} that is used in the rest of pymods
    name = 'single-example', -- recipe name if in single recipe mode *@*
    category = 'recipe-category', -- used in input recipe and output if outcategory not provided to set category
	singlerecipe = false, --=true: its a single recipe done 1 machine. takes ingredients and outputs the results. --=false: creates 2 recipes. 1 with the ingredients as inputs and outputs an item. 2nd recipe takes the item in and outputs the results.
	module_limitations = "ulric", --adds the recipes to a modules allowed recipes table *
	subgroup = 'subgroup', -- sets the recipes subgroups for menu organizion
    order = 'order', -- sets order for menu organizion
    mats = -- stuff needed for each recipe.
	{
		{
			ingredients = -- duh, first time can not be empty or youll get an empty ingredients table
				{
					{name = 'name', amount = 'amount'*('*!*'), return_item={name='item', amount='amount'*}*('*&*')},-- a single ingredient
                    {'ingredient'}, -- see above for details
                    {'ingredient'}, -- see above. no limits to the number of ingredients beyond what the machine is set to
				},
			results = -- double duh, same as ingredients first time cant be empty or you get nothing
				{
					{name='bones', amount = 'amount'*('*!*'),probability = 'probability'**, amount_min = 'amount_min'**'***', amount_max = 'amount_max'**'***'},
					{'result'}, -- see above for details
					{'result'}, -- again not limited by this code to number of results
				},
			icon = 'icon', --image used as part of a subicon for the item and output recipe* if not provided it will use the baseitems icon as the icon
			crafting_speed = 130, -- sets crafting speed of input recipe for both single mode and dual mode.
			tech = 'tech', -- tech that unlocks this recipe*
			name = 'name' --gives the correct name in rendering, loved it.
		},
		{
			ingredients = -- same as above but can be empty to reuse the same ingredients as the recipe before this one
				{

				},
			results = -- same as above but can be empty to reuse the same results as the recipe before this one
				{

				},

		},
	},
}
--]]

-- *: means this is not required for a recipe to work
-- *@*: is only used in single recipe mode as is (i.e. singlerecipe = true) dualmode adds a number
-- *#*: is only used in dual recipe mode (i.e. singlerecipe = false)
-- **: its all or nothing with these 3. if you use probability you have to use min and max
-- ***: amount min and max are optional as by default it is set to 1:1 which will give you perecent chance
-- *&*: return item allows you to set an item to be a result in the input recipe. amount is not need as it defaults to useing the same value as the item its a part of
--[[
*!*: inggredients and results carry over from the top recipe down. amount can have a few possible entries.
+,-,*,/,R, and numbers.
 +,-,*,/: if an item with the same name exist in the mats above this recipe it will preform the set math operation on that amount useing the new value (i.e. old amount + new amount). if this is a new item being added it will perform the math operation on the default value of the item from the items table.
R: will clear this entry from the ingredients/results table it is in
numbers: sets amount to this value no matter what it was before
]] --
--if you use the icon part its set to want a size 64 icon right now. if you want to use the size 32 ones ill need to add icon size in because i cant detect the icons size in the code

local function ensure_contiguous(tbl)
    if not tbl or type(tbl) ~= "table" then return tbl end
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
    if string.match(item.name, "%-barrel") and string.match(item.name, "empty%-barrel") == nil or string.match(item.name, "empty-milk-barrel") then
        barrel = string.gsub(item.name, "%-barrel", "")
    end

    local name
    if data.raw.item[item.name] or data.raw.module[item.name] or data.raw.fluid[item.name] then
        name = item.name
    elseif type(item.fallback) == "string" then
        name = item.fallback
        item.name = name
    elseif type(item.fallback) == "table" and item.fallback.name then
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
            item_type = "item"
        elseif data.raw.fluid[name] then
            item_type = "fluid"
        else
            item_type = "item"
        end
        item.type = item_type

        if item.amount and type(item.amount) == "number" then
            table.insert(items_table, item)
        elseif item.amount_min and item.amount_max then
            table.insert(items_table, item)
        end
    elseif previous_item_names[name] == true then
        if item.remove_item and item.remove_item == true then
            for p, pre in pairs(items_table) do
                if pre.name == name then
                    if string.match(item.name, "%-barrel") and string.match(item.name, "empty%-barrel") == nil or string.match(item.name, "empty%-milk%-barrel") == nil then
                        local barrel_name
                        if string.match(item.name, "barrel") then
                            barrel_name = "barrel"
                        elseif string.match(item.name, "canister") then
                            barrel_name = "empty-fuel-canister"
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
            item_type = "item"
        elseif data.raw.fluid[name] then
            item_type = "fluid"
        end
        return_item = { type = item_type, name = name, amount = amount }
        table.insert(result_table, return_item)
    end

    if item.return_barrel then
        local barrel_item_name
        if string.match(item.name, "barrel") then
            barrel_item_name = "barrel"
        elseif string.match(item.name, "canister") then
            barrel_item_name = "empty-fuel-canister"
        else
            error()
        end

        local amount = item.amount or item.add_amount
        local barrels_to_return = { type = "item", name = barrel_item_name, amount = amount, ignored_by_stats = amount, ignored_by_productivity = amount }

        for _, result in pairs(result_table) do
            if result.name == barrel_item_name then
                result.amount = result.amount + amount
                result.ignored_by_stats = (result.ignored_by_stats or 0) + amount
                result.ignored_by_productivity = (result.ignored_by_productivity or 0) + amount
                goto already_had_barrel_result
            end
        end
        table.insert(result_table, barrels_to_return)
        ::already_had_barrel_result::
    end
end

--handles all adjustments for each ingredient and result changes in autorecipe
local function recipe_item_builder(ingredients, results, previous_ingredients, previous_results)
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
            numbered_name = params.name .. "-" .. i
        until not data.raw.recipe[numbered_name]

        local recipe_name = tier.name or numbered_name

        local recipe = RECIPE({
            type = "recipe",
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
            main_product = tier.main_product or params.main_product,
            allow_productivity = params.category ~= "slaughterhouse",
        })
        if tier.tech then recipe:add_unlock(tier.tech) end
        if params.number_icons then -- add numbers to farming recipes so that they're not identical
            if tier.name then error("can't use number_icons with individual recipe names") end
            if recipe_name == "arthurian-egg-incubation-01" then log("fucked up") end
            if i > 9 then
                log(serpent.block(params))
                error("autorecipes can only count to 9, check logs")
            end
            data.raw.recipe[recipe_name].icons = data.raw.recipe[recipe_name].icons or {}
            if #data.raw.recipe[recipe_name].icons == 0 then
                local item_name = tier.main_product or params.main_product or tier.results[1].name
                local item = (data.raw.module[item_name] or data.raw.item[item_name])
                if not item.icon then
                    data.raw.recipe[recipe_name].icons = table.array_combine(data.raw.recipe[recipe_name].icons, item.icons)
                else
                    table.insert(
                        data.raw.recipe[recipe_name].icons,
                        { icon = tier.icon or item.icon, scale = 64 / (tier.icon_size or 128) }
                    )
                end
            end
            local scale = (data.raw.recipe[recipe_name].icons[1].scale or .5) / 2
            table.insert(
                data.raw.recipe[recipe_name].icons,
                { icon = "__pyalienlifegraphics__/graphics/icons/" .. i .. ".png", scale = scale, shift = { 32 * scale, 32 * scale }, floating = true }
            )
        elseif tier.icon then
            data.raw.recipe[recipe_name].icon = tier.icon
            if tier.icon_size then
                data.raw.recipe[recipe_name].icon_size = tier.icon_size
            else
                data.raw.recipe[recipe_name].icon_size = 32
            end
        end
    end
end
