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
    local info = debug.getinfo(2) ---@cast info -?
    local callsite = info.short_src .. ":" .. info.currentline
    
    log("DEBUG: " .. category .. ": " .. message)
    log("callsite: " .. callsite)
end

---@param category string used to identify what the log is about
---@param message string
local log_info = function(category, message)
    if log_level < 1 then return end
    local info = debug.getinfo(2) ---@cast info -?
    local callsite = info.short_src .. ":" .. info.currentline

    log("INFO: " .. category .. ": " .. message)
    log("callsite: " .. callsite)
end

---@param category string used to identify what the log is about
---@param message string
local log_warning = function(category, message)
    if log_level < 0 then return end
    local info = debug.getinfo(2) ---@cast info -?
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
py.log.debug = function(message)
    log_debug("default", message)
end

---@param message string
py.log.info = function(message)
    log_info("default", message)
end

---@param message string
py.log.warning = function(message)
    log_warning("default", message)
end
