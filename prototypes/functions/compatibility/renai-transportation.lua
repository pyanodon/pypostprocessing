if mods[ "RenaiTransportation" ] then
    if mods[ "pyindustry" ] then
        TECHNOLOGY("RTFlyingFreight"):remove_prereq("concrete")
        TECHNOLOGY("RTImpactTech"):remove_prereq("concrete")
    end

    if mods[ "pycoalprocessing" ] then
        TECHNOLOGY("RTDeliverThePayload"):remove_prereq("military-3"):remove_pack("chemical-science-pack")

        RECIPE("PrimerBouncePlateRecipe"):replace_ingredient("coal", "coke")
    end

    if mods[ "pyfusionenergy" ] and settings.startup[ "RTZiplineSetting" ].value == true then
        TECHNOLOGY("RTZiplineTech5"):remove_prereq("uranium-processing")
    end

    if mods[ "pyrawores" ] and settings.startup[ "RTZiplineSetting" ].value == true then
        TECHNOLOGY("RTZiplineTech5"):remove_prereq("kovarex-enrichment-process")
    end

    if mods[ "pypetroleumhandling" ] and settings.startup[ "RTZiplineSetting" ].value == true then
        RECIPE("RTZiplineTrolley3"):remove_ingredient("small-parts-01"):add_ingredient({ type = "item", name = "small-parts-02", amount = 50 })
        RECIPE("RTZiplineRecipe4"):remove_ingredient("small-parts-01"):add_ingredient({ type = "item", name = "small-parts-03", amount = 50 })
    end

    if mods[ "pyhightech" ] then
        TECHNOLOGY("RTImpactTech"):remove_prereq("advanced-circuit")
        TECHNOLOGY("RTSimonSays"):remove_prereq("advanced-circuit"):add_prereq("circuit-network")
        RECIPE("RTImpactUnloaderRecipe"):replace_ingredient("advanced-circuit", "electronic-circuit")
        RECIPE("RTMagnetTrainRampRecipe"):replace_ingredient("advanced-circuit", "electronic-circuit")
        RECIPE("RTImpactWagonRecipe"):replace_ingredient("advanced-circuit", "electronic-circuit")
        RECIPE("DirectorBouncePlateRecipie"):replace_ingredient("advanced-circuit", "decider-combinator")
    end

    if mods[ "pyhightech" ] and settings.startup[ "RTZiplineSetting" ].value == true then
        TECHNOLOGY("RTZiplineTech"):add_prereq("electronics"):remove_prereq("steel-processing")
        TECHNOLOGY("RTZiplineTech2"):remove_prereq("logistic-science-pack")
        TECHNOLOGY("RTZiplineTech3"):add_prereq("basic-electronics")
    end

    if mods[ "pyalienlife" ] then
        TECHNOLOGY("EjectorHatchRTTech"):add_prereq("py-science-pack-mk01")
        TECHNOLOGY("RTDeliverThePayload"):add_prereq("military-science-pack")
        TECHNOLOGY("EjectorHatchRTTech"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTFlyingFreight"):remove_pack("logistic-science-pack")
        --TECHNOLOGY("SignalPlateTech"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTFreightPlates"):remove_pack("logistic-science-pack")
        TECHNOLOGY("PrimerPlateTech"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTImpactTech"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTSimonSays"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTProgrammableZiplineControlTech"):remove_pack("logistic-science-pack")
        TECHNOLOGY("RTDeliverThePayload"):remove_pack("py-science-pack-2")

        if settings.startup[ "RTZiplineSetting" ].value == true then
            TECHNOLOGY("RTZiplineTech3"):remove_pack("chemical-science-pack")
            TECHNOLOGY("RTZiplineTech4"):add_pack("py-science-pack-3"):remove_prereq("")
        end
    end

    if mods[ "pyalternativeenergy" ] then
        TECHNOLOGY("RTMagnetTrainRamps"):remove_pack("chemical-science-pack"):remove_pack("py-science-pack-2")
        RECIPE("RTMagnetTrainRampRecipe"):add_ingredient({ type = "item", name = "nexelit-plate", amount = 10 }):replace_ingredient("substation", "big-electric-pole")
        RECIPE("RTTrainRampRecipe"):add_ingredient({ type = "item", name = "intermetallics", amount = 10 })

        if settings.startup[ "RTZiplineSetting" ].value == true then
            RECIPE("RTZiplineTrolley5"):add_ingredient({ type = "item", name = "fission-reactor-equipment", amount = 1 }):add_ingredient({ type = "item", name = "RTZiplineItem4", amount = 1 }):add_ingredient({ type = "item", name = "nuclear-fuel", amount = 5 })
            data.raw.recipe[ "RTZiplineTrolley5" ].ingredients = table.deepcopy(data.raw.recipe[ "exoskeleton-equipment" ].ingredients)
            RECIPE("RTZiplineTrolley3"):add_ingredient({ type = "item", name = "mechanical-parts-02", amount = 10 })
            RECIPE("RTZiplineTrolley4"):add_ingredient({ type = "item", name = "mechanical-parts-03", amount = 10 })
            TECHNOLOGY("RTZiplineTech4"):add_prereq("machine-components-mk03")
        end
    end
end
