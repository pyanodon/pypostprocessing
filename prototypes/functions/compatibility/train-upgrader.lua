if mods["train-upgrader"] and mods.pyindustry then
  TECHNOLOGY("tu-rail-modernization"):add_prereq("railway-mk02"):remove_pack("chemical-science-pack")
end
