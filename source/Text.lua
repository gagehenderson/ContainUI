local PATH    = (...):gsub('%.Text$', '')
local Element = require(PATH .. ".Element") ---@type UIElement
local ui_unit = require(PATH .. ".utils.ui_unit") ---@type ui_unit_utils

local DEFAULT_FONT = love.graphics.newFont(14)

-- Display text. Supports wrapping, shadows, and more.
---@class UIText: UIElement
---@field text string
---@field font love.Font
---@field align_text "left" | "center" | "right"
---@field wrap_text boolean
---@field text_color number[]
---@field text_shadow {x: number, y: number, color: number[]}
local Text = {}
setmetatable(Text, {__index = Element})

---@param specs UIElementSpecs
---@return UIText
function Text:new(specs)
    specs = specs or {}
    local new = Element:new(specs) ---@type UIText
    setmetatable(new, {__index = self})

    new.text = specs.text or ""
    new.font = specs.font or DEFAULT_FONT
    new.align_text  = specs.align_text or "left"
    new.wrap_text   = specs.wrap_text == nil and true or specs.wrap_text
    new.text_color  = specs.text_color or {1, 1, 1}
    new.text_shadow = {x = 0, y = 0, color = {0,0,0,0.5}}

    -- If any part of text shadow is specified we set it's default values to
    -- be visible - Otherwise it's values will make it not visible.
    if specs.text_shadow then
        new.text_shadow.x = specs.text_shadow.x or 2
        new.text_shadow.y = specs.text_shadow.y or 2
        new.text_shadow.color = specs.text_shadow.color or {0,0,0,0.5}
    end

    new:calculate_bounds()
    return new
end

-- TODO: Clean this up.
-- Notes:
--   * Need to be able to work with auto/non-auto dimensions as well as 
--     wrapping / non wrapping.
--   * If set to not wrap, we still need to account for \n characters manually
--     put in place by the user (font:getWrap() will account for these).
---@return number, number
function Text:get_content_dimensions()
    local dimensions = { width = 0, height = 0 }
    local wrap_width = math.huge
    local keys = { "width", "height" }

    -- Handle manually specified dimensions.
    for _, key in ipairs(keys) do
        local spec_dim = self.spec_dimensions[key]
        if spec_dim ~= "auto" then
            local success, type, value = ui_unit.parse(spec_dim)
            if not success then
                error("ContainUI: Text:get_content_dimensions():\nCould not parse spec_dimensions." .. key .. ":\n" .. value)
            end
            if type == "percentage" then
                local parent_bounds = self:get_parent_bounds()
                dimensions[key] = parent_bounds[key] * (value / 100)
            else
                dimensions[key] = value
            end

            if key == "width" and self.wrap_text then
                wrap_width = dimensions[key]
            end
        end
    end

    if self.spec_dimensions.width == "auto" then
        if self.wrap_text then
            local parent_bounds = self:get_parent_bounds()
            wrap_width = parent_bounds.width
        end
        local max_width, _ = self.font:getWrap(self.text, wrap_width)
        dimensions.width = max_width
    end
    if self.spec_dimensions.height == "auto" then
        local _, lines = self.font:getWrap(self.text, wrap_width)
        dimensions.height = #lines * self.font:getHeight()
    end

    return dimensions.width, dimensions.height
end

function Text:draw()
    local wrap_width = self.wrap_text and self.content_bounds.width or math.huge
    local max_width, _ = self.font:getWrap(self.text, wrap_width)
    wrap_width = max_width
    Element.draw(self)
    love.graphics.setFont(self.font)

    local x
    if self.align_text == "left" then
        x = self.content_bounds.x
    elseif self.align_text == "center" then
        x = self.content_bounds.x + self.content_bounds.width / 2 - max_width / 2
    elseif self.align_text == "right" then
        x = self.content_bounds.x + self.content_bounds.width - max_width
    end

    love.graphics.setColor(self.text_shadow.color)
    love.graphics.printf(
        self.text,
        x + self.text_shadow.x,
        self.content_bounds.y + self.text_shadow.y,
        wrap_width,
        self.align_text
    )

    love.graphics.setColor(self.text_color)
    love.graphics.printf(
        self.text,
        x,
        self.content_bounds.y,
        wrap_width,
        self.align_text
    )
end

return Text
