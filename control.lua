require "lib"

-- on_nth_tick functions
---@class NthTickOrder
---@field func string
---@field delay int

---@class NthTickFunc
---@field tick int
---@field mod string

---@type table<string, NthTickFunc>
py.nth_tick_funcs = {}

py.nth_tick_total = 0

---use instead of script.on_nth_tick
---@param func_list NthTickFunc[]
local register_on_nth_tick = function(func_list)
    for func_name, details in pairs(func_list) do
        log("registered on_nth_tick function " .. func_name .. " from mod " .. details.mod)
        py.nth_tick_total = py.nth_tick_total + 1 / details.tick
        py.nth_tick_funcs[details.mod .. "-" .. func_name] = {mod = details.mod, tick = details.tick}
    end
end

local function init_nth_tick(mod)
    ---@type table<int, NthTickOrder[]>
    storage.nth_tick_order = storage.nth_tick_order or {}
    local added_funcs = {}
    for _, tick_funcs in pairs(storage.nth_tick_order) do
        for _, details in pairs(tick_funcs) do
            added_funcs[details.func] = true
        end
    end
    for name, details in pairs(py.nth_tick_funcs) do
        if not added_funcs[name] then
            next_tick = math.ceil(game.tick / details.tick) * details.tick
            if not storage.nth_tick_order[next_tick] then storage.nth_tick_order[next_tick] = {} end
            table.insert(storage.nth_tick_order[next_tick], {func = name, delay = 0})
        end
    end
    py.nth_tick_total = math.ceil(py.nth_tick_total * 2)
    py.nth_tick_setup[mod] = true
end

local query_funcs = {}
local check_tick = -1
py.nth_tick_setup = {}

---@param mod string
---@param tick uint
---@return string[]
local query_nth_tick = function(mod, tick)
    if check_tick == tick and py.nth_tick_setup[mod] then
        return query_funcs[mod] or {}
    end
    check_tick = tick
    query_funcs = {}
    if not py.nth_tick_setup[mod] then init_nth_tick(mod) end
    local this_tick_total = 0
    local delayed = 0
    local add = tick ~= 0 and 1 or 0
    for _, order in pairs(storage.nth_tick_order[tick] or {}) do
        if not py.nth_tick_funcs[order.func] then goto continue end
        this_tick_total = this_tick_total + add
        if this_tick_total <= py.nth_tick_total then
            local mod_name = py.nth_tick_funcs[order.func].mod
            query_funcs[mod_name] = query_funcs[mod_name] or {}
            table.insert(query_funcs[mod_name], order.func)
            local next_tick = tick + py.nth_tick_funcs[order.func].tick - order.delay
            order.delay = 0
            if next_tick <= tick then
                order.delay = tick + 1 - next_tick
                next_tick = tick + 1
            end
            if not storage.nth_tick_order[next_tick] then storage.nth_tick_order[next_tick] = {} end
            table.insert(storage.nth_tick_order[next_tick], order)
        else
            delayed = delayed + 1
            if not storage.nth_tick_order[tick + 1] then storage.nth_tick_order[tick + 1] = {} end
            order.delay = order.delay + 1
            table.insert(storage.nth_tick_order[tick + 1], delayed, order)
        end
        ::continue::
    end
    storage.nth_tick_order[tick] = nil
    return query_funcs[mod] or {}
end

py.finalize_events()

remote.add_interface("on_nth_tick", {
    add = register_on_nth_tick,
    query = query_nth_tick,
})

-- delayed functions
---@type table<integer, table<int, {name: string, params: any[]?}>>
storage.on_tick = storage.on_tick or {}

py.on_event(defines.events.on_tick, function(event)
    local tick = event.tick
    storage.on_tick = storage.on_tick or {}
    if not storage.on_tick[tick] then return end
    for _, func_details in pairs(storage.on_tick[tick]) do
        local success, err = pcall(py.on_tick_funcs[func_details.name], table.unpack(func_details.params))
        if not success then error("error in on tick function " .. func_details.name .. ": " .. err) end
    end
    storage.on_tick[tick] = nil
end)

-- PAST HERE IS PY ONLY STUFF
if not py.has_any_py_mods() then
    return
end

script.on_configuration_changed(function()
    for _, force in pairs(game.forces) do
        force.reset_recipes()
        force.reset_technologies()
        force.reset_technology_effects()
    end

    if remote.interfaces["pywiki_turd_page"] then
        for _, force in pairs(game.forces) do remote.call("pywiki_turd_page", "reapply_turd_bonuses", force) end
    end

    if remote.interfaces["pyse_start_seqence"] then
        for _, force in pairs(game.forces) do remote.call("pyse_start_seqence", "update_force", force) end
    end
end)


-- We risk more problems than solutions if we expand further
-- This will need changes if TURD works off locking techs!
local checked_mods = {
    base = true,
    pyalienlife = true,
    pyalternativeenergy = true,
    pycoalprocessing = true,
    pyfusionenergy = true,
    pyhightech = true,
    pyindustry = true,
    pypetroleumhandling = true,
    pypostprocessing = true,
    pyrawores = true
}

commands.add_command("check-technology-consistency", {"command-help.check-technology-consistency"}, function()
    -- Build a list of base-game techs
    local filtered_prototypes = {}
    for name, prototype in pairs(prototypes.technology) do
        local history = prototypes.get_history("technology", name)
        if checked_mods[history.created] then
            filtered_prototypes[name] = prototype
        end
    end
    -- Iterate and verify
    for _, force in pairs(game.forces) do
        local force_techs = force.technologies
        for name, prototype in pairs(filtered_prototypes) do
            local tech = force_techs[name]
            if tech.enabled ~= prototype.enabled then
                tech.enabled = prototype.enabled
                local localised_name = tech.localised_name or ("technology-name." .. name)
                game.print {"command-output.fixed-technology", localised_name}
            end
        end
    end
    game.print {"command-output.consistency-check-complete"}
end)

if settings.startup["pypp-tests"].value then require "tests.control" end
