_G.py = {}

local factorio_globals = {
    "get_beam_sprite",
    "get_chain_sprite",
    "make_tesla_electric_beam_graphics",
    "make_tesla_electric_beam_chain_graphics",
    "make_tesla_beam",
    "make_tesla_beam_chain",
    "beam_tint",
    "blend_mode",
    "shared_bay_hatch",
    "platform_upper_hatch",
    "platform_lower_hatch",
    "load_cockpit_sprite",
    "cockpit_animation",
    "crusher_integration_patch_horizontal",
    "crusher_integration_patch_vertical",
    "crusher_animation_horizontal_main",
    "crusher_animation_horizontal_shadow",
    "crusher_animation_vertical_main",
    "crusher_animation_vertical_shadow",
    "crusher_working_visualisations_horizontal",
    "crusher_working_visualisations_vertical",
    "rocket_turret_rising",
    "rocket_turret_attack",
    "tesla_turret_rising",
    "tesla_turret_ready",
    "tesla_turret_cooldown",
    "tesla_turret_LED",
    "result_table",
    "get_leg_joint_rotation_offsets",
    "create_leg_graphics_set",
    "get_leg_hit_the_ground_when_attacking_trigger",
    "gleba_hit_effects",
    "make_pentapod_leg_dying_trigger_effects",
    "make_segment_name",
    "make_demolisher_ash_cloud_update_effect",
    "make_demolisher_head",
    "make_demolisher_corpse",
    "make_demolisher_segment",
    "make_demolisher_tail",
    "make_demolisher_segment_specifications",
    "make_demolisher_segments",
    "make_ash_cloud_trigger_effects",
    "make_demolisher_fissure_attack",
    "make_demolisher_effects",
    "make_demolisher",
    "make_leg",
    "wriggler_spritesheet",
    "wriggler_corpse_spritesheet",
    "make_stomper",
    "make_strafer",
    "make_wriggler",
    "leg_graphics_properties",
    "stream_tint_stomper",
    "splash_tint_stomper",
    "sticker_tint_stomper",
    "create_asteroid_chunk_parameter",
    "item_effects",
    "lava_tile_type_names",
    "space_age_tiles_util",
    "lava_transition_group_id",
    "vulcanus_tile_offset",
    "gleba_tile_offset",
    "gleba_lowland_tile_offset",
    "get_decal_pictures",
    "chimney_sulfuric_stateless_visualisation",
    "chimney_sulfuric_stateless_visualisation_tinted",
    "chimney_sulfuric_stateless_visualisation_faded",
    "variant_parameters",
    "gleba_water_tiles",
    "gleba_land_tiles",
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
    -- TODO those are bugs
    "tru",
    "usage",
    "i",
    "lava_stone_transitions",
    "ground_to_out_of_map_transition",
    "patch_for_inner_corner_of_transition_between_transition",
    "concrete_to_out_of_map_transition",
    "lake_ambience",
    "base_decorative_sprite_priority",
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
    "data", -- required to determine stage
    "script",
    -- control stage
    "gui_events",
    "mods", -- required to determine stage
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

if data and data.raw and not data.raw.item["iron-plate"] then
    py.stage = "settings"
elseif data and data.raw then
    py.stage = "data"
    require "data-stage"
elseif script then
    py.stage = "control"
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

if py.stage == "data" then
    data:extend {
        {
            type = "mod-data",
            name = "py-undocumented-globals",
            data = {}
        }
    }
end

local message_sent = false
if py.stage == "control" then
    py.on_event(defines.events.on_tick, function(_)
        ---@diagnostic disable-next-line: undefined-field
        if not message_sent and prototypes.mod_data["py-undocumented-globals"].get("exist") then
            game.print("[color=255,0,0]found references to undefined globals in data stage, check logs[/color]")
            message_sent = true
        end
    end)
end

if settings.startup["pypp-no-globals"].value then
    setmetatable(_G, {
        __newindex = function(t, n, v)
            if not declaredNames[n] then
                if py.stage == "control" then
                    -- temp
                    game.print(debug.traceback("attempt to write to undeclared global variable, please report it\nIf this is intended, add it to the globals list in pypp/lib/lib.lua" .. n, 2))
                    -- end temp
                    -- error("attempt to write to undeclared variable: " .. n, 2)
                end
                log(debug.traceback("INFO: creating a new global variable\nIf this is intended, add it to the globals list in pypp/lib/lib.lua" .. n, 2))
            end
            rawset(t, n, v) -- do the actual set
        end,
        __index = function(_, n)
            if not declaredNames[n] then
                if py.stage == "control" then
                    -- temp
                    game.print(debug.traceback("attempt to read undeclared global variable, please report it: " .. n, 2))
                    log(debug.traceback("attempt to read undeclared global variable: " .. n, 2))
                    -- end temp
                    -- error("attempt to read undeclared variable: " .. n, 2)
                elseif py.stage == "data" then
                    -- temp, ultimately won't print at game start and will have a strict mode setting for testing that will crash the game
                    log(debug.traceback("WARNING: attempt to read undeclared global variable: " .. n, 2))
                    data.raw["mod-data"]["py-undocumented-globals"].data.exist = true
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
    pyae_globals
)

for _, var in pairs(global_vars) do
    declare(var)
end

declare("_")
