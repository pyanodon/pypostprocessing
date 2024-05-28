--zinc
py.global_item_replacer("ore-zinc", "zinc-ore")
py.global_item_replacer("zinc-plate", "zinc-plate-stock")

--lead
py.global_item_replacer("ore-lead","lead-ore")
py.global_item_replacer("lead-plate", "lead-plate-stock")
TECHNOLOGY("gm-lead-stock-processing"):remove_pack("chemical-science-pack")
TECHNOLOGY("gm-lead-machined-part-processing"):remove_pack("chemical-science-pack")

--nickel
py.global_item_replacer("ore-nickel","nickel-ore")
py.global_item_replacer("nickel-plate", "nickel-plate-stock")

--titanium
py.global_item_replacer("ore-titanium","titanium-ore")
py.global_item_replacer("titanium-plate", "titanium-plate-stock")

--Shafts
RECIPE("shaft-mk01"):remove_ingredient("solder"):add_ingredient({type = "item", name = "basic-shafting", amount = 2})