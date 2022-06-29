local table = require "__stdlib__.stdlib.utils.table"
local queue = require "__stdlib__.stdlib.misc.queue"

local lazy_bfs = {}
lazy_bfs.__index = lazy_bfs


function lazy_bfs.create(g, start_node, strong, reverse)
    local b = {}
    setmetatable(b, lazy_bfs)

    b.graph = g
    b.start = start_node
    b.strong = strong or false
    b.reverse = reverse or false

    b.marked = {}
    b.labels = {}
    b.q = queue()
    b.finished = false

    b.q(start_node)
    b.marked[start_node.key] = true

    return b
end


function lazy_bfs:run(target_node)
    if self.finished or (target_node and self.marked[target_node.key]) then return end

    while not queue.is_empty(self.q) do
        local v = self.q()
        -- log("Processing: " .. v.key)
        local found_target = false

        for _, e in (not self.reverse and self.graph:iter_links_from(v) or self.graph:iter_links_to(v)) do
            local w = self.graph:get_node(e:other(v.key))

            if not self.marked[w.key] then
                -- log(" - Checking: " .. w.key)
                local progress = true

                if v.key ~= self.start.key and self.strong and e.label and e.label ~= "" then
                    local labels = self.labels[w.key]

                    if not labels then
                        labels = {}
                        self.labels[w.key] = labels
                    end

                    if not labels[e.label] then
                        labels[e.label] = {}

                        for _, ee in (not self.reverse and self.graph:iter_links_to(w, e.label) or self.graph:iter_links_from(w, e.label)) do
                            labels[e.label][ee:other(w.key)] = true
                        end
                    end

                    labels[e.label][v.key] = nil

                    if not table.is_empty(labels[e.label]) then
                        progress = false
                    end
                end

                if progress then
                    self.marked[w.key] = true
                    self.q(w)
                    -- log(" - Queued: " .. w.key)

                    if target_node and w.key == target_node.key then
                        found_target = true
                    end
                -- else
                --     log(" - Not queued: " .. w.key)
                end
            end
        end

        if found_target then return end
    end

    self.finished = true
end


function lazy_bfs:has_path_to(target_node)
    self:run(target_node)

    return self.marked[target_node.key] or false
end


return lazy_bfs
