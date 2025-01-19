---Define pipe connection pipe pictures by coping from an existing entity in the base mod.
---@param pictures string
---@param shift_north table?
---@param shift_south table?
---@param shift_west table?
---@param shift_east table?
---@param replacements table?
---@return table
py.pipe_pictures = function(pictures, shift_north, shift_south, shift_west, shift_east, replacements)
    local new_pictures = {
        north = shift_north and
            {
                filename = "__base__/graphics/entity/" .. pictures .. "/" .. pictures .. "-pipe-N.png",
                priority = "extra-high",
                width = 71,
                height = 38,
                shift = shift_north,
                scale = 0.5
            } or py.empty_image(),
        south = shift_south and
            {
                filename = "__base__/graphics/entity/" .. pictures .. "/" .. pictures .. "-pipe-S.png",
                priority = "extra-high",
                width = 88,
                height = 61,
                shift = shift_south,
                scale = 0.5
            } or py.empty_image(),
        west = shift_west and
            {
                filename = "__base__/graphics/entity/" .. pictures .. "/" .. pictures .. "-pipe-W.png",
                priority = "extra-high",
                width = 39,
                height = 73,
                shift = shift_west,
                scale = 0.5
            } or py.empty_image(),
        east = shift_east and
            {
                filename = "__base__/graphics/entity/" .. pictures .. "/" .. pictures .. "-pipe-E.png",
                priority = "extra-high",
                width = 42,
                height = 76,
                shift = shift_east,
                scale = 0.5
            } or py.empty_image()
    }
    for direction, image in pairs(replacements or {}) do
        if new_pictures[direction].filename ~= "__core__/graphics/empty.png" then
            new_pictures[direction].filename = image.filename
            new_pictures[direction].width = image.width
            new_pictures[direction].height = image.height
            new_pictures[direction].priority = image.priority or new_pictures[direction].priority
            new_pictures[direction].scale = 1 or new_pictures[direction].scale
        end
    end
    return new_pictures
end

---Define pipe connection pipe covers, not all entities use these.
---Example: https://github.com/pyanodon/pybugreports/issues/472
---@param n boolean?
---@param s boolean?
---@param w boolean?
---@param e boolean?
---@return table
py.pipe_covers = function(n, s, w, e)
    if (n == nil and s == nil and w == nil and e == nil) then
        n, s, e, w = true, true, true, true
    end

    n =
        n and {
            layers = {
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north.png",
                    priority = "extra-high",
                    width = 128,
                    height = 128,
                    scale = 0.5
                },
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north-shadow.png",
                    priority = "extra-high",
                    width = 128,
                    height = 128,
                    scale = 0.5,
                    draw_as_shadow = true
                }
            }
        } or py.empty_image()
    e =
        e and {
            layers = {
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east.png",
                    priority = "extra-high",
                    width = 128,
                    height = 128,
                    scale = 0.5
                },
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east-shadow.png",
                    priority = "extra-high",
                    width = 128,
                    height = 128,
                    scale = 0.5,
                    draw_as_shadow = true
                }
            }
        } or py.empty_image()
    s =
        s and {
            layers = {
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south.png",
                    priority = "extra-high",
                    width = 128,
                    height = 128,
                    scale = 0.5
                },
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south-shadow.png",
                    priority = "extra-high",
                    width = 128,
                    height = 128,
                    scale = 0.5,
                    draw_as_shadow = true
                }
            }
        } or py.empty_image()
    w =
        w and {
            layers = {
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west.png",
                    priority = "extra-high",
                    width = 128,
                    height = 128,
                    scale = 0.5
                },
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west-shadow.png",
                    priority = "extra-high",
                    width = 128,
                    height = 128,
                    scale = 0.5,
                    draw_as_shadow = true
                }
            }
        } or py.empty_image()

    return {north = n, south = s, east = e, west = w}
end

---Define nice looking pipe pictures based on the space age electromagnetic plant.
---These do not come with pipe covers! However there is a frozen variant.
---See seaweed-crop.lua in alien life for an example implementation.
py.sexy_pipe_pictures = function()
    local function by_direction(pipe_direction)
        return {
            layers = {
                util.sprite_load("__pypostprocessing__/graphics/pipe-connections/pipe-" .. pipe_direction,
                    {
                        scale = 0.5,
                    }
                ),
                util.sprite_load("__pypostprocessing__/graphics/pipe-connections/pipe-shadow-" .. pipe_direction,
                    {
                        scale = 0.5,
                        draw_as_shadow = true,
                    }
                )
            }
        }
    end

    return {
        north = by_direction("north"),
        east = by_direction("east"),
        south = by_direction("south"),
        west = by_direction("west")
    }
end

---Define nice looking pipe frozen pictures based on the space age electromagnetic plant.
py.sexy_pipe_pictures_frozen = function()
    local function by_direction(pipe_direction)
        return {
            layers = {
                util.sprite_load("__pypostprocessing__/graphics/pipe-connections/pipe-" .. pipe_direction .. "-frozen",
                    {
                        scale = 0.5,
                    }
                )
            }
        }
    end

    return {
        north = by_direction("north"),
        east = by_direction("east"),
        south = by_direction("south"),
        west = by_direction("west")
    }
end
