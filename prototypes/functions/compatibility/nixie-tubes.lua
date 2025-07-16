if mods["UPSFriendlyNixieTubeDisplay"] then
    TECHNOLOGY("classic-nixie-tubes"):remove_pack("logistic-science-pack")
    TECHNOLOGY("reinforced-nixie-tubes"):remove_pack("logistic-science-pack")

    TECHNOLOGY("classic-nixie-tubes"):add_pack("py-science-pack-1")
    TECHNOLOGY("reinforced-nixie-tubes"):add_pack("py-science-pack-1")

    RECIPE("classic-nixie-tube"):replace_ingredient("electronic-circuit", "battery-mk01")
    RECIPE("classic-nixie-tube"):replace_ingredient("iron-plate", "electronic-circuit")

    RECIPE("reinforced-nixie-tube"):replace_ingredient("steel-plate", "intermetallics")
    RECIPE("small-reinforced-nixie-tube"):replace_ingredient("steel-plate", "intermetallics")

    RECIPE("reinforced-nixie-tube"):replace_ingredient("iron-stick", "duralumin")
    RECIPE("small-reinforced-nixie-tube"):replace_ingredient("iron-stick", "duralumin")
end
