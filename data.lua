pypp_registered_cache_files = {}

-- Usage example (add in data-updates phase):
-- register_cache_file({"pycoalprocessing", "pyfusionenergy"}, "__pyfusionenergy__/cached-configs/pycoalprocessing+pyfusionenergy.lua")
function _G.register_cache_file(subset, cache_file)
	table.sort(subset)
	pypp_registered_cache_files[#pypp_registered_cache_files+1] =
	{
		subset=subset,
		cache_file=cache_file,
		is_fallback_from_pypp = false,
	}
end
 