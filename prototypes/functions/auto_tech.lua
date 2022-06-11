local table = require "__stdlib__.stdlib.utils.table"
local data_parser = require("prototypes.functions.data_parser")
local fz_graph = require("prototypes.functions.fuzzy_graph")
local py_utils = require("prototypes.functions.utils")
local BreadthFirstSearch = require("luagraphs.search.BreadthFirstSearch")

local auto_tech = {}
auto_tech.__index = auto_tech


function auto_tech.create()
    local a = {}
    setmetatable(a, auto_tech)

    return a
end


function auto_tech:run()
    local parser = data_parser.create()
    local fg = parser:run()

    -- cleanup dead-end nodes
    fg:recursive_remove(function (n) return n.ignore_for_dependencies and not fg:has_links_to(n) or false end, true)
    fg:recursive_remove(function (n) return n.ignore_for_dependencies and not fg:has_links_from(n) or false end, false)

    -- for _, node in pairs(fg.nodes) do
    --     if node.type == fz_graph.NT_TECH_HEAD then
    --         self:process_tech(node, fg)
    --     end
    -- end

    self:process_tech(fg:get_node("arqad", fz_graph.NT_TECH_HEAD), fg)
end


function auto_tech:process_tech(tech_node, fg)
    local tail_node = fg:add_node(tech_node.name, fz_graph.NT_TECH_TAIL, { tech_name = tech_node.name, factorio_name = tech_node.name })
    local recipes = {}

    for _, e in pairs(fg:get_links_from(tech_node)) do
        local node = fg.nodes[e:to()]
        fg:add_link(node, tail_node)
        recipes[node.key] = node
    end

    fg:add_link(tech_node, tail_node)
    local products = {}

    for _, node in pairs(recipes) do
        for _, e in pairs(fg:get_links_from(node)) do
            local p = fg.nodes[e:to()]
            py_utils.insert_double_lookup(products, p.key, node.key)
            products[p.key][node.key] = { label = e.label }
        end
    end

    local internal_nodes = {}

    for k, product_recipes in pairs(products) do
        local bfs = BreadthFirstSearch.create()

        bfs:run(fg.graph, k, function (v, from)
            local tech_name = fg.nodes[v].tech_name
            local result = tech_name ~= nil and tech_name ~= tech_node.tech_name

            if result then return true end

            if not result then
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
            end

            return result
        end)

        for r, _ in pairs(recipes) do
            if bfs:hasPathTo(r) then
                local n = bfs.pathTo[r]

                while n and fg.nodes[n].tech_name == nil do
                    if not internal_nodes[n] then
                        internal_nodes[n] = fg:clone_node(fg.nodes[n], tech_node.name .. ":" .. fg.nodes[n].name)
                        internal_nodes[n]:update{ignore_for_dependencies = true, tech_name = tech_node.name, internal = true, original_key = n}
                    end

                    n = bfs.pathTo[n]
                end
            end
        end
    end

    for _, node in pairs(internal_nodes) do
        for _, e in pairs(fg:get_links_from(node)) do
            local to_node = fg:get_node(e:to())

            if to_node.tech_name ~= tech_node.name then
                fg:remove_link(node, to_node)
            end
        end

        for label, _ in pairs(node.labels or {}) do
            local links = fg:get_links_to(node, label)
            local has_local_source = table.any(links, function (e)
                return fg:get_node(e:from()).tech_name == tech_node.name
            end)

            if has_local_source then
                for _, e in pairs(links) do
                    local from_node = fg:get_node(e:from())

                    if from_node.tech_name ~= tech_node.name then
                        fg:remove_link(from_node, node)
                    end
                end
            end
        end
    end

    -- log(serpent.block(internal_nodes))
    log(serpent.block(table.filter(fg.graph.adjList, function (v, k) return fg:get_node(k).internal and internal_nodes[fg:get_node(k).original_key] ~= nil end)))
    log(serpent.block(table.filter(fg.graph.revList, function (v, k) return fg:get_node(k).internal and internal_nodes[fg:get_node(k).original_key] ~= nil end)))
    -- log(serpent.block(table.filter(fg.graph.revList, function (v, k) return internal_nodes[k] ~= nil end)))
end


return auto_tech
