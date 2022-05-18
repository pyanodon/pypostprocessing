--
-- Created by IntelliJ IDEA.
-- User: chen0
-- Date: 9/7/2017
-- Time: 10:35 AM
-- To change this template use File | Settings | File Templates.
--

local queue = require('luagraphs.data.queue')
local stack = require('luagraphs.data.stack')

local BreadthFirstSearch = {}
BreadthFirstSearch.__index = BreadthFirstSearch


function BreadthFirstSearch.create()
    local s = {}
    setmetatable(s, BreadthFirstSearch)

    s.marked = {}
    s.pathTo = {}

    return s
end


function BreadthFirstSearch:run(G, s)
    self.s = s

    for _, v in pairs(G:vertices():enumerate()) do
        self.marked[v] = false
        self.pathTo[v] = -1
    end

    local q = queue.create()

    q:enqueue(s)

    while q:isEmpty() == false do
        local v = q:dequeue()
        self.marked[v] = true

        for _, e in pairs(G:adj(v):enumerate()) do
            local w = e:other(v)

            if self.marked[w] == false then
                self.pathTo[w] = v
                q:enqueue(w)
            end
        end

    end
end


function BreadthFirstSearch:hasPathTo(v)
    return self.marked[v]
end


function BreadthFirstSearch:getPathTo(v)
    local path = stack.create()
    local x = v

    while x ~= self.s do
        path:push(x)
        x = self.pathTo[x]
    end

    path:push(self.s)

    return path
end


return BreadthFirstSearch
