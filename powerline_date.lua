local segment_priority = plc_priority_date or 54

function plc_build_date_prompt(prompt)
	if plc_date_position ~= "above" and
			plc_date_position ~= "normal" and
			plc_date_position ~= "right" then
		return prompt
	end

	local batteryStatus,level
	if plc_battery_showLevel and plc_battery_withDate then
		batteryStatus,level = plc_get_battery_status()
		if batteryStatus and level > plc_battery_showLevel then
			batteryStatus = ""
		end
	end
	if not batteryStatus then
		batteryStatus = ""
	end

	local date_format = plc_date_format or (((plc_date_position == "above") and "%a %x  %X") or "%a %H:%M")

	if plc_date_position == "above" then
		if batteryStatus ~= "" then
			batteryStatus = plc_colorize_battery_status(batteryStatus.."  ", level)
		end
		return batteryStatus..os.date(plc_date_format)..newLineSymbol..prompt
	elseif plc_date_position == "right" then
		if batteryStatus ~= "" then
			batteryStatus = plc_colorize_battery_status(batteryStatus.."  ", level)
		end
		return addSegment("  "..batteryStatus..os.date(plc_date_format), colorWhite, colorBlack)
	else
		if batteryStatus ~= "" then
			batteryStatus = plc_colorize_battery_status(" "..batteryStatus.." ", level, colorBlack, colorBrightBlack)
		end
		return addSegment(batteryStatus.." "..os.date(plc_date_format).." ", colorBlack, colorBrightBlack)
	end
end

if not clink.version_major then

	-- Old Clink API (v0.4.x)
	addAddonSegment = function ()
		if plc_date_position == "normal" then
			clink.prompt.value = plc_build_date_prompt(clink.prompt.value)
		end
	end
	clink.prompt.register_filter(addAddonSegment, segment_priority)

else

	-- New Clink API (v1.x)
	local date_prompt = clink.promptfilter(segment_priority)
	function date_prompt:filter(prompt)
		if plc_date_position == "normal" then
			return plc_build_date_prompt(prompt)
		end
	end

end
