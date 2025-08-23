local events = {}
-- Moved to top for referencing below
--- Sentinel values for defining groups of events
py.events = {
    --- Called after an entity is constructed.
    --- Note: Using this event may be bad practice. Consider instead defining `created_effect` in the entity prototype.
    ---
    --- entity.created_effect = {
    --- 	type = 'direct',
    --- 	action_delivery = {
    --- 		type = 'instant',
    --- 		source_effects = {
    --- 			type = 'script',
    --- 			effect_id = 'on_built_[ENTITY NAME]'
    --- 		}
    --- 	}
    --- }
    on_built = function()
        return {
            defines.events.on_built_entity,
            defines.events.on_robot_built_entity,
            defines.events.script_raised_built,
            defines.events.script_raised_revive,
            defines.events.on_space_platform_built_entity,
            defines.events.on_biter_base_built
        }
    end,
    --- Called after the results of an entity being mined are collected just before the entity is destroyed. [...]
    on_destroyed = function()
        return {
            defines.events.on_player_mined_entity,
            defines.events.on_robot_mined_entity,
            defines.events.on_entity_died,
            defines.events.script_raised_destroy,
            defines.events.on_space_platform_mined_entity
        }
    end,
    --- Called after a tile is built.
    on_built_tile = function()
        return {
            defines.events.on_robot_built_tile,
            defines.events.on_player_built_tile,
            defines.events.on_space_platform_built_tile,
        }
    end,
    on_mined_tile = function()
        return {
            defines.events.on_player_mined_tile,
            defines.events.on_robot_mined_tile,
            defines.events.on_space_platform_mined_tile,
        }
    end,
    on_gui_opened = function()
        return {
            defines.events.on_gui_opened
        }
    end,
    on_gui_click = function()
        return {
            defines.events.on_gui_click
        }
    end,
    --- Called for on_init and on_configuration_changed
    on_init = function()
        return "ON INIT EVENT"
    end,
    --- Custom event for when a player clicks on an entity
    on_entity_clicked = function()
        return "open-gui"
    end
}

---Conditionally runs the given event based on if the player is not present within ignored_players
---@param event EventData.on_gui_click
---@param f function event handler
local function wrapped_click(event, f)
    -- Runs if the click wasn't caused by a custom-input click
    local player_index = event and event.player_index or -1
    if storage.ignored_players[player_index] then
        storage.ignored_players[player_index] = nil
        return
    end
    f(event)
end
---Sets event's player_index into ignored_players before running the given function
---@param f function event handler
---@return function function wrapped event handler
local function set_ignore_click(f)
    return function(event)
        if event.player_index ~= nil then
            local multiplier = settings.get_player_settings(event.player_index)["pypp-click-lock-duration"].value * 60
            local offset = math.floor(multiplier * game.speed + 0.5)
            if offset ~= 0 then
                storage.ignored_players[event.player_index] = game.tick + offset
            end
        end
        f(event)
    end
end


---Drop-in replacement for script.on_event however it supports multiple handlers per event. You can also use 'on_built' 'on_destroyed' and 'on_init' as shortcuts for multiple events.
---@param event defines.events|defines.events[]|string
---@param f function
---@diagnostic disable-next-line: duplicate-set-field
py.on_event = function(event, f)
    for _, event_name in pairs(type(event) == "table" and event or {event}) do
        event_name = tostring(event_name)
        events[event_name] = events[event_name] or {}
        -- Handle the GUI click wrapping
        if event_name == py.events.on_entity_clicked() then
            ---Sets event's player_index into ignored_players before running the given function
            table.insert(events[event_name], set_ignore_click(f))
        else
            table.insert(events[event_name], f)
        end
    end
end

local function one_function_from_many(functions)
    local l = #functions
    if l == 1 then return functions[1] end

    return function(arg)
        for i = 1, l do
            functions[i](arg)
        end
    end
end

local finalized = false
py.finalize_events = function()
    if finalized then error("Events already finalized") end
    local i = 0
    for event, functions in pairs(events) do
        local f = one_function_from_many(functions)
        if type(event) == "number" then
            script.on_nth_tick(event, f)
        elseif event == py.events.on_init() then
            script.on_init(f)
            script.on_configuration_changed(f)
        else
            script.on_event(tonumber(event) or event, f)
        end
        i = i + 1
    end
    finalized = true
    log("Finalized " .. i .. " events for " .. script.mod_name)
end

_G.gui_events = {
    [defines.events.on_gui_click] = {},
    [defines.events.on_gui_confirmed] = {},
    [defines.events.on_gui_text_changed] = {},
    [defines.events.on_gui_checked_state_changed] = {},
    [defines.events.on_gui_selection_state_changed] = {},
    [defines.events.on_gui_checked_state_changed] = {},
    [defines.events.on_gui_elem_changed] = {},
    [defines.events.on_gui_value_changed] = {},
    [defines.events.on_gui_location_changed] = {},
    [defines.events.on_gui_selected_tab_changed] = {},
    [defines.events.on_gui_switch_state_changed] = {}
}
local function process_gui_event(event)
    if event.element and event.element.valid then
        local is_click = event.name == defines.events.on_gui_click
        for pattern, f in pairs(gui_events[event.name]) do
            if event.element.name:match(pattern) then
                if is_click then
                    wrapped_click(event, f)
                else
                    f(event)
                end
                return
            end
        end
    end
end

for event, _ in pairs(gui_events) do
    py.on_event(event, process_gui_event)
end

---@type table<integer, table<int, {name: string, params: any[]?}>>
storage.on_tick = storage.on_tick or {}
---@type table<string, function>
py.on_tick_funcs = {}

---register delayed functions
---@param func_name string
---@param func function
py.register_delayed_function = function(func_name, func)
    log("registered delayed_event function " .. func_name)
    if py.on_tick_funcs[func_name] and py.on_tick_funcs[func_name] ~= func then error("attempting to overwrite a registered function " .. func_name) end
    py.on_tick_funcs[func_name] = func
end

-- use this to call functions after a delay
-- pass parameters in a list
---@param delay uint
---@param func_name string
---@param params any[]?
py.delayed_event = function(delay, func_name, params)
    if delay < 0 then
        error("invalid event delay with function " .. func_name)
        return
    end
    params = params or {}
    if type(params) ~= "table" then params = {params} end
    local tick = game.tick + delay
    storage.on_tick[tick] = storage.on_tick[tick] or {}
    table.insert(storage.on_tick[tick], {name = func_name, params = params})
end

local on_nth_tick_init = false
local function_list = {}

py.mod_nth_tick_funcs = {}

---use instead of script.on_nth_tick, avoids multiple functions running on the same tick
---@param tick int
---@param func_name string
---@param mod string
---@param func function
py.register_on_nth_tick = function(tick, func_name, mod, func)
    if py.mod_nth_tick_funcs[mod .. "-" .. func_name] then error("py.register_on_nth_tick: function with name " .. mod .. "-" .. func_name .. " is already registered") end
    function_list[func_name] = {tick = tick, mod = mod}
    py.mod_nth_tick_funcs[mod .. "-" .. func_name] = func
end

py.on_event(defines.events.on_tick, function(event)
    -- on_nth_tick
    local tick = event.tick
    if not on_nth_tick_init then
        remote.call("on_nth_tick", "add", function_list)
        on_nth_tick_init = true
    end

    -- gui handler
    -- do it here too since somehow config_changed doesn't always get called below
    storage.ignored_players = storage.ignored_players or {}
    for k, expiry in pairs(storage.ignored_players) do
        if tick >= expiry then
            storage.ignored_players[k] = nil
        end
    end

    -- delayed funcs
    if not (storage.on_tick and storage.on_tick[tick]) then return end
    for _, func_details in pairs(storage.on_tick[tick]) do
        local success, err = pcall(py.on_tick_funcs[func_details.name], table.unpack(func_details.params))
        if not success then error("error in on tick function " .. func_details.name .. ": " .. err) end
    end
    storage.on_tick[tick] = nil
end)

-- somehow this doesn't trigger for on config changed
py.on_event(py.events.on_init(), function(_)
    storage.ignored_players = storage.ignored_players or {}
end)
