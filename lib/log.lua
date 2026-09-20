py.log = {}

local int_log_levels = {warning = 0, info = 1, debug = 2}
local log_level = int_log_levels[settings.startup["pypp-log-level"].value]
if helpers.stage == "prototype" then log("log level: " .. log_level) end

---@class Logger
---@field debug fun(message: string)
---@field info fun(message: string)
---@field warning fun(message: string)

---@param category string used to identify what the log is about
---@param message string
---@param info_level int?
local log_debug = function(category, message, info_level)
    if log_level < 2 then return end
    info_level = info_level or 2
    local info = debug.getinfo(info_level) ---@cast info -?
    local callsite = info.short_src .. ":" .. info.currentline
    
    log("DEBUG: " .. category .. ": " .. message)
    log("callsite: " .. callsite)
end

---@param category string used to identify what the log is about
---@param message string
---@param info_level int?
local log_info = function(category, message, info_level)
    if log_level < 1 then return end
    info_level = info_level or 2
    local info = debug.getinfo(info_level) ---@cast info -?
    local callsite = info.short_src .. ":" .. info.currentline

    log("INFO: " .. category .. ": " .. message)
    log("callsite: " .. callsite)
end

---@param category string used to identify what the log is about
---@param message string
---@param info_level int?
local log_warning = function(category, message, info_level)
    if log_level < 0 then return end
    info_level = info_level or 2
    local info = debug.getinfo(info_level) ---@cast info -?
    local callsite = info.short_src .. ":" .. info.currentline

    log("WARNING: " .. category .. ": " .. message)
    log("callsite: " .. callsite)
end

--- returns a logger which adds the category to all logs  
--- logs respect the pypp log level setting
---@param category string used to identify what the log is about
---@return Logger
py.log.init = function(category)
    local debug = function(message)
        return log_debug(category, message)
    end
    local info = function(message)
        return log_info(category, message)
    end
    local warning = function(message)
        return log_warning(category, message)
    end
    ---@type Logger
    local logger = {debug = debug, info = info, warning = warning}
    return logger
end

---@param message string
---@param category string?
py.log.debug = function(message, category)
    category = category or "default"
    log_debug(category, message, 3)
end

---@param message string
---@param category string?
py.log.info = function(message, category)
    category = category or "default"
    log_info(category, message, 3)
end

---@param message string
---@param category string?
py.log.warning = function(message, category)
    category = category or "default"
    log_warning(category, message, 3)
end
