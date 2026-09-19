---@param value any?
---@param error_msg string error? message to throw if value is falsey. if not provided, will return false if falsey
---@return boolean
py.assert = function (value, error_msg, ...)
  if value then return true end
  if error_msg then error(... and error_msg:format(...) or error_msg, 2) end
  return false
end

---@enum (key) pY.value_type
local _value_type = {
  ["nil"] = 0,
  string = 1,
  table = 2,
  number = 3,
  userdata = 4,
  ["function"] = 5,
  boolean = 6,
  int = 7,
  uint = 8,
  nonzero = 9,
  gtzero = 10,
  ltzero = 11,
  gteqzero = 12,
  lteqzero = 13
}

---@generic V
---@type {[pY.value_type]: fun(value: V): boolean}
local type_check = {
  ["nil"]      = function (value) return value == nil end,
  ["string"]   = function (value) return type(value) == "string" end,
  ["table"]    = function (value) return type(value) == "table" end,
  ["number"]   = function (value) return type(value) == "number" end,
  ["userdata"] = function (value) return type(value) == "userdata" end,
  ["function"] = function (value) return type(value) == "function" end,
  ["boolean"]  = function (value) return type(value) == "boolean" end,
  ["int"]      = function (value) return type(value) == "number" and math.floor(value) == value and true or false end,
  ["uint"]     = function (value) return type(value) == "number" and math.floor(value) == value and value >= 0 and true or false end,
  ["nonzero"]  = function (value) return type(value) == "number" and value ~= 0 end,
  ["gtzero"]   = function (value) return type(value) == "number" and value > 0 end,
  ["ltzero"]   = function (value) return type(value) == "number" and value < 0 end,
  ["gteqzero"] = function (value) return type(value) == "number" and value >= 0 end,
  ["lteqzero"] = function (value) return type(value) == "number" and value <= 0 end,
}

---@type {[pY.value_type]: string}
local type_errors = {
  nonzero  = ". Number must be != 0, found %q",
  gtzero   = ". Number must be > 0, found %q",
  ltzero   = ". Number must be < 0, found %q",
  gteqzero = ". Number must be >= 0, found %q",
  lteqzero = ". Number must be <= 0, found %q"
}

---@param value any?
---@param type pY.value_type|pY.value_type[]? type or array of types to check against, nil if not passed. if passed an array, all types must match to pass
---@param error_msg string? error? message to throw if value is falsey. if not provided, will return false if falsey
---@return boolean
py.assert_type = function (value, type, error_msg, ...)
  type = type or "nil"
  if _G.type(type) == "table" then
    for _, t in pairs(type) do
      if not py.assert_type(value, t, error_msg, ...) then
        return false
      end
    end
    return true
  elseif _G.type(type) ~= "string" or not type_check[type] then
    error (("Error while running py.assert_type: unknown type %s"):format(type), 2)
  elseif type_check[type](value) then
    return true
  end
  ---@cast type pY.value_type
  if error_msg then error ((... and error_msg:format(...) or error_msg) .. (type_errors[type] and type_errors[type]:format(value) or (". Expected %s, found %s"):format(type, _G.type(value))), 0) end
  return false
end
