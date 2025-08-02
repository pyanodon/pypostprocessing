if py.stage == "data" then
  data:extend{
    {
      type = "mod-data",
      name = "py-smuggled-data",
      data = {}
    }
  }

  function py.smuggle(name, to_smuggle)
    data.raw["mod-data"]["py-smuggled-data"].data[name] = to_smuggle
  end

  function py.smuggle_get(name, nil_value)
    if data.raw["mod-data"]["py-smuggled-data"].data[name] == nil then
      py.smuggle(name, nil_value)
    end
  
    return data.raw["mod-data"]["py-smuggled-data"].data[name]
  end
elseif py.stage == "control" then
  function py.get_smuggled_data(name)
    return prototypes.mod_data["py-smuggled-data"].get(name)
  end
end
