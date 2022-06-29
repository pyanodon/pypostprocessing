local table = require "__stdlib__.stdlib.utils.table"
local queue = require "__stdlib__.stdlib.misc.queue"
local data_parser = require("prototypes.functions.data_parser")
local fz_graph = require("prototypes.functions.fuzzy_graph")
local py_utils = require("prototypes.functions.utils")
local fz_lazy_bfs = require("prototypes.functions.search.fz_lazy_bfs")
local fz_topo = require "prototypes.functions.fz_topo_sort"

local BreadthFirstSearch = require("luagraphs.search.BreadthFirstSearch")

local auto_tech = {}
auto_tech.__index = auto_tech


local function deadend_node(n, k, g) return not g:has_links_to(n) or not g:has_links_from(n) or false end
local function ifd_deadend_node(n, k, g) return n.ignore_for_dependencies and deadend_node(n, k, g) end


function auto_tech.create()
    local a = {}
    setmetatable(a, auto_tech)

    return a
end


function auto_tech:run()
    local parser = data_parser.create()
    local fg = parser:run()

    -- cleanup dead-end nodes
    fg:recursive_remove(ifd_deadend_node, false)

    local ts = fz_topo.create(fg)
    local error = ts:run(true)

    if error then
        log("ERROR: Dependency loop detected")
        for k, node in pairs(fg.nodes) do
            if not node.ignore_for_dependencies and not ts.sorted[k] then
                log(" - " .. k)
            end
        end
    end

    fg:recursive_remove(ifd_deadend_node, false)

    log("PROCESS TECHS START")
    for _, node in pairs(fg.nodes) do
        if node.type == fz_graph.NT_TECH_HEAD then
            self:process_tech(node, fg)
        end
    end

    -- self:process_tech(fg:get_node("__START__", fz_graph.NT_TECH_HEAD), fg)

    fg:recursive_remove(ifd_deadend_node, false)

    ts = fz_topo.create(fg)
    error = ts:run(false)

    if error then
        log("ERROR: Dependency loop detected")
        for k, node in pairs(fg.nodes) do
            if not node.ignore_for_dependencies and not ts.sorted[k] then
                log(" - " .. k)
            end
        end
    end

    -- log("ClEANUP START")
    -- self:remove_redundant_deps(fg)
    -- log("ClEANUP END")

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
            if e:to() ~= tail_node.key then
                local p = fg.nodes[e:to()]
                py_utils.insert_double_lookup(products, p.key, node.key)
                products[p.key][e.label] = true
            end
        end
    end

    local internal_nodes = {}
    -- local internal_nodes = self:find_internal_nodes(fg, tech_node.name, recipes)

    for k, product_labels in pairs(products) do
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
                local n = bfs.pathTo[r]

                while n and fg.nodes[n].tech_name == nil do
                    local new_name = tech_node.name .. ":" .. fg.nodes[n].name
                    local new_key = fz_graph.node.get_key(new_name, fg.nodes[n].type)

                    if not internal_nodes[new_key] then
                        internal_nodes[new_key] = fg:clone_node(fg.nodes[n], new_name)
                        internal_nodes[new_key]:update{ignore_for_dependencies = true, tech_name = tech_node.name, internal = true, original_key = n}
                    end

                    n = bfs.pathTo[n]
                end
            end
        end

        for label, _ in pairs(product_labels) do
            fg:add_link(fg:get_node(k), tail_node, label)
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

    local node_list = table.filter(fg.nodes, function (n) return n.tech_name == tech_node.name end)
    local tgraph = fg:create_subgraph(node_list)
    tgraph.start_node = tgraph:get_node(tech_node.name, fz_graph.NT_TECH_HEAD)

    local ts = fz_topo.create(tgraph)
    local error = ts:run(false, false)

    -- if error then
    --     log("Local loop: " .. tech_node.name)
    --     for k, node in pairs(tgraph.nodes) do
    --         if not node.ignore_for_dependencies and not ts.sorted[k] then
    --             log(" - " .. k)
    --         end
    --     end
    -- end
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

        for _, e in pairs(fg:get_links_from(fg.nodes[n.last])) do
            local node = fg.nodes[e:to()]

            if not marked[node.key] and not n.deps[node.key] and not node.tech_name then
                marked[node.key] = true
                local nn = { path = table.merge({}, n.path), deps = table.merge({}, n.deps) }
                nn.path[node.key] = nn.last
                nn.last = node.key
                nn.deps[node.key] = true

                for _, ee in pairs(fg:get_links_to(node)) do
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
end


return auto_tech
