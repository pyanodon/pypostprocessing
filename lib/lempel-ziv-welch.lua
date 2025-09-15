local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function b64encode(data)
    return ((data:gsub(".", function(x)
        local r, b = "", x:byte()
        for i = 8, 1, -1 do
            r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then return "" end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
        end
        return b64chars:sub(c + 1, c + 1)
    end) .. ({"", "==", "="})[#data % 3 + 1])
end

local function b64decode(data)
    data = data:gsub("[^" .. b64chars .. "=]", "") -- strip invalid chars

    local b64bytes = {}
    for i = 1, #b64chars do
        b64bytes[b64chars:sub(i, i)] = i - 1
    end
    local bitstr = ""
    for i = 1, #data do
        local c = data:sub(i, i)
        if c ~= "=" then
            local val = b64bytes[c]
            local bits = ""
            for j = 6, 1, -1 do
                bits = bits .. ((val % 2 ^ j - val % 2 ^ (j - 1) > 0) and "1" or "0")
            end
            bitstr = bitstr .. bits
        end
    end

    local decoded = {}
    for i = 1, #bitstr, 8 do
        local byte = bitstr:sub(i, i + 7)
        if #byte == 8 then
            local c = 0
            for j = 1, 8 do
                c = c + (byte:sub(j, j) == "1" and 2 ^ (8 - j) or 0)
            end
            decoded[#decoded + 1] = string.char(c)
        end
    end

    return table.concat(decoded)
end

local function lzw_compress(input)
    local function pack16(n)
        local hi = math.floor(n / 256)
        local lo = n % 256
        return string.char(hi, lo)
    end

    local dict = {}
    for i = 0, 255 do
        dict[string.char(i)] = i
    end
    local dict_size = 256

    local w = ""
    local result = {}

    for i = 1, #input do
        local c = input:sub(i, i)
        local wc = w .. c
        if dict[wc] then
            w = wc
        else
            result[#result + 1] = pack16(dict[w])
            dict[wc] = dict_size
            dict_size = dict_size + 1
            w = c
        end
    end

    if w ~= "" then
        result[#result + 1] = pack16(dict[w])
    end

    return b64encode(table.concat(result))
end

local function lzw_decompress(encoded)
    local compressed = b64decode(encoded)

    local function unpack16(s, i)
        local hi = s:byte(i)
        local lo = s:byte(i + 1)
        return hi * 256 + lo
    end

    local dict = {}
    for i = 0, 255 do
        dict[i] = string.char(i)
    end
    local dict_size = 256

    local codes = {}
    for i = 1, #compressed, 2 do
        table.insert(codes, unpack16(compressed, i))
    end

    local w = dict[codes[1]]
    local result = {w}

    for i = 2, #codes do
        local k = codes[i]
        local entry
        if dict[k] then
            entry = dict[k]
        elseif k == dict_size then
            entry = w .. w:sub(1, 1)
        else
            error("Bad compressed k: " .. tostring(k))
        end

        table.insert(result, entry)

        dict[dict_size] = w .. entry:sub(1, 1)
        dict_size = dict_size + 1

        w = entry
    end

    return table.concat(result)
end

local text = "It looks like you're writing a letter. Would you like help?"
assert(text == lzw_decompress(lzw_compress(text)))

return {lzw_compress = lzw_compress, lzw_decompress = lzw_decompress}
