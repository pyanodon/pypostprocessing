-- Changes mods that use radar tech to use py radar tech

if mods.pyhightech then
  for _, technology in pairs(data.raw.technology) do
    for i, pre in pairs(technology.prerequisites) do
      if pre == "radar" then
        technology:remove_prereq("radar"):add_prereq("radars-mk01")
      end
    end
  end
end

