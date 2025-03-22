local PATH    = (...):gsub('%.Container$', '')
local Element = require(PATH .. ".Element") ---@type UIElement
local ui_unit = require(PATH .. ".utils.ui_unit") ---@type ui_unit_utils

-- The primary building block for all UIs. Used to layout child elements.
-- Supports custom spacing, directions, alignment, and more.
---@class UIContainer: UIElement
---@field __is_container boolean Used by parent containers to determine if this is a container.
---@field children UIElement[] | UIText[] | UIContainer[]
---@field child_bounds {max_width: number, max_height: number, total_width: number, total_height: number}
---@field element_spacing number
---@field layout_direction "horizontal" | "vertical"
---@field align_children "start" | "center" | "end"
---@field justify_children "start" | "center" | "end"
local Container = {}
setmetatable(Container, {__index = Element})

---@param specs UIElementSpecs
---@return UIContainer
function Container:new(specs)
    local new = Element:new(specs) ---@type UIContainer
    setmetatable(new, {__index = self})

    new.__is_container = true
    new.children = {}
    new.element_spacing = specs.element_spacing or 0
    new.child_bounds = {
        max_width    = 0,
        max_height   = 0,
        total_width  = 0,
        total_height = 0,
    }
    new.layout_direction = specs.layout_direction or "vertical"
    new.align_children   = specs.align_children or "start"
    new.justify_children = specs.justify_children or "start"

    new:calculate_bounds()
    return new
end

---@return number, number
function Container:get_content_dimensions()
    ---@diagnostic disable: cast-local-type
    local dimensions = { width = 0, height = 0 }

    for dim, _ in pairs(dimensions) do
        if self.spec_dimensions[dim] == "auto" then
            if self.layout_direction == "vertical" then
                if dim == "width" then
                    dimensions.width = self.child_bounds.max_width
                else
                    dimensions.height = self.child_bounds.total_height
                end
            elseif self.layout_direction == "horizontal" then
                if dim == "width" then
                    dimensions.width = self.child_bounds.total_width
                else
                    dimensions.height = self.child_bounds.max_height
                end
            end
        else
            local success, type, value = ui_unit.parse(self.spec_dimensions[dim])
            if not success then
                error(("Error parsing %s: %s"):format(dim, type))
            end
            if type == "percentage" then
                local parent_bounds = self:get_parent_bounds()
                dimensions[dim] = parent_bounds[dim] * (value / 100)
            else
                dimensions[dim] = value
            end
        end
    end

    return dimensions.width, dimensions.height
    ---@diagnostic enable: cast-local-type
end

---@param child UIElement | UIText 
function Container:add_child(child)
    self:_validate_child(child)

    child.parent = self

    table.insert(self.children, child)

    child:calculate_bounds()
    self:_calc_child_bounds(child, true) -- TODO: Better name for this...
    self:calculate_bounds()
    self:update_layout()
end


---@param ... UIElement | UIText
function Container:add_children(...)
    for _, child in ipairs({...}) do
        self:add_child(child)
    end
end

function Container:update(dt)
end
function Container:draw()
    Element.draw(self)
    for _, child in ipairs(self.children) do
        child:draw()
    end
end
function Container:mousepressed(x, y, button)
    for _, child in ipairs(self.children) do
        if child.mousepressed then
            child:mousepressed(x, y, button)
        end
    end
end
function Container:keypressed(key)
    for _, child in ipairs(self.children) do
        if child.keypressed then
            child:keypressed(key)
        end
    end
end
function Container:textinput(text)
    for _, child in ipairs(self.children) do
        if child.textinput then
            child:textinput(text)
        end
    end
end
function Container:wheelmoved(x, y)
end

---@param child UIElement | UIText
function Container:_validate_child(child)
    if not child.draw then
        error("Container:add_child(): Child does not have a draw() method.")
    end
    if not child.get_content_dimensions then
        error("Container:add_child(): Child does not have a get_content_dimensions() method.")
    end
end

-- TODO: Clean this up, can do some mapping of coords/directions/dimensions so
-- we don't have to repeat the same code for vertical and horizontal layouts.
--
-- When updating our layout, we also need to update any child container's layouts.
function Container:update_layout()
    if self.layout_direction == "vertical" then
        local y
        if self.justify_children == "start" then
            y = self.content_bounds.y
        elseif self.justify_children == "center" then
            y = self.content_bounds.y + self.content_bounds.height / 2 - self.child_bounds.total_height / 2
        elseif self.justify_children == "end" then
            y = self.content_bounds.y + self.content_bounds.height - self.child_bounds.total_height
        end
        for _, child in ipairs(self.children) do
            local x

            if self.align_children == "start" then
                x = self.content_bounds.x
            elseif self.align_children == "center" then
                x = self.content_bounds.x + self.content_bounds.width / 2 - child.padding_bounds.width / 2
            elseif self.align_children == "end" then
                x = self.content_bounds.x + self.content_bounds.width - child.padding_bounds.width
            end

            child:set_position(x, y)

            y = y + child.padding_bounds.height + self.element_spacing
        end
    elseif self.layout_direction == "horizontal" then
        local x
        if self.justify_children == "start" then
            x = self.content_bounds.x
        elseif self.justify_children == "center" then
            x = self.content_bounds.x + self.content_bounds.width / 2 - self.child_bounds.total_width / 2
        elseif self.justify_children == "end" then
            x = self.content_bounds.x + self.content_bounds.width - self.child_bounds.total_width
        end

        for _, child in ipairs(self.children) do
            local y
            if self.align_children == "start" then
                y = self.content_bounds.y
            elseif self.align_children == "center" then
                y = self.content_bounds.y + self.content_bounds.height / 2 - child.padding_bounds.height / 2
            elseif self.align_children == "end" then
                y = self.content_bounds.y + self.content_bounds.height - child.padding_bounds.height
            end

            child:set_position(x, y)

            x = x + child.padding_bounds.width + self.element_spacing
        end
    end
    for _, child in ipairs(self.children) do
        if child.__is_container then
            child:update_layout()
        end
    end
end

-- We need to calculate these various values for helping us layout our children.
-- ──────────────────────────────────────────────────────────────────────
-- total_width: The width of all children if laid out horizontally.
-- total_height: The height of all children if laid out vertically.
-- max_width: The width of the widest child.
-- max_height: The height of the tallest child.
-- ──────────────────────────────────────────────────────────────────────
-- Instead of calculating this whenever we need them, we can just calculate them
-- whenever a child is added or removed, which is what this function does.
---@param new_child UIElement | UIText
---@param is_added boolean
function Container:_calc_child_bounds(new_child, is_added)
    local new_child_bounds = new_child:get_padding_bounds()
    if is_added then
        self.child_bounds.total_width = self.child_bounds.total_width + new_child_bounds.width
        self.child_bounds.total_height = self.child_bounds.total_height + new_child_bounds.height
    else
        self.child_bounds.total_width = self.child_bounds.total_width - new_child_bounds.width
        self.child_bounds.total_height = self.child_bounds.total_height - new_child_bounds.height
    end

    -- TODO: Make it so we don't have to iterate over all children.
    self.child_bounds.max_width = 0
    self.child_bounds.max_height = 0
    for _, c in ipairs(self.children) do
        local padding_bounds = c:get_padding_bounds()
        self.child_bounds.max_width = math.max(
            self.child_bounds.max_width,
            padding_bounds.width
        )
        self.child_bounds.max_height = math.max(
            self.child_bounds.max_height,
            padding_bounds.height
        )
    end
end

return Container

