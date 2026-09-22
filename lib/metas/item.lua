local item_prototypes = defines.prototypes.item

---@class pYdata.ItemPrototype:pYdata.AnyPrototype,data.ItemPrototype
---@operator call(string|pYdata.ItemPrototype|data.ItemPrototype): pYdata.ItemPrototype
---@field public add_flag fun(self: pYdata.ItemPrototype, flag: string): pYdata.ItemPrototype, boolean
---@field public remove_flag fun(self: pYdata.ItemPrototype, flag: string): pYdata.ItemPrototype, boolean
---@field public has_flag fun(self: pYdata.ItemPrototype, flag: string): boolean
---@field public spoil fun(self: pYdata.ItemPrototype, spoil_result: (string | table), spoil_ticks: uint): pYdata.ItemPrototype, boolean
---@field public add_category fun(self: pYdata.ItemPrototype, category_name: data.FuelCategoryID): pYdata.ItemPrototype, boolean
---@field public remove_category fun(self: pYdata.ItemPrototype, category_name: data.FuelCategoryID): pYdata.ItemPrototype, boolean
---@field public replace_category fun(self: pYdata.ItemPrototype, old: data.FuelCategoryID, new: data.FuelCategoryID): pYdata.ItemPrototype, boolean
---@field public has_category fun(self: pYdata.ItemPrototype, category_name: data.FuelCategoryID): boolean
---@field public has_categories fun(self: pYdata.ItemPrototype, category_name: data.FuelCategoryID[], all?: boolean): boolean # Returns true if the item has any of the fuel categories. all? categories must match to pass
ITEM = setmetatable({}, {
    ---@param item data.ItemPrototype
    __call = function(self, item)
        local itype = type(item)
        if itype == "string" then
            ---@cast item any somehow this works but string doesnt
            for _, pdata in py.iter_prototype_categories("item") do
                local result = pdata[item]
                if result then return result end
            end
        elseif itype == "table" then
            if not item.type then error("Tried to extend an item " .. item.name .. " without providing a type") end
            if not item_prototypes[item.type] then error("Tried to use ITEM{} on a non-item: " .. item.name) end

            data:extend {item}
            return item
        else
            error("Invalid type " .. itype)
        end
        error("Item " .. tostring(item) .. " does not exist")
    end,
    __index = function(self, item_name)
        for _, pdata in py.iter_prototype_categories("item") do
            local result = pdata[item_name]
            if result then return result end
        end
        return nil
    end
})

---@diagnostic disable-next-line: missing-fields
---@type pYdata.ItemPrototype
local metas = {}

metas.add_flag = function(self, flag)
    self.flags = self.flags or {}  
    for _, f in pairs(self.flags) do
        if f == flag then
            return self, false -- flag already exists
        end
    end
    table.insert(self.flags, flag)
    return self, true -- flag added
end

metas.remove_flag = function(self, flag)
    if not self.flags then return self, false end
    for i, f in pairs(self.flags) do
        if f == flag then
            table.remove(self.flags, i)
            return self, true -- flag found and removed
        end
    end
    return self, false -- could not find flag
end

metas.has_flag = function(self, flag)
    if not self.flags then return false end
    for _, f in pairs(self.flags) do
        if f == flag then return true end
    end
    return false
end

py.spoil_triggers = {
    -- typically used for items that evaporate at room temperature
    puff_of_smoke = function()
        return {
            trigger = {
                type = "direct",
                action_delivery = {
                    type = "instant",
                    source_effects = {
                        type = "create-trivial-smoke",
                        smoke_name = "smoke-building",
                        repeat_count = 4,
                        affects_target = true,
                        offset_deviation = {{-0.2, -0.2}, {0.2, 0.2}},
                        starting_frame_deviation = 5,
                        speed_from_center = 0.03
                    }
                }
            },
            items_per_trigger = 1,
        }
    end
}

metas.spoil = function(self, spoil_result, spoil_ticks)
    if not feature_flags.spoiling then return self, false end -- spoilage is off
    if not spoil_ticks then error("No spoil ticks provided for item " .. self.name) end

    if type(spoil_result) == "string" then
        self.spoil_result = spoil_result
    elseif type(spoil_result) == "table" and spoil_result.trigger then
        self.spoil_to_trigger_result = spoil_result
    elseif spoil_result ~= nil then
        error("Invalid spoil result provided for item " .. self.name)
    end

    self.spoil_ticks = spoil_ticks

    return self, true
end

metas.add_category = function(self, category_name)
    self.fuel_categories = self.fuel_categories or {}

    if not data.raw["fuel-category"][category_name] then
        log("WARNING @ \'" .. self.name .. "\':add_category(): Category " .. category_name .. " not found")
        return self, false -- category does not exist
    else
        for _, category in pairs(self.fuel_categories) do
            if category == category_name then
                return self, false -- category already set
            end
        end
        self.fuel_categories[#self.fuel_categories+1] = category_name
        return self, true -- successful set
    end
end

metas.remove_category = function(self, category_name)
    if not data.raw["fuel-category"][category_name] then
        log("WARNING @ \'" .. self.name .. "\':remove_category(): Category " .. category_name .. " not found")
        return self, false -- category does not exist
    else
        if category_name == "chemical" and (not self.fuel_categories or #self.fuel_categories == 0) then
            return self, true -- fake positive if trying to remove 'category' with no categories because its the default
        end
        for i, category in pairs(self.fuel_categories or {}) do
            if category == category_name then
                ---@diagnostic disable-next-line: param-type-mismatch
                table.remove(self.fuel_categories, i)
                if #self.fuel_categories == 0 then self.fuel_categories = nil end -- remove categories if it is an empty table
                return self, true -- successfully removed
            end
        end
        return self, false -- category not found
    end
end

metas.replace_category = function(self, old, new)
    if not data.raw["fuel-category"][old] then
        log("WARNING @ \'" .. self.name .. "\':replace_category(): Category " .. old .. " not found")
        return self, false -- category does not exist
    elseif not data.raw["fuel-category"][new] then
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
    if not data.raw["fuel-category"][category_name] then
        log("WARNING @ \'" .. self.name .. "\':has_category(): Category " .. category_name .. " not found")
        return false -- category does not exist
    elseif not self.fuel_value then
        return false -- does not support categories, is not a fuel
    else
        if category_name == "chemical" and (not self.categories or #self.categories == 0) then
            return true -- fake positive if trying to remove 'category' with no categories because its the default
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
    for _, category in pairs(categories) do
        if all and not self:has_category(category) then
            return false -- all categories must be contained but this one was not
        elseif not all and self:has_category(category) then
            return true -- any categories must match and this one matched
        end
    end
    return not not all -- all categories matched, or none did
end

return metas
