local tests = {}

local helper = require("scenario-helper")

local turd_upgrade_names_table = {
  "prototypes/upgrades/biofactory",
  "prototypes/upgrades/compost",
  "prototypes/upgrades/creature",
  "prototypes/upgrades/incubator",
  "prototypes/upgrades/slaughterhouse",
  "prototypes/upgrades/arthurian",
  "prototypes/upgrades/dhilmos",
  "prototypes/upgrades/dingrits",
  "prototypes/upgrades/korlex",
  "prototypes/upgrades/fawogae",
  "prototypes/upgrades/moss",
  "prototypes/upgrades/scrondrix",
  "prototypes/upgrades/vonix",
  "prototypes/upgrades/yaedols",
  "prototypes/upgrades/fwf",
  "prototypes/upgrades/cadaveric",
  "prototypes/upgrades/moondrop",
  "prototypes/upgrades/auog",
  "prototypes/upgrades/arqad",
  "prototypes/upgrades/phadai",
  "prototypes/upgrades/phagnot",
  "prototypes/upgrades/sponge",
  "prototypes/upgrades/tuuphra",
  "prototypes/upgrades/ulric",
  "prototypes/upgrades/vrauks",
  "prototypes/upgrades/xyhiphoe",
  "prototypes/upgrades/seaweed",
  "prototypes/upgrades/atomizer",
  "prototypes/upgrades/bioreactor",
  "prototypes/upgrades/zungror",
  "prototypes/upgrades/numal",
  "prototypes/upgrades/data-array",
  "prototypes/upgrades/xeno",
  "prototypes/upgrades/fish",
  "prototypes/upgrades/cottongut",
  "prototypes/upgrades/guar",
  "prototypes/upgrades/kicalk",
  "prototypes/upgrades/rennea",
  "prototypes/upgrades/navens",
  "prototypes/upgrades/antelope",
  "prototypes/upgrades/bhoddos",
  "prototypes/upgrades/genlab",
  "prototypes/upgrades/grod",
  "prototypes/upgrades/research",
  "prototypes/upgrades/yotoi",
  "prototypes/upgrades/cridren",
  "prototypes/upgrades/kmauts",
  "prototypes/upgrades/trits",
  "prototypes/upgrades/ralesia",
  "prototypes/upgrades/mukmoux",
  "prototypes/upgrades/simikmetalMK01",
  "prototypes/upgrades/simikmetalMK02",
  "prototypes/upgrades/simikmetalMK03",
  "prototypes/upgrades/simikmetalMK04",
  "prototypes/upgrades/simikmetalMK05",
  "prototypes/upgrades/simikmetalMK06",
  "prototypes/upgrades/sap",
  "prototypes/upgrades/bioprinting",
  "prototypes/upgrades/zipir",
  "prototypes/upgrades/wpu",
}
local turds = {}
for i, t in pairs(turd_upgrade_names_table) do
  turds[i] = require("__pyalienlife__/" .. t)
end


function tests.auog_turd_crash()
  helper.select_turd("auog-upgrade", "glowing-mushrooms")
  local auog_power_gen = game.surfaces.nauvis.create_entity({ name = "generator-1", position = { 0, 0 }, force = game.player.force, player = game.player, raise_built = true })
  helper.select_turd("auog-upgrade", "glowing-mushrooms")
  helper.get_entity_at({ 0, 0 }).destroy()

  return "Auog Glowing Mushrooms Turd"
end

function tests.test_all_turds()
  for _, turd in pairs(turds) do
    for _, subtech in pairs(turd.sub_techs) do
      helper.select_turd(turd.master_tech.name, subtech.name)
      helper.select_turd(turd.master_tech.name, subtech.name)
    end
  end
  return "Test all turds"
end

return tests
