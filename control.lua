script.on_configuration_changed(function()
	game.reload_script()

	for _, force in pairs(game.forces) do
	   force.reset_recipes()
	   force.reset_technologies()
	   force.reset_technology_effects()
	end

	if remote.interfaces['pywiki_turd_page'] then
		for _, force in pairs(game.forces) do remote.call('pywiki_turd_page', 'reapply_turd_bonuses', force) end
	end

	if remote.interfaces['pyse_start_seqence'] then
		for _, force in pairs(game.forces) do remote.call('pyse_start_seqence', 'update_force', force) end
	end
end)


-- We risk more problems than solutions if we expand further
-- This will need changes if TURD works off locking techs!
local checked_mods = {
	base = true,
	pyalienlife = true,
	pyalternativeenergy = true,
	pycoalprocessing = true,
	pyfusionenergy = true,
	pyhightech = true,
	pyindustry = true,
	pypetroleumhandling = true,
	pypostprocessing = true,
	pyrawores = true
}

commands.add_command('check-technology-consistency', {'command-help.check-technology-consistency'}, function()
	local prototypes = {}
	-- Build a list of base-game techs
	for name, prototype in pairs(prototypes.technology) do
		local history = script.get_prototype_history('technology', name)
		if checked_mods[history.created] then
			prototypes[name] = prototype
		end
	end
	-- Iterate and verify
	for _, force in pairs(game.forces) do
		local force_techs = force.technologies
		for name, prototype in pairs(prototypes) do
			local tech = force_techs[name]
			if tech.enabled ~= prototype.enabled then
				tech.enabled = prototype.enabled
				local localised_name = tech.localised_name or ('technology-name.' .. name)
				game.print({'command-output.fixed-technology', localised_name})
			end
		end
	end
	game.print({'command-output.consistency-check-complete'})
end)

local dev_mode = settings.startup['pypp-dev-mode'].value
if dev_mode then require "tests.control" end
