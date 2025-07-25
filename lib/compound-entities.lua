if py.stage == "data" then
  function py.compound_attach_entity_to(parent, child, additional)
    local info = py.smuggle_get("compound-info", {})
    log(serpent.block(info))

    if not info[parent] then
      info[parent] = {}
    end

    additional.child = child
  
    table.insert(info[parent], additional)
    log(serpent.block(data.raw["mod-data"]))
  end
elseif py.stage == "control" then
  py.on_event(py.events.on_init(), function()
    if not storage.py_compound_entity_pairs then
      storage.py_compound_entity_pairs = {}
    end
    if not storage.py_compound_entity_gui_pairs then
      storage.py_compound_entity_gui_pairs = {}
    end
  end)

  if not py._compound_functions then py._compound_functions = {} end

  function py.register_compound_function(name, func)
    py._compound_functions[name] = func
  end

  function py.get_compound_function(name)
    return py._compound_functions[name]
  end

  function py.match_entity_gui_type(name)
    if name == "rocket-silo" then
      return defines.relative_gui_type.rocket_silo_gui
    end

    return defines.relative_gui_type.assembling_machine_gui
  end

  function py.register_compound_entities()
    local info = py.get_smuggled_data("compound-info")

    for machine, children in pairs(info) do
      py.on_event(py.events.on_built(), function(event)
        if not event.entity.valid or machine ~= event.entity.name then return end
      
        local position = event.entity.position

        storage.py_compound_entity_pairs[event.entity.unit_number] = {}
        storage.py_compound_entity_gui_pairs[event.entity.unit_number] = {}

        for _, info in pairs(children) do
          local new_position = position
          -- game.print(serpent.line(info.position_offset))
          if info.position_offset then
            new_position = {
              x = (position[1] or position.x) + (info.position_offset[1] or info.position_offset.x),
              y = (position[2] or position.y) + (info.position_offset[2] or info.position_offset.y)
            }
            -- game.print(serpent.line(position) .. " vs. " .. serpent.line(new_position))
          end
        
          local new_entity = event.entity.surface.create_entity{
            name = info.child,
            position = new_position,
            force = "player"
          }

          storage.py_compound_entity_pairs[event.entity.unit_number][new_entity.unit_number] = new_entity
          if info.enable_gui then
            storage.py_compound_entity_gui_pairs[event.entity.unit_number][new_entity.unit_number] = {entity = new_entity, info = info}
          end
        end
      end)

      py.on_event(py.events.on_destroyed(), function(event)
        if not event.entity.valid or machine ~= event.entity.name then return end

        -- Check if the thing exists
        if not storage.py_compound_entity_pairs[event.entity.unit_number] then
          return
        end

        for _, child in pairs(storage.py_compound_entity_pairs[event.entity.unit_number]) do
          if child and child.valid then
            child.destroy()
          end

          child = nil
        end
        for _, child in pairs(storage.py_compound_entity_gui_pairs[event.entity.unit_number]) do
          if child[1] and child[1].valid then
            child.destroy()
          end

          child = nil
        end
      end)

      py.on_event(py.events.on_gui_opened(), function(event)
        if not event.entity or not event.entity.valid or not machine == event.entity.name then return end
      
        local player = game.players[event.player_index]
        local entity = event.entity
      
        if not storage.py_compound_entity_gui_pairs[event.entity.unit_number] then
          return
        end
        if not storage.py_compound_entity_pairs[event.entity.unit_number] then
          return
        end
        
        if player.gui.relative["compound-entity-children"] then
          player.gui.relative["compound-entity-children"].destroy()
        end

        local root = player.gui.relative.add{
          type = "frame",
          name = "compound-entity-children",
          caption = {"", {"entity-name." .. entity.name}, " Components"},
          direction = "vertical",
          anchor = {
            gui = py.match_entity_gui_type(entity.type),
            position = defines.relative_gui_position.right
          },
        }

        for _, gui_child in pairs(storage.py_compound_entity_gui_pairs[event.entity.unit_number]) do
          if gui_child.info.gui_title then
            root.caption = py.get_compound_function(gui_child.info.gui_title)(event.entity)
          end
          
          local gui_func = py.get_compound_function(gui_child.info.gui_function_name)
          local gui_func = gui_func or function(event, player, root, gui_child)
            root.add{
              type = "button",
              name = "open-compound-entity-child-" .. (gui_child.entity.unit_number or gui_child.entity.name),
              caption = gui_child.info.gui_caption or {"", "Open ", {"entity-name." .. gui_child.entity.name}, " gui"},
              tags = {
                unit_number = event.entity.unit_number,
                child_unit_number = gui_child.entity.unit_number,
              },
            }
          end
          gui_func(event, player, root, gui_child)
        end

        return
      end)

      py.on_event(py.events.on_gui_click(), function(event)
        local player = game.players[event.player_index]
        if not ((string.find(event.element.name, "open-compound-entity-child", 1, true) or -1) >= 0) then return end
        if not storage.py_compound_entity_gui_pairs[event.element.tags.unit_number] then return end
        if not storage.py_compound_entity_gui_pairs[event.element.tags.unit_number][event.element.tags.child_unit_number] then return end

        local gui_child = storage.py_compound_entity_gui_pairs[event.element.tags.unit_number][event.element.tags.child_unit_number]

        local gui_menu
        if gui_child.info.gui_function_name then
          gui_menu = py.get_compound_function(gui_child.info.gui_submenu_function_name)(gui_child.entity)
        else
          gui_menu = gui_child
        end
        player.opened = gui_menu
      end)
    end
  end
end
