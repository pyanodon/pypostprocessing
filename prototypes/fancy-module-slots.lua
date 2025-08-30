-- This causes icon overhang issues with compressed omni buildings.
if mods[ "omnimatter_compression" ] then return end

-- custom module alt-mode draw positioning
for prototype_name, inventory in pairs({
    [ "mining-drill" ] = defines.inventory.mining_drill_modules,
    [ "assembling-machine" ] = defines.inventory.assembling_machine_modules,
    [ "furnace" ] = defines.inventory.furnace_modules,
    [ "lab" ] = defines.inventory.lab_modules,
    [ "rocket-silo" ] = defines.inventory.rocket_silo_modules,
    [ "beacon" ] = defines.inventory.beacon_modules,
}) do
    for _, machine in pairs(data.raw[ prototype_name ] or {}) do
        local collision_box = machine.selection_box or machine.collision_box
        if not collision_box then goto continue end

        local left_top = collision_box[ 1 ] or collision_box.left_top
        local right_bottom = collision_box[ 2 ] or collision_box.right_bottom
        if not left_top or not right_bottom then goto continue end

        local x1, y1 = left_top[ 1 ] or left_top.x, left_top[ 2 ] or left_top.y
        local x2, y2 = right_bottom[ 1 ] or right_bottom.x, right_bottom[ 2 ] or right_bottom.y
        local width, height = x2 - x1, y2 - y1
        local area = width * height

        if not machine.module_slots or machine.module_slots == 0 then goto continue end

        local scale_factors = { 1 }
        for i = 1, 20 do scale_factors[ i + 1 ] = scale_factors[ i ] * 0.95 end

        if width > 4 then table.insert(scale_factors, 1, 1.25) end
        if width > 5 then table.insert(scale_factors, 1, 1.5) end
        if width > 12 then table.insert(scale_factors, 1, 2) end
        if width > 22 then table.insert(scale_factors, 1, 2.5) end
        if width > 32 then table.insert(scale_factors, 1, 3) end

        for _, scale in pairs(scale_factors) do
            local module_alt_mode_width = 1.1 * scale -- width and height of the module icon in tiles

            local area_covered_by_modules = (math.ceil(machine.module_slots ^ 0.5) ^ 2) * (module_alt_mode_width ^ 2)
            if area_covered_by_modules > area * 0.4 then goto too_big end

            local max_icons_per_row = machine.module_slots
            while max_icons_per_row * module_alt_mode_width > width do
                if max_icons_per_row <= 2 then break end
                max_icons_per_row = max_icons_per_row - 1
            end

            local num_module_rows = math.ceil(machine.module_slots / max_icons_per_row)
            if num_module_rows ~= 1 and num_module_rows * module_alt_mode_width > height * 0.35 then goto too_big end

            -- make it as even a square as possible
            while true do
                max_icons_per_row = max_icons_per_row - 1
                local new_rows = math.ceil(machine.module_slots / max_icons_per_row)
                if num_module_rows ~= new_rows then
                    max_icons_per_row = max_icons_per_row + 1
                    break
                end
            end

            local y = y2 - (num_module_rows * module_alt_mode_width)
            local shift = { 0, y }

            machine.icons_positioning = {
                { inventory_index = inventory, shift = shift, scale = scale, max_icons_per_row = max_icons_per_row },
            }
            break

            ::too_big::
        end
        ::continue::
    end
end
