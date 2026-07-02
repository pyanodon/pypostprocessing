-- functions and helpers for alerts, warnings, and errors

---Draws a red error icon at the entity's position.
---@param entity LuaEntity
---@param sprite string
---@param time_to_live integer? default forever
---@param blink_interval integer? default 30 ticks
---@return LuaRenderObject
py.draw_error_sprite = function(entity, sprite, time_to_live, blink_interval)
    return rendering.draw_sprite {
        sprite = sprite,
        x_scale = entity.prototype.alert_icon_scale or 0.5,
        y_scale = entity.prototype.alert_icon_scale or 0.5,
        target = entity,
        surface = entity.surface,
        time_to_live = time_to_live,
        blink_interval = blink_interval or 30,
        render_layer = "air-entity-info-icon"
    }
end

---Generates an error icon and alert at the entity's position, refreshing both until cancelled
---@param entity LuaEntity entity alert is tied to
---@param signal SignalID sprite of generated alert
---@param icon SpritePath sprite of rendered alert
---@param message LocalisedString message of alert
---@param show_on_map boolean whether to show alert on map
---@return uint alert_id unique identifier of this alert
py.generate_alert = function(entity, signal, icon, message, show_on_map)
    if not entity or not entity.valid or not signal then return end
    storage.alert_count = storage.alert_count + 1
    storage.alerts[storage.alert_count] = {
        entity = entity,
        surface = entity.surface,
        force = entity.force,
        signal = signal,
        message = message,
        show_on_map = show_on_map,
        offset = game.tick % 600,
        rendering = py.draw_error_sprite(entity, icon)
    }
    return storage.alert_count
end

---Clears an alert from a force. Works if referenced entity is invalid
---@param alert_id uint
py.clear_alert = function(alert_id)
    if not alert_id then return end
    local alert_data = storage.alerts[alert_id]
    if alert_data.entity and alert_data.entity.valid then
        alert_data.entity.force.remove_alert{
            entity = alert_data.entity,
            surface = alert_data.surface
        }
    else
        for _, alert in pairs(alert_data.force.players[1].get_alerts{
            type = defines.alert_type.custom,
            surface = alert_data.surface,
            icon = alert_data.signal,
            message = alert_data.message
        }) do
            alert_data.force.remove_alert(alert)
        end
    end
    storage.alerts[alert_id] = nil
end

py.on_event(defines.events.on_tick, function()
    -- check stored alerts, update if required
    local offset = game.tick % 600
    for i, alert_data in pairs(storage.alerts or {}) do
        if alert_data.offset == offset then
            if not alert_data.entity.valid then
                storage.alerts[i] = nil
            else
                alert_data.entity.force.add_custom_alert(
                    alert_data.entity,
                    alert_data.signal,
                    alert_data.message,
                    alert_data.show_on_map
                )
            end
        end
    end
end)

py.on_event(py.events.on_init(), function()
    storage.alerts = storage.alerts or {}
    storage.alert_count = storage.alert_count or 0
end)