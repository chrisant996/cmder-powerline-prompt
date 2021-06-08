plc_battery = {}

local function init_config()
    plc_battery.priority = plc_battery.priority or plc_priority_battery or (plc_priority_start + 1)

    -- Options.
    plc_battery.withDate = plc.bool_config(plc_battery.withDate, plc_battery_withDate, false)
    plc_battery.showLevel = plc_battery.showLevel or plc_battery_showLevel
    plc_battery.lowLevel = plc_battery.lowLevel or plc_battery_lowLevel
    plc_battery.mediumLevel = plc_battery.mediumLevel or plc_battery_mediumLevel
    plc_battery.idle_refresh = (plc_battery.idle_refresh or plc_battery.idle_refresh == nil) -- Default is true.
    plc_battery.refresh_interval = plc_battery.refresh_interval or 15

    -- Symbols.
    plc_battery.levelSymbol = plc_battery.levelSymbol or plc_battery_levelSymbol or "%"
    plc_battery.chargingSymbol = plc_battery.chargingSymbol or plc_battery_chargingSymbol or "⚡"
end

---
-- Also called from powerline_date.lua
---
function plc_get_battery_status()
    local level, acpower, charging
    local batt_symbol = plc_battery.levelSymbol

    local status = os.getbatterystatus()
    level = status.level
    acpower = status.acpower
    charging = status.charging

    if not level or level < 0 or (acpower and not charging) then
        return "", 0
    end
    if charging then
        batt_symbol = plc_battery.chargingSymbol
    end

    return level..batt_symbol, level
end

local rainbow_rgb =
{
    {
        foreground = "38;2;239;65;54",
        background = "48;2;239;65;54"
    },
    {
        foreground = "38;2;252;176;64",
        background = "48;2;252;176;64"
    },
    {
        foreground = "38;2;248;237;50",
        background = "48;2;248;237;50"
    },
    {
        foreground = "38;2;142;198;64",
        background = "48;2;142;198;64"
    },
    {
        foreground = "38;2;1;148;68",
        background = "48;2;1;148;68"
    }
}

local function get_battery_status_color(level)
    local index = ((((level > 0) and level or 1) - 1) / 20) + 1
    index = math.modf(index)
    return rainbow_rgb[index]
end

local function can_use_fancy_colors()
    if plc_battery.mediumLevel or plc_battery.lowLevel then
        return false
    elseif not clink.getansihost then
        return false
    else
        local host = clink.getansihost()
        if host == "conemu" or host == "winconsolev2" or host == "winterminal" then
            return true;
        end
        return false
    end
end

function plc_colorize_battery_status(status, level, textRestoreColor, fillRestoreColor)
    local levelColor
    if can_use_fancy_colors() then
        local clr = get_battery_status_color(level)
        if textRestoreColor then
            levelColor = "\x1b[0;"..clr.background..";"..colorBlack.foreground.."m"
        else
            levelColor = "\x1b["..clr.foreground.."m"
        end
    elseif level > (plc_battery.mediumLevel or 40) then
        levelColor = ""
    elseif level > (plc_battery.lowLevel or 20) then
        if textRestoreColor then
            levelColor = "\x1b[0;"..colorYellow.background..";"..colorBlack.foreground.."m"
        else
            levelColor = "\x1b["..colorBrightYellow.foreground.."m"
        end
    else
        if textRestoreColor then
            levelColor = "\x1b[0;"..colorRed.background..";"..colorBlack.foreground.."m"
        else
            levelColor = "\x1b["..colorBrightRed.foreground.."m"
        end
    end

    local resetColor
    if textRestoreColor and fillRestoreColor then
        resetColor = "\x1b[0;"..fillRestoreColor.background..";"..textRestoreColor.foreground.."m"
    else
        resetColor = settings.get("color.prompt")
    end
    if not resetColor or resetColor == "" then
        resetColor = "\x1b[m"
    end

    return levelColor..status..resetColor
end

local prev_status, prev_level
local function update_battery_prompt()
    while true do
        local status,level = plc_get_battery_status()
        if prev_status ~= status or prev_level ~= level then
            clink.refilterprompt()
        end
        coroutine.yield()
    end
end

---
-- Builds the segment content.
---
local function init()
    if (plc_battery.showLevel or 0) <= 0 or (plc_battery.withDate and plc_date.position) then
        return
    end

    local batteryStatus,level = plc_get_battery_status()
    prev_status = batteryStatus
    prev_level = level

    if clink.addcoroutine and plc_battery.idle_refresh and not plc.cached_state.battery_coroutine then
        local t = coroutine.create(update_battery_prompt)
        plc.cached_state.battery_coroutine = t
        clink.addcoroutine(t, plc_battery.refresh_interval)
    end

    if not batteryStatus or batteryStatus == "" or level > plc_battery.showLevel then
        return
    end

    batteryStatus = " "..batteryStatus.." "

    local textColor = colorBlack
    local fillColor = colorRed
    if can_use_fancy_colors() then
        fillColor = get_battery_status_color(level)
    elseif level > (plc_battery.mediumLevel or 40) then
        fillColor = colorGreen
    elseif level > (plc_battery.lowLevel or 20) then
        fillColor = colorYellow
    end

    plc.addSegment(batteryStatus, textColor, fillColor)
    plc.addSegment("", colorWhite, colorBlack)
end

---
-- Register this addon with Clink
---
plc_battery.init = init_config
plc.addModule(init, plc_battery)
