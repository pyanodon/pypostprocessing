-- all things relating to inventory management and transfers

---@param stack LuaItemStack
---@return boolean simple whether or not the stack is simple, in that is has no special data to be managed
local function is_simple_stack(stack)
    return not stack.is_item_with_label and
        not stack.is_item_with_entity_data and
        not stack.is_tool and
        not stack.grid
end

---@param stack LuaItemStack
---@param inventory LuaInventory
---@param amount_to_transfer? uint|double maximum amount to transfer, attempts to transfer full stack if omitted. can be specified as number of items or ratio of current stack size
---@return uint amount_transferred
py.transfer_stack = function(stack, inventory, amount_to_transfer)
    if not stack or not stack.valid_for_read or not inventory then return 0 end
    if not inventory.can_insert(stack) then return 0 end
    local destination = inventory.find_empty_stack(stack)
    if stack.grid and not destination then return 0 end -- special case for grid items, can only use transfer_stack
    if amount_to_transfer and amount_to_transfer < 1 then
        amount_to_transfer = math.floor(stack.count * amount_to_transfer + 0.5)
    end
    ---@cast amount_to_transfer uint
    if not destination or is_simple_stack(stack) then
        local pre_transfer_amount = stack.count
        stack.count = amount_to_transfer and amount_to_transfer < stack.count and amount_to_transfer or stack.count
        -- full, or almost full
        local amount_transferred = inventory.insert(stack)
        if amount_transferred == pre_transfer_amount then
            stack.clear()
        else
            stack.count = pre_transfer_amount - amount_transferred
        end
        return amount_transferred
    end
    destination.transfer_stack(stack, amount_to_transfer)
    return amount_to_transfer or destination.count
end

---@param player LuaPlayer
---@param stack LuaItemStack
---@param amount_to_transfer? uint|double maximum amount to transfer, attempts to transfer full stack if omitted. can be specified as number of items or ratio of current stack size
py.transfer_stack_to_cursor = function(player, stack, amount_to_transfer)
    if not stack or not stack.valid_for_read or player.controller_type == defines.controllers.spectator then return end
    local cursor_stack = player.cursor_stack
    if amount_to_transfer and amount_to_transfer < 1 then
        amount_to_transfer = math.floor(stack.count * amount_to_transfer + 0.5)
    end
    ---@cast amount_to_transfer uint
    if is_simple_stack(stack) then
        cursor_stack.set_stack{
            name = stack.name,
            quality = stack.quality,
            count = amount_to_transfer or stack.count,
            spoil_percent = stack.spoil_percent,
            health = stack.health
        }
        if amount_to_transfer then
            stack.count = stack.count - amount_to_transfer
        else
            stack.clear()
        end 
    else
        cursor_stack.transfer_stack(stack, amount_to_transfer)
    end
end

---@param player LuaPlayer
---@param stack LuaItemStack
---@param amount_to_transfer? uint|double maximum amount to transfer, attempts to transfer full stack if omitted. can be specified as number of items or ratio of current stack size
py.transfer_cursor_to_stack = function(player, stack, amount_to_transfer)
    local cursor_stack = player.cursor_stack
    if not cursor_stack or not cursor_stack.valid_for_read then return end
    if amount_to_transfer and amount_to_transfer < 1 then
        amount_to_transfer = math.floor(cursor_stack.count * amount_to_transfer + 0.5)
    end
    ---@cast amount_to_transfer uint
    if is_simple_stack(cursor_stack) then
        stack.set_stack{
            name = cursor_stack.name,
            quality = cursor_stack.quality,
            count = amount_to_transfer or cursor_stack.count,
            spoil_percent = cursor_stack.spoil_percent,
            health = cursor_stack.health
        }
        if amount_to_transfer then
            cursor_stack.count = cursor_stack.count - amount_to_transfer
        else
            cursor_stack.clear()
        end 
    else
        stack.transfer_stack(cursor_stack, amount_to_transfer)
    end
end

---@param inventory LuaInventory
---@param target_inventory LuaInventory
---@param stack_to_match? LuaItemStack item stack to match. attempts to match quality and name, transfers all items if omitted or no items in the stack
---@param amount_to_transfer? uint|double maximum amount to transfer, attempts to transfer full stack if omitted. can be specified as number of items or ratio of current stack size
---@param is_supported? function whether the target inventory is supported
py.transfer_inventory_items = function(inventory, target_inventory, stack_to_match, amount_to_transfer, is_supported)
    local total_transferred = 0

    local item = stack_to_match and stack_to_match.valid_for_read and {name = stack_to_match.name, quality = stack_to_match.quality}
    for i = 1, #inventory do
        if not inventory[i].valid_for_read or is_supported and not is_supported(inventory[i]) then goto continue end
        if item and (inventory[i].name ~= item.name or inventory[i].quality ~= item.quality) then goto continue end

        total_transferred = total_transferred + py.transfer_stack(inventory[i], target_inventory, amount_to_transfer)

        ::continue::
    end
    return total_transferred
end