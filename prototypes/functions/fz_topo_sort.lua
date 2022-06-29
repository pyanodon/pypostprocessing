local table = require "__stdlib__.stdlib.utils.table"
local queue = require "__stdlib__.stdlib.misc.queue"
local fz_lazy_bfs = require "prototypes.functions.search.fz_lazy_bfs"

local fz_topo = {}
fz_topo.__index = fz_topo


function fz_topo.create(g)
    local s = {}
    setmetatable(s, fz_topo)

    s.graph = g
    s.work_graph = g:copy()
    s.sorted = {}
    s.queue = queue()
    s.fuzzy_nodes = {}

    return s
end


function fz_topo:run(check_ancestry, logging)
    self.queue(self.work_graph.start_node)

    while not queue.is_empty(self.queue) do
        local node = self.queue()

        self.sorted[node.key] = true
        local adj_labels = {}
        local adj = {}
        local bfs

        if logging then log("- Processing node: " .. node.key) end

        for _, e in self.work_graph:iter_links_from(node) do
            if e.label and e.label ~= "" then
                if not adj_labels[e:to()] then
                    adj_labels[e:to()] = {}
                end

                adj_labels[e:to()][e.label] = true
            else
                adj[e:to()] = true
            end
        end

        local links_to_remove = {}

        for to_key, labels in pairs(adj_labels) do
            local to_node = self.work_graph:get_node(to_key)

            for label, _ in pairs(labels) do
                for _, e in pairs(self.work_graph:get_links_to(to_node, label)) do
                    table.insert(links_to_remove, e)
                end
            end

            adj[to_key] = true
        end

        if check_ancestry and not table.is_empty(links_to_remove) then
            bfs = fz_lazy_bfs.create(self.work_graph, node, true)

            for _, e in pairs(links_to_remove) do
                if e:from() ~= node.key and bfs:has_path_to(self.work_graph:get_node(e:from())) then
                    if logging then log("  - Removing link: " .. e:from() .. " >> " .. e:to() .. " : " .. e.label) end
                    self.graph:remove_link(self.graph:get_node(e:from()), self.graph:get_node(e:to()), e.label)
                end
            end
        end

        for _, e in pairs(links_to_remove) do
            self.work_graph:remove_link(self.work_graph:get_node(e:from()), self.work_graph:get_node(e:to()), e.label)
        end

        self.work_graph:remove_node(node)

        for to_key, _ in pairs(adj) do
            local to_node = self.work_graph:get_node(to_key)

            if not self.work_graph:has_links_to(to_node) then
                self.queue(to_node)
                if logging then log("  - Queued: " .. to_key) end
            elseif logging then
                log("  - Not queued: " .. to_key)
                for _, e in self.work_graph:iter_links_to(to_node) do
                    log("    - " .. e:from() .. " : " .. e.label)
                end
            end
        end
    end

    return table.any(self.graph.nodes, function (n) return not n.ignore_for_dependencies and not self.sorted[n.key] end)
end


return fz_topo