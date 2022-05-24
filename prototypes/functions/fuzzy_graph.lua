

local fz_graph = {}
fz_graph.__index = fz_graph

fz_graph.Node = {}
fz_graph.Node.__index = fz_graph.Node


function fz_graph.Node.create()
    local n = {}
    setmetatable(n, fz_graph.Node)

    return n
end


function fz_graph.create()
    local g = {}
    setmetatable(g, fz_graph)

    return g
end


return fz_graph
