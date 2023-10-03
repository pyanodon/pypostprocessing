local Table = require('__stdlib__/stdlib/utils/table')

local function merge(table, value)
	for k, v in pairs(value) do
		if type(v) == 'table' and k ~= 'prerequisites' and k ~= 'ingredients' then
			table[k] = table[k] or {}
			merge(table[k], v)
		else
			table[k] = v
		end
	end
end

function _G.fix_tech(tech_name, properties)
	local existing = data.raw.technology[tech_name]
	if not existing then
		log('WARNING: pypostprocessing could not find technology with name "' .. tech_name .. '"')
		return
	end
	merge(existing, properties)
end

function _G.science_pack_order(science_pack, order)
	local sp = data.raw.tool[science_pack]
	sp.subgroup = 'science-pack'
	sp.order = order
end

local function register_cache_file_pypp(subset)
	table.sort(subset)
	local cache_file = table.concat(subset, '+')
	pypp_registered_cache_files[#pypp_registered_cache_files + 1] =
	{
		subset=subset,
		cache_file=cache_file,
		is_fallback_from_pypp = true,
	}
end

-- simple py
register_cache_file_pypp{'pycoalprocessing'}
register_cache_file_pypp{'pyindustry'}
register_cache_file_pypp{'pyindustry', 'pycoalprocessing'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry'}

-- medium py
register_cache_file_pypp{'pycoalprocessing', 'pyindustry', 'pyrawores'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pypetroleumhandling'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyhightech'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pyhightech'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pypetroleumhandling', 'pyhightech'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling', 'pyhightech'}

-- full py
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling', 'pyalienlife'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling', 'pyalienlife', 'pyhightech'}
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling', 'pyalienlife', 'pyhightech', 'pyalternativeenergy'}

-- PyBlock
register_cache_file_pypp{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling', 'pyalienlife', 'pyhightech', 'pyalternativeenergy', 'PyBlock'}

local union_of_all_subsets = {}
for _, cache_file_info in pairs(pypp_registered_cache_files) do
	for _, mod in pairs(cache_file_info.subset) do
		union_of_all_subsets[mod] = 1
	end
end
union_of_all_subsets = Table.keys(union_of_all_subsets)
local recognized_enabled_mods = Table.filter(union_of_all_subsets, function(potential_mod) return mods[potential_mod] end)
table.sort(recognized_enabled_mods)

if #recognized_enabled_mods == 0 then
	log("No Pyanodon mods appear to be loaded, not loading cache file.")
	return
end

local function can_left_replace_fallback_right(left, right)
	return not left.is_fallback_from_pypp and right.is_fallback_from_pypp
end

local best_cache_file = nil
for _, cache_file_info in pairs(pypp_registered_cache_files) do
	local subset = cache_file_info.subset
	if #subset == #recognized_enabled_mods then
		local is_applicable = true
		for i = 1, #recognized_enabled_mods do
			if subset[i] ~= recognized_enabled_mods[i] then
				is_applicable = false
				break
			end
		end
		if is_applicable then
			if best_cache_file == nil or can_left_replace_fallback_right(cache_file_info, best_cache_file) then
				best_cache_file = cache_file_info
			elseif not can_left_replace_fallback_right(best_cache_file, cache_file_info) then
				error("There are two cache files for mod sets registered that are equally good given the mods that are active. The first is " .. best_cache_file.cache_file .. ", the second is " .. cache_file_info.cache_file)
			end
		end
	end
end

if best_cache_file == nil then
	for _, cache_file_info in pairs(pypp_registered_cache_files) do
		log("Cache file " .. cache_file_info.cache_file .. ", supported mods " .. table.concat(cache_file_info.subset, "+"))
	end
	error("No cache file registered that supports all your enabled mods. Enabled known mods: " .. table.concat(recognized_enabled_mods, "+") .. ", registered cache files printed in logs.")
else
	log("Unique best cache file found, applying " .. best_cache_file.cache_file .. ", which " .. (best_cache_file.is_fallback_from_pypp and "is" or "is not") .. " a PyPP default.")
	require(best_cache_file.cache_file)
end
