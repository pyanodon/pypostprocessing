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

local pymods = {
	'pycoalprocessing',
	'pyindustry',
	'pyfusionenergy',
	'pyrawores',
	'pypetroleumhandling',
	'pyhightech',
	'pyalienlife',
	'pyalternativeenergy'
}
local success = false
local function run_cache_files(subset)
	local truth_table = {}
	for _, mod in pairs(subset) do truth_table[mod] = true end
	
	for _, pymod in pairs(pymods) do
		if (not truth_table[pymod]) ~= (not mods[pymod]) then
			-- the current modlist does match input
			return
		end
	end
	
	if success then error('pypostprocessing cache files were ran twice! Please report this') end
	success = true

	table.sort(subset)
	require(table.concat(subset, '+'))
end

-- simple py
run_cache_files{'pycoalprocessing'}
run_cache_files{'pyindustry'}
run_cache_files{'pyindustry', 'pycoalprocessing'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry'}

-- medium py
run_cache_files{'pycoalprocessing', 'pyindustry', 'pyrawores'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pypetroleumhandling'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyhightech'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pyhightech'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pypetroleumhandling', 'pyhightech'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling', 'pyhightech'}

-- full py
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling', 'pyalienlife'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling', 'pyalienlife', 'pyhightech'}
run_cache_files{'pycoalprocessing', 'pyfusionenergy', 'pyindustry', 'pyrawores', 'pypetroleumhandling', 'pyalienlife', 'pyhightech', 'pyalternativeenergy'}

if not success then
	error('pypostprocessing was not loaded correctly! Please report this')
end
