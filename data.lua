if mods["space-age"] and not mods["pystellarexpedition"] then
	local message = "[color=255,0,0]The Space Age mod is not currently compatible with Pyanodons.[/color] Please disable Space Age."
	message = message .. "\nNote: In order to gain DLC features in Pyanodons such as spoilage, elevated rails, and stacking belts you may install the \"Enable All Feature Flags\" mod."
	message = message .. "\nhttps://mods.factorio.com/mod/enable-all-feature-flags"
	error("\n\n\n\n[font=default-semibold]" .. message .. "[/font]\n\n\n\n")
end

require "lib"

_G.pypp_registered_cache_files = {}

-- Usage example (add in data-updates phase):
-- register_cache_file({"pycoalprocessing", "pyfusionenergy"}, "__pyfusionenergy__/cached-configs/pycoalprocessing+pyfusionenergy.lua")
function _G.register_cache_file(subset, cache_file)
	table.sort(subset)
	pypp_registered_cache_files[#pypp_registered_cache_files + 1] =
	{
		subset = subset,
		cache_file = cache_file,
		is_fallback_from_pypp = false,
	}
end
