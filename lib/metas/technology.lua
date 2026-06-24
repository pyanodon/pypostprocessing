---@class pYdata.TechnologyPrototype:pYdata.AnyPrototype,data.TechnologyPrototype
---@operator call(string|pYdata.TechnologyPrototype|data.TechnologyPrototype): pYdata.TechnologyPrototype
---@field public standardize fun(self: pYdata.TechnologyPrototype): pYdata.TechnologyPrototype
---@field public add_prereq fun(self: pYdata.TechnologyPrototype, prereq_technology_name: data.TechnologyID): pYdata.TechnologyPrototype, boolean
---@field public remove_prereq fun(self: pYdata.TechnologyPrototype, prereq_technology_name: data.TechnologyID): pYdata.TechnologyPrototype, boolean
---@field public replace_prereq fun(self: pYdata.TechnologyPrototype, old: data.TechnologyID, new: data.TechnologyID): pYdata.TechnologyPrototype, boolean
---@field public remove_pack fun(self: pYdata.TechnologyPrototype, science_pack_name: data.ItemID): pYdata.TechnologyPrototype, boolean
---@field public add_pack fun(self: pYdata.TechnologyPrototype, science_pack_name: data.ItemID): pYdata.TechnologyPrototype, boolean
TECHNOLOGY = setmetatable(data.raw.technology, {
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

---@diagnostic disable-next-line: missing-fields
---@type pYdata.TechnologyPrototype
local metas = {}

metas.standardize = function(self)
 ---@diagnostic disable-next-line: assign-type-mismatch
    if not self.unit and not self.research_trigger then self.unit = {ingredients = {}} end

    self.prerequisites = self.prerequisites or {}
    self.effects = self.effects or {}

    return self
end

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

metas.remove_prereq = function(self, prereq_technology_name)
    self.prerequisites = self.prerequisites or {}

    for i, prereq in pairs(self.prerequisites) do
      if prereq == prereq_technology_name then
        table.remove(self.prerequisites, i)
        return self, true -- remove prereq succeeds
      end
    end

    return self, false -- remove prereq fails
end

--- Replace old prerequesite with the new one. Fails if the old one was not found.
metas.replace_prereq = function(self, old, new)
    local _, success = self:remove_prereq(old)
    if success then
        return self:add_prereq(new) -- conditional on success of add_prereq
    else
        return self, false -- DNE, do not add
    end
end

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
metas.add_pack = function(self, science_pack_name)
    if self.research_trigger then
        error("WARNING @ \'" .. self.name .. "\':add_pack(): Attempted to add science packs to technology with research_trigger.")
    end

    ---@diagnostic disable-next-line: assign-type-mismatch
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
