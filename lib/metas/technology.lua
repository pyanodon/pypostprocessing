local log = py.log.init("TECHNOLOGY")

---@diagnostic disable-next-line: missing-fields
---@type pYdata.TechnologyPrototype
local metas = {}

local metatable = {
    __index = function(self, index) return metas[index] or self.prototype[index] end,
    __newindex = function(self, index, value) self.prototype[index] = value end
}

---@class pYdata.TechnologyPrototype:pYdata.AnyPrototype,data.TechnologyPrototype
---@field prerequisites data.TechnologyID[]
---@field effects data.Modifier[]
---@operator call(string|pYdata.TechnologyPrototype|data.TechnologyPrototype): pYdata.TechnologyPrototype
---@field public standardize fun(self: pYdata.TechnologyPrototype): pYdata.TechnologyPrototype
---@field public add_prereq fun(self: pYdata.TechnologyPrototype, prereq_technology_name: data.TechnologyID): pYdata.TechnologyPrototype, boolean
---@field public remove_prereq fun(self: pYdata.TechnologyPrototype, prereq_technology_name: data.TechnologyID): pYdata.TechnologyPrototype, boolean
---@field public replace_prereq fun(self: pYdata.TechnologyPrototype, old: data.TechnologyID, new: data.TechnologyID): pYdata.TechnologyPrototype, boolean
---@field public remove_pack fun(self: pYdata.TechnologyPrototype, science_pack_name: data.ItemID): pYdata.TechnologyPrototype, boolean
---@field public add_pack fun(self: pYdata.TechnologyPrototype, science_pack_name: data.ItemID): pYdata.TechnologyPrototype, boolean
---wraps the given icon with the border taken from the same mod (graphics/technology/border.png)  
---strips any numbers from the end of the mod name  
---scales the icon to the prototype's icon_size or 128  
---if you want to adjust the icon manually, pass an empty sprite as the path and the icon as the second argument
---@field public create_icons fun(self: pYdata.TechnologyPrototype, icon_path: string?, ...: data.IconData): pYdata.TechnologyPrototype
TECHNOLOGY = setmetatable({}, {
    __call = function(_, object)
        local type = type(object)
        if type == "string" then
            object = assert(data.raw.technology[object], "Technology " .. object .. " does not exist")
            return setmetatable({prototype = object}, metatable):standardize()
        elseif type == "table" and getmetatable(object) == metatable then
            return object:standardize()
        elseif type == "table" then
            local old_object = data.raw.technology[object.name]
            if old_object then
                local info = debug.getinfo(2) ---@cast info -?
                local callsite = info.source .. ":" .. info.currentline
                log.warning("overwriting existing technology: " .. object.name .. " at " .. callsite)
            end
            object.type = "technology"
            data:extend {object}
            return setmetatable({prototype = object}, metatable):standardize()
        end
    end
})

metas.create_icons = function(self, icon_path,  ...)
    local icon_size = self.icon_size or 128
    if type(self.icons) == "string" then icon_path = self.icons end
    if not icon_path then error("provide a icon path for " .. self.name) end
    local base_mod = string.gsub(icon_path, "%d*__/.*", "__")
    self.icons = {
        {icon = base_mod .. "/graphics/technology/border.png", icon_size = 128},
        {icon = icon_path, icon_size = icon_size, scale = 0.7 * 128 / icon_size},
    }
    for _, icon in pairs{...} do
        table.insert(self.icons, icon)
    end
    self.icon_size = 128
    return self
end

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
        log.warning("\'" .. self.name .. "\':add_prereq(): Technology " .. prereq_technology_name .. " does not exist")
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
