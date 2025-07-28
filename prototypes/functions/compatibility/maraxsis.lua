-- Thank you melon!!!
if mods.maraxsis then
    for _, technology in pairs(data.raw.technology) do
        for _, prereq in pairs(technology.prerequisites or {}) do
            if prereq == "quality-module" then
                technology:remove_prereq("quality-module")
            end
        end
    end
end
