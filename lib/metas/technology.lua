---@class data.TechnologyPrototype
---@field public standardize fun(): data.TechnologyPrototype
---@field public add_prereq fun(prereq_technology_name: string): data.TechnologyPrototype
---@field public remove_prereq fun(prereq_technology_name: string): data.TechnologyPrototype
---@field public remove_pack fun(science_pack_name: string): data.TechnologyPrototype
---@field public add_pack fun(science_pack_name: string): data.TechnologyPrototype
---@field dependencies string[]

TECHNOLOGY = setmetatable(data.raw.technology, {
    ---@param technology data.TechnologyPrototype
    __call = function(self, technology)
        local ttype = type(technology)
        if ttype == "string" then
            if not self[technology] then error("Technology " .. technology .. " does not exist") end
            technology = self[technology]
        elseif ttype == "table" then
            technology.type = "technology"
            data:extend {technology}
        else
            error("Invalid type " .. ttype)
        end
        return technology:standardize()
    end
})

local metas = {}

metas.standardize = function(self)
    if not self.unit and not self.research_trigger then self.unit = {ingredients = {}} end

    self.prerequisites = self.prerequisites or {}
    self.dependencies = self.dependencies or {}
    self.effects = self.effects or {}

    return self
end

metas.add_prereq = function(self, prereq_technology_name)
    local prereq_technology = data.raw.technology[prereq_technology_name]
    if not prereq_technology then
        log("WARNING @ \'" .. self.name .. "\':add_prereq(): Technology " .. prereq_technology_name .. " does not exist")
        return self
    end

    if not self.prerequisites then
        self.prerequisites = {}
    end

    table.insert(self.prerequisites, prereq_technology_name)

    return self
end

metas.remove_prereq = function(self, prereq_technology_name)
    if not self.prerequisites then
        return self
    end

    self.prerequisites = table.filter(self.prerequisites, function(prereq) return prereq ~= prereq_technology_name end)

    return self
end

metas.remove_pack = function(self, science_pack_name)
    if not self.unit then
        return self
    end

    self.unit.ingredients = table.filter(self.unit.ingredients, function(ingredient) return ingredient[1] ~= science_pack_name end)

    return self
end

metas.add_pack = function(self, science_pack_name)
    if self.research_trigger then
        error("WARNING @ \'" .. self.name .. "\':add_pack(): Attempted to add science packs to technology with research_trigger.")
    end

    if not self.unit then
        self.unit = {ingredients = {}}
    end

    table.insert(self.unit.ingredients, {science_pack_name, 1})

    return self
end

return metas
