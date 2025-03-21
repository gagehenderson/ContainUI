-- Function for validating user specifications.
--
-- Specifications represent how the user wants an element to look / behave, and
-- may not necessary reflect the actual state of the element.
--
-- They are used when instantiating or updating an element.
-- (e.g. `Element:new(specs_go_here)`)
--
-- This function compares provided specifications to a sort of "spec definition"
-- that describes what the user specified ones should look like.
--
-- Basically ensuring types and values are correct (to a degree), hopefully
-- helping the user understand how to properly specify what they want!
--
-- Could obviously be more robust, but I think it does a good enough job of
-- guiding the user to make sure they are using the right types and values.
--
-- As of writing, there is only one spec definition (ElementSpecs.lua), which 
-- includes every possible spec for every element - But in the future, it may
-- make sense to split them up.

local PATH    = (...):gsub('%.validate_specs$', '')
local ui_unit = require(PATH .. ".ui_unit")

---@param specs UIElementSpecs
---@param spec_def table
---@param path string
---@return string | nil - Error message or nil if valid.
local function validate_specs(specs, spec_def, path)
    path = path or ""

    for key, def in pairs(spec_def) do
        local value = specs[key]

        if value == nil then
            if not def._optional then
                return ("Missing required field: %s%s"):format(path, key)
            end
        else
            local valid_type = false
            for _, expected_type in ipairs(def.types or {}) do
                if type(value) == expected_type then
                    valid_type = true
                    break
                elseif expected_type == "ui_unit" then
                    local err = ui_unit.validate(value)
                    if not err then
                        valid_type = true
                        break
                    end
                end
            end

            if not valid_type then
                return ("Invalid type for %s%s. Expected %s, got %s")
                    :format(path, key, table.concat(def.types, " or "), type(value) or "(Unable to determine type)")
            end

            if def.valid_values then
                local found = false
                for _, valid in ipairs(def.valid_values) do
                    if value == valid then
                        found = true
                        break
                    end
                end
                if not found then
                    return ("Invalid value for %s%s. Expected one of [%s], got '%s'")
                        :format(path, key, table.concat(def.valid_values, ", "), tostring(value))
                end
            end

            if def.values and type(value) == "table" then
                local err = validate_specs(value, def.values, path .. key .. ".")
                if err then return err end
            end
        end
    end
end

return validate_specs
