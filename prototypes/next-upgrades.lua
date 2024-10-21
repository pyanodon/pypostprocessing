local collision_mask_util = require "__core__/lualib/collision-mask-util"
local math2d = require "__core__/lualib/math2d"

---Given an entity prototype name, return the next tier of that entity. For example electrolyzer-mk01 -> electrolyzer-mk02
---@param prototype_name string
---@param prototype_category table<string, EntityPrototype>
---@return string
local function next_tier(prototype_name, prototype_category)
    local tier_num = prototype_name:match("%-mk(%d%d)")
    if tier_num then
        tier_num = tonumber(tier_num)
        if not tier_num then return end
        tier_num = tier_num + 1
        tier_num = string.format("%02d", tier_num)
        local next_upgrade = prototype_name:gsub("%-mk%d%d", "-mk" .. tier_num)
        if prototype_category[next_upgrade] then return next_upgrade end
    else
        local next_upgrade = prototype_name .. "-mk02"
        if prototype_category[next_upgrade] then return next_upgrade end
    end
end

---Given a prototype, check if it has valid minable properties for use in the next upgrade system.
---@param entity EntityPrototype
---@return boolean
local function check_for_valid_minable_properties(entity)
    if not entity.minable then return false end

    local minable = entity.minable
    if not minable.result and not minable.results then return false end
    local minable_result = minable.result or minable.results[1].name or minable.results[1][1]
    if not minable_result then return false end
    if minable_result ~= entity.name then return false end

    minable_result = ITEM(minable_result)
    if not minable_result then return false end
    if minable_result.hidden then return false end

    return true
end

---Given an entity prototype, check if it meets the criteria for being upgradable.
---@param entity EntityPrototype
---@return boolean
local function can_be_upgraded(entity)
    if not entity then return false end
    if entity.hidden then return false end
    if entity.joint_distance then return false end -- Exclude all trains.
    if entity:has_flag("not-upgradable") then return false end
    if not entity.fast_replaceable_group then return false end
    if not entity.collision_box then return false end
    if not check_for_valid_minable_properties(entity) then return false end
    return true
end

for category_name, category in py.iter_prototype_categories("entity") do
    for name, prototype in pairs(category) do
        if prototype.next_upgrade then goto continue end
        if not can_be_upgraded(prototype) then goto continue end

        local next_upgrade = category[next_tier(name, category)]
        if not can_be_upgraded(next_upgrade) then goto continue end

        if next_upgrade.fast_replaceable_group ~= prototype.fast_replaceable_group then goto continue end

        local mask_1 = collision_mask_util.get_mask(prototype)
        local mask_2 = collision_mask_util.get_mask(next_upgrade)
        if not collision_mask_util.masks_are_same(mask_1, mask_2) then goto continue end

        if serpent.line(prototype.collision_box) ~= serpent.line(next_upgrade.collision_box) then goto continue end

        prototype.next_upgrade = next_upgrade.name

        ::continue::
    end
end
