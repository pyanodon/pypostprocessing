local tr = {}
tr.__index = tr


function tr.create(graph)
    local t = {}
    setmetatable(t, tr)

    t.g = graph
    t.visited = {}
    t.closure = {}

    for k, _ in pairs(graph.nodes) do
        t.closure[k] = {}
    end

    return t
end

function tr:run()
    for _, node in pairs(self.g.nodes) do
        self:visit(node)
    end
end

function tr:visit(node)
    if not self.visited[node.key] then
        self.visited[node.key] = true

        local indirect = {}

        for _, e in self.g:iter_links_to(node) do
            local p = self.g:get_node(e:from())
            self:visit(p)
            table.merge(indirect, self.closure[p.key])
        end

        self.closure[node.key] = table.merge({}, indirect)

        for _, e in pairs(self.g:get_links_to(node)) do
            local p = self.g:get_node(e:from())
            self.closure[node.key][p.key] = true

            if indirect[p.key] then
                self.g:remove_link(p, node, e.label)
            end
        end
    end
end

return tr
