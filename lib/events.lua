if data then
	local delays = {}
	for _, n in pairs(powers_of_two) do
		delays[#delays + 1] = {
			name = 'py-ticked-script-delay-' .. n,
			type = 'flying-text',
			time_to_live = n,
			speed = 0,
		}
	end
	data:extend(delays)
	return
end

local events = {}

---Drop-in replacement for script.on_event however it supports multiple handlers per event. You can also use 'on_built' 'on_destroyed' and 'on_init' as shortcuts for multiple events.
---@param event defines.events|defines.events[]|string
---@param f function
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

py.on_nth_tick = function(event, f)
	events[event] = events[event] or {}
	table.insert(events[event], f)
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

local powers_of_two = {}
for i = 0, 20 do
	powers_of_two[i] = 2 ^ i
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

py.delayed_functions = {}
---use this to execute a script after a delay
---example:
---py.delayed_functions.my_delayed_func = function(param1, param2, param3) ... end
---py.execute_later('my_delayed_func', 60, param1, param2, param3)
---The above code will execute my_delayed_func after waiting for 60 ticks
---@param function_key string
---@param ticks integer
---@param ... any
function py.execute_later(function_key, ticks, ...)
	if ticks < 1 or ticks % 1 ~= 0 then error('Invalid delay: ' .. ticks) end
	local highest = 1
	for _, n in pairs(powers_of_two) do
		if n <= ticks then
			highest = n
		else break end
	end
	local flying_text = game.surfaces.nauvis.create_entity{
		name = 'py-ticked-script-delay-' .. highest,
		position = {0, 0},
		create_build_effect_smoke = false,
		text = ''
	}
	if not flying_text then error() end
	global._delayed_functions = global._delayed_functions or {}
	global._delayed_functions[script.register_on_entity_destroyed(flying_text)] = {function_key, ticks - highest, {...}}
end
py.on_event(defines.events.on_entity_destroyed, function(event)
	if not global._delayed_functions then return end
	local data = global._delayed_functions[event.registration_number]
	if not data then return end
	global._delayed_functions[event.registration_number] = nil

	local function_key = data[1]
	local ticks = data[2]

	if ticks == 0 then
		local f = py.delayed_functions[function_key]
		if not f then error('No function found for key: ' .. function_key) end
		f(table.unpack(data[3]))
	else
		py.execute_later(function_key, ticks, table.unpack(data[3]))
	end
end)