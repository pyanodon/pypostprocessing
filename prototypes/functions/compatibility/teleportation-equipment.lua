if mods["TeleportationEquipment"] then
	
    TECHNOLOGY("teleportation-equipment"):remove_prereq("solar-panel-equipment"):add_prereq("modular-armor")

	if mods["pyalternativeenergy"] then
		RECIPE("teleportation-equipment")
			:replace_ingredient("battery-mk01", "nexelit-battery")
			:replace_ingredient("advanced-circuit", "electronics-mk02")
			:replace_ingredient("iron-plate", "crmoni")
			:add_ingredient({ type = "item", name = "controler-mk02", amount = 1})
			:add_ingredient({ type = "item", name = "mirror-mk01", amount = 6})
			:add_ingredient({ type = "item", name = "self-assembly-monolayer", amount = 25 })
			:add_ingredient({ type = "item", name = "small-parts-02", amount = 30 })
	end

	if mods["pyalienlife"] then
		TECHNOLOGY("teleportation-equipment"):add_pack("py-science-pack-2"):add_pack("chemical-science-pack")
	end
end