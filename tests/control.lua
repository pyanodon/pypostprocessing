local total_string_count
local function test_localised_strings()
    local excluded_categories = {}
    local localised_strings = {}
    for _, recipe in pairs(prototypes.recipe) do
        if not excluded_categories[recipe.category] and not recipe.hidden then table.insert(localised_strings, recipe.localised_name) end
    end
    local excluded_types = {}
    for _, category in pairs {"item", "fluid", "entity"} do
        for _, item in pairs(prototypes[category]) do
            if not excluded_types[item.type] and not item.hidden then table.insert(localised_strings, item.localised_name) end
        end
    end
    game.players[1].request_translations(localised_strings)
    total_string_count = #localised_strings
    log("\ntest localised strings:")
end

local string_test_success = true
local string_count = 0
--- @param event EventData.on_string_translated
script.on_event(defines.events.on_string_translated, function(event)
    string_count = string_count + 1
    if not event.translated then
        log("WARNING: localised string " .. serpent.block(event.localised_string) .. " is missing a translation")
        string_test_success = false
    end
    if string_count == total_string_count then if string_test_success then log("localised strings test successful") end end
end)

script.on_nth_tick(1, function()
    log("control stage tests:")
    test_localised_strings()
    script.on_nth_tick(1, nil)
end)

local tests = require("scenario-tests")

commands.add_command("pytest", nil, function(param)
    for _, test in pairs(tests) do
        game.print("Test `" .. test() .. "` succeeded")
    end
end)
