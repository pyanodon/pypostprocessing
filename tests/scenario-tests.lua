local tests = {}

local helper = require("scenario-helper")

function tests.auog_turd_crash()
  helper.select_turd("auog-upgrade", "glowing-mushrooms")
  local auog_power_gen = game.surfaces.nauvis.create_entity{name = "generator-1", position = {0, 0}, force = game.player.force, player = game.player, raise_built = true}
  helper.select_turd("auog-upgrade", "glowing-mushrooms")
  helper.get_entity_at({0, 0}).destroy()

  return "Auog Glowing Mushrooms Turd"
end

return tests
