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

  function helper.get_entity_at(position)
    radius = radius or 0.5
    local area = {
      {position[1] - radius, position[2] - radius},
      {position[1] + radius, position[2] + radius}
    }
    local entities = game.surfaces.nauvis.find_entities_filtered{area = area}
    return entities[1]
  end
end

return helper
