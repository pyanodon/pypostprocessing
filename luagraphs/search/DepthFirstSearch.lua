--
-- Created by IntelliJ IDEA.
-- User: chen0
-- Date: 6/7/2017
-- Time: 3:06 PM
-- To change this template use File | Settings | File Templates.
--

local stack = require('luagraphs.data.stack')

local DepthFirstSearch = {}
DepthFirstSearch.__index = DepthFirstSearch


function DepthFirstSearch.create()
    local s = {}
    setmetatable(s, DepthFirstSearch)

    s.marked = {}
    s.pathTo = {}

    return s
end


function DepthFirstSearch:run(G, s)
    self.s = s

    for _, v in pairs(G:vertices():enumerate()) do
        self.marked[v] = false
        self.pathTo[v] = -1
    end

    self:dfs(G, s)
end


function DepthFirstSearch:dfs(G, v)
    self.marked[v] = true

    for _, e in pairs(G:adj(v):enumerate()) do
        local w = e:other(v)

        if self.marked[w] == false then
            self.pathTo[w] = v
            self:dfs(G, w)
        end
    end
end


function DepthFirstSearch:hasPathTo(v)
    return self.marked[v]
end


function DepthFirstSearch:getPathTo(v)
    local path = stack.create()
    local x = v

    while x ~= self.s do
        path:push(x)
        x = self.pathTo[x]
    end

    path:push(self.s)

    return path
end


return DepthFirstSearch
