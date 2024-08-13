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

---@type table<integer, table<string, any[]?>>
global.on_tick = global.on_tick or {}
---@type table<string, function>
py.on_tick_funcs = {}

-- use this to register functions that run at a specific tick
-- can replace on_nth_tick if you register the same function for a later tick
-- pass parameters in a list
---@param tick uint
---@param func_name string
---@param params any[]?
function py.register_tick_event(tick, func_name, params)
	if tick < (game and game.tick or 0) then
		error('invalid tick event registration with function ' .. func_name)
		return
	end
	params = params or {}
	if type(params) ~= 'table' then params = {params} end
	global.on_tick[tick] = global.on_tick[tick] or {}
	global.on_tick[tick][func_name] = params
end

-- register a function to use as a tick event
---@param func_name string
---@param func function
function py.register_function(func_name, func)
	if py.on_tick_funcs[func_name] and py.on_tick_funcs[func_name] ~= func then error('attempting to overwrite a registered function ' .. func_name) end
	py.on_tick_funcs[func_name] = func
end

py.on_event(defines.events.on_tick, function(event)
	local tick = event.tick
	if not global.on_tick[tick] then return end
	for func_name, params in pairs(global.on_tick[tick]) do
		py.on_tick_funcs[func_name](table.unpack(params))
	end
	global.on_tick[tick] = nil
end)