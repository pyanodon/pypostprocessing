local helper = {}

if script.active_mods.pyalienlife then
  function helper.select_turd(master_tech_name, sub_tech_name)
    local fake_event = {
      skip_gui = true,
      player = game.player,
      master_tech_name = master_tech_name,
      sub_tech_name = sub_tech_name,
    }

    remote.call("pywiki_turd_page", "new_turd", fake_event)
  end

  function helper.get_recipes(machine)
    local category, _ = next(machine.crafting_categories, nil)
    local recipes = prototypes.get_recipe_filtered({ { filter = "category", category = category } })
    return recipes
  end

  local function first_item(t)
    for k, v in pairs(t) do
      return k, v
    end
  end

  function helper.get_first_recipe(machine)
    local recipes = helper.get_recipes(machine)
    local _, recipe = first_item(recipes)
    return recipe
  end

  function helper.build(name, position)
    local machine = game.surfaces.nauvis.create_entity({ name = name, position = position, force = game.player.force, player = game.player, raise_built = true })
    return machine
  end

  function helper.create_speed_beacons()
    local beacons = {}
    local position = { 22.5, -22.5 }

    for i = 1, 16 do
      local beacon = helper.build("ee-super-beacon", position)
      table.insert(beacons, beacon)
      beacon.get_module_inventory().insert({
        name = "ee-super-speed-module",
        count = 10
      })
      position[1] = position[1] - 3
    end

    return beacons
  end

  function helper.get_entity_prototype_of_type(name)
    return prototypes.get_entity_filtered({ { filter = "type", type = name } })
  end

  function helper.get_entity_at(position)
    radius = radius or 0.5
    local area = {
      { position[1] - radius,   position[2] - radius },
      { position[1] + radius,   position[2] + radius }
    }
    local entities = game.surfaces.nauvis.find_entities_filtered({ area = area })
    return entities[1]
  end
end

return helper
