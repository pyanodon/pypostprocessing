local function make_essential(tech_name)
    local tech = data.raw.technology[tech_name]
    if not tech then return end
    tech.essential = true
end

make_essential("steam-power")

-- science packs
make_essential("automation-science-pack")
make_essential("py-science-pack-mk01")
make_essential("logistic-science-pack")
make_essential("military-science-pack")
make_essential("py-science-pack-mk02")
make_essential("chemical-science-pack")
make_essential("py-science-pack-mk03")
make_essential("production-science-pack")
make_essential("py-science-pack-mk04")
make_essential("utility-science-pack")
make_essential("space-science-pack")
make_essential("quantum")
make_essential("pyrrhic")

-- high tech progression
make_essential("electronics")
make_essential("basic-electronics")
make_essential("advanced-circuit")
make_essential("nano-tech")

-- alternative energy progression
make_essential("machine-components-mk01")
make_essential("machine-components-mk02")
make_essential("machine-components-mk03")
make_essential("machine-components-mk04")

make_essential("intermetallics-mk01")
make_essential("intermetallics-mk02")
make_essential("intermetallics-mk03")
make_essential("intermetallics-mk04")

-- alien life progression
make_essential("genetics-mk01")
make_essential("genetics-mk02")
make_essential("genetics-mk03")
make_essential("genetics-mk04")
make_essential("genetics-mk05")

-- coal processing progression
make_essential("coal-processing-1")
make_essential("coal-processing-2")
make_essential("coal-processing-3")

-- raw ores progression
make_essential("big-mines")

-- fusion energy progression
make_essential("fusion-mk01")
