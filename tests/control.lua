local function test_localised_strings()
    local excluded_categories = {}
    local localised_strings = {}
    for _, recipe in pairs(prototypes.get_recipe_filtered{}) do
        if not excluded_categories[recipe.category] then table.insert(localised_strings, recipe.localised_name) end
    end
    game.players[1].request_translations(localised_strings)
end

--- @param event EventData.on_string_translated
script.on_event(defines.events.on_string_translated, function(event)
    if not event.translated then
        log("WARNING: localised string " .. serpent.block(event.localised_string) .. " is missing a translation")
    end
end)

script.on_nth_tick(1, function()
    test_localised_strings()
    script.on_nth_tick(1, nil)
end)
