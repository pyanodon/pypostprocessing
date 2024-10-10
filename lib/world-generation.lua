---Returns a random number generator based on another generator.
---@param generator LuaRandomGenerator
---@return LuaRandomGenerator
py.reseed = function(generator)
	return game.create_random_generator(generator(341, 2147483647))
end

---Sets a noise constant which can be accessed inside a named_noise_expression. WARNING: Prone to floating point inaccuracies, don't use this to transfer worldgen seeds.
---@param i integer
---@param surface LuaSurface
---@param data number
py.set_noise_constant = function(i, surface, data)
	local mgs = surface.map_gen_settings
	mgs.autoplace_controls = mgs.autoplace_controls or {}
	mgs.autoplace_controls["py-autoplace-control-" .. i] = mgs.autoplace_controls["py-autoplace-control-" .. i] or {}
	mgs.autoplace_controls["py-autoplace-control-" .. i].richness = data
	surface.map_gen_settings = mgs
end

---Data stage only. Gets a noise constant which can be accessed inside a named_noise_expression.
---@param i integer
py.get_noise_constant = function(i)
	return "var('control-setting:py-autoplace-control-'" .. i .. ":richness:multiplier"
end

---Returns a noise expression which is an approximation of perlin noise. The output ranges from -1.2 to 1.2.
---@param x NoiseExpression
---@param y NoiseExpression
---@param seed integer
---@param zoom number
py.basis_noise = function(x, y, seed, zoom) -- todo: remove first two parameters in all uses.
	return [[basis_noise{
		x = x,
		y = y,
		seed0 = map_seed,
		seed1 = ]] .. seed .. [[,
		input_scale = 0.9999728452 / ]] .. zoom .. [[,
		output_scale = 1.2 / 1.7717819213867
	}]]
end
