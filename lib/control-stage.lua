-- Adds helper functions for control stage. Shared across all pymods

local random = math.random

require "events"
require "vector"

---Draws a red error icon at the entity's position.
---@param entity LuaEntity
---@param sprite string
---@param time_to_live integer
py.draw_error_sprite = function(entity, sprite, time_to_live)
    rendering.draw_sprite {
        sprite = sprite,
        x_scale = entity.prototype.alert_icon_scale or 0.5,
        y_scale = entity.prototype.alert_icon_scale or 0.5,
        target = entity,
        surface = entity.surface,
        time_to_live = time_to_live or 30,
        render_layer = "air-entity-info-icon"
    }
end

---Creates a localised string tooltip for allowed modules.
---@param allowed_modules table<string, any>
---@return LocalisedString
py.generate_allowed_module_tooltip = function(allowed_modules)
    local item_prototypes = prototypes.item
    ---@type LocalisedString
    local result = {"", {"gui.module-description"}, "\n"}
    for module, _ in pairs(allowed_modules) do
        result[#result + 1] = {"", "[font=heading-2][item=" .. module .. "][/font]", " ", item_prototypes[module].localised_name}
        result[#result + 1] = "\n"
    end
    result[#result] = nil
    return result
end

---Randomizes a position by a factor.
---@param position MapPosition
---@param factor number?
---@return MapPosition
py.randomize_position = function(position, factor)
    local x = position.x or position[1]
    local y = position.y or position[2]
    factor = factor or 1
    return {x = x + factor * (random() - 0.5), y = y + factor * (random() - 0.5)}
end

---Intended to be called inside a build event. Cancels creation of the entity.
---Returns its item_to_place back to the player or spills it on the ground.
---@param entity LuaEntity
---@param player_index integer?
---@param message LocalisedString?
---@param color Color?
py.cancel_creation = function(entity, player_index, message, color)
    local inserted = 0
    local items_to_place_this = entity.prototype.items_to_place_this
    local item_to_place = items_to_place_this and items_to_place_this[1]
    local surface = entity.surface
    local position = entity.position
    local name = entity.name

    if player_index then
        local player = game.get_player(player_index) --[[@as LuaPlayer]]
        if player.mine_entity(entity, false) then
            inserted = 1

            -- remove from undo stack
            local undo_stack = player.undo_redo_stack
            local top
            for i = 1, undo_stack.get_undo_item_count() do
                top = undo_stack.get_undo_item(i)
                for j, action in pairs(top) do
                    local target = action.target
                    if target and target.name == name and serpent.line(target.position) == serpent.line(position) then
                        undo_stack.remove_undo_action(i, j)
                        break
                    end
                end
            end
        elseif item_to_place then
            inserted = player.insert(item_to_place)
        end
    end

    if inserted == 0 and item_to_place then
        surface.spill_item_stack {
            position = position,
            stack = item_to_place,
            enable_looted = true,
            force = entity.force_index,
            allow_belts = false
        }
    end

    entity.destroy {raise_destroy = true}

    if not message then return end

    local tick = game.tick
    local last_message = storage._last_cancel_creation_message or 0
    if last_message + 60 < tick then
        for _, player in pairs(game.connected_players) do
            player.create_local_flying_text {
                text = message,
                position = position,
                color = color,
                create_at_cursor = player.index == player_index
            }
        end
        storage._last_cancel_creation_message = game.tick
    end
end

local seconds_per_year = 60 * 60 * 24 * 365.25
local seconds_per_day = 60 * 60 * 24
local seconds_per_hour = 60 * 60
local seconds_per_minute = 60
---Creates a string representation of a time in seconds.
---@param seconds number?
---@return string?
py.format_large_time = function(seconds)
    if not seconds then return end
    local result = ""
    if seconds >= seconds_per_year then
        local years = math.floor(seconds / seconds_per_year)
        result = result .. years .. "y "
        seconds = seconds % seconds_per_year
    end

    if seconds >= seconds_per_day or result ~= "" then
        local days = math.floor(seconds / seconds_per_day)
        result = result .. days .. "d "
        seconds = seconds % seconds_per_day
    end

    if seconds >= seconds_per_hour or result ~= "" then
        local hours = math.floor(seconds / seconds_per_hour)
        result = result .. hours .. ":"
        seconds = seconds % seconds_per_hour
    end

    local minutes = math.floor(seconds / seconds_per_minute)
    if minutes < 10 then
        result = result .. "0" .. minutes .. ":"
    else
        result = result .. minutes .. ":"
    end
    seconds = seconds % seconds_per_minute

    seconds = math.ceil(seconds)
    if seconds < 10 then
        result = result .. "0" .. seconds
    else
        result = result .. seconds
    end

    return result
end

---Returns the grandparent gui element with the given name.
---@param element LuaGuiElement
---@param name string
---@return LuaGuiElement
py.find_grandparent = function(element, name)
    while element do
        if element.name == name then return element end
        element = element.parent
    end
    error("Could not find parent gui element with name: " .. name)
end

local si_prefixes = {
    [0] = "",
    "si-prefix-symbol-kilo",
    "si-prefix-symbol-mega",
    "si-prefix-symbol-giga",
    "si-prefix-symbol-tera",
    "si-prefix-symbol-peta",
    "si-prefix-symbol-exa",
    "si-prefix-symbol-zetta",
    "si-prefix-symbol-yotta"
}
---formats a number into the amount of energy. Requires 'W' or 'J' as the second parameter
---@param energy number
---@param watts_or_joules string
py.format_energy = function(energy, watts_or_joules)
    if watts_or_joules == "W" then
        watts_or_joules = "si-unit-symbol-watt"
        energy = energy * 60
    elseif watts_or_joules == "J" then
        watts_or_joules = "si-unit-symbol-joule"
    else
        error()
    end

    local prefix = 0
    while energy >= 1000 do
        energy = energy / 1000
        prefix = prefix + 1
    end
    return {"", string.format("%.1f", energy), " ", si_prefixes[prefix] and {si_prefixes[prefix]} or "* 10^" .. (prefix * 3) .. " ", {watts_or_joules}}
end

---Returns the distance from 0,0
---@param x number
---@param y number
---@return number
py.distance = function(x, y)
    return (x ^ 2 + y ^ 2) ^ 0.5
end

---Returns the squared distance between two points.
---@param first MapPosition
---@param second MapPosition
---@return number
py.distance_squared = function(first, second)
    local x = first.x - second.x
    local y = first.y - second.y
    return x * x + y * y
end
