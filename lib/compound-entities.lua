if py.stage == "data" then
  -- Attachs an entity to another entity with additional properties
  -- @param parent string
  -- @param child string
  -- 
  -- @param additional AdditionalParams
  -- @class AdditionalParams
  -- @field enable_gui bool Enables an entry in the gui of the parent
  -- @field gui_title string The title of the parent gui
  -- @field gui_function_name string The name of the register compound function that handles adding the button to the gui
  -- @field gui_submenu_function string The fuction called when you hit the button itself
  -- @field gui_caption string The text the button has
  -- @field position_offset MapPosition https://lua-api.factorio.com/2.0.64/concepts/MapPosition.html
  --
  -- @see https://pyanodon.github.io/pybugreports/internal_apis/compound_entities.html 
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

  local init = function()
    if not storage.compound_entity_pairs then
      storage.compound_entity_pairs = {}
    end
    if not storage.compound_entity_pairs_reverse then
      storage.compound_entity_pairs_reverse = {}
    end
    if not storage.compound_entity_gui_pairs then
      storage.compound_entity_gui_pairs = {}
    end
  end
  py.on_event(py.events.on_init(), init)

  if not py.compound_functions then py.compound_functions = {} end

  -- Registers a new compound function
  -- @param name string Name of the function
  -- @param func (GuiTitleFunction|GuiFunction|GuiSubmenuFunction)
  --
  -- @function GuiTitleFunction
  -- @param entity LuaEntity parent entity
  -- @return string Title
  -- 
  -- @function GuiFunction
  -- @param event events.on_gui_opened Event data of when on_gui_opened is called
  -- @param player LuaEntity the player who opened the GUI
  -- @param gui_root LuaGuiElement The root of the preset GUI that you can add to
  -- @param current_index number The index of the compound-entity child you are
  -- @param gui_child LuaGuiElement The Button you are in the the gui_root
  -- @return nil
  --
  -- @function GuiSubmenuFunction
  -- @param entity Parent entity
  -- @return (LuaGuiElement|LuaEntity) Anything that can be put in `player.opened`
  -- 
  -- @see https://pyanodon.github.io/pybugreports/internal_apis/compound_entities.html 
  function py.register_compound_function(name, func)
    py.compound_functions[name] = func
  end

  -- Gets a registered compound_function from a name
  -- @param name string The name of the function
  function py.get_compound_function(name)
    return py.compound_functions[name]
  end

  -- Gets the compound entity's children from it's unit_number
  -- @param unit_number number Unit number of the parent
  function py.get_compound_entity_children(unit_number)
    return storage.compound_entity_pairs[unit_number]
  end

  -- Gets the compound_entity parent from a child's unit_number
  -- @param unit_number number Unit number of a child
  function py.get_compound_entity_parent(unit_number)
    return storage.compound_entity_pairs_reverse[unit_number]
  end

  -- WARNING: THIS SHOULD BE SOMEWHERE ELSE AND SHOULD BE REPLACED IF DOESN'T EXIST ALREADY
  function py.match_entity_gui_type(name)
    if name == "rocket-silo" then
      return defines.relative_gui_type.rocket_silo_gui
    end

    return defines.relative_gui_type.assembling_machine_gui
  end


  -- Adds a new child to a compound entity
  -- Unsure about using this on non compound register parents, beware...
  -- Will not clean up compound entity children on non registered parents
  -- 
  -- @param parent LuaEntity the parent compound entity
  -- @param child_name string Name of the child
  -- @param info Info
  --
  -- @class Info
  -- @field enable_gui bool Not sure if it works but it's the same as the normal enable_gui property
  -- @field possition_offset MapPosition https://lua-api.factorio.com/2.0.64/concepts/MapPosition.html
  function py.compound_attach_entity_to(parent, child_name, info)
    init()
    if not parent.valid then return end
  
    local position = parent.position

    if not storage.compound_entity_pairs[parent.unit_number] then
      storage.compound_entity_pairs[parent.unit_number] = {}
      storage.compound_entity_gui_pairs[parent.unit_number] = {}
    end
    
    local new_position = position
    -- game.print(serpent.line(info.position_offset))
    if info.position_offset then
      new_position = {
        x = (position[1] or position.x) + (info.position_offset[1] or info.position_offset.x),
        y = (position[2] or position.y) + (info.position_offset[2] or info.position_offset.y)
      }
      -- game.print(serpent.line(position) .. " vs. " .. serpent.line(new_position))
    end
  
    local new_entity = parent.surface.create_entity{
      name = child_name,
      position = new_position,
      force = "player"
    }

    storage.compound_entity_pairs[parent.unit_number][new_entity.unit_number] = new_entity
    storage.compound_entity_pairs_reverse[new_entity.unit_number] = parent
    if info.enable_gui then
      storage.compound_entity_gui_pairs[parent.unit_number][new_entity.unit_number] = {entity = new_entity, info = info}
    end
  end

  -- Deletes children from a parent by a filter function
  -- Do not worry about validity it is checked internally
  --
  -- @param parent_unit_number number Unit number of the parent
  -- @param filter_func fun(child: LuaEntity): bool Return true if delete
  function py.delete_attached_entities_by_filter(parent_unit_number, filter_func)
    init()
    if not storage.compound_entity_pairs[parent_unit_number] then
      return
    end

    for _, child in pairs(storage.compound_entity_pairs[parent_unit_number]) do
      local delete = filter_func(child)
      if child and child.valid and delete then
        if storage.compound_entity_pairs_reverse then
          storage.compound_entity_pairs_reverse[child.unit_number] = nil
        end
    
        child.destroy()
        child = nil
      end
    end

    for _, child in pairs(storage.compound_entity_gui_pairs[parent_unit_number]) do
      local delete = filter_func(child[1])
      if child[1] and child[1].valid and delete then
        child.destroy()
        child = nil
      end
    end
  end

  -- Register all compound_entities and create their events
  function py.register_compound_entities()
    init()
    local info = py.get_smuggled_data("compound-info")

    for machine, children in pairs(info) do
      py.on_event(py.events.on_built(), function(event)
        init()
        if not event.entity.valid or machine ~= event.entity.name then return end
      
        local position = event.entity.position

        storage.compound_entity_pairs[event.entity.unit_number] = {}
        storage.compound_entity_gui_pairs[event.entity.unit_number] = {}

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

          storage.compound_entity_pairs[event.entity.unit_number][new_entity.unit_number] = new_entity
          storage.compound_entity_pairs_reverse[new_entity.unit_number] = event.entity
          if info.enable_gui then
            storage.compound_entity_gui_pairs[event.entity.unit_number][new_entity.unit_number] = {entity = new_entity, info = info}
          end
        end
      end)

      py.on_event(py.events.on_destroyed(), function(event)
        init()
        if not event.entity.valid or machine ~= event.entity.name then return end

        -- Check if the thing exists
        if not storage.compound_entity_pairs[event.entity.unit_number] then
          return
        end

        for _, child in pairs(storage.compound_entity_pairs[event.entity.unit_number]) do
          if child and child.valid then
            if storage.compound_entity_pairs_reverse then
              storage.compound_entity_pairs_reverse[child.unit_number] = nil
            end
            
            child.destroy()
          end
          child = nil
        end

        for _, child in pairs(storage.compound_entity_gui_pairs[event.entity.unit_number]) do
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
      
        if not storage.compound_entity_gui_pairs[event.entity.unit_number] then
          return
        end
        if not storage.compound_entity_pairs[event.entity.unit_number] then
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

        if #storage.compound_entity_gui_pairs[event.entity.unit_number] == 0 then
          root.destroy()
        end

        local i = 1
        for _, gui_child in pairs(storage.compound_entity_gui_pairs[event.entity.unit_number]) do
          if gui_child.info.gui_title then
            root.caption = py.get_compound_function(gui_child.info.gui_title)(event.entity)
          end

          local gui_func = py.get_compound_function(gui_child.info.gui_function_name)
          local gui_func = gui_func or function(event, player, root, _, gui_child)
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
          gui_func(event, player, root, i, gui_child)

          i = i + 1
        end

        return
      end)

      py.on_event(py.events.on_gui_click(), function(event)
        local player = game.players[event.player_index]
        if not ((string.find(event.element.name, "open-compound-entity-child", 1, true) or -1) >= 0) then return end
        if not storage.compound_entity_gui_pairs[event.element.tags.unit_number] then return end
        if not storage.compound_entity_gui_pairs[event.element.tags.unit_number][event.element.tags.child_unit_number] then return end

        local gui_child = storage.compound_entity_gui_pairs[event.element.tags.unit_number][event.element.tags.child_unit_number]

        local gui_menu
        if gui_child.info.gui_submenu_function_name then
          gui_menu = py.get_compound_function(gui_child.info.gui_submenu_function_name)(gui_child.entity)
        else
          gui_menu = gui_child.entity
        end
        player.opened = gui_menu
      end)
    end
  end
end
