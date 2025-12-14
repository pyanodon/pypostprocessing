data:extend {
    {
        type = "custom-input",
        name = "open-gui",
        key_sequence = "",
        linked_game_control = "open-gui",
        include_selected_prototype = true
    },
    { -- left click / A
        type = "custom-input",
        name = "py-interact-1",
        key_sequence = "mouse-button-1",
        controller_key_sequence = "controller-a"
    },
    { -- shift + left click / LT + A
        type = "custom-input",
        name = "py-interact-2",
        key_sequence = "SHIFT + mouse-button-1",
        controller_key_sequence = "controller-lefttrigger + controller-a"
    },
    { -- control + left click / RT + A
        type = "custom-input",
        name = "py-interact-3",
        key_sequence = "CONTROL + mouse-button-1",
        controller_key_sequence = "controller-righttrigger + controller-a"
    },
    { -- control + shift + left click / LT + RT + A
        type = "custom-input",
        name = "py-interact-4",
        key_sequence = "CONTROL + SHIFT + mouse-button-1",
        controller_key_sequence = "controller-lefttrigger + controller-righttrigger + controller-a"
    },
    { -- left click / A
        type = "custom-input",
        name = "py-interact-5",
        key_sequence = "ALT + mouse-button-1",
    },
    { -- shift + left click / LT + A
        type = "custom-input",
        name = "py-interact-6",
        key_sequence = "SHIFT + ALT + mouse-button-1",
    },
    { -- control + left click / RT + A
        type = "custom-input",
        name = "py-interact-7",
        key_sequence = "CONTROL + ALT + mouse-button-1",
    },
    { -- control + shift + left click / LT + RT + A
        type = "custom-input",
        name = "py-interact-8",
        key_sequence = "CONTROL + SHIFT + ALT + mouse-button-1",
    },
    { -- up
        type = "custom-input",
        name = "py-up",
        key_sequence = "UP",
        controller_key_sequence = "controller-dpup"
    },
    { -- down
        type = "custom-input",
        name = "py-down",
        key_sequence = "DOWN",
        controller_key_sequence = "controller-dpdown"
    },
    { -- left
        type = "custom-input",
        name = "py-left",
        key_sequence = "LEFT",
        controller_key_sequence = "controller-dpleft"
    },
    { -- right
        type = "custom-input",
        name = "py-right",
        key_sequence = "RIGHT",
        controller_key_sequence = "controller-dpright"
    },
}