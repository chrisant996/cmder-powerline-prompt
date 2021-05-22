plc_battery = {}
plc_battery.priority = plc_priority_start + 1

---
-- Also called from powerline_date.lua
---
function plc_get_battery_status()
	local level, acpower, charging
	local batt_symbol = plc_battery_levelSymbol

	local status = os.getbatterystatus()
	level = status.level
	acpower = status.acpower
	charging = status.charging

	if not level or level < 0 or (acpower and not charging) then
		return "", 0
	end
	if charging then
		batt_symbol = plc_battery_chargingSymbol
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
	if plc_battery_mediumLevel or plc_battery_lowLevel then
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
	elseif level > (plc_battery_mediumLevel or 40) then
		levelColor = ""
	elseif level > (plc_battery_lowLevel or 20) then
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

---
-- Builds the segment content.
---
local function init()
	if (plc_battery_showLevel or 0) <= 0 or (plc_battery_withDate and plc_date_position) then
		return
	end

	local batteryStatus,level = plc_get_battery_status()
	if not batteryStatus or batteryStatus == "" or level > plc_battery_showLevel then
		return
	end

	batteryStatus = " "..batteryStatus.." "

	local textColor = colorBlack
	local fillColor = colorRed
	if can_use_fancy_colors() then
		fillColor = get_battery_status_color(level)
	elseif level > (plc_battery_mediumLevel or 40) then
		fillColor = colorGreen
	elseif level > (plc_battery_lowLevel or 20) then
		fillColor = colorYellow
	end

	plc.addSegment(batteryStatus, textColor, fillColor)
	plc.addSegment("", colorWhite, colorBlack)
end

---
-- Register this addon with Clink
---
plc.add_module(init, plc_battery)
