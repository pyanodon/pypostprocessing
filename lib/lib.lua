_G.py = {}

local factorio_globals = {
    -- data stage
    "generate_recycling_recipe_icons_from_item",
    "add_recipe_values",
    "scale",
    "shift",
    "tint",
    -- control stage
    "util",
    "gram",
    "grams",
    "kg",
    "tons",
    "second",
    "minute",
    "hour",
    "meter",
    "kilometer",
}

local spidertron_patrols_globals = {
    -- data stage
    "sp_data_stage",
    "contains",
    "contains_key",
    "content_equals",
    "table_equals",
    "for_n_of",
}

local spidertron_enhancements_globals = {
    -- data stage
    "create_dummy_spidertron",
}

local pyal_globals = {
    -- data stage
    "make_unit_melee_ammo_type",
    "Biofluid",
    "Digosaurus",
    -- tries to read nil
    "yafc_turd_integration",
    -- control stage
    "Caravan",
    "CaravanGuiComponents",
    "CaravanGui",
    "entity_has_caravan",
    "has_entity_in_schedule",
    "new_digosaur",
    "remove_digosaur",
    "Oculua",
    "Farming",
    "Smart_Farm",
    "Worm",
    "Turd",
    "Vatbrain",
    "Ulric",
    "entity_changed_unit_number",
    "order_by_distance",
    "Mounts",
}

local maraxsis_globals = {
    -- data stage
    "maraxsis_dome_collision_mask",
    "maraxsis_underwater_collision_mask",
    "maraxsis_lava_collision_mask",
    "maraxsis_coral_collision_mask",
    "maraxsis_trench_entrance_collision_mask",
    "maraxsis",
    "maraxsis_constants",
    -- tries to read nil
    "aai_vehicle_exclusions",
    "stone_driving_sound",
    "nuke_shockwave_starting_speed_deviation",
}

local pysex_globals = {
    -- data stage
    "collision_mask_util",
    -- tries to read nil
    "default_orange_color",
    "transitions",
    "transitions_between_transitions",
    "stone_path_vehicle_speed_modifier",
    -- control stage
    "Planet",
    "Orbit",
    "Planets",
    "H2O2",
    "Centrifuge",
    "RocketSilo",
    -- tries to read nil
    "on_search",
}

local pypp_globals = {
    -- data stage
    "ENTITY",
    "FLUID",
    "ITEM",
    "RECIPE",
    "TECHNOLOGY",
    "TILE",
    "pypp_registered_cache_files",
    "register_cache_file",
    "fix_tech",
    "science_pack_order",
    "tech",
    "data", -- required for turd stuff
    "script",
    -- control stage
    "gui_events",
    "mods", -- required for turd stuff
}

local pycp_globals = {
    -- data stage
    "prerequisites",
    -- control stage
    "Wiki",
    "Pond",
    "Beacons",
}

local pyae_globals = {
    -- control stage
    "Thermosolar",
    "Solar_Updraft_Tower",
    "Heliostat",
    "Solar",
    "Wind",
    "Aerial",
    "Tidal"
}

local debugadapter_globals = {
    -- data stage
    "setfenv",
    -- control stage
}

function py.has_any_py_mods()
    local mods = mods or script.active_mods
    return mods.pyindustry or mods.pycoalprocessing
end

py.range = function(start, stop, step)
    step = step or 1
    if start > stop then
        step = -step
    end

    local range = {}
    for i = start, stop, step do
        table.insert(range, i)
    end
    return range
end

require "table"
require "string"
require "defines"
require "color"
require "world-generation"

if helpers.stage == "settings" then

elseif helpers.stage == "prototype" then
    require "data-stage"
elseif helpers.stage == "runtime" then
    require "control-stage"
else
    error("Could not determine load order stage.")
end

local declaredNames = {}

---declare a new global variable
---luals doesn't like them being declared like that so use the function here and assign value later
---@param name string
---@param initval any
local function declare(name, initval)
    rawset(_G, name, initval or rawget(_G, name))
    if declaredNames[name] then
        error("attempt to overwrite global variable: " .. name, 2)
    end
    declaredNames[name] = true
end

local control_globals_outside_of_events = false
if helpers.stage == "runtime" then
    py.on_event(defines.events.on_tick, function(_)
        if not storage.global_messages_sent then
            if py.mod_data.undeclared_globals_exist then
                game.print("[color=255,0,0]found references to undefined globals in data stage, check logs[/color]")
            end
            if control_globals_outside_of_events then
                game.print("[color=255,0,0]found references to undefined globals in control stage, check logs[/color]")
            end
            storage.global_messages_sent = true
        end
    end)
end

if settings.startup["pypp-no-globals"].value then
    setmetatable(_G, {
        __newindex = function(t, n, v)
            if not declaredNames[n] then
                if helpers.stage == "runtime" then
                    -- temp
                    if game then
                        game.print(debug.traceback("attempt to write to undeclared global variable, please report it\nIf this is intended, add it to the globals list in pypp/lib/lib.lua\n" .. n, 2))
                    else
                        log(debug.traceback("attempt to write to undeclared global variable, please report it\nIf this is intended, add it to the globals list in pypp/lib/lib.lua\n" .. n, 2))
                        control_globals_outside_of_events = true
                    end
                    -- end temp
                    -- error("attempt to write to undeclared variable: " .. n, 2)
                else
                    py.mod_data.undeclared_globals_exist = true
                end
                log(debug.traceback("INFO: creating a new global variable\nIf this is intended, add it to the globals list in pypp/lib/lib.lua\n" .. n, 2))
            end
            rawset(t, n, v) -- do the actual set
        end,
        __index = function(_, n)
            if not declaredNames[n] then
                if helpers.stage == "runtime" then
                    -- temp
                    if game then
                        game.print(debug.traceback("attempt to read undeclared global variable, please report it: " .. n, 2))
                    else
                        control_globals_outside_of_events = true
                    end
                    log(debug.traceback("attempt to read undeclared global variable: " .. n, 2))
                    -- end temp
                    -- error("attempt to read undeclared variable: " .. n, 2)
                elseif helpers.stage == "prototype" then
                    -- temp, ultimately won't print at game start and will have a strict mode setting for testing that will crash the game
                    log(debug.traceback("WARNING: attempt to read undeclared global variable: " .. n, 2))
                    py.mod_data.undeclared_globals_exist = true
                end
            else
                return nil
            end
        end,
    })
end


local global_vars = table.array_combine(
    factorio_globals,
    spidertron_patrols_globals,
    pyal_globals,
    maraxsis_globals,
    pysex_globals,
    pypp_globals,
    spidertron_enhancements_globals,
    pycp_globals,
    pyae_globals,
    debugadapter_globals
)

for _, var in pairs(global_vars) do
    declare(var)
end

declare("_")
declare("game") -- needed for globals used outside of events
