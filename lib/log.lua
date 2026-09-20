py.log = {}

local int_log_levels = {warning = 0, info = 1, debug = 2}
local log_level = int_log_levels[settings.startup["pypp-log-level"].value]
log("log level: " .. log_level)

---@class Logger
---@field debug fun(message: string)
---@field info fun(message: string)
---@field warning fun(message: string)

---@param category string used to identify what the log is about
---@param message string
local log_debug = function(category, message)
    if log_level < 2 then return end
    log("DEBUG: " .. category .. ": " .. message)
end

---@param category string used to identify what the log is about
---@param message string
local log_info = function(category, message)
    if log_level < 1 then return end
    log("INFO: " .. category .. ": " .. message)
end

---@param category string used to identify what the log is about
---@param message string
local log_warning = function(category, message)
    if log_level < 0 then return end
    log("WARNING: " .. category .. ": " .. message)
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
