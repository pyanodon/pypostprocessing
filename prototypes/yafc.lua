---@diagnostic disable-next-line: undefined-field
if type(data.data_crawler) ~= "string" or string.sub(data.data_crawler, 1, 5) ~= "yafc " then return end

for index, fun in pairs(py.yafc_integrations) do
    py.log.info("Running YAFC integration: " .. index)
    fun()
end
