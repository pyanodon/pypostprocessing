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

py.distance = function(x, y)
    return (x ^ 2 + y ^ 2) ^ 0.5
end