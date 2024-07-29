local node_types = require "prototypes.new_auto_tech.node_types"
local item_verbs = require "prototypes.new_auto_tech.item_verbs"
local fluid_verbs = require "prototypes.new_auto_tech.fluid_verbs"

local object_node_base = {}
object_node_base.__index = object_node_base

function object_node_base:create_class_impl(type_name, node_type, create_method)
    local object_class = { type_name = type_name }
    object_class.__index = object_class
    setmetatable(object_class, {__index = object_node_base})
    object_class.node_type = node_type
    object_class.create = create_method
    return object_class
end

function object_node_base:create_unique_class(type_name, node_type)
    return object_node_base:create_class_impl(type_name, node_type, object_node_base.create_unique)
end

function object_node_base:create_object_class(type_name, node_type)
    return object_node_base:create_class_impl(type_name, node_type, object_node_base.create_object)
end

function object_node_base:create_object(object, nodes, configuration)
    local s = {}
    -- Yes, we're setting up the inheritance in the base class, this skips all the cumbersome base class calls we don't need anyway
    setmetatable(s, self.__index)
    s.configuration = configuration
    s.depends = {}
    s.reverse_depends = {}
    s.disjunctive_depends = {}
    s.disjunctive_depends_count = 0
    s.reverse_disjunctive_depends = {}
    if object == nil then
        s.printable_name = self.type_name
        nodes[self.node_type][1] = s
    else
        s.object = object
        s.printable_name = object.name .. " (" .. self.type_name .. ")"
        nodes[self.node_type][object.name] = s
    end

    -- These get changed in the linearisation
    s.depends_count = 0
    s.canonicalised_choices = {}
    s.canonicalised_choices_count = 0

    if configuration.verbose_logging then
        log("Created node for " .. s.printable_name)
    end

    return s
end

function object_node_base:has_no_more_dependencies()
    return self.depends_count == 0 and self.disjunctive_depends_count == self.canonicalised_choices_count
end

function object_node_base:print_dependencies()
    local result = self.depends_count .. " fixed dependencies"

    if self.disjunctive_depends_count ~= self.canonicalised_choices_count then
        result = result .. " and these disjunctive dependencies: "
        for verb, _ in pairs(self.disjunctive_depends) do
            if self.canonicalised_choices[verb] == nil then
                result = result .. verb .. ", "
            end
        end
    end

    return result
end

function object_node_base:release_dependents()
    local newly_independent_nodes = {}
    local verbose_logging = self.configuration.verbose_logging

    for _, data in pairs(self.reverse_depends) do
        local node = data[1]
        local verb = data[2]
        local dependency_type = data[3]

        node.depends_count = node.depends_count - 1
        if verbose_logging then
            log("Virtually removing dependency from " .. node.printable_name .. " on " .. self.printable_name .. " to " .. verb .. " via " .. dependency_type)
        end
        if node:has_no_more_dependencies() then
            newly_independent_nodes[#newly_independent_nodes+1] = node
            if verbose_logging then
                log("Node " .. node.printable_name .. " has no more dependencies.")
            end
        end
    end

    for _, data in pairs(self.reverse_disjunctive_depends) do
        local node = data[1]
        local verb = data[2]
        local dependency_type = data[3]
        if node.canonicalised_choices[verb] ~= nil then
            node.canonicalised_choices[verb] = {self, dependency_type}
            node.canonicalised_choices_count = node.canonicalised_choices_count + 1
            if verbose_logging then
                log("Canonising the dependency for " .. node.printable_name .. " for " .. verb .. " to be on " .. self.printable_name .. " via " .. dependency_type)
            end
    
            if not node:still_has_dependencies() then
                newly_independent_nodes[#newly_independent_nodes+1] = node
                if verbose_logging then
                    log("Node " .. node.printable_name .. " has no more dependencies.")
                end
            end
        end
    end
    
    return newly_independent_nodes
end

function object_node_base:create_unique(nodes, configuration)
    return self:create_object(nil, nodes, configuration)
end

function object_node_base:lookup_dependency(nodes, node_type, node_name)
    local dependency = nodes[node_type][node_name]
    if dependency == nil then
        error("Could not find dependency " .. node_name .. " of type " .. node_type.type_name .. ", this is probably a bug in the data parser.")
    end
    return dependency
end

function object_node_base:add_dependency_impl(dependency, dependency_type, verb)
    local depends = self.depends
    depends[#depends+1] = {dependency, dependency_type}
    self.depends_count = self.depends_count + 1
    local reverse_depends = dependency.reverse_depends
    reverse_depends[#reverse_depends+1] = {self, verb, dependency_type}
    if self.configuration.verbose_logging then
        log("In order to " .. verb .. " " .. self.printable_name .. " you require " .. dependency.printable_name .. " via " .. dependency_type)
    end
end

function object_node_base:add_disjunctive_dependency_impl(dependency, dependency_type, verb)
    if self.disjunctive_depends[verb] == nil then
        self.disjunctive_depends[verb] = {}
        self.disjunctive_depends_count = self.disjunctive_depends_count + 1
    end
    local target = self.disjunctive_depends[verb]
    target[#target+1] = {dependency, dependency_type}
    local reverse_disjunctive_depends = dependency.reverse_disjunctive_depends
    reverse_disjunctive_depends[#reverse_disjunctive_depends+1] = {self, verb, dependency_type}
    if self.configuration.verbose_logging then
        log("In order to " .. verb .. " " .. self.printable_name .. " you could use " .. dependency.printable_name .. " via " .. dependency_type)
    end
end

function loop_if_table_ignore_nil(func, node_name, optional_inner_name)
    function doCall(actual_node_name)
        if optional_inner_name == nil then
            func(actual_node_name)
        else
            func(actual_node_name[optional_inner_name])
        end
    end
    function doCallOnObject()
        doCall(node_name)
    end
    function doCallOnTable()
        for _, actual_node_name in pairs(node_name) do
            doCall(actual_node_name)
        end
    end

    if node_name == nil then
        return
    end
    if type(node_name) == "table" then
        if optional_inner_name ~= nil then
            -- have to distinguish between { item='fish', count=5 } and a table of such entries
            if node_name[optional_inner_name] == nil then
                doCallOnTable()
            else
                doCallOnObject()
            end
        else
            doCallOnTable()
        end
    else
        doCallOnObject()
    end
end

function object_node_base:add_dependency(nodes, node_type, node_name, dependency_type, verb, optional_inner_name)
    loop_if_table_ignore_nil(function (node_name_inner)
        self:add_dependency_impl(self:lookup_dependency(nodes, node_type, node_name_inner), dependency_type, verb)
    end, node_name, optional_inner_name)
end

function object_node_base:add_disjunctive_dependency(nodes, node_type, node_name, dependency_type, verb, optional_inner_name)
    loop_if_table_ignore_nil(function (node_name_inner)
        self:add_disjunctive_dependency_impl(self:lookup_dependency(nodes, node_type, node_name_inner), dependency_type, verb)
    end, node_name, optional_inner_name)
end

function object_node_base:add_dependent(nodes, node_type, node_name, dependency_type, verb, optional_inner_name)
    loop_if_table_ignore_nil(function (node_name_inner)
        self:lookup_dependency(nodes, node_type, node_name_inner):add_dependency_impl(self, dependency_type, verb)
    end, node_name, optional_inner_name)
end

function object_node_base:add_disjunctive_dependent(nodes, node_type, node_name, dependency_type, verb, optional_inner_name)
    loop_if_table_ignore_nil(function (node_name_inner)
        self:lookup_dependency(nodes, node_type, node_name_inner):add_disjunctive_dependency_impl(self, dependency_type, verb)
    end, node_name, optional_inner_name)
end

function object_node_base:add_productlike_dependency(nodes, single_product, table_product, dependency_type, verb)
    self:add_productlike_dependency_impl(nodes, single_product, table_product, dependency_type, function (self2, nodes2, node_type2, node_name2, dependency_type2, verb2)
        self2:add_dependency(nodes2, node_type2, node_name2, dependency_type2, verb)
    end)
end

function object_node_base:add_productlike_disjunctive_dependent(nodes, single_product, table_product, dependency_type)
    self:add_productlike_dependency_impl(nodes, single_product, table_product, dependency_type, self.add_disjunctive_dependent)
end

function object_node_base:add_productlike_dependency_impl(nodes, single_product, table_product, dependency_type, dependency_function)
    local function unwrap_result(wrapped_result)
        return type(wrapped_result) == "table" and (wrapped_result.name or wrapped_result[1]) or wrapped_result
    end

    if table_product ~= nil then
        for _, result in pairs(table_product) do
            local result_name = unwrap_result(result)
            if result.type == "fluid" then
                dependency_function(self, nodes, node_types.fluid_node, result_name, dependency_type, fluid_verbs.create)
            else
                dependency_function(self, nodes, node_types.item_node, result_name, dependency_type, item_verbs.create)
            end
        end
    end
    if single_product ~= nil then
        local result_name = unwrap_result(single_product)
        dependency_function(self, nodes, node_types.item_node, result_name, dependency_type, item_verbs.create)
    end
end

return object_node_base
