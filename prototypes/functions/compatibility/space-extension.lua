-- https://mods.factorio.com/mod/SpaceModFeorasFork

-- Will fix: https://github.com/pyanodon/pybugreports/issues/1050
if mods["SpaceModFeorasFork"] and mods.pyhightech then
  TECHNOLOGY("space-ai-robots"):remove_prereq("battery-mk2-equipment")
end
