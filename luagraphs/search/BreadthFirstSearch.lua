--
-- Created by IntelliJ IDEA.
-- User: chen0
-- Date: 9/7/2017
-- Time: 10:35 AM
-- To change this template use File | Settings | File Templates.
--

local queue = require 'luagraphs.data.queue'
local stack = require 'luagraphs.data.stack'

local BreadthFirstSearch = {}
BreadthFirstSearch.__index = BreadthFirstSearch


function BreadthFirstSearch.create()
    local s = {}
    setmetatable(s, BreadthFirstSearch)

    s.marked = {}
    s.pathTo = {}

    return s
end


function BreadthFirstSearch:run(G, s, stop_filter)
    self.s = s

    local q = queue.create()

    q:enqueue(s)
    self.marked[s] = true

    while q:isEmpty() == false do
        local v = q:dequeue()

        for _, e in pairs(G:adj(v)) do
            local w = e:other(v)

            if not self.marked[w] and (not stop_filter or not stop_filter(w, v)) then
                self.marked[w] = true
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

    while x and x ~= self.s do
        path:push(x)
        x = self.pathTo[x]
    end

    path:push(self.s)

    return path
end


return BreadthFirstSearch
