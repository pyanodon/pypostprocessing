local table = require "__stdlib__.stdlib.utils.table"
local queue = require "__stdlib__.stdlib.misc.queue"
local config = require "prototypes.config"
local data_parser = require("prototypes.functions.data_parser")
local fz_graph = require("prototypes.functions.fuzzy_graph")
local py_utils = require("prototypes.functions.utils")
local fz_lazy_bfs = require("prototypes.functions.search.fz_lazy_bfs")
local fz_topo = require "prototypes.functions.fz_topo_sort"
local trans_reduct = require "prototypes.functions.transitive_reduction"

local BreadthFirstSearch = require("luagraphs.search.BreadthFirstSearch")

local auto_tech = {}
auto_tech.__index = auto_tech

local LABEL_UNLOCK_RECIPE = "__unlock_recipe__"

local function deadend_node(n, _, g) return not g:has_links_to(n) or not g:has_links_from(n) or false end
local function ifd_deadend_node(n, _, g) return n.ignore_for_dependencies and deadend_node(n, _, g) end


function auto_tech.create()
    local a = {}
    setmetatable(a, auto_tech)

    return a
end


function auto_tech:run()
    local parser = data_parser.create()
    local fg = parser:run()

    -- for _, node in pairs(fg.nodes) do
    --     if node.type == fz_graph.NT_RECIPE then
    --         local deps = {}

    --         for _, e in fg:iter_links_to(node) do
    --             deps[e:from()] = e
    --         end

    --         for _, e in pairs(fg:get_links_from(node)) do
    --             if deps[e:to()] and e.label == "__recipe_result__" then
    --                 if deps[e:to()].label == "__crafting__" then
    --                     fg:remove_link(fg:get_node(e:to()), node, deps[e:to()].label)
    --                     log("  - Removing link: " .. e:to() .. " >> " .. node.key .. " : " .. deps[e:to()].label)
    --                 else
    --                     fg:remove_link(node, fg:get_node(e:to()), e.label)
    --                     log("  - Removing link: " .. node.key .. " >> " .. e:to() .. " : " .. e.label)
    --                 end
    --             end
    --         end
    --     end
    -- end

    -- cleanup dead-end nodes
    fg:recursive_remove(ifd_deadend_node, false)
    local ts = fz_topo.create(fg)
    ts:run(true, false)
    fg:recursive_remove(ifd_deadend_node, false)


    local fg_tmp = fg:copy()
    local ts_tmp = fz_topo.create(fg_tmp)
    ts_tmp:run(false, false)

    local bfs = fz_lazy_bfs.create(fg_tmp, fg_tmp:get_node(config.WIN_GAME_TECH, fz_graph.NT_TECH_HEAD), false, true)
    local recipe_count = 0
    local opt_recipe_count = 0
    local recipes = {}

    for _, node in pairs(fg_tmp.nodes) do
        if node.type == fz_graph.NT_RECIPE and not node.virtual and data.raw.recipe[node.factorio_name] and not recipes[node.factorio_name] then
            recipes[node.factorio_name] = true

            if bfs:has_path_to(node) then
                recipe_count = recipe_count + 1
            else
                opt_recipe_count = opt_recipe_count + 1
            end
        end
    end

    log("Mandatory recipe count: " .. recipe_count)
    log("Optional recipe count: " .. opt_recipe_count)

    log("PROCESS TECHS START")

    for _, node in pairs(fg.nodes) do
        if node.type == fz_graph.NT_TECH_HEAD then
            self:process_tech(node, fg)
        end
    end

    log("PROCESS TECHS END")

    -- log(serpent.block(fg.graph.revList[fg:get_node("fracking / frack-natural-gas", fz_graph.NT_RECIPE).key]))

    -- self:process_tech(fg:get_node("tholin-mk01", fz_graph.NT_TECH_HEAD), fg)
    fg:recursive_remove(ifd_deadend_node, false)

    local fg2 = fg:copy()

    ts = fz_topo.create(fg)
    local error_found = ts:run(false, false)

    -- log(serpent.block(fg:get_node("fluid|silicon-mk01:hydrogen-chloride(10)")))

    if error_found then
        -- for k, node in pairs(fg.nodes) do
        --     if not node.ignore_for_dependencies and not ts.sorted[k] then
        --         log(" - " .. k)
        --     end
        -- end

        -- local loop = self:find_dependency_loop(fg, ts)
        local msg = "\n\nERROR: Dependency loop detected\n"
        -- local prev_node

        -- while not queue.is_empty(loop) do
        --     local key = loop()
        --     local node = fg:get_node(key)

        --     if node.type == fz_graph.NT_TECH_HEAD then
        --         msg = msg .. "  - Technology: " .. node.name .. "\n"
        --     elseif node.type == fz_graph.NT_RECIPE then
        --         msg = msg .. "  - Recipe: " .. node.name .. "\n"
        --     elseif node.type == fz_graph.NT_ITEM then
        --         msg = msg .. "  - Item: " .. node.name .. "\n"
        --     elseif node.type == fz_graph.NT_FLUID then
        --         msg = msg .. "  - Fluid: " .. node.name .. "\n"
        --     elseif node.type == fz_graph.NT_TECH_TAIL and prev_node then
        --         for _, e in fg:iter_links_to(node) do
        --             local recipe_node = fg:get_node(e:from())
        --             if recipe_node.products[prev_node.key] then
        --                 msg = msg .. "  - Recipe: " .. recipe_node.name .. "\n"
        --                 break
        --             end
        --         end
        --     end

        --     prev_node = node
        -- end

        error(msg)
    end

    self:add_original_prerequisites(fg, fg2, ts.level)

    ts = fz_topo.create(fg2)
    error_found = ts:run(false, false)
    local node_level = ts.level

    if error_found then
        -- for k, node in pairs(fg.nodes) do
        --     if not node.ignore_for_dependencies and not ts.sorted[k] then
        --         log(" - " .. k)
        --     end
        -- end
        local msg = "\n\nERROR: Dependency loop detected\n"
        error(msg)
    end

    local tg = self:extract_tech_graph(fg2)
    local tech_ts = fz_topo.create(tg)
    error_found = tech_ts:run(false, false)

    if error_found then
        local msg = "\n\nERROR: Dependency loop detected\n"
        error(msg)
    end

    local spg = self:extract_science_pack_graph(fg2, parser, node_level)
    local sp_ts = fz_topo.create(spg)
    sp_ts:run()

    local sp_level = {}
    local level_amount = {}
    local max_level = 0
    local sp_cost = {}

    -- Set science pack order
    for _, node in pairs(spg.nodes) do
        local sp = data.raw.tool[node.name]

        sp.subgroup = "science-pack"
        sp.order = string.format("%03d-%06d", sp_ts.level[node.key], ts.level[node.key])
        sp_level[node.name] = sp_ts.level[node.key]

        if sp_level[sp.name] > max_level then
            max_level = sp_level[sp.name]
        end

        sp_cost[sp_level[sp.name]] = {}
    end

    for _, lab in pairs(data.raw.lab) do
        table.sort(lab.inputs, function (i1, i2) return data.raw.tool[i1].order < data.raw.tool[i2].order end)
    end

    local mult_count = table.size(config.TC_SCIENCE_PACK_MULT)

    for i = 1, max_level do
        level_amount[i] = math.floor(config.TC_SCIENCE_PACK_MULT[(i-1) % mult_count + 1] * math.pow(config.TC_SCIENCE_PACK_MULT_STEP, math.floor((i-1) / mult_count)) + 0.5)

        for sp, c in pairs(config.TC_SCIENCE_PACK_COST) do
            if i == 1 then
                sp_cost[i][sp] = c
            else
                sp_cost[i][sp] = sp_cost[i-1][sp]

                for sp2, l in pairs(sp_level) do
                    if l == i-1 and config.TC_SCIENCE_PACK_COST_REDUCE[sp2] then
                        sp_cost[i][sp] = sp_cost[i][sp] / config.TC_SCIENCE_PACK_COST_REDUCE[sp2]
                    end
                end
            end
        end
    end

    local tech_sp_cost = {}
    local tech_bfs = fz_lazy_bfs.create(tg, tg:get_node(config.WIN_GAME_TECH, fz_graph.NT_TECH_HEAD), false, true)
    local level_sp_cost = {}

    -- Export tech changes to prototypes
    for _, node in pairs(tg.nodes) do
        local tech = data.raw.technology[node.name]

        if tech then
            node.mandatory = node.name == config.WIN_GAME_TECH or tech_bfs:has_path_to(node)
            local pre = {}

            for _, e in tg:iter_links_to(node) do
                if data.raw.technology[tg:get_node(e:from()).name] then
                    pre[tg:get_node(e:from()).name] = true
                end
            end

            local highest_sp
            local highest_level = 0

            for _, sp in pairs(py_utils.standardize_products(tech.unit.ingredients)) do
                if sp_level[sp.name] > highest_level then
                    highest_level = sp_level[sp.name]
                    highest_sp = sp.name
                end
            end

            tech_sp_cost[tech.name] = 0

            for i, sp in pairs(py_utils.standardize_products(tech.unit.ingredients)) do
                sp.amount = level_amount[highest_level - sp_level[sp.name] + 1]
                tech.unit.ingredients[i] = sp
                tech_sp_cost[tech.name] = tech_sp_cost[tech.name] + sp.amount * sp_cost[highest_level][sp.name]
            end

            -- TODO
            -- tech_sp_cost[tech.name] = 1

            if node.mandatory then
                if not level_sp_cost[tech_ts.level[node.key]] then
                    level_sp_cost[tech_ts.level[node.key]] = tech_sp_cost[tech.name]
                else
                    level_sp_cost[tech_ts.level[node.key]] = level_sp_cost[tech_ts.level[node.key]] + tech_sp_cost[tech.name]
                end
            end

            tech.unit.time = config.TC_SCIENCE_PACK_TIME[highest_sp]
            tech.prerequisites = table.keys(pre)
            tech.order = string.format("%06d", tech_ts.level[node.key])
        end
    end

    -- Calculate tech costs
    local target = config.TC_BASE_MULT * (recipe_count * config.TC_MANDATORY_RECIPE_COUNT_MULT + opt_recipe_count * config.TC_OPTIONAL_RECIPE_COUNT_MULT)
    -- log("Target: " .. target)

    local factor = self:calculate_factor(level_sp_cost, target)
    -- local factor = 1.2

    for _, node in pairs(tg.nodes) do
        local tech = data.raw.technology[node.name]

        if tech and not tech.unit.count_formula then
            tech.unit.count = self.cost_rounding(config.TC_STARTING_TECH_COST * math.max(1, math.pow(factor, tech_ts.level[node.key] - 1) / tech_sp_cost[tech.name]))
            -- log(tech.name .. " : 10 * " .. math.pow(factor, tech_ts.level[node.key] - 2) .. " / " .. tech_sp_cost[tech.name] .. " = "..  tech.unit.count)
        end
    end
end


function auto_tech.cost_rounding(num)
    local t = config.TC_COST_ROUNDING_TARGETS

    local exp = 1

    while num >= (t[#t] + t[1]*10) / 2 do
        num = num / 10
        exp = exp * 10
    end

    for i, n in pairs(t) do
        if i == #t or num < (n + t[i+1]) / 2 then
            return n * exp
        end
    end
end


function auto_tech:calculate_factor(level_sp_cost, target)
    local max_f = 2.0
    local min_f = 1.0
    local f

    while true do
        local m = config.TC_STARTING_TECH_COST
        local t = 0

        for _, c in pairs(level_sp_cost) do
            t = t + m * c
            m = m * max_f

            if t > target * (1 + config.TC_EXP_THRESHOLD) then break end
        end

        -- log("MAXF: " .. max_f .. " T: " .. t)

        if t < target * (1 - config.TC_EXP_THRESHOLD) then
            max_f = max_f * 2
        else
            break
        end
    end

    while min_f < max_f do
        f = (min_f + max_f) / 2
        local m = config.TC_STARTING_TECH_COST
        local t = 0

        for _, c in pairs(level_sp_cost) do
            t = t + m * c
            m = m * f

            if t > target * (1 + config.TC_EXP_THRESHOLD) then break end
        end

        -- log("F: " .. f .. " T: " .. t)

        if t < target * (1 - config.TC_EXP_THRESHOLD) then
            min_f = f
        elseif t > target * (1 + config.TC_EXP_THRESHOLD) then
            max_f = f
        else
            break
        end
    end

    return f
end


function auto_tech:extract_science_pack_graph(fg, parser, level)
    local sp_graph = fz_graph.create()

    for item_name, _ in pairs(parser.science_packs) do
        sp_graph:add_node(item_name, fz_graph.NT_ITEM)
    end

    sp_graph:remove_node(sp_graph.start_node)

    for _, node in pairs(sp_graph.nodes) do
        local fg_node = fg:get_node(node.key)
        local bfs = fz_lazy_bfs.create(fg, fg_node)

        for _, node2 in pairs(sp_graph.nodes) do
            if node.key ~= node2.key and bfs:has_path_to(node2) then
                sp_graph:add_link(node, node2, node.name)
            end
        end
    end

    local tr = trans_reduct.create(sp_graph)
    tr:run()

    for _, node in pairs(sp_graph.nodes) do
        if not sp_graph:has_links_to(node) then
            sp_graph.start_node = node
            break
        end
    end

    return sp_graph
end


function auto_tech:extract_tech_graph(fg)
    local tech_graph = fz_graph.create()

    for _, tech in pairs(data.raw.technology) do
        if fg:node_exists(tech.name, fz_graph.NT_TECH_HEAD) then
            tech_graph:add_node(tech.name, fz_graph.NT_TECH_HEAD)
        end
    end

    for k, node in pairs(tech_graph.nodes) do
        self:add_tech_prerequisites(fg, tech_graph, fg:get_node(node.name, fz_graph.NT_TECH_TAIL))

        if not tech_graph:has_links_to(node) and node.name ~= "__START__" then
            tech_graph:add_link(tech_graph.start_node, node, "__tech_prerequisite____START__")
        end
    end

    -- log(serpent.block(tech_graph.graph.adjList))

    local tr = trans_reduct.create(tech_graph)
    tr:run()

    return tech_graph
end


function auto_tech:add_tech_prerequisites(fg, tg, node)
    local q = queue()
    local marked = {}
    q(node)

    while not queue.is_empty(q) do
        local n = q()

        for _, e in fg:iter_links_to(n) do
            local p_node = fg:get_node(e:from())

            if not marked[p_node.key] then
                marked[p_node.key] = true
                local tg_node = tg:get_node(p_node.name, fz_graph.NT_TECH_HEAD)

                if tg_node and p_node.type == fz_graph.NT_TECH_TAIL then
                    tg:add_link(tg_node, tg:get_node(node.name, fz_graph.NT_TECH_HEAD), "__tech_prerequisite__" .. p_node.name)
                else
                    q(p_node)
                end
            end
        end
    end
end


function auto_tech:add_original_prerequisites(fg, tg, levels)
    local nodes = table.filter(table.values(fg.nodes), function (n) return n.type == fz_graph.NT_TECH_HEAD and data.raw.technology[n.name] ~= nil end)
    table.sort(nodes, function (n1, n2) return levels[fg:get_node(n1.name, fz_graph.NT_TECH_TAIL).key] < levels[fg:get_node(n2.name, fz_graph.NT_TECH_TAIL).key] end)

    for _, node in pairs(nodes) do
        -- log("Processing " .. node.key)
        local target_hnode = tg:get_node(node.key)
        local tech = data.raw.technology[node.name]
        local bfs = fz_lazy_bfs.create(fg, node, true)

        for _, pre in pairs(table.merge(tech.dependencies or {}, tech.prerequisites or {})) do
            if tg:node_exists(pre, fz_graph.NT_TECH_TAIL) then
                local found = false

                for _, e in tg:iter_links_to(target_hnode) do
                    if tg:get_node(e:from()).factorio_name == pre then
                        found = true
                    end
                end

                if not found then
                    if not bfs:has_path_to(fg:get_node(pre, fz_graph.NT_TECH_TAIL)) then
                        tg:add_link(tg:get_node(pre, fz_graph.NT_TECH_TAIL), target_hnode, "__tech_prerequisite__" .. pre)
                        fg:add_link(fg:get_node(pre, fz_graph.NT_TECH_TAIL), target_hnode, "__tech_prerequisite__" .. pre)
                        -- log("  - Adding link " .. tg:get_node(pre, fz_graph.NT_TECH_TAIL).key .. " >> " .. target_hnode.key)
                    -- else
                    --     log("  - Skipping link " .. tg:get_node(pre, fz_graph.NT_TECH_TAIL).key .. " >> " .. target_hnode.key)
                    end
                end
            end
        end
    end
end


function auto_tech:process_tech(tech_node, fg)
    local tail_node = fg:add_node(tech_node.name, fz_graph.NT_TECH_TAIL, { tech_name = tech_node.name, factorio_name = tech_node.name })
    local recipes = {}
    local tmp_nodes = {}

    for _, e in pairs(fg:get_links_from(tech_node)) do
        local node = fg.nodes[e:to()]

        if node.type == fz_graph.NT_RECIPE then
            fg:add_link(node, tail_node, node.key)
            recipes[node.key] = node
        end
    end

    fg:add_link(tech_node, tail_node, tech_node.key)
    local change = true
    local internal_nodes = {}
    local products = {}

    while change do
        change = false

        for _, node in pairs(recipes) do
            if not node.temp then
                for label, _ in pairs(node.labels) do
                    if not recipes[fz_graph.node.get_key(node.name .. "/" .. label, node.type)] and fg:has_label_to(node, label) then
                        local tmp_node = fg:add_node(node.name .. "/" .. label, node.type, node)
                        tmp_node.temp = true
                        recipes[tmp_node.key] = tmp_node
                        table.insert(tmp_nodes, tmp_node)
                        fg:add_link(tech_node, tmp_node, LABEL_UNLOCK_RECIPE)

                        for _, e2 in fg:iter_links_to(node, label) do
                            fg:add_link(fg:get_node(e2:from()), tmp_node, label)
                        end
                    end
                end
            end
        end

        for _, node in pairs(recipes) do
            for _, e in pairs(fg:get_links_from(node)) do
                if e:to() ~= tail_node.key then
                    local p = fg.nodes[e:to()]
                    py_utils.insert_double_lookup(products, p.key, e.label)
                    node.products[p.key] = true
                end
            end
        end

        -- local internal_nodes = self:find_internal_nodes(fg, tech_node.name, recipes)

        for k, _ in pairs(products) do
            -- if tech_node.name == "__START__" then log("  - Processing product: " .. k) end
            local bfs = BreadthFirstSearch.create()

            bfs:run(fg.graph, k, function (v, from)
                local tech_name = fg.nodes[v].tech_name
                local result = tech_name and tech_name ~= tech_node.tech_name

                if result then return true end

                -- Stop the barrel/unbarrel and similar loops
                if fg.nodes[from].tech_name == nil and fg.nodes[from].type == fz_graph.NT_RECIPE then
                    local p = bfs.pathTo[from]

                    while p and fg.nodes[p].tech_name == nil do
                        local p_node = fg.nodes[p]

                        if p_node.type == fz_graph.NT_RECIPE then
                            for _, e in pairs(fg:get_links_to(p_node)) do
                                if e:from() == v then
                                    return true
                                end
                            end
                        end

                        p = bfs.pathTo[p]
                    end
                end

                return result
            end)

            for r, _ in pairs(recipes) do
                if bfs:hasPathTo(r) then
                    -- if tech_node.name == "__START__" then log("    - Path to recipe: " .. r) end
                    local n = bfs.pathTo[r]

                    while n and fg.nodes[n].tech_name == nil do
                        -- if tech_node.name == "__START__" then log("      - " .. n) end
                        local new_name = tech_node.name .. ":" .. fg.nodes[n].name
                        local new_key = fz_graph.node.get_key(new_name, fg.nodes[n].type)

                        if not internal_nodes[new_key] then
                            internal_nodes[new_key] = fg:clone_node(fg.nodes[n], new_name)
                            internal_nodes[new_key]:update{ignore_for_dependencies = true, tech_name = tech_node.name, internal = true, original_key = n}

                            if internal_nodes[new_key].type == fz_graph.NT_RECIPE then
                                recipes[new_key] = internal_nodes[new_key]
                                change = true
                            end
                            -- if tech_node.name == "__START__" then log("        - Add internal node: " .. new_key) end
                        end

                        n = bfs.pathTo[n]
                    end
                end
            end
        end
    end

    for _, node in pairs(internal_nodes) do
        for _, e in pairs(fg:get_links_from(node)) do
            local to_node = fg:get_node(e:to())

            if to_node.tech_name ~= tech_node.name then
                fg:remove_link(node, to_node, e.label)
            end
        end

        for label, _ in pairs(node.labels or {}) do
            local found_local = false

            for _, e in pairs(fg:get_links_to(node, label)) do
                if fg:get_node(e:from()).tech_name == tech_node.name then
                    found_local = true
                    break
                end
            end

            if found_local then
                for _, e in pairs(fg:get_links_to(node, label)) do
                    local from_node = fg:get_node(e:from())

                    if from_node.tech_name ~= tech_node.name then
                        fg:remove_link(from_node, node, label)
                    end
                end
            end
        end
    end

    -- log(serpent.block(internal_nodes))

    local node_list = table.filter(fg.nodes, function (n) return n.tech_name == tech_node.name end)
    local tgraph = fg:create_subgraph(node_list)
    tgraph.start_node = tgraph:get_node(tech_node.name, fz_graph.NT_TECH_HEAD)

    local ts = fz_topo.create(tgraph)
    local error_found = ts:run(false, false)

    for _, e in pairs(ts.removed_links) do
        -- log("Remove link: " .. e:from() .. " > " .. e:to() .. " / " .. e.label)
        fg:remove_link(fg:get_node(e:from()), fg:get_node(e:to()), e.label)
    end

    if error_found then
        -- log("Local loop: " .. tech_node.name)
        -- for k, node in pairs(tgraph.nodes) do
        --     if not node.ignore_for_dependencies and not ts.sorted[k] then
        --         log(" - " .. k)
        --     end
        -- end
    else
        for _, node in pairs(internal_nodes) do
            for _, e in fg:iter_links_from(node) do
                local cons_node = fg:get_node(e:to())

                if not cons_node.internal then
                    fg:remove_link(fg:get_node(node.original_key), cons_node, e.label)
                end
            end
        end
    end

    for k, product_labels in pairs(products) do
        local product_node = fg:get_node(k)

        if not product_node.internal then
            for _, e in pairs(fg:get_links_to(product_node)) do
                local from_node = fg:get_node(e:from())

                if from_node.tech_name == tech_node.name then
                    fg:remove_link(from_node, product_node, e.label)
                end
            end

            for label, _ in pairs(product_labels) do
                fg:add_link(tail_node, product_node, label)
            end
        end
    end

    for _, node in pairs(tmp_nodes) do
        fg:remove_node(node)
    end
end


function auto_tech:find_internal_nodes(fg, tech_name, recipes)
    -- log("find_internal_nodes - START")
    local internal_nodes = {}
    local q = queue()
    local marked = {}

    for r, _ in pairs(recipes) do
        local n = { path = {}, deps = {} }
        n.last = r
        n.deps[r] = true

        q(n)
    end

    while not queue.is_empty(q) do
        local n = q()

        for _, e in fg:iter_links_from(fg.nodes[n.last]) do
            local node = fg.nodes[e:to()]

            if not marked[node.key] and not n.deps[node.key] and not node.tech_name then
                marked[node.key] = true
                local nn = { path = table.merge({}, n.path), deps = table.merge({}, n.deps) }
                nn.path[node.key] = nn.last
                nn.last = node.key
                nn.deps[node.key] = true

                for _, ee in fg:iter_links_to(node) do
                    nn.deps[ee:from()] = true
                end

                q(nn)
            elseif (node.tech_name == tech_name and node.type == fz_graph.NT_RECIPE)
                or (marked[node.key] and not n.deps[node.key] and not node.tech_name)
            then
                local p = n.last

                while p and not internal_nodes[p] and not fg.nodes[p].tech_name do
                    internal_nodes[p] = true
                    p = n.path[p]
                end
            end
        end
    end
    -- log("find_internal_nodes - END")
    return internal_nodes
end


function auto_tech:find_dependency_loop(fg, ts)
    local node_list = table.filter(fg.nodes, function (n, k) return not ts.sorted[k] end)
    local g = fg:create_subgraph(node_list)
    g:recursive_remove(deadend_node, false)
    -- self:remove_redundant_deps(g)
    -- log(serpent.block(g:get_links_to(g:get_node("silicon-mk01 / trichlorosilane", fz_graph.NT_RECIPE), "hydrogen-chloride")))
    -- g:recursive_remove(deadend_node, false)
    -- log(serpent.block(g:get_links_to(g:get_node("silicon-mk01 / trichlorosilane", fz_graph.NT_RECIPE), "hydrogen-chloride")))

    local path

    for _, node in pairs(g.nodes) do
        if node.type == fz_graph.NT_RECIPE and not node.internal then
            local bfs = fz_lazy_bfs.create(g, node, true)
            bfs.marked[node.key] = nil

            if bfs:has_path_to(node, false, path and queue.size(path) or nil) then
                path = bfs:get_path_to(node, false)
            end
        end
    end

    return path
end


function auto_tech:remove_redundant_deps(fg)
    local fuzzy_nodes = {}

    for key, node in pairs(fg.nodes) do
        for _, e in fg:iter_links_from(node) do
            if e.label and e.label ~= "" then
                local to_node = fg:get_node(e:to())
                local count = 0

                for k, _ in fg:iter_links_to(to_node, e.label) do
                    count = count + 1
                    if count > 1 then break end
                end

                if count > 1 then
                    fuzzy_nodes[key] = node
                    break
                end
            end
        end
    end

    local change = true

    while change do
        change = false

        for key, node in pairs(fuzzy_nodes) do
            local bfs = fz_lazy_bfs.create(fg, node, true, false)
            local bfs_rev = fz_lazy_bfs.create(fg, node, true, true)
            local clear = true
            local links_to_remove = {}

            for _, e in fg:iter_links_from(node) do
                if e.label and e.label ~= "" then
                    local to_node = fg:get_node(e:to())

                    for _, e2 in fg:iter_links_to(to_node, e.label) do
                        local from_node = fg:get_node(e2:from())

                        if ((from_node.internal or false) == (node.internal or false)) and e2:from() ~= key and not bfs_rev:has_path_to(from_node) then
                            if bfs:has_path_to(from_node)then
                                table.insert(links_to_remove, e2)
                                change = true
                            else
                                clear = false
                            end
                        end
                    end
                end
            end

            for _, e in pairs(links_to_remove) do
                -- log("  - Removing link: " .. e:from() .. " >> " .. e:to() .. " : " .. e.label)
                fg:remove_link(fg:get_node(e:from()), fg:get_node(e:to()), e.label)
            end

            if clear then
                -- log("- Cleared node: " .. key)
                fuzzy_nodes[key] = nil
            end
        end
    end
end


return auto_tech
