local FUN = require("__pycoalprocessing__/prototypes/functions/functions")

--zinc
FUN.global_item_replacer("ore-zinc", "zinc-ore")
FUN.global_item_replacer("zinc-plate", "zinc-plate-stock")

--lead
FUN.global_item_replacer("ore-lead","lead-ore")
FUN.global_item_replacer("lead-plate", "lead-plate-stock")
TECHNOLOGY("gm-lead-stock-processing"):remove_pack("chemical-science-pack")
TECHNOLOGY("gm-lead-machined-part-processing"):remove_pack("chemical-science-pack")

--nickel
FUN.global_item_replacer("ore-nickel","nickel-ore")
FUN.global_item_replacer("nickel-plate", "nickel-plate-stock")

--titanium
FUN.global_item_replacer("ore-titanium","titanium-ore")
FUN.global_item_replacer("titanium-plate", "titanium-plate-stock")

--Shafts
RECIPE("shaft-mk01"):remove_ingredient("solder"):add_ingredient({type = "item", name = "basic-shafting", amount = 2})