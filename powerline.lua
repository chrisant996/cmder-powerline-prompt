-- Configurations: Provide default values in case config file is missing.
-- Config file is ".powerline_config.lua".
-- Sample config file is ".powerline_config.lua.sample".
--
-- The "." prefix is important so that the config file is loaded first.

------
-- Core file, and addon files
------
-- The core functions keep track of current colors so it can attach segments
-- with the correct colors (for fancy arrow transitions) without addon modules
-- needing to manage this on their own.

-- Each type of segment should have its own addon module file.
-- One file for Git segment, Hg segment, Node.js, Python, etc.
-- Note:  The core 'powerline.lua' file must be loaded before addon modules
-- can use the core functions, so naming addon modules as 'powerline_foo.lua'
-- ensures the core functions are loaded first.

-- Core functions for use by all addon modules:
--
-- * plc.addSegment(text, textColor, fillColor, right)
--   - text: The text to display in the segment.
--   - textColor: Use one of the color constants (Ex: colorWhite).
--   - fillColor: Use one of the color constants (Ex: colorBlue).
--   - right: Optional; use true to add a right-justified segment.
--
-- * plc.add_module(init, module_defaults)
--   - init: The function to add segments for the addon module.
--   - module_defaults: A table with the module defaults, which must contain
--     at least the following element.
--     - priority: The priority order for the addon module.

-- In all addon module files:
-- * Must call plc.add_module and pass an init function and module defaults.
-- * For each segment that the init function wants to add it must call plc.addSegment.

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
local leftSegments = {}
local rightSegments = {}

-- Constants
-- Symbols
newLineSymbol = "\n"..ansiEscChar.."[m" -- ESC[m is needed when colour.input is set

plc_prompt = {}

-- Default symbols
-- Some symbols are required. If the user fails to provide them in the config file, they're created here
-- Prompt displayed instead of user's home folder e.g. C:\Users\username
plc_prompt_homeSymbol = plc_prompt_homeSymbol or "~"
-- Symbol connecting each segment of the prompt. Be careful before you change this.
plc_prompt_arrowSymbol = plc_prompt_arrowSymbol or ""
plc_prompt_leftArrowSymbol = plc_prompt_leftArrowSymbol or ""
-- Symbol displayed in the new line below the prompt.
plc_prompt_lambSymbol = plc_prompt_lambSymbol or "λ"
-- SGR parameters for ANSI color for plc_prompt_lambSymbol.
plc_prompt.lambTextColor = plc_prompt.lambTextColor or ansiFgBold
plc_prompt.lambFillColor = plc_prompt.lambFillColor or ansiBgClrDefault
-- Version control (e.g. Git) branch symbol. Used to indicate the name of a branch.
plc_git_branchSymbol = plc_git_branchSymbol or ""
-- Version control (e.g. Git) conflict symbol. Used to indicate there's a conflict.
plc_git_conflictSymbol = plc_git_conflictSymbol or "!"
-- Version control (e.g. Hg) changes symbol. Used to indicate there's a change.
plc_hg_changesSymbol = plc_hg_changesSymbol or "*"

plc_git_addcountSymbol = plc_git_addcountSymbol or "+"
plc_git_modifycountSymbol = plc_git_modifycountSymbol or "*"
plc_git_deletecountSymbol = plc_git_deletecountSymbol or "-"
plc_git_renamecountSymbol = plc_git_renamecountSymbol or "" -- Empty string counts renamed as modified.
plc_git_summarycountSymbol = plc_git_summarycountSymbol or "±"
plc_git_untrackedcountSymbol = plc_git_untrackedcountSymbol or "?"

plc_git_aheadbehindSymbol = plc_git_aheadbehindSymbol or "" -- Optional symbol preceding the ahead/behind counts.
plc_git_aheadcountSymbol = plc_git_aheadcountSymbol or "↓"
plc_git_behindcountSymbol = plc_git_behindcountSymbol or "↑"

plc_git_stagedSymbol = plc_git_stagedSymbol or "↗"

plc_battery_levelSymbol = plc_battery_levelSymbol or "%"
plc_battery_chargingSymbol = plc_battery_chargingSymbol or "⚡"

-- Range of priorities.
plc_priority_start = 51
plc_priority_finish = 99

plc = plc or {}
function plc.bookend_priority(prio)
	if prio <= plc_priority_start then
		return plc_priority_start + 1
	elseif prio >= plc_priority_finish then
		return plc_priority_finish - 1
	else
		return prio
	end
end
bookend_priority = plc.bookend_priority -- backward compatibility

---
-- Adds an arrow symbol to the input text with the correct colors
-- text {string} input text to which an arrow symbol will be added
-- oldColor {color} Color of the prompt on the left of the arrow symbol. Use one of the color constants as input.
-- newColor {color} Color of the prompt on the right of the arrow symbol. Use one of the color constants as input.
-- @return {string} text with an arrow symbol added to it
---
local plc_lastArrow_len = 0
function plc.addArrow(text, oldColor, newColor, right)
	-- Old color is the color of the previous segment
	-- New color is the color of the next segment
	-- An arrow is a character written using the old color on a background of the new color
	local old_len = #text
	if plc_simple then
		text = plc.addTextWithColor(text, "  ", colorDefault, colorDefault)
	elseif right then
		text = plc.addTextWithColor(text, plc_prompt_leftArrowSymbol, newColor, oldColor)
	else
		text = plc.addTextWithColor(text, plc_prompt_arrowSymbol, oldColor, newColor)
	end
	plc_lastArrow_len = #text - old_len
	return text
end
addArrow = plc.addArrow -- backward compatibility

---
-- Adds text to the input text with the correct colors
-- @param text {string}         Input text to which more text will be added
-- @param textToAdd {string}    Text to be added with the specified colors
-- @param textColor {color}     Text color for the newly added text. Use one of the color constants as input.
-- @param fillColor {color}     Fill Color for the newly added text. Use one of the color constants as input.
-- @return {string} concatination of the the two input text with the correct color formatting.
---
function plc.addTextWithColor(text, textToAdd, textColor, fillColor)
	local textColorValue = plc_simple and fillColor.foreground or textColor.foreground
	local fillColorValue = plc_simple and colorDefault.background or fillColor.background
	return text..ansiEscChar.."[0;"..textColorValue..";"..fillColorValue.."m"..textToAdd..ansiEscChar.."[0m"
end
addTextWithColor = plc.addTextWithColor -- backward compatibility

---
-- Adds a new segment to the prompt with the specified colors.
-- @param text {string}         Text of the new segment to be added to the prompt.
-- @param textColor {color}     Foreground color of the new segment. Use one of the color constants.
-- @param fillColor {color}     Background color of the new segment. Use one of the color constants.
-- @param right {bool}          When true, the segment is right-justified. If there isn't room for
--                              all the right-justified segments, the last-added ones are dropped as
--                              needed to fit.
---
function plc.addSegment(text, textColor, fillColor, right)
	if plc_simple then
		text = text:match("^%s*(.-)%s*$")
		if #text == 0 then
			return
		end
	end

	if right then
		table.insert(rightSegments, {text, textColor, fillColor})
	else
		table.insert(leftSegments, {text, textColor, fillColor})
	end
end
addSegment = plc.addSegment -- backward compatibility

---
-- Gets the parent directory for specified entry (either file or directory),
-- or "" if not possible.
---
function plc.toParent(dir)
	if dir == nil then dir = '.' end
	if dir == '.' then dir = clink.get_cwd() end
	local prefix,child = path.toparent(dir)
	if child == "" then
		prefix = ""
	end
	return prefix
end
toParent = plc.toParent -- backward compatibility

---
-- Joins path components.
---
function plc.joinPaths(lhs, rhs)
	return path.join(lhs, rhs)
end
joinPaths = plc.joinPaths -- backward compatibility

---
-- Gets the .git directory.
-- This function was copied from clink.lua in %CMDER_ROOT%\vendor.
-- @return {bool} Indicating whether there's a git directory.
---
function plc.get_git_dir(path)

	-- Checks if provided directory contains git directory
	local function has_git_dir(dir)
			local dotgit = plc.joinPaths(dir, '.git')
			return clink.is_dir(dotgit) and dotgit
	end

	local function has_git_file(dir)
			dotgit = plc.joinPaths(dir, '.git')

			-- More efficient than unconditionally opening the file.
			if os.isfile(dotgit) then
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
			local rel_dir = plc.joinPaths(dir, git_dir)
			local file_when_relative = git_dir and clink.is_dir(rel_dir) and rel_dir
			if file_when_relative then
				return file_when_relative
			end
	end

	-- Set default path to current directory
	if not path or path == '.' then path = clink.get_cwd() end

	-- Calculate parent path now otherwise we won't be
	-- able to do that inside of logical operator
	local parent_path = plc.toParent(path)

	return has_git_dir(path)
			or has_git_file(path)
			-- Otherwise go up one level and make a recursive call
			or (parent_path ~= "" and plc.get_git_dir(parent_path) or nil)
end
get_git_dir = plc.get_git_dir -- backward compatibility

---
-- Build the string of left-justified segments.
---
local function plc_build_left_justified_segments()
	local x = ""
	local currentTextColor = colorDefault
	local currentFillColor = colorBlue

	for _,seg in ipairs(leftSegments) do
		-- Add separator if needed.
		if x ~= "" then
			x = plc.addArrow(x, currentFillColor, seg[3])
		end
		-- Add the segment text.
		x = plc.addTextWithColor(x, seg[1], seg[2], seg[3])
		-- Remember the current fill color.
		currentFillColor = seg[3]
	end

	if not plc_simple then
		x = plc.addArrow(x, currentFillColor, colorDefault)
	end

	return x
end

---
-- Build the string of right-justified segments.
---
local function plc_build_right_justified_segments(leftSegments)
	local genericArrow = plc.addArrow("", colorDefault, colorDefault)
	local arrowCellCount = console.cellcount(genericArrow)
	local leftCellCount = console.cellcount(leftSegments)
	local consoleWidth = console.getwidth()
	local segments = {}

	-- Find how many segments fit.
	for _,seg in ipairs(rightSegments) do
		local segCellCount = console.cellcount(seg[1])
		if segCellCount + arrowCellCount > consoleWidth then
			break
		end
		table.insert(segments, seg)
	end

	-- Add the segments that fit.
	local x = ""
	local currentTextColor = colorDefault
	local currentFillColor = colorDefault
	for i = #segments, 1, -1 do
		local seg = segments[i]
		x = plc.addArrow(x, currentFillColor, seg[3], true)
		x = plc.addTextWithColor(x, seg[1], seg[2], seg[3])
		currentTextColor = seg[2]
		currentFillColor = seg[3]
	end

	if #x > 0 then
		return string.rep(" ", consoleWidth - leftCellCount - console.cellcount(x))..x
	else
		return x
	end
end

---
-- Install a segment.
---
plc._install = {}
function plc.add_module(func, defaults)
	if not defaults or not defaults.priority then
		error("Missing priority field.", 2)
	end
	table.insert(plc._install, { func=func, defaults=defaults })
end

-- Register filters for resetting the prompt and closing it before and after all addons
if (clink.version_encoded or 0) >= 10020005 then

	resetPrompt = clink.promptfilter(plc_priority_start)
	closePrompt = clink.promptfilter(plc_priority_finish)

	---
	-- Resets the prompt and all state variables
	---
	function resetPrompt:filter(prompt)
		leftSegments = {}
		rightSegments = {}
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
		if plc_date_position == "above" then
			prompt = plc_build_date_prompt(prompt)
		end
		local plaintext = console.plaintext(prompt)
		if #plaintext > 0 and plaintext:sub(-1) ~= "\n" then
			prompt = prompt..newLineSymbol
		end
		-- Any prompt so far will go above the powerline prompt.
		local leftText = plc_build_left_justified_segments()
		local rightText = plc_build_right_justified_segments(leftText)
		prompt = prompt..leftText..rightText
		-- Finally add a delimiter between the prompt and the input.
		if useLamb then
			return prompt..newLineSymbol..ansiEscChar.."[0;"..plc_prompt.lambTextColor..";"..plc_prompt.lambFillColor.."m"..plc_prompt_lambSymbol.." "
		else
			local div = ""
			if #rightText > 0 then
				div = newLineSymbol..plc_prompt_simpleClose
			elseif plc_simple then
				div = " "..plc_prompt_simpleClose
			end
			return prompt..div.." "
		end
	end

	local function install_segments()
		for _,def in ipairs(plc._install) do
			local func = def.func
			local defaults = def.defaults
			local prio = plc.bookend_priority(defaults and defaults.priority or 999999)
			local seg = clink.promptfilter(prio)
			function seg:filter(prompt)
				func()
			end
		end
		plc._install = {}
		plc.cached_state = {}
	end
	clink.onbeginedit(install_segments)

else

	-- console.cellcount and console.plaintext are required by the segment
	-- processing routines.
	print("clink-powerline requires Clink v1.2.5 or higher.")

end
