--
-- Created by IntelliJ IDEA.
-- User: chen0
-- Date: 26/6/2017
-- Time: 12:48 AM
-- To change this template use File | Settings | File Templates.
--

local list = require('luagraphs.data.list')

local graph = {}
graph.__index = graph

graph.Edge = {}
graph.Edge.__index = graph.Edge


function graph.Edge.create(v, w, weight)
    local s = {}
    setmetatable(s, graph.Edge)

    if weight == nil then
        weight = 1.0
    end

    s.v = v
    s.w = w
    s.weight = weight

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

    g.vertexList = list.create()
    g.adjList = {}

    for v = 0, V-1 do
        g.vertexList:add(v)
        g.adjList[v] = list.create()
    end

    g.directed = directed

    return g
end


function graph:vertexCount()
    return self.vertexList:size()
end


function graph:vertices()
    return self.vertexList
end


function graph.createFromVertexList(vertices, directed)
    local g = {}
    setmetatable(g, graph)

    if directed == nil then
        directed = false
    end

    g.vertexList = vertices
    g.adjList = {}

    for _, v in pairs(g.vertexList:enumerate()) do
        g.adjList[v] = list.create()
    end

    g.directed = directed

    return g
end


function graph:addVertexIfNotExists(v)
    if self.vertexList:contains(v) then
        return false
    else
        self.vertexList:add(v)
        self.adjList[v] = list.create()
        return true
    end
end


function graph:removeVertex(v)
    if self.vertexList:contains(v) then
        self.vertexList:remove(v)
        self.adjList[v] = nil

        for _, w in pairs(self.vertexList:enumerate()) do
            local adj_w = self.adjList[w]

            for k, e in pairs(adj_w:enumerate()) do
                if e:other(w) == v then
                    adj_w:removeAt(k)
                    break
                end
            end
        end
    end
end


function graph:containsVertex(v)
    return self.vertexList:contains(v)
end


function graph:adj(v)
    return self.adjList[v]
end


function graph:addEdge(v, w, weight)
    local e = graph.Edge.create(v, w, weight)
    self:addVertexIfNotExists(v)
    self:addVertexIfNotExists(w)

    if self.directed then
        self.adjList[e:from()]:add(e)
    else
        self.adjList[e:from()]:add(e)
        self.adjList[e:to()]:add(e)
    end
end


function graph:reverse()
    local g = graph.createFromVertexList(self.vertexList, self.directed)

    for _, v in pairs(self.vertexList:enumerate()) do
        for _, e in pairs(self:adj(v):enumerate()) do
            g:addEdge(e:to(), e:from(), e.weight)
        end
    end

    return g
end


function graph:copy()
    local g = graph.createFromVertexList(self.vertexList, self.directed)

    for _, v in pairs(self.vertexList:enumerate()) do
        for _, e in pairs(self:adj(v):enumerate()) do
            g:addEdge(e:from(), e:to(), e.weight)
        end
    end

    return g
end


function graph:create_subgraph(vertexList)
    local g = graph.createFromVertexList(vertexList, self.directed)

    for _, v in pairs(vertexList:enumerate()) do
        for _, e in pairs(self:adj(v):enumerate()) do
            if vertexList:contains(e:other(v)) then
                g:addEdge(e:from(), e:to(), e.weight)
            end
        end
    end

    return g
end


function graph:vertexAt(i)
    return self.vertexList:get(i)
end


function graph:edges()
    local l = list.create()

    for _, v in pairs(self.vertexList:enumerate()) do
        for _, e in pairs(self:adj(v):enumerate()) do
            if self.directed == true or e:other(v) > v then
                l:add(e)
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

    return false
end

return graph
