if not mods.PlutoniumEnergy or not data.raw.technology["uranium-processing"].hidden then return end

local prereqs = data.raw.technology["plutonium-processing"].prerequisites
data.raw.technology["plutonium-processing"].prerequisites = {}
for _, prereq in pairs(prereqs) do
  if prereq ~= "uranium-processing" then
    data.raw.technology["plutonium-processing"].prerequisites[#data.raw.technology["plutonium-processing"].prerequisites+1] = prereq
  end
end
