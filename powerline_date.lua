plc_date = {}
plc_date.priority = plc_priority_start + 2
plc_date.allow_refresh = false          -- false keeps the date/time from changing until the next input line.
plc_date.position = "normal"            -- Position:  "normal", "above", "below", or "right".
plc_date.format = nil                   -- nil auto-selects date format based on plc_date.position.

plc_date.textColor = colorBlack
plc_date.fillColor = colorBrightBlack

plc_date.above_textColor = colorDefault
plc_date.above_fillColor = colorDefault

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

plc.addModule(init, plc_date)
