local segment_priority

if plc_date_position == "above" then
	segment_priority = plc_priority_finish + 1
	plc_date_format = plc_date_format or "%a %x  %X"
elseif plc_date_position == "left" then
	segment_priority = plc_priority_start + 2
	plc_date_format = plc_date_format or "%a %H:%M"
elseif plc_date_position == "right" then
	segment_priority = plc_priority_finish - 1
	plc_date_format = plc_date_format or "%a %H:%M"
elseif plc_date_position == "priority" then
	segment_priority = plc_priority_date or (plc_priority_first + 1)
	plc_date_format = plc_date_format or "%a %H:%M"
end

local function build_prompt(prompt)
	local batteryStatus,level
	if plc_battery_showLevel and plc_battery_withDate then
		batteryStatus,level = get_battery_status()
		if batteryStatus and level > plc_battery_showLevel then
			batteryStatus = ""
		end
	end
	if not batteryStatus then
		batteryStatus = ""
	end

	if plc_date_position == "above" then
		if batteryStatus ~= "" then
			batteryStatus = colorize_battery_status(batteryStatus.."  ", level)
		end
		return batteryStatus..os.date(plc_date_format)..newLineSymbol..prompt
	elseif plc_date_position == "right" then
		if batteryStatus ~= "" then
			batteryStatus = colorize_battery_status(batteryStatus.."  ", level)
		end
		return addSegment("  "..batteryStatus..os.date(plc_date_format), colorWhite, colorBlack)
	else
		if batteryStatus ~= "" then
			batteryStatus = colorize_battery_status(" "..batteryStatus.." ", level, colorBlack, colorBrightBlack)
		end
		return addSegment(batteryStatus.." "..os.date(plc_date_format).." ", colorBlack, colorBrightBlack)
	end
end

if segment_priority then
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
end
