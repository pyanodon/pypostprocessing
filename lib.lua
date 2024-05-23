if py then return py end
local py = {}

py.gravitational_constant = 6.67408e-11 -- m^3 kg^-1 s^-2

local events = {}
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

py.finalize_events = function()
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
	end
end

local random = math.random
py.randomize_position = function(position, factor)
	local x = position.x or position[1]
	local y = position.y or position[2]
	factor = factor or 1
	return {x = x + factor * (random() - 0.5), y = y + factor * (random() - 0.5)}
end

py.empty_image = function() return {
	filename = '__pystellarexpeditiongraphics__/graphics/empty.png',
	size = 1,
	priority = 'high',
	direction_count = 1,
	frame_count = 1,
	line_length = 1
} end

py.merge = function(old, new)
	old = table.deepcopy(old)
	for k, v in pairs(new) do
		if v == 'nil' then
			old[k] = nil
		else
			old[k] = v
		end
	end
	return old
end

py.add_to_description = function(type, prototype, localised_string)
	if prototype.localised_description and prototype.localised_description ~= '' then
		prototype.localised_description = {'', prototype.localised_description, '\n', localised_string}
		return
	end

	local place_result = prototype.place_result or prototype.placed_as_equipment_result
	if type == 'item' and place_result then
		for _, machine in pairs(data.raw) do
			machine = machine[place_result]
			if machine and machine.localised_description then
				prototype.localised_description = {
					'?',
					{'', machine.localised_description, '\n', localised_string},
					localised_string
				}
				return
			end
		end

		local entity_type = prototype.place_result and 'entity' or 'equipment'
		prototype.localised_description = {
			'?',
			{'', {entity_type .. '-description.' .. place_result}, '\n', localised_string},
			{'', {type .. '-description.' .. prototype.name}, '\n', localised_string},
			localised_string
		}
	else
		prototype.localised_description = {
			'?',
			{'', {type .. '-description.' .. prototype.name}, '\n', localised_string},
			localised_string
		}
	end
end

py.cancel_creation = function(entity, player_index, message)
	local inserted = 0
	local item_to_place = entity.prototype.items_to_place_this[1]
	local surface = entity.surface
	local position = entity.position

	if player_index then
		local player = game.get_player(player_index)
		if player.mine_entity(entity, false) then
			inserted = 1
		elseif item_to_place then
			inserted = player.insert(item_to_place)
		end
	end

	if inserted == 0 and item_to_place then
		surface.spill_item_stack(
			position,
			item_to_place,
			true,
			entity.force_index,
			false
		)
	end

	entity.destroy{raise_destroy = true}

	if not message then return end

	local tick = game.tick
	local last_message = global.last_cancel_creation_message or 0
	if last_message + 60 < tick then
		surface.create_entity{
			name = 'flying-text',
			position = position,
			text = message,
			render_player_index = player_index
		}
		global.last_cancel_creation_message = game.tick
	end
end

local function parse_restriction_condition(condition)
	local function helper()
		local type = condition.type
		if type == 'placed-on' then
			return {'placement-restriction.placed-on', {'entity-name.' .. condition.entity}}
		elseif type == 'surface-type' then
			return {'placement-restriction.surface-type', {'surface-type.' .. condition.surface_type}}
		elseif type == 'surface-tag' then
			return {'placement-restriction.surface-tag', {'surface-tag-name.' .. condition.tag}}
		elseif type == 'distance' then
			return {'placement-restriction.distance', {'surface-distance.' .. condition.distance}}
		end

		-- greater than less than
		local args
		if condition.min_amount and condition.max_amount then
			args = {'placement-restriction.' .. type .. '-3', condition.min_amount, condition.max_amount}
		elseif condition.max_amount then
			args = {'placement-restriction.' .. type .. '-2', condition.max_amount}
		elseif condition.min_amount then
			args = {'placement-restriction.' .. type .. '-1', condition.min_amount}
		else
			error('min_amount or max_amount missing from placement restriction of type: ' .. type)
		end

		if type == 'atmosphere' then
			if not condition.gas then error('No gas provided for atomspheric condition') end
			if not data.raw.fluid[condition.gas] then error('Invalid gas: ' .. condition.gas) end
			for i = 2, #args do
				args[i] = args[i] * 100
			end
			table.insert(args, 2, {data.raw.fluid[condition.gas].localised_name or ('fluid-name.' .. condition.gas)})
			table.insert(args, 2, '[fluid=' .. condition.gas .. ']')
		end

		return args
	end

	local localised_string = helper()
	if condition.NOT then localised_string = {'placement-restriction.not', localised_string} end
	return localised_string
end

local function placement_restriction_description_helper(i, restriction, parens)
	if i == #restriction then
		if data then
			return {'placement-restriction.dot', parse_restriction_condition(restriction[i])}
		else
			return parse_restriction_condition(restriction[i])
		end
	end
	return {
		parens,
		parse_restriction_condition(restriction[i]),
		{'placement-restriction.' .. restriction[i + 1]},
		placement_restriction_description_helper(i + 2, restriction, parens)
	}
end

py.placement_restriction_description = function(restriction)
    if #restriction % 2 == 0 then error('Placement restriction length must be odd') end
	local parens = data and 'placement-restriction.parens-dot' or 'placement-restriction.parens'
    return {'placement-restriction.header', placement_restriction_description_helper(1, restriction, parens)}
end

py.stringsplit = function(s, sep)
	if sep == nil then sep = '%s' end
	local t = {}
	for str in string.gmatch(s, '([^' .. sep .. ']+)') do
		table.insert(t, str)
	end
	return t
end

py.distance = function(x, y)
    return (x ^ 2 + y ^ 2) ^ 0.5
end

py.tints = {
	{r = 1.0, g = 1.0, b = 0.0, a = 1.0},
	{r = 1.0, g = 0.0, b = 0.0, a = 1.0},
	{r = 0.223, g = 0.490, b = 0.858, a = 1.0},
	{r = 1.0, g = 0.0, b = 1.0, a = 1.0}
}

py.light_tints = {}
for i, tint in pairs(py.tints) do
	py.light_tints[i] = {}
	for color, amount in pairs(tint) do
		py.light_tints[i][color] = (amount - 0.5) / 2 + 0.5
	end
	py.light_tints[i].a = 1
end

---@param color Color
---@return Color
function py.color_normalize(color)
	local r = color.r or color[1]
	local g = color.g or color[2]
	local b = color.b or color[3]
	local a = color.a or color[4] or 1
	if r > 1 then r = r / 255 end
	if g > 1 then g = g / 255 end
	if b > 1 then b = b / 255 end
	if a > 1 then a = a / 255 end
	return {r = r, g = g, b = b, a = a}
end

---@param a Color
---@param b Color
---@param percent number
---@return Color
function py.color_combine(a, b, percent)
	a = py.color_normalize(a)
	b = py.color_normalize(b)

	return {
		r = a.r * percent + b.r * (1 - percent),
		g = a.g * percent + b.g * (1 - percent),
		b = a.b * percent + b.b * (1 - percent),
		a = a.a * percent + b.a * (1 - percent)
	}
end

if script then
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
		script.on_event(event, process_gui_event)
	end
end

function py.reseed(generator)
	return game.create_random_generator(generator(341, 2147483647))
end

function py.find_grandparent(element, name)
	while element do
		if element.name == name then return element end
		element = element.parent
	end
	error('Could not find parent gui element with name: ' .. name)
end

-- data stage. adds a glow layer to any prototype with the 'icons' field.
function py.make_item_glowing(prototype)
	if not prototype then
		error('No prototype provided')
	end
	if prototype.pictures then
		for _, picture in pairs(prototype.pictures) do
			picture.draw_as_glow = true
		end
		return
	end
	if prototype.icon and not prototype.icons then
		prototype.icons = {{icon = prototype.icon, icon_size = prototype.icon_size, icon_mipmaps = prototype.icon_mipmaps}}
		prototype.icon = nil
	end
	if not prototype.icons then
		error('No icon found for ' .. prototype.name)
	end
	local pictures = {}
	for _, picture in pairs(table.deepcopy(prototype.icons)) do
		picture.draw_as_glow = true
		local icon_size = picture.icon_size or prototype.icon_size
		picture.filename = picture.icon
		picture.shift = {0, 0}
		picture.width = icon_size
		picture.height = icon_size
		picture.scale = 16 / icon_size
		picture.icon = nil
		picture.icon_size = nil
		picture.icon_mipmaps = nil
		pictures[#pictures + 1] = picture
	end
	prototype.pictures = pictures
end

function py.starts_with(str, start)
	return str:sub(1, #start) == start
end

local seconds_per_year = 60 * 60 * 24 * 365.25
local seconds_per_day = 60 * 60 * 24
local seconds_per_hour = 60 * 60
local seconds_per_minute = 60
function py.format_large_time(seconds)
    if not seconds then return end
    local result = ''
	if seconds >= seconds_per_year then
		local years = math.floor(seconds / seconds_per_year)
		result = result .. years .. 'y '
		seconds = seconds % seconds_per_year
	end
    
    if seconds >= seconds_per_day or result ~= '' then
    	local days = math.floor(seconds / seconds_per_day)
        result = result .. days .. 'd '
        seconds = seconds % seconds_per_day
    end

    if seconds >= seconds_per_hour or result ~= '' then
		local hours = math.floor(seconds / seconds_per_hour)
        result = result .. hours .. ':'
        seconds = seconds % seconds_per_hour
    end

    local minutes = math.floor(seconds / seconds_per_minute)
    if minutes < 10 then
        result = result .. '0' .. minutes .. ':'
    else
        result = result .. minutes .. ':'
    end
    seconds = seconds % seconds_per_minute

    seconds = math.ceil(seconds)
    if seconds < 10 then
        result = result .. '0' .. seconds
    else
        result = result .. seconds
    end

	return result
end

function py.reverse(t)
	for i = 1, #t / 2, 1 do
        t[i], t[#t - i + 1] = t[#t - i + 1], t[i]
    end
    return t
end

py.opposite_direction = {
	[defines.direction.north] = defines.direction.south,
	[defines.direction.northeast] = defines.direction.southwest,
	[defines.direction.east] = defines.direction.west,
	[defines.direction.southeast] = defines.direction.northwest,
	[defines.direction.south] = defines.direction.north,
	[defines.direction.southwest] = defines.direction.northeast,
	[defines.direction.west] = defines.direction.east,
	[defines.direction.northwest] = defines.direction.southeast
}

py.invert_table = function(t)
	local inverted = {}
	for k, v in pairs(t) do
		inverted[v] = k
	end
	return inverted
end

local noise = require 'noise'
local tne = noise.to_noise_expression

py.set_noise_constant = function(i, surface, data)
	local mgs = surface.map_gen_settings
	mgs.autoplace_controls = mgs.autoplace_controls or {}
	mgs.autoplace_controls['py-autoplace-control-' .. i] = mgs.autoplace_controls['py-autoplace-control-' .. i] or {}
	mgs.autoplace_controls['py-autoplace-control-' .. i].richness = data
	surface.map_gen_settings = mgs
end

py.get_noise_constant = function(i)
	return noise.get_control_setting('py-autoplace-control-' .. i).richness_multiplier
end

py.basis_noise = function(x, y, seed, zoom)
	return {
		type = 'function-application',
		function_name = 'factorio-basis-noise',
		arguments = {
			x = x,
			y = y,
			seed0 = tne(noise.var('map_seed')),
			seed1 = tne(seed),
			input_scale = tne(0.9999728452) / zoom,
			output_scale = tne(1.2 / 1.7717819213867)
		}
	}
end

--[[
use this to execute a script after a delay
example:

py.delayed_functions.my_delayed_func = function(param1, param2, param3) ... end
py.execute_later('my_delayed_func', 60, param1, param2, param3)

The above code will execute my_delayed_func after waiting for 60 ticks
]]
local powers_of_two = {}
for i = 0, 20 do
	powers_of_two[i] = 2 ^ i
end
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
else
	py.delayed_functions = {}
	py.on_event('on_init', function()
		global._delayed_functions = global._delayed_functions or {}
	end)
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
		global._delayed_functions[script.register_on_entity_destroyed(flying_text)] = {function_key, ticks - highest, {...}}
	end
	py.on_event(defines.events.on_entity_destroyed, function(event)
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
end

return py