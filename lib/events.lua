local events = {}

---Drop-in replacement for script.on_event however it supports multiple handlers per event. You can also use 'on_built' 'on_destroyed' and 'on_init' as shortcuts for multiple events.
---@param event defines.events|defines.events[]|string
---@param f function
---@diagnostic disable-next-line: duplicate-set-field
py.on_event = function(event, f)
	if event == 'on_built' then
		py.on_event({defines.events.on_built_entity,
			defines.events.on_robot_built_entity,
			defines.events.script_raised_built,
			defines.events.script_raised_revive
		}, f)
		return
	end
	if event == 'on_destroyed' then
		py.on_event({
			defines.events.on_player_mined_entity,
			defines.events.on_robot_mined_entity,
			defines.events.on_entity_died,
			defines.events.script_raised_destroy
		}, f)
		return
	end
	for _, event in pairs(type(event) == 'table' and event or {event}) do
		event = tostring(event)
		events[event] = events[event] or {}
		table.insert(events[event], f)
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
	if finalized then error('Events already finalized') end
	local i = 0
	for event, functions in pairs(events) do
		local f = one_function_from_many(functions)
		if type(event) == 'number' then
			script.on_nth_tick(event, f)
		elseif event == 'on_init' then
			script.on_init(f)
			script.on_configuration_changed(f)
		else
			script.on_event(tonumber(event) or event, f)
		end
		i = i + 1
	end
	finalized = true
	log('Finalized ' .. i .. ' events for ' .. script.mod_name)
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
		for pattern, f in pairs(gui_events[event.name]) do
			if event.element.name:match(pattern) then f(event); return end
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

-- use this to register functions that run at a specific tick
-- pass parameters in a list
---@param tick uint
---@param func_name string
---@param func function
---@param params any[]?
py.register_tick_event = function(tick, func_name, func, params)
	log('registered tick_event function ' .. func_name)
	if py.on_tick_funcs[func_name] and py.on_tick_funcs[func_name] ~= func then error('attempting to overwrite a registered function ' .. func_name) end
	py.on_tick_funcs[func_name] = func
	if tick < (game and game.tick or 0) then
		error('invalid tick event registration with function ' .. func_name)
		return
	end
	params = params or {}
	if type(params) ~= 'table' then params = {params} end
	storage.on_tick[tick] = storage.on_tick[tick] or {}
	table.insert(storage.on_tick[tick], {name = func_name, params = params})
end

local on_nth_tick_init = false
local function_list = {}

py.mod_nth_tick_funcs = {}

---use instead of script.on_nth_tick
---@param tick int
---@param func_name string
---@param mod string
---@param func function
py.register_on_nth_tick = function(tick, func_name, mod, func)
	if py.mod_nth_tick_funcs[func_name] then error("py.register_on_nth_tick: function with name " .. func_name .. " is already registered") end
	function_list[func_name] = {tick=tick, mod=mod}
	py.mod_nth_tick_funcs[mod .. "-" .. func_name] = func
end

py.on_event(defines.events.on_tick, function(event)
	-- on_nth_tick
	if not on_nth_tick_init then
		remote.call("on_nth_tick", "add", function_list)
		on_nth_tick_init = true
	end

	-- delayed funcs
	local tick = event.tick
	if not (storage.on_tick and storage.on_tick[tick]) then return end
	for _, func_details in pairs(storage.on_tick[tick]) do
		local success, err = pcall(py.on_tick_funcs[func_details.name], table.unpack(func_details.params))
		if not success then error('error in on tick function ' .. func_details.name .. ': ' .. err) end
	end
	storage.on_tick[tick] = nil
end)
