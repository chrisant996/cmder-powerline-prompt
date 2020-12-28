local date_prompt_priority

if plc_date_position == "above" then
	date_prompt_priority = 150
	plc_date_format = plc_date_format or "%a %x  %X"
elseif plc_date_position == "left" then
	date_prompt_priority = 52 -- after prompt_pushd_depth
	plc_date_format = plc_date_format or "%a %H:%M"
elseif plc_date_position == "right" then
	date_prompt_priority = 98
	plc_date_format = plc_date_format or "%a %H:%M"
end

if date_prompt_priority then

	local date_prompt = clink.promptfilter(date_prompt_priority)
	function date_prompt:filter(prompt)
		if plc_date_position == "above" then
			return os.date(plc_date_format)..newLineSymbol..prompt
		elseif plc_date_position == "left" then
			return addSegment(" "..os.date(plc_date_format).." ", colorBlack, colorBrightBlack)
		else
			return addSegment("  "..os.date(plc_date_format), colorWhite, colorBlack)
		end
	end

end
