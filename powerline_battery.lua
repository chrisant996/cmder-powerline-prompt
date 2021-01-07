local segment_priority = plc_priority_battery or 52 -- Can't use plc_priority_start+1 because of Lua load order.

---
-- Also called from powerline_date.lua
---
function plc_get_battery_status()
    local level, charging
    local batt_symbol = plc_battery_levelSymbol

	if (clink.version_encoded or 0) >= 10010020 then
		local status = os.getbatterystatus()
		level = status.level
		charging = status.charging
	elseif (clink.version_encoded or 0) >= 10010017 then
		local acpower, batterysaver
		level,acpower,charging,batterysaver = os.getbatterystatus()
	else
		local windir = os.getenv("SystemRoot")
		if not windir or window == "" then
			windir = ""
		else
			windir = path.join(windir, "System32\\wbem\\")
		end

		for line in io.popen(windir..'wmic.exe Path Win32_Battery Get EstimatedChargeRemaining'):lines() do
			if tonumber(line) then
				level = tonumber(line)
			end
		end
		if level then
			for line in io.popen(windir..'wmic.exe /Namespace:"\\\\root\\wmi" Path BatteryStatus Get Charging'):lines() do
				if line:match("TRUE") then
					charging = true
				end
			end
		end
	end

	if not level or level < 0 then
		return "", 0
	end
	if charging then
		batt_symbol = plc_battery_chargingSymbol
	end

    return level..batt_symbol, level
end

function plc_colorize_battery_status(status, level, textRestoreColor, fillRestoreColor)
	local levelColor
	if level > (plc_battery_mediumLevel or 40) then
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
	elseif clink.version_major then
		resetColor = settings.get("color.prompt")
	end
	if not resetColor or resetColor == "" then
		resetColor = "\x1b[m"
	end

	return levelColor..status..resetColor
end

local function build_prompt(prompt)
	if (plc_battery_showLevel or 0) <= 0 or (plc_battery_withDate and plc_date_position) then
		return prompt
	end

	local batteryStatus,level = plc_get_battery_status()
	if not batteryStatus or batteryStatus == "" or level > plc_battery_showLevel then
		return prompt
	end

	batteryStatus = " "..batteryStatus.." "

	local textColor = colorBlack
	local fillColor = colorRed
	if level > (plc_battery_mediumLevel or 40) then
		fillColor = colorGreen
	elseif level > (plc_battery_lowLevel or 20) then
		fillColor = colorYellow
	end

	addSegment(batteryStatus, textColor, fillColor)
	return addSegment("", colorWhite, colorBlack)
end

if not clink.version_major then

	-- Old Clink API (v0.4.x)
	addAddonSegment = function ()
		clink.prompt.value = build_prompt(clink.prompt.value)
	end
	clink.prompt.register_filter(addAddonSegment, segment_priority)

else

	-- New Clink API (v1.x)
	local date_prompt = clink.promptfilter(segment_priority)
	function date_prompt:filter(prompt)
		return build_prompt(prompt)
	end

end
