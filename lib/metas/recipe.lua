local table_insert = table.insert

---@class data.RecipePrototype
---@field public standardize fun(self: data.RecipePrototype): data.RecipePrototype
---@field public add_unlock fun(self: data.RecipePrototype, technology_name: string | string[]): data.RecipePrototype
---@field public remove_unlock fun(self: data.RecipePrototype, technology_name: string | string[]): data.RecipePrototype
---@field public replace_unlock fun(self: data.RecipePrototype, technology_old: string | string[], technology_new: string | string[]): data.RecipePrototype
---@field public replace_ingredient fun(self: data.RecipePrototype, old_ingredient: string, new_ingredient: string | data.IngredientPrototype, new_amount: integer?): data.RecipePrototype
---@field public add_ingredient fun(self: data.RecipePrototype, ingredient: string | data.IngredientPrototype): data.RecipePrototype
---@field public remove_ingredient fun(self: data.RecipePrototype, ingredient_name: string): data.RecipePrototype, integer
---@field public replace_result fun(self: data.RecipePrototype, old_result: string, new_result: string | data.ProductPrototype, new_amount: integer?): data.RecipePrototype
---@field public add_result fun(self: data.RecipePrototype, result: string | data.ProductPrototype): data.RecipePrototype
---@field public remove_result fun(self: data.RecipePrototype, result_name: string): data.RecipePrototype
---@field public clear_ingredients fun(self: data.RecipePrototype): data.RecipePrototype
---@field public multiply_result_amount fun(self: data.RecipePrototype, result_name: string, percent: number): data.RecipePrototype
---@field public multiply_ingredient_amount fun(self: data.RecipePrototype, ingredient_name: string, percent: number): data.RecipePrototype
---@field public add_result_amount fun(self: data.RecipePrototype, result_name: string, increase: number): data.RecipePrototype
---@field public add_ingredient_amount fun(self: data.RecipePrototype, ingredient_name: string, increase: number): data.RecipePrototype
---@field public set_result_amount fun(self: data.RecipePrototype, result_name: string, amount: number): data.RecipePrototype
---@field public set_ingredient_amount fun(self: data.RecipePrototype, ingredient_name: string, amount: number): data.RecipePrototype
---@field public get_main_product fun(self: data.RecipePrototype): LuaItemPrototype?|LuaFluidPrototype?
---@field public get_icons fun(self: data.RecipePrototype): data.IconData

local metas = {}

RECIPE = setmetatable(data.raw.recipe, {
    ---@param recipe data.RecipePrototype
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
        for _, tech in pairs(technology_name) do
            self:add_unlock(tech)
        end
        return self
    end

    local technology = data.raw.technology[technology_name]
    if not technology then
        log("WARNING @ \'" .. self.name .. "\':add_unlock(): Technology " .. technology_name .. " does not exist")
        return self
    end

    if not technology.effects then
        technology.effects = {}
    end

    table_insert(technology.effects, {type = "unlock-recipe", recipe = self.name})

    self.enabled = false

    return self
end

metas.remove_unlock = function(self, technology_name)
    if type(technology_name) == "table" then
        for _, tech in pairs(technology_name) do
            self:remove_unlock(tech)
        end
        return self
    end

    local technology = data.raw.technology[technology_name]
    if not technology then
        log("WARNING @ \'" .. self.name .. "\':remove_unlock(): Technology " .. technology_name .. " does not exist")
        return self
    end

    if not technology.effects then
        return self
    end

    technology.effects = table.filter(technology.effects, function(effect)
        return effect.recipe ~= self.name
    end)

    return self
end

metas.replace_unlock = function(self, technology_old, technology_new)
    self:remove_unlock(technology_old):add_unlock(technology_new)

    return self
end

do
    --old is a string
    local function replacement_helper(recipe, ingredients_or_results, old, new, new_amount)
        local type = type(new)
        if type == "string" then
            if not FLUID[new] and not ITEM[new] then
                log("WARNING @ \'" .. recipe.name .. "\':replace_ingredient(): Ingredient " .. new .. " does not exist")
                return
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
            if not FLUID[new.name] and not ITEM[new.name] then
                log("WARNING @ \'" .. recipe.name .. "\':replace_ingredient(): Ingredient " .. new.name .. " does not exist")
                return
            end
            for k, ingredient in pairs(ingredients_or_results) do
                if ingredient.name == old then
                    ingredients_or_results[k] = new
                end
            end
        end
    end

    metas.replace_ingredient = function(self, old_ingredient, new_ingredient, new_amount)
        self:standardize()
        replacement_helper(self, self.ingredients, old_ingredient, new_ingredient, new_amount)
        return self
    end

    metas.replace_result = function(self, old_result, new_result, new_amount)
        self:standardize()
        replacement_helper(self, self.results, old_result, new_result, new_amount)
        if self.main_product == old_result then
            self.main_product = type(new_result) == "string" and new_result or new_result[1] or new_result.name
        end
        return self
    end
end

metas.add_ingredient = function(self, ingredient)
    self:standardize()
    if not FLUID[ingredient.name] and not ITEM[ingredient.name] then
        log("WARNING @ \'" .. self.name .. "\':add_ingredient(): Ingredient " .. ingredient.name .. " does not exist")
        return self
    end

    -- Ensure that this ingredient does not already exist in this recipe.
    -- If so, combine their amounts and catalyst amounts.
    for _, existing in pairs(self.ingredients) do
        if existing.name == ingredient.name and existing.type == ingredient.type then
            if existing.amount and ingredient.amount then
                existing.amount = existing.amount + ingredient.amount
                existing.ignored_by_productivity = (existing.ignored_by_productivity or 0) + (ingredient.ignored_by_productivity or 0)
                return self
            end
        end
    end

    if (not self.category or self.category == "crafting") and ingredient.type == "fluid" then
        self.category = "crafting-with-fluid"
    end

    table_insert(self.ingredients, ingredient)
    return self
end

metas.add_result = function(self, result)
    self:standardize()
    table_insert(self.results, result)
    return self
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
            local amount = result.amount * (result.probability or 1) or (result.amount_min + result.amount_max) * (result.probability or 1) / 2
            amount_removed = amount_removed + amount
            return false
        end
        return true
    end)
    return self, amount_removed
end

metas.clear_ingredients = function(self)
    self.ingredients = {}
    return self
end

metas.multiply_result_amount = function(self, result_name, percent)
    self:standardize()

    for _, result in pairs(self.results) do
        if result.name == result_name then
            local amount = result.amount or (result.amount_min + result.amount_max) / 2
            result.amount = math.ceil(amount * percent)
            if result.amount == 0 then
                self:remove_result(result_name)
                return
            end
            result.amount_min = nil
            result.amount_max = nil
            return self
        end
    end

    log("WARNING @ \'" .. self.name .. "\':multiply_result_amount(): Result " .. result_name .. " not found")
    return self
end

metas.multiply_ingredient_amount = function(self, ingredient_name, percent)
    self:standardize()

    for _, ingredient in pairs(self.ingredients) do
        if ingredient.name == ingredient_name then
            ingredient.amount = math.ceil(ingredient.amount * percent)
            if ingredient.amount == 0 then
                self:remove_ingredient(ingredient_name)
                return
            end
            return self
        end
    end

    log("WARNING @ \'" .. self.name .. "\':multiply_ingredient_amount(): Ingredient " .. ingredient_name .. " not found")
    return self
end

metas.add_result_amount = function(self, result_name, increase)
    self:standardize()

    for _, result in pairs(self.results) do
        if result.name == result_name then
            result.amount = result.amount + increase
            if result.amount == 0 then
                self:remove_result(result_name)
                return
            end
            return self
        end
    end

    log("WARNING @ \'" .. self.name .. "\':add_result_amount(): Result " .. result_name .. " not found")
    return self
end

metas.add_ingredient_amount = function(self, ingredient_name, increase)
    self:standardize()

    for _, ingredient in pairs(self.ingredients) do
        if ingredient.name == ingredient_name then
            ingredient.amount = ingredient.amount + increase
            if ingredient.amount == 0 then
                self:remove_ingredient(ingredient_name)
                return
            end
            return self
        end
    end

    log("WARNING @ \'" .. self.name .. "\':add_ingredient_amount(): Ingredient " .. ingredient_name .. " not found")
    return self
end

metas.set_result_amount = function(self, result_name, amount)
    self:replace_result(result_name, result_name, amount)
    return self
end

metas.set_ingredient_amount = function(self, ingredient_name, amount)
    self:replace_ingredient(ingredient_name, ingredient_name, amount)
    return self
end

metas.change_category = function(self, category_name)
    self:standardize()

    if data.raw['recipe-category'][category_name] then
        self.category = category_name
    else
        log("WARNING @ \'" .. self.name .. "\':change_category(): Category " .. category_name  .. " not found")
    end

    return self
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
    -- Special modding funtimes case: invalid spec
    if not (result.type == "research-progress" and result.research_item or result.name) then return end
    if result.type ~= nil and (result.type ~= "item" and result.type ~= "fluid" and result.type ~= "research-progress") then return end
    target, target_type = result.name, result.type or target_type
    -- Special case: type of research-progress uses an item prototype
    if target_type == "research-progress" then
        target = result.research_item
        target_type = "item"
    end
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
