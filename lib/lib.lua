_G.py = {}

py.range = function(start, stop, step)
    step = step or 1
    if start > stop then
        step = -step
    end

    local range = {}
    for i = start, stop, step do
        table.insert(range, i)
    end
    return range
end

require "table"
require "string"
require "defines"
require "color"
require "world-generation"

if data and data.raw and not data.raw.item["iron-plate"] then
    py.stage = "settings"
elseif data and data.raw then
    py.stage = "data"
    require "data-stage"
elseif script then
    py.stage = "control"
    require "control-stage"
else
    error("Could not determine load order stage.")
end
