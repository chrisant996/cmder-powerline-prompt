local segment_priority = plc_priority_prompt or 55

plc_prompt_segment_textColor = colorWhite
plc_prompt_segment_fillColor = colorBlue

-- Configurations
--- plc_prompt_type is whether the displayed prompt is the full path or only the folder name
 -- Use:
 -- "full" for full path like C:\Windows\System32
local promptTypeFull = "full"
 -- "folder" for folder name only like System32
local promptTypeFolder = "folder"
 -- "smart" to switch in git repo to folder name instead of full path
local promptTypeSmart = "smart"

local home = clink.get_env("HOMEDRIVE") .. clink.get_env("HOMEPATH")

 -- default is promptTypeSmart
 -- Set default value if no value is already set
if not plc_prompt_type then
    plc_prompt_type = promptTypeSmart
end
if not plc_prompt_useHomeSymbol then
	plc_prompt_useHomeSymbol = true
end

-- Extracts only the folder name from the input Path
-- Ex: Input C:\Windows\System32 returns System32
---
local function get_folder_name(path)
	local reversePath = string.reverse(path)
	local slashIndex = string.find(reversePath, "\\")
	return string.sub(path, string.len(path) - slashIndex + 2)
end

-- * Segment object with these properties:
---- * isNeeded: sepcifies whether a segment should be added or not. For example: no Git segment is needed in a non-git folder
---- * text
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue
local segment = {
    isNeeded = true,
    text = "",
    textColor = plc_prompt_segment_textColor,
    fillColor = plc_prompt_segment_fillColor
}

---
-- If the prompt envvar has $+ at the beginning of any line then this
-- captures the pushd stack depth.  Also if the translated prompt has + at
-- the beginning of any line then that will be (mis?)interpreted as the
-- pushd stack depth.
---
local dirStackDepth = ""
local function extract_pushd_depth(prompt)
	dirStackDepth = ""
	local plusBegin, plusEnd = prompt:find("^[+]+")
	if plusBegin == nil then
		plusBegin, plusEnd = prompt:find("[\n][+]+")
	end
	if plusBegin ~= nil then
		dirStackDepth = prompt:sub(plusBegin, plusEnd).." "
	end
end

---
-- Sets the properties of the Segment object, and prepares for a segment to be added
---
local function init()
    -- fullpath
    cwd = clink.get_cwd()

    -- show just current folder
    if plc_prompt_type == promptTypeFolder then
		cwd =  get_folder_name(cwd)
    else
    -- show 'smart' folder name
    -- This will show the full folder path unless a Git repo is active in the folder
    -- If a Git repo is active, it will only show the folder name
    -- This helps users avoid having a super long prompt
        local git_dir = get_git_dir()
        if plc_prompt_useHomeSymbol and string.find(cwd, home) and git_dir ==nil then
            -- in both smart and full if we are in home, behave like a proper command line
            cwd = string.gsub(cwd, home, plc_prompt_homeSymbol)
        else
            -- either not in home or home not supported then check the smart path
            if plc_prompt_type == promptTypeSmart then
                if git_dir then
                    -- get the root git folder name and reappend any part of the directory that comes after
                    -- Ex: C:\Users\username\cmder-powerline-prompt\innerdir -> cmder-powerline-prompt\innerdir
                    local git_root_dir = toParent(git_dir)
                    local appended_dir = string.sub(cwd, string.len(git_root_dir) + 1)
                    cwd = get_folder_name(git_root_dir)..appended_dir
                    if plc_prompt_gitSymbol then
                        cwd = plc_prompt_gitSymbol.." "..cwd
                    end
                end
                -- if not git dir leave the full path
            end
        end
    end

	segment.text = " "..dirStackDepth..cwd.." "
	segment.textColor = plc_prompt_segment_textColor
	segment.fillColor = plc_prompt_segment_fillColor
end

-- Register this addon with Clink
local addAddonSegment = nil

---
-- Uses the segment properties to add a new segment to the prompt
---
if not clink.version_major then

	-- Old Clink API (v0.4.x)

	addAddonSegment = function ()
		init()
		addSegment(segment.text, segment.textColor, segment.fillColor)
	end
	clink.prompt.register_filter(addAddonSegment, segment_priority)

	clink.prompt.register_filter(function() extract_pushd_depth(clink.prompt.value) end, 1)

else

	-- New Clink API (v1.x)

	addAddonSegment = clink.promptfilter(segment_priority)
	function addAddonSegment:filter(prompt)
		init()
		return addSegment(segment.text, segment.textColor, segment.fillColor)
	end

	local plus_capture = clink.promptfilter(1)
	function plus_capture:filter(prompt)
		extract_pushd_depth(prompt)
	end

end
