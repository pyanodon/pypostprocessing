if mods["Rocket-Silo-Construction"] then
    RECIPE("rsc-construction-stage1"):add_unlock("rocket-silo").enabled = false
    RECIPE("rsc-construction-stage2"):add_unlock("rocket-silo").enabled = false
    RECIPE("rsc-construction-stage3"):add_unlock("rocket-silo").enabled = false
    RECIPE("rsc-construction-stage4"):add_unlock("rocket-silo").enabled = false
    RECIPE("rsc-construction-stage5"):add_unlock("rocket-silo").enabled = false
    RECIPE("rsc-construction-stage6"):add_unlock("rocket-silo").enabled = false

    if mods["pyindustry"] and mods["pycoalprocessing"] then
        RECIPE("rsc-excavation-site"):replace_ingredient("pipe", "niobium-pipe")
        RECIPE("rsc-construction-stage4"):replace_ingredient("pipe", "niobium-pipe"):replace_ingredient("pipe-to-ground", "niobium-pipe-to-ground")
        RECIPE("rsc-construction-stage6"):replace_ingredient("radar", "megadar")
    end

    if mods["pyrawores"] then
        RECIPE("rsc-construction-stage2"):replace_ingredient("steel-plate", "stainless-steel")
        RECIPE("rsc-construction-stage4"):replace_ingredient("steel-plate", "stainless-steel")
        RECIPE("rsc-construction-stage5"):replace_ingredient("steel-plate", "stainless-steel"):replace_ingredient("copper-plate", "nexelit-plate")
    end

    if mods["pypetroleumhandling"] then
        RECIPE("rsc-excavation-site"):replace_ingredient("processing-unit", "advanced-circuit")
        RECIPE("rsc-construction-stage2"):add_ingredient {type = "item", name = "small-parts-02", amount = 20}
        RECIPE("rsc-construction-stage4"):add_ingredient {type = "item", name = "small-parts-02", amount = 10}
        RECIPE("rsc-construction-stage5"):add_ingredient {type = "item", name = "small-parts-02", amount = 10}
        RECIPE("rsc-construction-stage6"):remove_ingredient("processing-unit"):add_ingredient {type = "item", name = "small-parts-02", amount = 10}
    end

    if mods["pyalternativeenergy"] then
        RECIPE("rsc-construction-stage2"):add_ingredient {type = "item", name = "self-assembly-monolayer", amount = 5}
        RECIPE("rsc-construction-stage4"):add_ingredient {type = "item", name = "self-assembly-monolayer", amount = 5}
        RECIPE("rsc-construction-stage5"):add_ingredient {type = "item", name = "self-assembly-monolayer", amount = 5}
    end
end
