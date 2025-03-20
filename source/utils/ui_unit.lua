
-- The user can specify certain units as pixel values or percentages.
-- Percentages are relative to the parent's bounds.
---@alias ui_unit
---| string
---| number

---@class ui_unit_utils
local ui_unit = {}

-- Ensure a value is a proper ui_unit. Returns nil if valid, or an error message
-- if not.
---@param unit ui_unit
---@return string | nil - Error message or nil if valid.
function ui_unit.validate(unit)
    if type(unit) == "number" then
        return nil
    end

    if type(unit) ~= "string" then
        return "Unit must be a number or string"
    end

    if not string.sub(unit, -1) == "%" then
        return "String unit must end with % symbol"
    end

    local num_str = string.sub(unit, 1, -2)
    local value = tonumber(num_str)
    if not value then
        return "Could not convert to a number.\nMake sure it's a number or a valid percentage string (\"100%\", \"52%\", etc)"
    end

    return nil
end

-- First return value is whether or not there was an error.
-- Second is either the type of unit or the error message.
-- Third is the value or the unit (as a number).
---@param unit ui_unit
---@return boolean, "pixel" | "percentage" | string, number | nil
function ui_unit.parse(unit)
    local err = ui_unit.validate(unit)
    if err then return false, err, nil end

    if type(unit) == "string" and tonumber(unit) ~= nil then
        return true, "pixel", tonumber(unit)
    elseif type(unit) == "string" and unit:sub(-1) == "%" then
        return true, "percentage", tonumber(unit:sub(1, -2))
    end

    return true, "pixel", unit
end

return ui_unit

