local create_signal_mode = settings.startup["pypp-extended-recipe-signals"].value

if create_signal_mode then
    data:extend {
        {
            type = "item-group",
            name = "py-postprocessing",
            order = "v",
            inventory_order = "v",
            icon = "__pycoalprocessinggraphics__/graphics/icons/automated-factory-mk01.png",
            icon_size = 64
        },
        {
            type = "item-subgroup",
            name = "py-recipes",
            group = "py-postprocessing",
            order = "a-a"
        },
    }
end
