-- Created by IntelliJ IDEA.
-- User: chen0
-- Date: 26/6/2017
-- Time: 12:48 AM
-- To change this template use File | Settings | File Templates.

local graph = {}
graph.__index = graph

graph.Edge = {}
graph.Edge.__index = graph.Edge


function graph.Edge.create(v, w, weight, label)
    local s = {}
    setmetatable(s, graph.Edge)

    if weight == nil then
        weight = 1.0
    end

    s.v = v
    s.w = w
    s.weight = weight
    s.label = label or ""

    return s
end


function graph.Edge:from()
    return self.v
end


function graph.Edge:to()
    return self.w
end


function graph.Edge:either()
    return self.v
end


function graph.Edge:label()
    return self.label
end


function graph.Edge:other(x)
    if x == self.v then
        return self.w
    else
        return self.v
    end

end


function graph.create(V, directed)
    local g = {}
    setmetatable(g, graph)

    if directed == nil then
        directed = false
    end

    g.vertexList = {}
    g.adjList = {}

    if directed then
        g.revList = {}
    end

    for v = 0, V-1 do
        g.vertexList[v] = true
        g.adjList[v] = {}

        if directed then
            g.revList[v] = {}
        end
    end

    g.directed = directed

    return g
end


function graph:vertexCount()
    return table.size(self.vertexList)
end


function graph:vertices()
    return self.vertexList
end


function graph.createFromVertexList(vertices, directed)
    local g = graph.create(0, directed)
    setmetatable(g, graph)

    g.vertexList = table.deepcopy(vertices)
    g.adjList = {}

    for v, _ in pairs(g.vertexList) do
        g.adjList[v] = {}

        if directed then
            g.revList[v] = {}
        end
    end

    g.directed = directed

    return g
end


function graph:addVertexIfNotExists(v)
    if self.vertexList[v] then
        return false
    else
        self.vertexList[v] = true
        self.adjList[v] = {}

        if self.directed then
            self.revList[v] = {}
        end

        return true
    end
end


function graph:removeVertex(v)
    if self.vertexList[v] then
        self.vertexList[v] = nil

        local edges = table.merge({}, self.adjList[v])

        if self.directed then
            table.merge(edges, self.revList[v])
        end

        for _, e in pairs(edges) do
            self:removeEdge(e:from(), e:to(v))
        end

        self.adjList[v] = nil

        if self.directed then
            self.revList[v] = nil
        end
    end
end


function graph:containsVertex(v)
    return self.vertexList[v] or false
end


function graph:adj(v)
    return self.adjList[v]
end


function graph:rev(v)
    return self.directed and self.revList[v] or nil
end


function graph:addEdge(v, w, weight, label)
    local e = graph.Edge.create(v, w, weight, label)
    self:addVertexIfNotExists(v)
    self:addVertexIfNotExists(w)
    table.insert(self.adjList[v], e)

    if not self.directed then
        table.insert(self.adjList[w], e)
    else
        table.insert(self.revList[w], e)
    end
end


function graph:removeEdge(v, w, label)
    local adj_v = self.adjList[v]

    for k, e in pairs(adj_v) do
        if e:other(v) == w and (not label or label == "" or label == e.label) then
            table.remove(adj_v, k)
            break
        end
    end

    local adj_w = self.directed and self.revList[w] or self.adjList[w]
    if not adj_w then error(w) end

    for k, e in pairs(adj_w) do
        if e:other(w) == v and (not label or label == "" or label == e.label) then
            table.remove(adj_w, k)
            break
        end
    end
end


function graph:reverse()
    local g = graph.createFromVertexList(self.vertexList, self.directed)

    for v, _ in pairs(self.vertexList) do
        local adj_v = self:adj(v)

        for _, e in pairs(adj_v) do
            g:addEdge(e.w, e.v, e.weight, e.label)
        end
    end

    return g
end


function graph:copy()
    local g = graph.createFromVertexList(self.vertexList, self.directed)

    for v, _ in pairs(self.vertexList) do
        local adj_v = self:adj(v)

        for _, e in pairs(adj_v) do
            g:addEdge(e.v, e.w, e.weight, e.label)
        end
    end

    return g
end


function graph:create_subgraph(vertexList)
    local g = graph.createFromVertexList(vertexList, self.directed)

    for v, _ in pairs(vertexList) do
        local adj_v = self:adj(v)

        for _, e in pairs(adj_v) do
            if vertexList[e:other(v)] then
                g:addEdge(e.v, e.w, e.weight, e.label)
            end
        end
    end

    return g
end


function graph:edges()
    local l = {}

    for v, _ in pairs(self.vertexList) do
        local adj_v = self:adj(v)

        for _, e in pairs(adj_v) do
            if self.directed == true or e:other(v) > v then
                table.insert(l, e)
            end
        end
    end

    return l
end


function graph:hasEdge(v, w)
    local adj_v = self:adj(v)

    for _, e in pairs(adj_v) do
        if e:to() == w then
            return true
        end
    end
end

return graph
