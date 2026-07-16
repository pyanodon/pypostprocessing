if helpers.stage == "prototype" then
  data:extend{
    {
      type = "mod-data",
      name = "pyanodons",
      data = {}
    }
  }
  py.mod_data = data.raw["mod-data"].pyanodons.data
else
  py.mod_data = prototypes.mod_data.pyanodons.data
end

---Adds data to the pyanodons mod-data object, for use at runtime. Data validation must be done by the script in question
---@param index string
---@param data AnyBasic
function py.smuggle(index, data)
  data.raw["mod-data"].pyanodons.data[index] = data
end

---@class (partial) pyModData
---@cast py.mod_data pyModData