local data_parser = require("prototypes.functions.data_parser")

local auto_tech = {}
auto_tech.__index = auto_tech


function auto_tech.create()
    local a = {}
    setmetatable(a, auto_tech)

    return a
end


function auto_tech:run()
    local parser = data_parser.create()
    local fg = parser:run()

    -- cleanup dead-end nodes
    fg:recursive_remove(function (n, k)
        return n.ignore_for_dependencies and not fg:has_links_to(k) or false
    end, true)
    fg:recursive_remove(function (n, k)
        return n.ignore_for_dependencies and not fg:has_links_from(k) or false
    end, false)

    
end


return auto_tech
