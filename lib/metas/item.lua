---@class data.ItemPrototype
---@field public add_flag fun(self: data.ItemPrototype, flag: string): data.ItemPrototype
---@field public remove_flag fun(self: data.ItemPrototype, flag: string): data.ItemPrototype
---@field public has_flag fun(self: data.ItemPrototype, flag: string): boolean
---@field public spoil fun(self: data.ItemPrototype, spoil_result: (string | table), spoil_ticks: number): data.ItemPrototype

local item_prototypes = defines.prototypes.item
ITEM = setmetatable({}, {
    ---@param item data.ItemPrototype
    __call = function(self, item)
        local itype = type(item)
        if itype == "string" then
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

local metas = {}

metas.add_flag = function(self, flag)
    if not self.flags then self.flags = {} end
    table.insert(self.flags, flag)
    return self
end

metas.remove_flag = function(self, flag)
    if not self.flags then return self end
    for i, f in pairs(self.flags) do
        if f == flag then table.remove(self.flags, i) end
    end
    return self
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
    if not feature_flags.space_travel then return end
    if not spoil_ticks then error("No spoil ticks provided for item " .. self.name) end
    
    if type(spoil_result) == "string" then
        self.spoil_result = spoil_result
    elseif type(spoil_result) == "table" and spoil_result.trigger then
        self.spoil_to_trigger_result = spoil_result
    else
        error("Invalid spoil result provided for item " .. self.name)
    end

    self.spoil_ticks = spoil_ticks
end

return metas
