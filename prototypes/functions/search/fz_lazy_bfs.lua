local queue = require("luagraphs.queue.queue")

local lazy_bfs = {}
lazy_bfs.__index = lazy_bfs


function lazy_bfs.create(g, start_node, strong, reverse, stop_filter)
    local b = {}
    setmetatable(b, lazy_bfs)

    b.graph = g
    b.start = start_node
    b.strong = strong or false
    b.reverse = reverse or false
    b.stop_filter = stop_filter

    b.marked = {}
    b.labels = {}
    b.q = queue()
    b.finished = false
    b.path_to = {}
    b.level = {}

    b.q(start_node)
    b.marked[start_node.key] = true
    b.level[start_node.key] = 1

    return b
end

function lazy_bfs:run(target_node, logging, max_level)
    if self.finished or (target_node and self.marked[target_node.key]) then return end

    while not queue.is_empty(self.q) do
        if max_level and self.level[self.q:peek().key] > max_level then
            return
        end

        local v = self.q()
        if logging then log("Processing: " .. v.key) end
        local stop_search = false

        for _, e in (not self.reverse and self.graph:iter_links_from(v) or self.graph:iter_links_to(v)) do
            local w = self.graph:get_node(e:other(v.key))

            if not self.marked[w.key] and (not self.stop_filter or not self.stop_filter(w, v)) then
                -- if logging then log(" - Checking: " .. w.key) end
                local progress = true

                if self.path_to[w.key] == nil
                    or (not v.internal and self.graph:get_node(self.path_to[w.key]).internal)
                    or ((v.internal or false) == (self.graph:get_node(self.path_to[w.key]).internal or false)
                        and self.level[v.key] < self.level[self.path_to[w.key]])
                then
                    self.path_to[w.key] = v.key
                end

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
                    self.level[w.key] = self.level[self.path_to[w.key]] + 1
                    self.q(w)
                    if logging then log(" - Queued: " .. w.key .. " (level " .. self.level[w.key] .. ")") end

                    if target_node and w.key == target_node.key then
                        stop_search = true
                    end
                elseif logging then
                    log(" - Not queued: " .. w.key)
                end
            end
        end

        if stop_search then return end
    end

    self.finished = true
end

function lazy_bfs:has_path_to(target_node, logging, max_level)
    self:run(target_node, logging, max_level)

    return self.marked[target_node.key] or false
end

function lazy_bfs:get_path_to(target_node, logging)
    self:run(target_node, logging)

    local q = queue()
    q(target_node.key)
    local x = self.path_to[target_node.key]

    while x and x ~= self.start.key do
        q(x)
        x = self.path_to[x]
    end

    q(self.start.key)

    return q
end

return lazy_bfs
