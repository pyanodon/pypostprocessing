local table_insert = table.insert

--unsafe functions overrides protections for ingredient/result existence

---@diagnostic disable-next-line: missing-fields
---@type pYdata.RecipePrototype
local metas = {}

---@class pYdata.RecipePrototype:pYdata.AnyPrototype,data.RecipePrototype
---@operator call(string|pYdata.RecipePrototype|data.RecipePrototype): pYdata.RecipePrototype
---@field public standardize fun(self: pYdata.RecipePrototype): pYdata.RecipePrototype
---@field public add_unlock fun(self: pYdata.RecipePrototype, technology_name: string | string[]): pYdata.RecipePrototype, boolean
---@field public remove_unlock fun(self: pYdata.RecipePrototype, technology_name: string | string[]): pYdata.RecipePrototype, boolean
---@field public replace_unlock fun(self: pYdata.RecipePrototype, technology_old: string | string[], technology_new: string | string[]): pYdata.RecipePrototype, boolean
---@field public replace_ingredient fun(self: pYdata.RecipePrototype, old_ingredient: string, new_ingredient: string | data.IngredientPrototype, new_amount: integer?): pYdata.RecipePrototype, boolean
---@field public replace_ingredient_unsafe fun(self: pYdata.RecipePrototype, old_ingredient: string, new_ingredient: string | data.IngredientPrototype, new_amount: integer?): pYdata.RecipePrototype, boolean
---@field public add_ingredient fun(self: pYdata.RecipePrototype, ingredient: data.IngredientPrototype): pYdata.RecipePrototype, boolean
---@field public add_ingredient_unsafe fun(self: pYdata.RecipePrototype, ingredient: data.IngredientPrototype): pYdata.RecipePrototype, boolean
---@field public remove_ingredient fun(self: pYdata.RecipePrototype, ingredient_name: string): pYdata.RecipePrototype, integer
---@field public replace_result fun(self: pYdata.RecipePrototype, old_result: string, new_result: string | data.ProductPrototype, new_amount: integer?): pYdata.RecipePrototype, boolean
---@field public replace_result_unsafe fun(self: pYdata.RecipePrototype, old_result: string, new_result: string | data.ProductPrototype, new_amount: integer?): pYdata.RecipePrototype, boolean
---@field public add_result fun(self: pYdata.RecipePrototype, result: data.ProductPrototype): pYdata.RecipePrototype, boolean
---@field public remove_result fun(self: pYdata.RecipePrototype, result_name: string): pYdata.RecipePrototype, integer
---@field public clear_ingredients fun(self: pYdata.RecipePrototype): pYdata.RecipePrototype, boolean
---@field public clear_results fun(self: pYdata.RecipePrototype): pYdata.RecipePrototype, boolean
---@field public multiply_result_amount fun(self: pYdata.RecipePrototype, result_name: string, percent: number): pYdata.RecipePrototype, boolean
---@field public multiply_ingredient_amount fun(self: pYdata.RecipePrototype, ingredient_name: string, percent: number): pYdata.RecipePrototype, boolean
---@field public add_result_amount fun(self: pYdata.RecipePrototype, result_name: string, increase: number): pYdata.RecipePrototype, boolean
---@field public add_ingredient_amount fun(self: pYdata.RecipePrototype, ingredient_name: string, increase: number): pYdata.RecipePrototype, boolean
---@field public set_result_amount fun(self: pYdata.RecipePrototype, result_name: string, amount: number): pYdata.RecipePrototype, boolean
---@field public set_ingredient_amount fun(self: pYdata.RecipePrototype, ingredient_name: string, amount: number): pYdata.RecipePrototype, boolean
---@field public add_category fun(self: pYdata.RecipePrototype, category_name: data.RecipeCategoryID): pYdata.RecipePrototype, boolean
---@field public remove_category fun(self: pYdata.RecipePrototype, category_name: data.RecipeCategoryID): pYdata.RecipePrototype, boolean
---@field public replace_category fun(self: pYdata.RecipePrototype, old: data.RecipeCategoryID, new: data.RecipeCategoryID): pYdata.RecipePrototype, boolean
---@field public has_category fun(self: pYdata.RecipePrototype, category_name: data.RecipeCategoryID): boolean
---@field public has_categories fun(self: pYdata.RecipePrototype, category_name: data.RecipeCategoryID[], all?: boolean): boolean # Returns true if the recipe has any of the categories. all? categories must match to pass
---@field public get_main_product fun(self: pYdata.RecipePrototype, allow_multi_product: boolean?): LuaItemPrototype?|LuaFluidPrototype?
---@field public get_icons fun(self: pYdata.RecipePrototype): data.IconData[]
RECIPE = setmetatable(data.raw.recipe, {
    __call = function(self, recipe)
        local rtype = type(recipe)
        if rtype == "string" then
            if not self[recipe] then
                local dummyResult = {
                    __index = function(self2)
                        return self2
                    end,
                    __call = function(self2)
                        return self2
                    end
                }
                setmetatable(dummyResult, dummyResult)
                return dummyResult
            end
            recipe = setmetatable(self[recipe], {__index = metas})
        elseif rtype == "table" then
            local old_recipe = data.raw.recipe[recipe.name]
            if old_recipe then
                recipe.allow_productivity = recipe.allow_productivity or old_recipe.allow_productivity
            end
            recipe.type = "recipe"
            data:extend {recipe}
        else
            error("Invalid type " .. rtype)
        end
        return recipe:standardize()
    end
})

metas.standardize = function(self)
    self.results = self.results or {}

    -- ingredients is optional
    self.ingredients = self.ingredients or {}

    self.energy_required = self.energy_required or 0.5

    return self
end

py.allow_productivity = function(recipe_names)
    for _, recipe_name in pairs(recipe_names) do
        if data.raw.recipe[recipe_name] then
            data.raw.recipe[recipe_name].allow_productivity = true
        else
            log("WARNING @ allow_productivity(): Recipe " .. recipe_name .. " does not exist")
        end
    end
end

metas.add_unlock = function(self, technology_name)
    if type(technology_name) == "table" then
        local success = true
        for _, tech in pairs(technology_name) do
            local _, this_success = self:add_unlock(tech)
            success = success and this_success -- if any addition fails, the whole check fails
        end
        return self, success
    end

    local technology = data.raw.technology[technology_name]
    if not technology then
        log("WARNING @ \'" .. self.name .. "\':add_unlock(): Technology " .. technology_name .. " does not exist")
        return self, false -- fails, tech does not exist
    end

    technology.effects = technology.effects or {}

    -- skip adding unlocks twice
    for _, effect in pairs(technology.effects) do
        if effect.type == "unlock-recipe" and effect.recipe == self.name then
            return self, false -- fails, already in tech
        end
    end

    table_insert(technology.effects, {type = "unlock-recipe", recipe = self.name})

    self.enabled = false

    return self, true
end

metas.remove_unlock = function(self, technology_name)
    if type(technology_name) == "table" then
        local success = true
        for _, tech in pairs(technology_name) do
            local _, this_success = self:remove_unlock(tech)
            success = success and this_success
        end
        return self, success -- if any removal fails, the whole check fails
    end

    local technology = data.raw.technology[technology_name]
    if not technology then
        log("WARNING @ \'" .. self.name .. "\':remove_unlock(): Technology " .. technology_name .. " does not exist")
        return self, false -- fails, tech does not exist
    elseif not technology.effects then
        return self, false -- tech effects do not exist
    end

    for i, effect in pairs(technology.effects) do
        if effect.recipe == self.name then
            table.remove(technology.effects, i)
            return self, true -- successfully removed recipe from tech
        end
    end

    return self, false -- recipe not part of tech
end

metas.replace_unlock = function(self, technology_old, technology_new)
    local _, success_remove = self:remove_unlock(technology_old)
    local _, success_add = self:add_unlock(technology_new)

    return self, success_remove and success_add -- fails if either fails
end

do
    --old is a string
    local function replacement_helper(recipe, ingredients_or_results, old, new, new_amount, unsafe)
        local type = type(new)
        if type == "string" then
            if not FLUID[new] and not ITEM[new] and not unsafe then
                log("WARNING @ \'" .. recipe.name .. "\':replace_ingredient(): Ingredient " .. new .. " does not exist")
                return false
            end
            for _, ingredient in pairs(ingredients_or_results) do
                if ingredient.name == old then
                    ingredient.name = new
                    ingredient.type = FLUID[new] and "fluid" or "item"
                    ingredient.minimum_temperature = nil
                    ingredient.maximum_temperature = nil
                    ingredient.temperature = nil
                    if new_amount then
                        ingredient.amount = new_amount
                        ingredient.amount_min = nil
                        ingredient.amount_max = nil
                    end
                end
            end
        elseif type == "table" then
            new = table.deepcopy(new)
            if not FLUID[new.name] and not ITEM[new.name] and not unsafe then
                log("WARNING @ \'" .. recipe.name .. "\':replace_ingredient(): Ingredient " .. new.name .. " does not exist")
                return false
            end
            for k, ingredient in pairs(ingredients_or_results) do
                if ingredient.name == old then
                    ingredients_or_results[k] = new
                end
            end
        end
        return true -- must have been a success! cant early return on success because of possible repeated results
    end

    metas.replace_ingredient = function(self, old_ingredient, new_ingredient, new_amount)
        self:standardize()
        local success = replacement_helper(self, self.ingredients, old_ingredient, new_ingredient, new_amount, false)
        return self, success
    end

    metas.replace_ingredient_unsafe = function(self, old_ingredient, new_ingredient, new_amount)
        self:standardize()
        local success = replacement_helper(self, self.ingredients, old_ingredient, new_ingredient, new_amount, true)
        return self, success
    end

    metas.replace_result = function(self, old_result, new_result, new_amount)
        self:standardize()
        local success = replacement_helper(self, self.results, old_result, new_result, new_amount, false)
        if self.main_product == old_result then
            self.main_product = type(new_result) == "string" and new_result or new_result.name
        end
        return self, success
    end

    metas.replace_result_unsafe = function(self, old_result, new_result, new_amount)
        self:standardize()
        local success = replacement_helper(self, self.results, old_result, new_result, new_amount, true)
        if self.main_product == old_result then
            self.main_product = type(new_result) == "string" and new_result or new_result.name
        end
        return self, success
    end
end

metas.add_ingredient_unsafe = function(self, ingredient)
    self:standardize()
    -- Ensure that this ingredient does not already exist in this recipe.
    -- If so, combine their amounts and catalyst amounts.
    for _, existing in pairs(self.ingredients) do
        if existing.name == ingredient.name and existing.type == ingredient.type then
            if existing.amount and ingredient.amount then
                existing.amount = existing.amount + ingredient.amount
                existing.ignored_by_stats = (existing.ignored_by_stats or 0) + (ingredient.ignored_by_stats or 0)
                return self, true
            end
        end
    end

    if ingredient.type == "fluid" and self:has_category("crafting") then
        self:replace_category("crafting", "crafting-with-fluid")
    end

    table_insert(self.ingredients, ingredient)
    return self, true
end

metas.add_ingredient = function(self, ingredient)
    self:standardize()
    if not FLUID[ingredient.name] and not ITEM[ingredient.name] then
        log("WARNING @ \'" .. self.name .. "\':add_ingredient(): Ingredient " .. ingredient.name .. " does not exist")
        return self, false
    end

    return metas.add_ingredient_unsafe(self, ingredient)
end

metas.add_result = function(self, result)
    self:standardize()
    table_insert(self.results, result)
    return self, true
end

metas.remove_ingredient = function(self, ingredient_name)
    self:standardize()
    local amount_removed = 0
    self.ingredients = table.filter(self.ingredients, function(ingredient)
        if ingredient.name == ingredient_name then
            amount_removed = amount_removed + ingredient.amount
            return false
        end
        return true
    end)
    return self, amount_removed
end

metas.remove_result = function(self, result_name)
    self:standardize()
    local amount_removed = 0
    self.results = table.filter(self.results, function(result)
        if result.name == result_name then
            local amount = result.amount * (result.independent_probability or 1) or (result.amount_min + result.amount_max) * (result.independent_probability or 1) / 2
            amount_removed = amount_removed + amount
            return false
        end
        return true
    end)
    return self, amount_removed
end

metas.clear_ingredients = function(self)
    self.ingredients = {}
    return self, true -- impossible to fail
end

metas.clear_results = function(self)
    self.results = {}
    return self, true -- impossible to fail
end

metas.multiply_result_amount = function(self, result_name, percent)
    self:standardize()

    for _, result in pairs(self.results) do
        if result.name == result_name then
            local amount = result.amount or (result.amount_min + result.amount_max) / 2
            result.amount = math.ceil(amount * percent)
            if result.amount == 0 then
                self:remove_result(result_name)
                return self, true -- successful multiply
            end
            result.amount_min = nil
            result.amount_max = nil
            return self, true -- successful multiply
        end
    end

    log("WARNING @ \'" .. self.name .. "\':multiply_result_amount(): Result " .. result_name .. " not found")
    return self, false -- could not find result
end

metas.multiply_ingredient_amount = function(self, ingredient_name, percent)
    self:standardize()

    for _, ingredient in pairs(self.ingredients) do
        if ingredient.name == ingredient_name then
            ingredient.amount = math.ceil(ingredient.amount * percent)
            if ingredient.amount == 0 then
                self:remove_ingredient(ingredient_name)
                return self, true -- successful multiply
            end
            return self, true -- successful multiply
        end
    end

    log("WARNING @ \'" .. self.name .. "\':multiply_ingredient_amount(): Ingredient " .. ingredient_name .. " not found")
    return self, false -- could not find ingredient
end

metas.add_result_amount = function(self, result_name, increase)
    self:standardize()

    for _, result in pairs(self.results) do
        if result.name == result_name then
            result.amount = result.amount + increase
            if result.amount <= 0 then
                self:remove_result(result_name)
                return self, true -- successful addition
            end
            return self, true -- successful addition
        end
    end

    log("WARNING @ \'" .. self.name .. "\':add_result_amount(): Result " .. result_name .. " not found")
    return self, false -- could not find result
end

metas.add_ingredient_amount = function(self, ingredient_name, increase)
    self:standardize()

    for _, ingredient in pairs(self.ingredients) do
        if ingredient.name == ingredient_name then
            ingredient.amount = ingredient.amount + increase
            if ingredient.amount <= 0 then
                self:remove_ingredient(ingredient_name)
                return self, true -- successful addition
            end
            return self, true -- successful addition
        end
    end

    log("WARNING @ \'" .. self.name .. "\':add_ingredient_amount(): Ingredient " .. ingredient_name .. " not found")
    return self, false -- could not find ingredient
end

metas.set_result_amount = function(self, result_name, amount)
    return self:replace_result(result_name, result_name, amount)
end

metas.set_ingredient_amount = function(self, ingredient_name, amount)
    return self:replace_ingredient(ingredient_name, ingredient_name, amount)
end

metas.add_category = function(self, category_name)
    self:standardize()
    self.categories = self.categories or {} -- not in self:standardize() because a recipe with no categories errors the game

    if not data.raw["recipe-category"][category_name] then
        log("WARNING @ \'" .. self.name .. "\':add_category(): Category " .. category_name .. " not found")
        return self, false -- category does not exist
    else
        for _, category in pairs(self.categories) do
            if category == category_name then
                return self, false -- category already set
            end
        end
        self.categories[#self.categories+1] = category_name
        return self, true -- successful set
    end
end

metas.remove_category = function(self, category_name)
    self:standardize()

    if not data.raw["recipe-category"][category_name] then
        log("WARNING @ \'" .. self.name .. "\':remove_category(): Category " .. category_name .. " not found")
        return self, false -- category does not exist
    else
        if category_name == "crafting" and (not self.categories or #self.categories == 0) then
            return self, true -- fake positive if trying to remove 'category' with no categories because its the default
        end
        for i, category in pairs(self.categories or {}) do
            if category == category_name then
                table.remove(self.categories, i)
                if #self.categories == 0 then self.categories = nil end -- remove categories if it is an empty table
                return self, true -- successfully removed
            end
        end
        return self, false -- category not found
    end
end

metas.replace_category = function(self, old, new)
    self:standardize()

    if not data.raw["recipe-category"][old] then
        log("WARNING @ \'" .. self.name .. "\':replace_category(): Category " .. old .. " not found")
        return self, false -- category does not exist
    elseif not data.raw["recipe-category"][new] then
        log("WARNING @ \'" .. self.name .. "\':replace_category(): Category " .. new .. " not found")
        return self, false -- category does not exist
    else
        local _, success = self:remove_category(old)
        if success then
            return self:add_category(new) -- conditional on success of add_category
        else
            log("WARNING @ \'" .. self.name .. "\':replace_category(): Category " .. old .. " not present for replacement")
            return self, false -- DNE, do not add
        end
    end
end

metas.has_category = function(self, category_name)
    self:standardize()

    if not data.raw["recipe-category"][category_name] then
        log("WARNING @ \'" .. self.name .. "\':replace_category(): Category " .. category_name .. " not found")
        return false -- category does not exist
    else
        if category_name == "crafting" and (not self.categories or #self.categories == 0) then
            return self, true -- fake positive if trying to remove 'category' with no categories because its the default
        end
        for _, category in pairs(self.categories or {}) do
            if category == category_name then
                return true -- category found
            end
        end
        return false -- category not found
    end
end

metas.has_categories = function(self, categories, all)
    self:standardize()

    for _, category in pairs(categories) do
        if all and not self:has_category(category) then
            return false -- all categories must be contained but this one was not
        elseif not all and self:has_category(category) then
            return true -- any categories must match and this one matched
        end
    end
    return not not all -- all categories matched, or none did
end

--- Get the prototype for the main_product using the same logic the game uses.
--- Set allow_multi_product to take the *first* result (not game behavior) instead of failing when a recipe has no main_product set but has multiple results.
--- <br /> Check https://lua-api.factorio.com/latest/prototypes/RecipePrototype.html#main_product for more details
metas.get_main_product = function(self, allow_multi_product)
    self:standardize()
    local target, target_type = self.main_product, "item"
    -- main product of "" prevents the recipe from inheriting properties from a single result
    if target == "" then
        target = nil
    end

    local result_count = table_size(self.results or {})
    if result_count == 0 or (not target and not allow_multi_product and result_count > 1) then return end

    local result
    if target then -- find with specific name
        for _, v in pairs(self.results) do
            if v.name == target then
                result = v
            end
        end
    else -- or only result
        _, result = next(self.results)
    end
    --[[@cast result data.ItemProductPrototype]]
    -- Special modding funtimes case: invalid spec
    if not result.name then return end
    if result.type ~= nil and result.type ~= "item" and result.type ~= "fluid" then return end
    target, target_type = result.name, result.type or target_type
    -- Find our prototype :)
    for _, category in py.iter_prototype_categories(target_type) do
        local proto = category[target]
        if proto then return proto end
    end
    -- haha oh no
end

local function icons(proto)
    -- Has priority over .icon
    if proto.icons then
        return table.deepcopy(proto.icons)
    end
    if proto.icon then
        return {{
            icon = proto.icon,
            icon_size = proto.icon_size
        }}
    end
end

--- Returns the icons table a recipe would use (i.e. using the item icon if the recipe prototype has no .icons/.icon set).
--- May error on malformed prototypes.
--- <br /> Check https://lua-api.factorio.com/latest/prototypes/RecipePrototype.html#icon for more details.
metas.get_icons = function(self)
    local icon = icons(self)
    if icon then return icon end

    local product = self:get_main_product()
    if product then
        icon = icons(product)
        if icon then return icon end
        local place_result = product.place_result
        if place_result then
            -- Step through the list until either it ends or we find our thing
            local iterable = py.iter_prototype_categories("entity")
            while true do
                local _, next_category = iterable()
                if not next_category then break end
                local placed_entity = next_category[place_result]
                if placed_entity then
                    return icons(placed_entity)
                end
            end
        end
    end
    log(serpent.block(self))
    error(string.format("Couldn't find icons for recipe %s", self.name))
end

return metas
