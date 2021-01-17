-- Configurations: Provide default values in case config file is missing
-- Config file is "_powerline_config.lua"
-- Sample config file is "_powerline_config.lua.sample"

------
-- Core file, and addon files
------
-- Prompt consists of multiple segments. Each segment consists of:
-- * Whether a segment should be added or not
-- * Text
-- * Color indicating status

-- There's a core file that contain basic info and functions
-- Then, each type of segment should have its own 'addon' file
-- One file for Git segment, Hg segment, Node.js, Python, etc.

-- Info shared between segments
-- * Current fill color
-- * Current text color
-- * Current prompt value

-- Functions used by all 'addon' code will go into the core file
-- * addSegment(text, forecolor, backcolor)
--      Because core file keeps track of current colors, it can attach segments with the correct colors without addon files needing to manage this on their own

-- In all 'addon' files:
-- * Segment object with these properties:
---- * isNeeded: specifies whether a segment should be added or not. For example: no Git segment is needed in a non-git folder
---- * text
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue
-- Function in all 'addon' files
---- * init: Sets the properties of the Segment object, and prepares for a segment to be added
---- * addAddonSegment: uses the segment properties to add a new segment to the prompt
-- * Must call clink.prompt.register_filter and pass addAddonSegment

-- ANSI Escape Character
ansiEscChar = "\x1b"
-- ANSI Foreground Colors
ansiFgBold = "1"
ansiFgClrDefault = "39"
ansiFgClrBlack = "30"
ansiFgClrRed = "31"
ansiFgClrGreen = "32"
ansiFgClrYellow = "33"
ansiFgClrBlue = "34"
ansiFgClrMagenta = "35"
ansiFgClrCyan = "36"
ansiFgClrWhite = "37"
ansiFgClrBrightBlack = "90"
ansiFgClrBrightRed = "91"
ansiFgClrBrightGreen = "92"
ansiFgClrBrightYellow = "93"
ansiFgClrBrightBlue = "94"
ansiFgClrBrightMagenta = "95"
ansiFgClrBrightCyan = "96"
ansiFgClrBrightWhite = "97"
-- ANSI Background Colors
ansiBgClrDefault = "49"
ansiBgClrBlack = "40"
ansiBgClrRed = "41"
ansiBgClrGreen = "42"
ansiBgClrYellow = "43"
ansiBgClrBlue = "44"
ansiBgClrMagenta = "45"
ansiBgClrCyan = "46"
ansiBgClrWhite = "47"
ansiBgClrBrightBlack = "100"
ansiBgClrBrightRed = "101"
ansiBgClrBrightGreen = "102"
ansiBgClrBrightYellow = "103"
ansiBgClrBrightBlue = "104"
ansiBgClrBrightMagenta = "105"
ansiBgClrBrightCyan = "106"
ansiBgClrBrightWhite = "107"

-- Colors
colorBlack = {
	foreground = ansiFgClrBlack,
	background = ansiBgClrBlack
}
colorRed = {
	foreground = ansiFgClrRed,
	background = ansiBgClrRed
}
colorGreen = {
	foreground = ansiFgClrGreen,
	background = ansiBgClrGreen
}
colorYellow = {
	foreground = ansiFgClrYellow,
	background = ansiBgClrYellow
}
colorBlue = {
	foreground = ansiFgClrBlue,
	background = ansiBgClrBlue
}
colorMagenta = {
	foreground = ansiFgClrMagenta,
	background = ansiBgClrMagenta
}
colorCyan = {
	foreground = ansiFgClrCyan,
	background = ansiBgClrCyan
}
colorWhite = {
	foreground = ansiFgClrWhite,
	background = ansiBgClrWhite
}
colorBrightBlack = {
	foreground = ansiFgClrBrightBlack,
	background = ansiBgClrBrightBlack
}
colorBrightRed = {
	foreground = ansiFgClrBrightRed,
	background = ansiBgClrBrightRed
}
colorBrightGreen = {
	foreground = ansiFgClrBrightGreen,
	background = ansiBgClrBrightGreen
}
colorBrightYellow = {
	foreground = ansiFgClrBrightYellow,
	background = ansiBgClrBrightYellow
}
colorBrightBlue = {
	foreground = ansiFgClrBrightBlue,
	background = ansiBgClrBrightBlue
}
colorBrightMagenta = {
	foreground = ansiFgClrBrightMagenta,
	background = ansiBgClrBrightMagenta
}
colorBrightCyan = {
	foreground = ansiFgClrBrightCyan,
	background = ansiBgClrBrightCyan
}
colorBrightWhite = {
	foreground = ansiFgClrBrightWhite,
	background = ansiBgClrBrightWhite
}

-- Use this with caution; it probably will NOT do what you might want if used
-- with a segment color.
colorDefault = {
	foreground = ansiFgClrDefault,
	background = ansiBgClrDefault
}

-- Variables to maintain prompt state
currentSegments = ""
currentFillColor = colorBlue.background
currentTextColor = colorWhite.foreground

-- Constants
-- Symbols
newLineSymbol = "\n"..ansiEscChar.."[m" -- ESC[m is needed when colour.input is set

-- Default symbols
-- Some symbols are required. If the user fails to provide them in the config file, they're created here
-- Prompt displayed instead of user's home folder e.g. C:\Users\username
plc_prompt_homeSymbol = plc_prompt_homeSymbol or "~"
-- Symbol connecting each segment of the prompt. Be careful before you change this.
plc_prompt_arrowSymbol = plc_prompt_arrowSymbol or ""
-- Symbol displayed in the new line below the prompt.
plc_prompt_lambSymbol = plc_prompt_lambSymbol or "λ"
-- SGR parameters for ANSI color for plc_prompt_lambSymbol.
plc_prompt_lambTextColor = plc_prompt_lambTextColor or ansiFgBold
plc_prompt_lambFillColor = plc_prompt_lambFillColor or ansiBgClrDefault
-- Version control (e.g. Git) branch symbol. Used to indicate the name of a branch.
plc_git_branchSymbol = plc_git_branchSymbol or ""
-- Version control (e.g. Git) conflict symbol. Used to indicate there's a conflict.
plc_git_conflictSymbol = plc_git_conflictSymbol or "!"
-- Version control (e.g. Hg) changes symbol. Used to indicate there's a change.
plc_hg_changesSymbol = plc_hg_changesSymbol or ""

plc_git_addcountSymbol = plc_git_addcountSymbol or "+"
plc_git_modifycountSymbol = plc_git_modifycountSymbol or "*"
plc_git_deletecountSymbol = plc_git_deletecountSymbol or "-"
plc_git_renamecountSymbol = plc_git_renamecountSymbol or "🎃"
plc_git_summarycountSymbol = plc_git_summarycountSymbol or "±"
plc_git_untrackedcountSymbol = plc_git_untrackedcountSymbol or "?"

plc_git_aheadbehindSymbol = plc_git_aheadbehindSymbol or "☁"
plc_git_aheadcountSymbol = plc_git_aheadcountSymbol or "↓"
plc_git_behindcountSymbol = plc_git_behindcountSymbol or "↑"

plc_git_stagedSymbol = plc_git_stagedSymbol or "↗"

plc_battery_levelSymbol = plc_battery_levelSymbol or "%"
plc_battery_chargingSymbol = plc_battery_chargingSymbol or "⚡"

-- Range of priorities.
plc_priority_start = 51
plc_priority_finish = 99

local function bookend_priority(prio)
	if prio <= plc_priority_start then
		return plc_priority_start + 1
	elseif prio >= plc_priority_finish then
		return plc_priority_finish - 1
	else
		return prio
	end
end

-- Segment priorities.
-- Can be defined in _powerline_config.lua to reorder segments.
-- Keep them between plc_priority_start and plc_priority_finish.
plc_priority_battery = bookend_priority(plc_priority_battery or plc_priority_start + 1)
plc_priority_date = bookend_priority(plc_priority_date or plc_priority_start + 2)
plc_priority_prompt = bookend_priority(plc_priority_prompt or 55)
plc_priority_npm = bookend_priority(plc_priority_npm or 60)
plc_priority_versionControl = bookend_priority(plc_priority_versionControl or 61)

---
-- Adds an arrow symbol to the input text with the correct colors
-- text {string} input text to which an arrow symbol will be added
-- oldColor {color} Color of the prompt on the left of the arrow symbol. Use one of the color constants as input.
-- newColor {color} Color of the prompt on the right of the arrow symbol. Use one of the color constants as input.
-- @return {string} text with an arrow symbol added to it
---
local plc_lastArrow_len = 0
function addArrow(text, oldColor, newColor)
	-- Old color is the color of the previous segment
	-- New color is the color of the next segment
	-- An arrow is a character written using the old color on a background of the new color
	local old_len = #text
	text = addTextWithColor(text, plc_prompt_arrowSymbol, oldColor.foreground, newColor.background)
	plc_lastArrow_len = #text - old_len
	return text
end

---
-- Adds text to the input text with the correct colors
-- text {string} input text to which more text will be added
-- textToAdd {string} text to be added with the specified colors
-- textColorValue {number} Foreground color of the newly added text. Provide an ANSI color value.
-- fillColorValue {number} Background color of the newly added text. Provide an ANSI color value.
-- @return {string} concatination of the the two input text with the correct color formatting.
---
function addTextWithColor(text, textToAdd, textColorValue, fillColorValue)
	-- let's say the
	-- fillColorValue is 41
	-- textColorValue is 30
	-- textToAdd is "Hello"
	-- This adds to text \x1b[30;40mHello\x1b[0m
	-- which add Hello with red background and black letters
	-- [0m at the end restore default attributes
	text = text..ansiEscChar.."[0;"..textColorValue..";"..fillColorValue.."m"..textToAdd..ansiEscChar.."[0m"
	return text
end

---
-- Adds a new segment to the prompt with the specified colors.
-- text {string} Text of the new segment to be added to the prompt.
-- textColor {color} Foreground color of the new segment. Use one of the color constants as input.
-- fillColor {color} Background color of the new segment. Use one of the color constants as input.
-- @return {string|nil} New Clink API: return prompt string; old Clink API: set clink.prompt.value.
---
function addSegment(text, textColor, fillColor)
	local newPrompt = ""
	-- If there's an existing segment
	if currentSegments == "" then
		newPrompt = ""
	else
		-- Remove the existing arrow
		newPrompt = string.sub(currentSegments, 0, string.len(currentSegments) - plc_lastArrow_len)
		-- Add arrow with color of new segment
		newPrompt = addArrow(newPrompt, currentFillColor, fillColor)
	end
	-- Write the text with the fill color
	newPrompt = addTextWithColor(newPrompt, text, textColor.foreground, fillColor.background)
	-- Write the closing arrow
	newPrompt = addArrow(newPrompt, fillColor, colorDefault)

	-- Update current values
	currentSegments = newPrompt
	currentFillColor = fillColor
	currentTextColor = textColor

	-- Update clink prompt
	if clink.version_major then
		return newPrompt
	else
		clink.prompt.value = newPrompt
	end
end 

---
-- Resets the prompt and all state variables
---
resetPrompt = nil
if not clink.version_major then
	resetPrompt = function ()
		clink.prompt.value = ""
		currentSegments = ""
		currentFillColor = colorBlue
		currentTextColor = colorWhite
	end
end

---
-- Closes the prompts with a new line and the lamb symbol
---
closePrompt = nil
if not clink.version_major then
	closePrompt = function ()
		clink.prompt.value = clink.prompt.value..newLineSymbol..ansiEscChar.."[0;"..plc_prompt_lambTextColor..";"..plc_prompt_lambFillColor.."m"..plc_prompt_lambSymbol.." "
	end
end

---
-- Gets the parent directory for specified entry (either file or directory),
-- or "" if not possible.
---
function toParent(dir)
	local prefix = ""
	if dir == nil then dir = '.' end
	if dir == '.' then dir = clink.get_cwd() end
	if (clink.version_encoded or 0) >= 10010020 then
		-- Clink v1.1.20 and higher provide an API to do this right.
		local child
		prefix,child = path.toparent(dir)
		if child == "" then
			prefix = ""
		end
	else
		-- This approach has several bugs. For example, "c:/" yields "c".
		-- So walking up looking for .git or .hg tries "c:/.git" and then
		-- tries "c/.git".
		local i = dir:find("[\\/:][^\\/:]*$")
		if i then
			prefix = dir:sub(1, i-1)
		end
	end
	return prefix
end

---
-- Joins path components.
---
function joinPaths(lhs, rhs)
	if (clink.version_encoded or 0) >= 10010020 then
		return path.join(lhs, rhs)
	else
		return lhs..'/'..rhs
	end
end

---
-- Gets the .git directory
-- copied from clink.lua
-- clink.lua is saved under %CMDER_ROOT%\vendor
-- @return {bool} indicating there's a git directory or not
---
function get_git_dir(path)

	-- Checks if provided directory contains git directory
	local function has_git_dir(dir)
			local dotgit = joinPaths(dir, '.git')
			return clink.is_dir(dotgit) and dotgit
	end

	local function has_git_file(dir)
			dotgit = joinPaths(dir, '.git')
			local gitfile
			if (clink.version_encoded or 0) >= 10010000 then
				-- More efficient than unconditionally opening the file.
				if os.isfile(dotgit) then
					gitfile = io.open(dotgit)
				end
			else
				gitfile = io.open(dotgit)
			end
			if not gitfile then return false end

			local git_dir = gitfile:read():match('gitdir: (.*)')
			gitfile:close()

			-- gitdir can (apparently) be absolute or relative:
			local file_when_absolute = git_dir and clink.is_dir(git_dir) and git_dir
			if file_when_absolute then
				-- don't waste time calling clink.is_dir on a potentially
				-- relative path if we already know it's an absolute path.
				return file_when_absolute
			end
			local rel_dir = joinPaths(dir, git_dir)
			local file_when_relative = git_dir and clink.is_dir(rel_dir) and rel_dir
			if file_when_relative then
				return file_when_relative
			end
	end

	-- Set default path to current directory
	if not path or path == '.' then path = clink.get_cwd() end

	-- Calculate parent path now otherwise we won't be
	-- able to do that inside of logical operator
	local parent_path = toParent(path)

	return has_git_dir(path)
			or has_git_file(path)
			-- Otherwise go up one level and make a recursive call
			or (parent_path ~= "" and get_git_dir(parent_path) or nil)
end

-- Register filters for resetting the prompt and closing it before and after all addons
if not clink.version_major then

	-- Old Clink API (v0.4.x)
	clink.prompt.register_filter(resetPrompt, plc_priority_start)
	clink.prompt.register_filter(closePrompt, plc_priority_finish)

else

	-- New Clink API (v1.x)
	resetPrompt = clink.promptfilter(plc_priority_start)
	closePrompt = clink.promptfilter(plc_priority_finish)

	---
	-- Resets the prompt and all state variables
	---
	function resetPrompt:filter(prompt)
		currentSegments = ""
		currentFillColor = colorBlue
		currentTextColor = colorWhite
		return ""
	end

	---
	-- Closes the prompts with a new line and the lamb symbol
	---
	function closePrompt:filter(prompt)
		local useLamb = plc_prompt_useLambSymbol
		if useLamb == nil then
			useLamb = true
		end
		if plc_date_position == "above" or plc_date_position == "right" then
			prompt = plc_build_date_prompt(prompt)
		end
		if useLamb then
			return prompt..newLineSymbol..ansiEscChar.."[0;"..plc_prompt_lambTextColor..";"..plc_prompt_lambFillColor.."m"..plc_prompt_lambSymbol.." "
		else
			return prompt.." "
		end
	end

end
