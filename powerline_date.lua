plc_date = {}

local function init_config()
    plc_date.priority = plc_date.priority or plc_priority_date or (plc_priority_start + 2)

    -- Colors.
    plc_date.textColor = plc_date.textColor or plc_date_textColor or colorBlack
    plc_date.fillColor = plc_date.fillColor or plc_date_fillColor or colorBrightBlack
    plc_date.above_textColor = plc_date.above_textColor or plc_date_above_textColor or colorDefault
    plc_date.above_fillColor = plc_date.above_fillColor or plc_date_above_fillColor or colorDefault

    -- false keeps the date/time from changing until the next input line.
    plc_date.allow_refresh = plc.bool_config(plc_date.allow_refresh, false)

    -- Position for date segment:
    --      "normal"    Left justified segment.
    --      "right"     Right justified segment.
    --      "above"     Separate text above the powerline prompt.
    --      nil         Don't show the date (the default).
    plc_date.position = plc_date.position or plc_date_position or nil

    -- Date format.  Nil auto-selects date format based on plc_date.position.
    plc_date.format = plc_date.format or plc_date_format or nil
end

local function plc_colorize_date_above(prompt)
    return plc.addTextWithColor("", prompt, plc_date.above_textColor, plc_date.above_fillColor)
end

function plc_build_date_prompt(prompt)
    if plc_date.position ~= "above" and
            plc_date.position ~= "normal" and
            plc_date.position ~= "right" then
        return prompt
    end

    local batteryStatus,level
    if plc_battery.showLevel and plc_battery.withDate then
        batteryStatus,level = plc_get_battery_status()
        if batteryStatus and level > plc_battery.showLevel then
            batteryStatus = ""
        end
    end
    if not batteryStatus then
        batteryStatus = ""
    end

    local date_format = plc_date.format
    if not date_format then
        if plc_date.position == "above" then
            date_format = "%a %x  %X"
        else
            date_format = "%a %H:%M"
        end
    end

    local date_text = (not plc_date.allow_refresh and plc.cached_state.date_text) or os.date(date_format)
    plc.cached_state.date_text = date_text

    if plc_date.position == "above" then
        if batteryStatus ~= "" then
            batteryStatus = plc_colorize_battery_status(batteryStatus.."  ", level)
        end
        return batteryStatus..plc_colorize_date_above(date_text)..newLineSymbol..prompt
    else
        if batteryStatus ~= "" then
            batteryStatus = plc_colorize_battery_status(" "..batteryStatus.." ", level, plc_date.textColor, plc_date.fillColor)
        end
        return plc.addSegment(batteryStatus.." "..date_text.." ", plc_date.textColor, plc_date.fillColor, (plc_date.position == "right"))
    end
end

local function init()
    if plc_date.position ~= "above" then
        plc_build_date_prompt()
    end
end

plc_date.init = init_config
plc.addModule(init, plc_date)
