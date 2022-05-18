--
-- Created by IntelliJ IDEA.
-- User: chen0
-- Date: 28/7/2017
-- Time: 10:11 AM
-- To change this template use File | Settings | File Templates.
--

local list = require('luagraphs.data.list')
local intexedMinPQ = require('luagraphs.data.IndexedMinPQ')

local EagerPrimMST = {}
EagerPrimMST.__index = EagerPrimMST


function EagerPrimMST.create()
    local s = {}
    setmetatable(s, EagerPrimMST)

    s.path = list.create()
    s.marked = {}

    return s
end


function EagerPrimMST:run(G)
    self.path = list.create()
    self.marked = {}

    for _, v in pairs(G:vertices():enumerate()) do
        self.marked[v] = false
    end

    local pq = intexedMinPQ.create(function(e1, e2) return e1.weight - e2.weight end)
    self:visit(G, 0, pq)

    while self.path:size() < G:vertexCount() -1 and pq:isEmpty() == false do
        local w = pq:minIndex()
        local e = pq:delMin()
        self.path:add(e)
        self:visit(G, w, pq)
    end
end


function EagerPrimMST:visit(G, v, pq)
    self.marked[v] = true

    for _, e in pairs(G:adj(v):enumerate()) do
        local w = e:other(v)

        if self.marked[w] == false then
            if pq:contains(w) then
                pq:decreaseKey(w, e)
            else
                pq:add(w, e)
            end
        end
    end
end


return EagerPrimMST

