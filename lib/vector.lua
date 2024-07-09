---@class Pyvector 3d vector
---@field x number
---@field y number
---@field z number
---@field cross fun(self, v: Pyvector): Pyvector
---@field dot fun(self, v: Pyvector): number
---@field is_vector fun(self): boolean
---@operator call(): Pyvector
---@operator add(): Pyvector
---@operator sub(): Pyvector
---@operator mul(): Pyvector
---@operator div(): Pyvector
---@operator unm(): Pyvector
py.vector = {
    ---@return Pyvector
    __call = function(_, x, y, z)
        if type(x) == 'table' then
            return setmetatable(x, py.vector)
        end
        return setmetatable({x = x or 0, y = y or 0, z = z or 0}, py.vector)
    end,

    __add = function(self, v)
        return py.vector(self.x + v.x, self.y + v.y, self.z + v.z)
    end,

    __sub = function(self, v)
        return py.vector(self.x - v.x, self.y - v.y, self.z - v.z)
    end,

    __mul = function(self, v)
        if type(v) == 'number' then v = py.vector(v,v,v) end
        return py.vector(self.x * v.x, self.y * v.y, self.z * v.z)
    end,

    __div = function(self, v)
        if type(v) == 'number' then v = py.vector(v,v,v) end
        return py.vector(self.x / v.x, self.y / v.y, self.z / v.z)
    end,

    __unm = function(self)
        return py.vector(self.x * -1, self.y * -1, self.z * -1)
    end,

    __tostring = function(self)
        return string.format('(%f, %f, %f)', self.x, self.y, self.z)
    end,

    __index = {
        ---@return boolean
        is_vector = function(self)
            return getmetatable(self) == py.vector
        end,

        ---@param v Pyvector
        ---@return Pyvector
        dot = function(self, v)
            return self.x * v.x + self.y * v.y + self.z * v.z
        end,

        ---@param v Pyvector
        ---@return Pyvector
        cross = function(self, v)
            local out = {}
            local a, b, c = self.x, self.y, self.z
            out.x = b * v.z - c * v.y
            out.y = c * v.x - a * v.z
            out.z = a * v.y - b * v.x
            return py.vector(out)
        end,
    }
}

setmetatable(py.vector, py.vector)