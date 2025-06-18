if mods["bobinserters"] and mods["pyalienlife"] then
    if bobInsertersVersion:sub(1, 1) == "1" then
        TECHNOLOGY("more-inserters-1"):add_pack("py-science-pack-2")
    else
        TECHNOLOGY("bob-more-inserters-1"):add_pack("py-science-pack-2")
    end
end

if mods["bobmodules"] then
    RECIPE("module-case"):add_unlock("basic-electronics")
    RECIPE("module-contact"):add_unlock("basic-electronics")
    RECIPE("module-circuit-board"):add_unlock("basic-electronics")
    RECIPE("module-processor-board"):add_unlock("basic-electronics")
    RECIPE("module-processor-board-2"):add_unlock("basic-electronics")
    RECIPE("module-processor-board-3"):add_unlock("basic-electronics")
    RECIPE("lab-module"):add_unlock("basic-electronics")
    RECIPE("speed-processor"):add_unlock("basic-electronics")
    RECIPE("effectivity-processor"):add_unlock("basic-electronics")
    RECIPE("productivity-processor"):add_unlock("basic-electronics")
    RECIPE("pollution-clean-processor"):add_unlock("basic-electronics")
    RECIPE("pollution-create-processor"):add_unlock("basic-electronics")
end
