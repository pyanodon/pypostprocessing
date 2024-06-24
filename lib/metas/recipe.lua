---@class data.RecipePrototype
---@field public standardize fun(self: data.RecipePrototype): data.RecipePrototype
---@field public allow_productivity fun(self: data.RecipePrototype): data.RecipePrototype
---@field public add_unlock fun(self: data.RecipePrototype, technology_name: string | string[]): data.RecipePrototype
---@field public remove_unlock fun(self: data.RecipePrototype, technology_name: string | string[]): data.RecipePrototype
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

RECIPE = setmetatable(data.raw.recipe, {
    ---@param recipe data.RecipePrototype
    __call = function(self, recipe)
        local rtype = type(recipe)
        if rtype == 'string' then
            if not self[recipe] then error('Recipe ' .. tostring(recipe) .. ' does not exist') end
            recipe = self[recipe]
        elseif rtype == 'table' then
            recipe.type = 'recipe'
            data:extend{recipe}
        else error('Invalid type ' .. rtype) end
        return recipe:standardize()
    end
})

local metas = {}

metas.standardize = function(self)
    if self.normal then
        for k, v in pairs(self.normal) do
            if not self[k] then self[k] = v end
        end
    elseif self.expensive then
        for k, v in pairs(self.expensive) do
            if not self[k] then self[k] = v end
        end
    end
    self.normal = nil
    self.expensive = nil

    if self.results and type(self.results) == 'table' then
        self.result = nil
        self.result_count = nil
    elseif self.result then
        self.results = {{type = 'item', name = self.result, amount = self.result_count or 1}}
    else
        self.results = {}
    end

    for k, p in pairs(self.results) do
        self.results[k] = py.standardize_product(p)
    end

    for k, p in pairs(self.ingredients) do
        self.ingredients[k] = py.standardize_product(p)
    end

    self.energy_required = self.energy_required or 0.5

    return self
end

local productivity_modules = nil
metas.allow_productivity = function(self)
    if not productivity_modules then
        productivity_modules = {}
        for _, module in pairs(data.raw.module) do
            if module.name:find('productivity%-module') and module.limitation then
                productivity_modules[module] = true
            end
        end
    end

    for module in pairs(productivity_modules) do
        table.insert(module.limitation, self.name)
    end

    return self
end

py.allow_productivity = function(recipe_names)
    productivity_modules = nil
    for _, recipe_name in pairs(recipe_names) do
        if data.raw.recipe[recipe_name] then
            RECIPE(recipe_name):allow_productivity()
        else
            log('WARNING @ allow_productivity(): Recipe ' .. recipe_name .. ' does not exist')
        end
    end

    for module in pairs(productivity_modules or {}) do
        module.limitation = table.dedupe(module.limitation)
    end
end

metas.add_unlock = function(self, technology_name)
    if type(technology_name) == 'table' then
        for _, tech in pairs(technology_name) do
            self:add_unlock(tech)
        end
        return self
    end

    local technology = data.raw.technology[technology_name]
    if not technology then
        log('WARNING @ \'' .. self.name .. '\':add_unlock(): Technology ' .. technology_name .. ' does not exist')
        return self
    end

    if not technology.effects then
        technology.effects = {}
    end

    table.insert(technology.effects, {type = 'unlock-recipe', recipe = self.name})

    self.enabled = false

    return self
end

metas.remove_unlock = function(self, technology_name)
    if type(technology_name) == 'table' then
        for _, tech in pairs(technology_name) do
            self:remove_unlock(tech)
        end
        return self
    end

    local technology = data.raw.technology[technology_name]
    if not technology then
        log('WARNING @ \'' .. self.name .. '\':remove_unlock(): Technology ' .. technology_name .. ' does not exist')
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

do
    local function replacement_helper(recipe, ingredients_or_results, old, new, new_amount)
        local type = type(new)
        if type == 'string' then
            if not FLUID[new] and not ITEM[new] then
                log('WARNING @ \'' .. recipe.name .. '\':replace_ingredient(): Ingredient ' .. new .. ' does not exist')
                return
            end
            for _, ingredient in pairs(ingredients_or_results) do
                if ingredient.name == old then
                    ingredient.name = new
                    ingredient.type = FLUID[new] and 'fluid' or 'item'
                    if new_amount then
                        ingredient.amount = new_amount
                        ingredient.amount_min = nil
                        ingredient.amount_max = nil
                    end
                end
            end
        elseif type == 'table' then
            for k, ingredient in pairs(ingredients_or_results) do
                if ingredient.name == old then
                    ingredients_or_results[k] = py.standardize_product(new)
                end
            end
        end
    end

    metas.replace_ingredient = function(self, old_ingredient, new_ingredient, new_amount)
        self:standardize()
        replacement_helper(self, self.ingredients, old_ingredient, new_ingredient, new_amount)
        return self
    end

    metas.replace_result = function(self, old_result, new_result)
        self:standardize()
        replacement_helper(self, self.results, old_result, new_result, new_amount)
        if self.main_product == old_result then
            self.main_product = type(new_result) == 'string' and new_result or new_result[1] or new_result.name
        end
        return self
    end
end

metas.add_ingredient = function(self, ingredient)
    self:standardize()
    ingredient = py.standardize_product(ingredient)
    if not FLUID[ingredient.name] and not ITEM[ingredient.name] then
        log('WARNING @ \'' .. self.name .. '\':add_ingredient(): Ingredient ' .. ingredient.name .. ' does not exist')
    else
        table.insert(self.ingredients, ingredient)
    end
    return self
end

metas.add_result = function(self, result)
    self:standardize()
    table.insert(self.results, py.standardize_product(result))
    return self
end

metas.remove_ingredient = function(self, ingredient_name)
    self:standardize()
    local amount_removed = 0
    self.ingredients = table.filter(self.ingredients, function(ingredient)
        if ingredient.name == ingredient_name then
            local amount = ingredient.amount or (ingredient.amount_min + ingredient.amount_max) / 2
            amount_removed = amount_removed + amount
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
            local amount = result.amount or (result.amount_min + result.amount_max) / 2
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
            result.amount_min = nil
            result.amount_max = nil
            return self
        end
    end

    log('WARNING @ \'' .. self.name .. '\':multiply_result_amount(): Result ' .. result_name .. ' not found')
    return self
end

metas.multiply_ingredient_amount = function(self, ingredient_name, percent)
    self:standardize()

    for _, ingredient in pairs(self.ingredients) do
        if ingredient.name == ingredient_name then
            ingredient.amount = math.ceil(ingredient.amount * percent)
            return self
        end
    end

    log('WARNING @ \'' .. self.name .. '\':multiply_ingredient_amount(): Ingredient ' .. ingredient_name .. ' not found')
    return self
end

metas.add_result_amount = function(self, result_name, increase)
    self:standardize()

    for _, result in pairs(self.results) do
        if result.name == result_name then
            result.amount = result.amount + increase
            return self
        end
    end

    log('WARNING @ \'' .. self.name .. '\':add_result_amount(): Result ' .. result_name .. ' not found')
    return self
end

metas.add_ingredient_amount = function(self, ingredient_name, increase)
    self:standardize()

    for _, ingredient in pairs(self.ingredients) do
        if ingredient.name == ingredient_name then
            ingredient.amount = ingredient.amount + increase
            return self
        end
    end

    log('WARNING @ \'' .. self.name .. '\':add_ingredient_amount(): Ingredient ' .. ingredient_name .. ' not found')
    return self
end

return metas