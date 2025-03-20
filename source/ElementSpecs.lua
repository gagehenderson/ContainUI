-- See: utils/validate_specs.lua for more information about specifications.

---@class UIElementSpecs
---@field text? string
---@field font? love.Font|userdata
---@field align_text? "left" | "center" | "right"
---@field wrap_text? boolean
---@field text_color? number[]
---@field element_spacing? number
---@field layout_direction? "horizontal" | "vertical"
---@field align_children? "start" | "center" | "end"
---@field justify_children? "start" | "center" | "end"
---@field text_shadow? {x?: number, y?: number, color?: number[]}
---@field box_shadow? {x?: number, y?: number, color?: number[], extra_width?: number, extra_height?: number}
---@field background? {image?: love.Image|userdata, color?: number[], scale_mode?: "cover" | "contain",  position?: {x?: ui_unit, y?: ui_unit}, size?: {x?: ui_unit, y?: ui_unit}}
---@field position? {x?: ui_unit, y?: ui_unit}
---@field dimensions? {width?: ui_unit, height?: ui_unit}
---@field border? {width?: number, radius?: number, color?: number[]}
---@field padding? {x?: number, y?: number, left?: number, right?: number, top?: number, bottom?: number}
---@field margin? {x?: number, y?: number, left?: number, right?: number, top?: number, bottom?: number}
---@field offset? {x?: ui_unit, y?: ui_unit}

return {
    text = { _optional = true, types = {"string"} },
    font = { _optional = true, types = {"userdata"} },
    align_text = {
        _optional = true,
        types = {"string"},
        valid_values = { "left", "center", "right" }
    },
    wrap_text = { _optional = true, types = {"boolean"} },
    text_color = { _optional = true, types = {"table"} },
    element_spacing = { _optional = true, types = {"number"} },
    layout_direction = {
        _optional = true,
        types = {"string"},
        valid_values = { "horizontal", "vertical" }
    },
    align_children = {
        _optional = true,
        types = {"string"},
        valid_values = { "start", "center", "end" }
    },
    justify_children = {
        _optional = true,
        types = {"string"},
        valid_values = { "start", "center", "end" }
    },
    text_shadow = {
        _optional = true,
        types = {"table"},
        values = {
            x = {
                _optional = true,
                types = {"number"},
            },
            y = {
                _optional = true,
                types = {"number"},
            },
            color = {
                _optional = true,
                types = {"table"},
            },
        }
    },
    box_shadow = {
        _optional = true,
        types = {"table"},
        values = {
            x = {
                _optional = true,
                types = {"number"},
            },
            y = {
                _optional = true,
                types = {"number"},
            },
            color = {
                _optional = true,
                types = {"table"},
            },
            extra_width = {
                _optional = true,
                types = {"number"},
            },
            extra_height = {
                _optional = true,
                types = {"number"},
            },
        }
    },
    background = {
        _optional = true,
        types = {"table"},
        values = {
            image = {
                _optional = true,
                types = {"userdata"},
            },
            color = {
                _optional = true,
                types = {"table"},
            },
            scale_mode = {
                _optional = true,
                types = {"string"},
                valid_values = { "contain", "cover" },
            },
            position = {
                _optional = true,
                types = {"table"},
                values = {
                    x = {
                        _optional = true,
                        types = {"ui_unit"},
                    },
                    y = {
                        _optional = true,
                        types = {"ui_unit"},
                    },
                }
            },
            size = {
                _optional = true,
                types = {"table"},
                values = {
                    x = {
                        _optional = true,
                        types = {"ui_unit"},
                    },
                    y = {
                        _optional = true,
                        types = {"ui_unit"},
                    },
                }
            },
        }
    },
    position = {
        _optional = true,
        types = {"table"},
        values = {
            x = {
                _optional = true,
                types = {"ui_unit"},
            },
            y = {
                _optional = true,
                types = {"ui_unit"},
            }
        }
    },
    dimensions = {
        _optional = true,
        types = {"table"},
        values = {
            width = {
                _optional = true,
                types = {"ui_unit", "string"},
            },
            height = {
                _optional = true,
                types = {"ui_unit", "string"},
            }
        }
    },
    border = {
        _optional = true,
        types = {"table"},
        values = {
            width = {
                _optional = true,
                types = {"number"},
            },
            radius = {
                _optional = true,
                types = {"number"},
            },
            color = {
                _optional = true,
                types = {"table"},
            },
        }
    },
    padding = {
        _optional = true,
        types = {"table"},
        values = {
            x = {
                _optional = true,
                types = {"number"},
            },
            y = {
                _optional = true,
                types = {"number"},
            },
            left = {
                _optional = true,
                types = {"number"},
            },
            right = {
                _optional = true,
                types = {"number"},
            },
            top = {
                _optional = true,
                types = {"number"},
            },
            bottom = {
                _optional = true,
                types = {"number"},
            }
        }
    },
    margin = {
        _optional = true,
        types = {"table"},
        values = {
            x = {
                _optional = true,
                types = {"number"},
            },
            y = {
                _optional = true,
                types = {"number"},
            },
            left = {
                _optional = true,
                types = {"number"},
            },
            right = {
                _optional = true,
                types = {"number"},
            },
            top = {
                _optional = true,
                types = {"number"},
            },
            bottom = {
                _optional = true,
                types = {"number"},
            }
        }
    },
    offset = {
        _optional = true,
        types = {"table"},
        values = {
            x = {
                _optional = true,
                types = {"ui_unit"},
            },
            y = {
                _optional = true,
                types = {"ui_unit"},
            }
        }
    },
}
