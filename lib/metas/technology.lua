---@class data.TechnologyPrototype
---@field public standardize fun(): data.TechnologyPrototype
---@field public add_prereq fun(self, prereq_technology_name: string): data.TechnologyPrototype
---@field public remove_prereq fun(self, prereq_technology_name: string): data.TechnologyPrototype
---@field public remove_pack fun(self, science_pack_name: string): data.TechnologyPrototype
---@field public add_pack fun(self, science_pack_name: string): data.TechnologyPrototype
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
    self.effects = self.effects or {}

    return self
end

---@param self data.TechnologyPrototype
---@param prereq_technology_name string
---@return data.TechnologyPrototype self
---@return boolean success
metas.add_prereq = function(self, prereq_technology_name)
    local prereq_technology = data.raw.technology[prereq_technology_name]
    if not prereq_technology then
        log("WARNING @ \'" .. self.name .. "\':add_prereq(): Technology " .. prereq_technology_name .. " does not exist")
        return self, false -- add prereq failed
    end

    self.prerequisites = self.prerequisites or {}

    for _, prereq in pairs(self.prerequisites) do
        if prereq == prereq_technology_name then
            return self, true -- should it be true? false? its already in the tech
        end
    end

    self.prerequisites[#self.prerequisites + 1] = prereq_technology_name

    return self, true -- add prereq succeeds
end

---@param self data.TechnologyPrototype
---@param prereq_technology_name string
---@return data.TechnologyPrototype self
---@return boolean success
metas.remove_prereq = function(self, prereq_technology_name)
    if not self.prerequisites then
        return self, true -- should it be true? false?
    end

    for i, prereq in pairs(self.prerequisites) do
      if prereq == prereq_technology_name then
        table.remove(self.prerequisites, i)
        return self, true -- remove prereq succeeds
      end
    end

    return self, false -- remove prereq fails
end

---@param self data.TechnologyPrototype
---@param science_pack_name string
---@return data.TechnologyPrototype self
---@return boolean success
metas.remove_pack = function(self, science_pack_name)
    if not self.unit then
        return self, true -- should it be true? false?
    end

    for i, ingredient in pairs(self.unit.ingredients) do
        if ingredient[1] == science_pack_name then
            table.remove(self.unit.ingredients, i)
            return self, true -- remove pack succeeds
        end
    end

    return self, false -- remove pack fails
end

-- possible to add the same pack twice, should probably check for that
---@param self data.TechnologyPrototype
---@param science_pack_name string
---@return data.TechnologyPrototype self
---@return boolean success
metas.add_pack = function(self, science_pack_name)
    if self.research_trigger then
        error("WARNING @ \'" .. self.name .. "\':add_pack(): Attempted to add science packs to technology with research_trigger.")
    end

    self.unit = self.unit or {ingredients = {}}

    for _, ingredient in pairs(self.unit.ingredients) do
        if ingredient[1] == science_pack_name then
            return self, true -- add pack fails, it already exists
        end
    end

    table.insert(self.unit.ingredients, {science_pack_name, 1})

    return self, true -- add pack succeeds
end

return metas
