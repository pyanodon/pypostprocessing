local graph = require("luagraphs.data.graph")

local fz_graph = {}
fz_graph.__index = fz_graph

fz_graph.node = {}
fz_graph.node.__index = fz_graph.node


fz_graph.START_NODE_NAME = "__START__"
fz_graph.NT_TECH_HEAD = "tech-h"
fz_graph.NT_TECH_TAIL = "tech-t"
fz_graph.NT_ITEM = "item"
fz_graph.NT_FLUID = "fluid"
fz_graph.NT_RECIPE = "recipe"


fz_graph.node.property_names = table.invert({ "virtual", "factorio_name", "tech_name", "ignore_for_dependencies", "internal", "original_key" })

function fz_graph.node.create(name, type, properties)
    local n = {}
    setmetatable(n, fz_graph.node)

    n.name = name
    n.type = type
    n.key = fz_graph.node.get_key(name, type)
    n.labels = {}
    n.virtual = false
    n.products = {}
    n:update(properties)

    return n
end

function fz_graph.node:update(properties)
    if not properties then return end

    for k, v in pairs(properties) do
        if v ~= nil and fz_graph.node.property_names[k] then
            self[k] = v
        end
    end

    if properties.labels ~= nil then
        self.labels = table.merge(self.labels, properties.labels)
    end

    if properties.products ~= nil then
        self.products = table.merge(self.products, properties.products)
    end
end

function fz_graph.node:add_label(label)
    self.labels[label] = true
end

function fz_graph.node.get_key(name, type)
    return type .. "|" .. name
end

function fz_graph.node:inherit_ignore_for_dependencies(parent_node)
    if parent_node.ignore_for_dependencies and self.ignore_for_dependencies == nil then
        self.ignore_for_dependencies = true
    elseif not parent_node.ignore_for_dependencies and self.ignore_for_dependencies then
        self.ignore_for_dependencies = false
    end
end

function fz_graph.create()
    local g = {}
    setmetatable(g, fz_graph)

    g.graph = graph.create(0, true)
    g.nodes = {}
    g.start_node = g:add_node(fz_graph.START_NODE_NAME, fz_graph.NT_TECH_HEAD, { virtual = true, tech_name = fz_graph.START_NODE_NAME })

    return g
end

function fz_graph:copy()
    local g = {}
    setmetatable(g, fz_graph)

    g.graph = self.graph:copy()
    g.nodes = table.deepcopy(self.nodes)
    g.start_node = g.nodes[self.start_node.key]

    return g
end

function fz_graph:create_subgraph(node_list)
    local g = {}
    setmetatable(g, fz_graph)

    local keys = table.map(node_list, function() return true end)
    g.graph = self.graph:create_subgraph(keys)
    g.nodes = table.deepcopy(node_list)
    g.start_node = g.nodes[self.start_node.name]

    return g
end

function fz_graph:add_node(name, type, properties)
    local key = fz_graph.node.get_key(name, type)
    local node = self.nodes[key]

    if not node then
        node = fz_graph.node.create(name, type, properties)
        self.nodes[key] = node
        self.graph:addVertexIfNotExists(key)
    else
        node:update(properties)
    end

    return node
end

function fz_graph:get_node(name, type)
    local key = type and fz_graph.node.get_key(name, type) or name
    return self.nodes[key]
end

function fz_graph:node_exists(name, type)
    return self:get_node(name, type) ~= nil and true or false
end

function fz_graph:add_link(from, to, label)
    if not label or label == "" then error("Missing parameter: label") end

    if not self:link_exists(from, to, label) then
        self.graph:addEdge(from.key, to.key, 1, label)

        if label then
            to:add_label(label)
        end
    end
end

function fz_graph:remove_link(from, to, label)
    self.graph:removeEdge(from.key, to.key, label)
end

function fz_graph:remove_node(node)
    if self.nodes[node.key] then
        self.graph:removeVertex(node.key)
        self.nodes[node.key] = nil
    end
end

function fz_graph:recursive_remove(filter, logging)
    local found

    repeat
        found = false

        for key, node in pairs(table.filter(self.nodes, filter, self)) do
            self:remove_node(node)
            found = true

            if logging then
                log(" - Removed from dependency graph: " .. key)
            end
        end
    until not found
end

function fz_graph:has_links_from(node)
    return not table.is_empty(self.graph:adj(node.key))
end

function fz_graph:has_links_to(node)
    return not table.is_empty(self.graph:rev(node.key))
end

function fz_graph:get_links_from(node, label)
    return table.filter(self.graph:adj(node.key), function(e) return not label or e.label == label end)
end

function fz_graph:get_links_to(node, label)
    return table.filter(self.graph:rev(node.key), function(e) return not label or e.label == label end)
end

function fz_graph:link_exists(from, to, label)
    return table.any(self.graph.adjList[from.key], function(e) return e:to() == to.key and e.label == label end)
end

function fz_graph:iter_links_from(node, label)
    local tab = self.graph:adj(node.key)
    local k, e

    return
        function()
            repeat
                k, e = next(tab, k)
            until (label or "") == "" or not k or e.label == label

            return k, e
        end
end

function fz_graph:iter_links_to(node, label)
    local tab = self.graph:rev(node.key)
    local k, e

    return
        function()
            repeat
                k, e = next(tab, k)
            until (label or "") == "" or not k or e.label == label

            return k, e
        end
end

function fz_graph:has_label_from(node, label)
    return table.any(self.graph:adj(node.key), function(e) return e.label and e.label ~= "" and (not label or e.label == label) end)
end

function fz_graph:has_label_to(node, label)
    return table.any(self.graph:rev(node.key), function(e) return e.label and e.label ~= "" and (not label or e.label == label) end)
end

function fz_graph:clone_node(source_node, name)
    local node = self:add_node(name, source_node.type)
    node:update(source_node)

    for _, e in self:iter_links_from(source_node) do
        self:add_link(node, self.nodes[e:other(source_node.key)], e.label)
    end

    for _, e in self:iter_links_to(source_node) do
        self:add_link(self.nodes[e:other(source_node.key)], node, e.label)
    end

    return node
end

return fz_graph
