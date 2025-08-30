if mods[ "miniloader" ] then
    TECHNOLOGY("miniloader"):add_pack("py-science-pack-1"):add_pack("logistic-science-pack")
    TECHNOLOGY("fast-miniloader"):add_pack("py-science-pack-2")
    RECIPE("chute-miniloader"):add_ingredient({ type = "item", name = "burner-inserter", amount = 2 })
end
