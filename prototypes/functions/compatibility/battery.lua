-- Makes mods that use battery-mk2-equipment or battery-equipment compatible with py's tech tree

if mods.pyhightech then
  for _, technology in pairs(data.raw.technology) do
    for i, pre in pairs(technology.prerequisites) do
      if pre == "battery-mk2-equipment" then
        technology:remove_prereq("battery-mk2-equipment"):add_prereq("py-accumulator-mk01")
      elseif pre == "battery-equipment" then
        technology:remove_prereq("battery-equipment"):add_prereq("electric-energy-accumulators")
      end
    end
  end
end
