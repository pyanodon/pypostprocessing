--
-- Created by IntelliJ IDEA.
-- User: chen0
-- Date: 26/7/2017
-- Time: 9:29 AM
-- To change this template use File | Settings | File Templates.
--

local list = require('luagraphs.data.list')
local minPQ = require('luagraphs.data.MinPQ')

local PrimMST = {}
PrimMST.__index = PrimMST


function PrimMST.create()
    local s = {}
    setmetatable(s, PrimMST)

    s.marked = {}
    s.path = list.create()

    return s
end


function PrimMST:run(G)
    self.marked = {}
    self.path = list.create()
    local pq = minPQ.create(function(e1, e2) return e1.weight - e2.weight end)

    for _, v in pairs(G:vertices():enumerate()) do
        self.marked[v] = false
    end

    local source = G:vertexAt(0)
    self.marked[source] = true

    for _, e in pairs(G:adj(source):enumerate()) do
        pq:add(e)
    end

    while pq:isEmpty() == false and self.path:size() < G:vertexCount() - 1 do
        local e = pq:delMin()
        local v = e:either()
        local w = e:other(v)

        if self.marked[v] == false or self.marked[w] == false then
            self.path:add(e)

            if self.marked[v] == false then
                self.marked[v] = true

                for _, e_v in pairs(G:adj(v):enumerate()) do
                    pq:add(e_v)
                end
            end

            if self.marked[w] == false then
                self.marked[w] = true

                for _, e_w in pairs(G:adj(w):enumerate()) do
                    pq:add(e_w)
                end
            end
        end
    end
end


return PrimMST

