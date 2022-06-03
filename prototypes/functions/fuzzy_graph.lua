local graph = require "luagraphs.data.graph"
local list  = require "luagraphs.data.list"


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


function fz_graph:add_link(from, to, label)
    self.graph:addEdge(from.key, to.key, 1, label)

    if label then
        to:add_label(label)
    end
end


return fz_graph
