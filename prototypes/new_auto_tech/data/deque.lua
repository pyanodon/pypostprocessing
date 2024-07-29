local push_left = function(self, value)
    local first = self.first - 1
    self.first = first
    self[first] = value
end

local push_right = function(self, value)
    local last = self.last + 1
    self.last = last
    self[last] = value
end

local pop_left = function(self)
    local first = self.first
    if first > self.last then error("self is empty") end
    local value = self[first]
    self[first] = nil
    self.first = first + 1
    return value
end

local pop_right = function(self)
    local last = self.last
    if self.first > last then error("self is empty") end
    local value = self[last]
    self[last] = nil
    self.last = last - 1
    return value
end


local is_empty = function(self)
    return self.last + 1 == self.first
end

local methods = {
    push_right = push_right,
    push_left = push_left,
    pop_right = pop_right,
    pop_left = pop_left,
    is_empty = is_empty,
}

local new = function()
    local r = { first = 0, last = -1 }
    return setmetatable(r, { __index = methods })
end

return {
    new = new,
}
