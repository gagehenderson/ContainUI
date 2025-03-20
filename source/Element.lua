local PATH           = (...):gsub('%.Element$', '')
local ElementSpecs   = require(PATH .. ".ElementSpecs")
local validate_specs = require(PATH .. ".utils.validate_specs")
local ui_unit        = require(PATH .. ".utils.ui_unit") ---@type ui_unit_utils

-- All child classes must implement `get_content_dimensions()`.
-- It is recommended to call `Element:calculate_bounds()` in the constructor.
---@class UIElement
---@field parent? UIContainer
---@field content_bounds {x: number, y: number, width: number, height: number}
---@field padding_bounds {x: number, y: number, width: number, height: number}
---@field margin_bounds {x: number, y: number, width: number, height: number}
---@field offset {x: number, y: number}
---@field border {width: number, radius: number, color: number[]}
---@field box_shadow {x: number, y: number, color: number[], extra_width: number, extra_height: number}
---@field background {image: love.Image|userdata, color: number[], position: {x: number, y: number}, scale: {x: number, y: number}}
---@field spec_position {x?: ui_unit, y?: ui_unit}
---@field spec_dimensions {width?: ui_unit|"auto", height?: ui_unit|"auto"}
---@field spec_padding {x?: number, y?: number, left?: number, right?: number, top?: number, bottom?: number}
---@field spec_margin {x?: number, y?: number, left?: number, right?: number, top?: number, bottom?: number}
---@field spec_offset {x?: number, y?: number}
---@field spec_background {position: {x: ui_unit, y: ui_unit}, size: {x?: ui_unit, y?: ui_unit}, scale_mode: "contain" | "cover"}
---@field get_content_dimensions fun(): number, number - Width, height
local Element = {}

---@param specs UIElementSpecs
---@return any - Override where this is called.
function Element:new(specs)
    specs = specs or {}
    local err = validate_specs(specs, ElementSpecs)
    if err then
        error("Element:new(): Error validating specs: \n" .. err)
    end

    -- If any part of a border is specified we set it's default values to 
    -- ones that let it be displayed. Otherwise it will be values that make it
    -- invisible.
    local border_specs = {
        width = 0,
        radius = 0,
        color = {1, 1, 1}
    }
    if specs.border then
        border_specs.width  = specs.border.width or 1
        border_specs.radius = specs.border.radius or 0
        border_specs.color  = specs.border.color or {1, 1, 1}
    end
    local box_shadow_specs = {
        x = 0, y = 0,
        color = {0,0,0,0.5},
        extra_width = 0,
        extra_height = 0,
    }
    if specs.box_shadow then
        box_shadow_specs.x     = specs.box_shadow.x or 2
        box_shadow_specs.y     = specs.box_shadow.y or 2
        box_shadow_specs.color = specs.box_shadow.color or {0,0,0,0.5}
        box_shadow_specs.extra_width  = specs.box_shadow.extra_width or 0
        box_shadow_specs.extra_height = specs.box_shadow.extra_height or 0
    end
    local new = {
        content_bounds = { x = 0, y = 0, width = 0, height = 0 },
        padding_bounds = { x = 0, y = 0, width = 0, height = 0 },
        margin_bounds  = { x = 0, y = 0, width = 0, height = 0 },
        offset = { x = 0, y = 0 },
        spec_position = {
            x = specs.position and specs.position.x or 0,
            y = specs.position and specs.position.y or 0
        },
        spec_dimensions = {
            width  = specs.dimensions and specs.dimensions.width or "auto",
            height = specs.dimensions and specs.dimensions.height or "auto"
        },
        spec_padding = {
            x      = specs.padding and specs.padding.x or nil,
            y      = specs.padding and specs.padding.y or nil,
            left   = specs.padding and specs.padding.left or 0,
            right  = specs.padding and specs.padding.right or 0,
            top    = specs.padding and specs.padding.top or 0,
            bottom = specs.padding and specs.padding.bottom or 0
        },
        spec_margin = {
            x      = specs.margin and specs.margin.x or nil,
            y      = specs.margin and specs.margin.y or nil,
            left   = specs.margin and specs.margin.left or 0,
            right  = specs.margin and specs.margin.right or 0,
            top    = specs.margin and specs.margin.top or 0,
            bottom = specs.margin and specs.margin.bottom or 0,
        },
        spec_offset = {
            x = specs.offset and specs.offset.x or 0,
            y = specs.offset and specs.offset.y or 0
        },
        spec_background = {
            position = {
                x = specs.background and specs.background.position and specs.background.position.x or 0,
                y = specs.background and specs.background.position and specs.background.position.y or 0,
            },
            size = {
                x = specs.background and specs.background.size and specs.background.size.x or nil,
                y = specs.background and specs.background.size and specs.background.size.y or nil,
            },
            scale_mode = specs.background and specs.background.scale_mode or "contain",
        },
        border = border_specs,
        box_shadow = box_shadow_specs,
        background = {
            color    = specs.background and specs.background.color or {0,0,0,0},
            image    = specs.background and specs.background.image,
            position = { x = 0, y = 0 },
            scale    = { x = 1, y = 1 },
        },
    }

    setmetatable(new, {__index = self})

    return new
end

-- Recalculates padding, margin, content bounds, and background position.
--
-- Should be called whenever an element is created, or any of the following
-- properties are changed:
--   * position
--   * dimensions
--   * padding
--   * margin
function Element:calculate_bounds()
    if self.get_content_dimensions == nil then
        error("Element:calculate_bounds(): Element subclass missing get_content_dimensions().")
    end
    local content_width, content_height = self:get_content_dimensions()
    local padding = {
        left   = self.spec_padding.x and self.spec_padding.x / 2 or self.spec_padding.left or 0,
        right  = self.spec_padding.x and self.spec_padding.x / 2 or self.spec_padding.right or 0,
        top    = self.spec_padding.y and self.spec_padding.y / 2 or self.spec_padding.top or 0,
        bottom = self.spec_padding.y and self.spec_padding.y / 2 or self.spec_padding.bottom or 0
    }
    local margin = {
        left   = self.spec_margin.x and self.spec_margin.x / 2 or self.spec_margin.left or 0,
        right  = self.spec_margin.x and self.spec_margin.x / 2 or self.spec_margin.right or 0,
        top    = self.spec_margin.y and self.spec_margin.y / 2 or self.spec_margin.top or 0,
        bottom = self.spec_margin.y and self.spec_margin.y / 2 or self.spec_margin.bottom or 0
    }
    local keys = { ["x"] = "width", ["y"] = "height" }
    local parent_bounds = self:get_parent_bounds()


    -- Calculate bound dimensions.
    self.padding_bounds.width  = content_width + padding.left + padding.right
    self.padding_bounds.height = content_height + padding.top + padding.bottom
    self.content_bounds.width  = content_width
    self.content_bounds.height = content_height
    self.margin_bounds.width   = self.padding_bounds.width + margin.left + margin.right
    self.margin_bounds.height  = self.padding_bounds.height + margin.top + margin.bottom

    -- Calculate offset.
    for key, dim in pairs(keys) do
        local success, type, value = ui_unit.parse(self.spec_offset[key])
        if not success then
            error("Element:calculate_bounds(): Could not parse spec_offset." .. key .. ": " .. value)
        end
        if type == "percentage" then
            self.offset[key] = self.padding_bounds[dim] * (value / 100)
        else
            self.offset[key] = value
        end
    end

    -- Calculate bound positions.
    for key, dim in pairs(keys) do
        local success, type, value = ui_unit.parse(self.spec_position[key])
        if not success then
            error("Element:calculate_bounds(): Could not parse spec_position." .. key .. ": " .. value)
        end
        if type == "percentage" then
            self.margin_bounds[key] = parent_bounds[dim] * (value / 100)
        else
            self.margin_bounds[key] = value
        end

        self.margin_bounds[key] = self.margin_bounds[key] - self.offset[key]
    end
    self.padding_bounds.x = self.margin_bounds.x + margin.left
    self.padding_bounds.y = self.margin_bounds.y + margin.top
    self.content_bounds.x = self.padding_bounds.x + padding.left
    self.content_bounds.y = self.padding_bounds.y + padding.top

    -- Background image stuff.
    if self.background.image then

        -- Background position.
        for key, dim in pairs(keys) do
            local success, type, value = ui_unit.parse(self.spec_background.position[key])
            if not success then
                error("Element:calculate_bounds(): Could not parse spec_background.position." .. key .. ": " .. value)
            end
            if type == "percentage" then
                self.background.position[key] = self.padding_bounds[key] + self.padding_bounds[dim] * (value / 100)
            else
                self.background.position[key] = self.padding_bounds[key] + value
            end
        end

        -- Background size / scaling.
        local desired_dim = { width = nil, height = nil }
        for key, dim in pairs(keys) do
            if self.spec_background.size[key] ~= nil then
                local success, type, value = ui_unit.parse(self.spec_background.size[key])
                if not success then
                    error("Element:calculate_bounds(): Could not parse spec_background.size." .. key .. ": " .. value)
                end
                if type == "percentage" then
                    desired_dim[dim] = self.padding_bounds[dim] * (value / 100)
                else
                    desired_dim[dim] = value
                end
            end
        end

        if desired_dim.width ~= nil and desired_dim.height ~= nil then
            self.background.scale.x = desired_dim.width / self.background.image:getWidth()
            self.background.scale.y = desired_dim.height / self.background.image:getHeight()
        elseif desired_dim.width ~= nil and desired_dim.height == nil then
            self.background.scale.x = desired_dim.width / self.background.image:getWidth()
            self.background.scale.y = self.background.scale.x
        elseif desired_dim.width == nil and desired_dim.height ~= nil then
            self.background.scale.x = self.background.scale.y
            self.background.scale.y = desired_dim.height / self.background.image:getHeight()
        elseif desired_dim.width == nil and desired_dim.height == nil then
            -- Use scale_mode to determine our scale as the user hasn't
            -- specified a size.
            if self.spec_background.scale_mode == "contain" then
                self.background.scale.x = math.min(
                    self.padding_bounds.width / self.background.image:getWidth(),
                    self.padding_bounds.height / self.background.image:getHeight()
                )
                self.background.scale.y = self.background.scale.x
            elseif self.spec_background.scale_mode == "cover" then
                self.background.scale.x = math.max(
                    self.padding_bounds.width / self.background.image:getWidth(),
                    self.padding_bounds.height / self.background.image:getHeight()
                )
                self.background.scale.y = self.background.scale.x
            end
        end
    end

end

---@param x? number
---@param y? number
function Element:set_position(x, y)
    self.spec_position.x = x or self.spec_position.x
    self.spec_position.y = y or self.spec_position.y
    self:calculate_bounds()
end

-- If we don't have a parent, we return the content bounds of the screen.
---@return {x: number, y: number, width: number, height: number}
function Element:get_parent_bounds()
    if self.parent then
        if not self.parent.content_bounds then
            error("ContainUI error: Parent does not have content bounds.")
        end
        return self.parent.content_bounds
    end
    return {
        x = 0, y = 0,
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }
end

---@return {x: number, y: number, width: number, height: number}
function Element:get_content_bounds()
    return self.content_bounds
end

---@return {x: number, y: number, width: number, height: number}
function Element:get_padding_bounds()
    return self.padding_bounds
end

---@return {x: number, y: number, width: number, height: number}
function Element:get_margin_bounds()
    return self.margin_bounds
end

function Element:draw()
    self:_draw_background_color()
    self:_draw_background_image()
    self:_draw_border()
    self:_draw_box_shadow()
end

function Element:_draw_background_color()
    love.graphics.setColor(self.background.color)
    love.graphics.rectangle(
        "fill",
        self.padding_bounds.x, self.padding_bounds.y,
        self.padding_bounds.width, self.padding_bounds.height
    )
end

function Element:_draw_background_image()
    ---@diagnostic disable: param-type-mismatch
    if not self.background.image then return end
    love.graphics.setScissor(
        self.padding_bounds.x,
        self.padding_bounds.y,
        self.padding_bounds.width,
        self.padding_bounds.height
    )
    love.graphics.setColor(1,1,1)
    love.graphics.draw(
        self.background.image,
        self.background.position.x,
        self.background.position.y,
        0,
        self.background.scale.x,
        self.background.scale.y
    )
    love.graphics.setScissor()
    ---@diagnostic enable: param-type-mismatch
end

function Element:_draw_border()
    if self.border.width == 0 then return end

    love.graphics.setColor(self.border.color)
    love.graphics.rectangle(
        "line",
        self.padding_bounds.x, self.padding_bounds.y,
        self.padding_bounds.width, self.padding_bounds.height
    )
end

function Element:_draw_box_shadow()
    local stencil_func = function()
        love.graphics.rectangle(
            "fill",
            self.padding_bounds.x, self.padding_bounds.y,
            self.padding_bounds.width, self.padding_bounds.height
        )
    end
    love.graphics.stencil(stencil_func, "replace", 1)
    love.graphics.setStencilTest("lequal", 0)
    love.graphics.setColor(self.box_shadow.color)
    love.graphics.rectangle(
        "fill",
        self.padding_bounds.x + self.box_shadow.x,
        self.padding_bounds.y + self.box_shadow.y,
        self.padding_bounds.width + self.box_shadow.extra_width,
        self.padding_bounds.height + self.box_shadow.extra_height
    )
    love.graphics.setStencilTest()
end

return Element
