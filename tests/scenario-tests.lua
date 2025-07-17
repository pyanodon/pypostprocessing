local tests = {}

local helper = require("scenario-helper")

function tests.auog_turd_crash()
  select_turd = helper.select_turd("auog-upgrade", "glowing-mushrooms")
  local auog_power_gen = game.surfaces.nauvis.create_entity{name = "generator-1", position = {0, 0}, force = game.player.force}
end

return tests
