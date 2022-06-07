local graph = require "luagraphs.data.graph"
local table = require "__stdlib__.stdlib.utils.table"


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


function fz_graph.node.create(name, type, properties)
    local n = {}
    setmetatable(n, fz_graph.node)

    n.name = name
    n.type = type
    n.key = fz_graph.node.get_key(name, type)
    n.labels = {}
    n.virtual = false
    n:update(properties)

    return n
end


function fz_graph.node:update(properties)
    if not properties then return end

    if properties.virtual ~= nil then
        self.virtual = properties.virtual
    end

    if properties.factorio_name ~= nil then
        self.factorio_name = properties.factorio_name
    end

    if properties.ignore_for_dependencies ~= nil then
        self.ignore_for_dependencies = properties.ignore_for_dependencies
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
    g.start_node = g:add_node(fz_graph.START_NODE_NAME, fz_graph.NT_TECH_HEAD, { virtual = true })

    return g
end


function fz_graph:copy()
    local g = {}
    setmetatable(g, fz_graph)

    g.graph = self.graph:copy()
    g.nodes = table.deep_copy(self.nodes)
    g.start_node = g.nodes[fz_graph.START_NODE_NAME]

    return g
end


function fz_graph:create_subgraph(node_list)
    local g = {}
    setmetatable(g, fz_graph)

    local keys = table.map(node_list, function () return true end)
    g.graph = self.graph:create_subgraph(keys)
    g.nodes = table.deep_copy(node_list)
    g.start_node = g.nodes[fz_graph.START_NODE_NAME]
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
    local key = fz_graph.node.get_key(name, type)
    return self.nodes[key]
end


function fz_graph:node_exists(name, type)
    return self:get_node(name, type) ~= nil and true or false
end


function fz_graph:add_link(from, to, label)
    self.graph:addEdge(from.key, to.key, 1, label)

    if label then
        to:add_label(label)
    end
end


function fz_graph:remove_link(from, to)
    self.graph:removeEdge(from.key, to.key)
end


function fz_graph:remove_node(key)
    if self.nodes[key] then
        self.graph:removeVertex(key)
        self.nodes[key] = nil
    end
end


function fz_graph:recursive_remove(filter, logging)
    local found

    repeat
        found = false

        for key, _ in pairs(table.filter(self.nodes, filter)) do
            self:remove_node(key)
            found = true

            if logging then
                log(" - Removed from dependency graph: " .. key)
            end
        end
    until not found
end


function fz_graph:has_links_from(key)
    return not table.is_empty(self.graph:adj(key))
end


function fz_graph:has_links_to(key)
    return not table.is_empty(self.graph:rev(key))
end


return fz_graph
