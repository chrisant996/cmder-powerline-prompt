plc_prompt = plc_prompt or {}

local function init_config()
    -- Priority for segment.
    plc_prompt.priority = plc_prompt.priority or plc_prompt_priority or 55

    -- Colors for segment.
    plc_prompt.textColor = plc_prompt.textColor or plc_prompt_textColor or colorWhite
    plc_prompt.fillColor = plc_prompt.fillColor or plc_prompt_fillColor or colorBlue

    -- Display plc_prompt.homeSymbol instead of user's home folder (e.g. C:\Users\username).
    plc_prompt.useHomeSymbol = plc.bool_config(plc_prompt.useHomeSymbol, plc_prompt_useHomeSymbol, true)
    plc_prompt.homeSymbol = plc_prompt.homeSymbol or plc_prompt_homeSymbol or "~"

    -- Prompt type:
    --      "full"      = C:\Windows\System32
    --      "folder"    = System32
    --      "smart"     = Full path outside git repo, or
    --                    repo-relative path inside git repo.
    plc_prompt.type = plc_prompt.type or plc_prompt_type or "smart"

    -- Symbol for git path when plc_prompt.type is "smart".
    plc_prompt.gitSymbol = plc_prompt.gitSymbol or plc_prompt_gitSymbol or nil
end

-- Extracts only the folder name from the input Path
-- Ex: Input C:\Windows\System32 returns System32
---
local function get_folder_name(path)
    local reversePath = string.reverse(path)
    local slashIndex = string.find(reversePath, "\\")
    return string.sub(path, string.len(path) - slashIndex + 2)
end

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
        if plusBegin then
            plusBegin = plusBegin + 1
        end
    end
    if plusBegin ~= nil then
        dirStackDepth = prompt:sub(plusBegin, plusEnd).." "
    end
end

---
-- Builds the segment content.
---
local function init()
    -- fullpath
    cwd = clink.get_cwd()

    -- show just current folder
    if plc_prompt.type == "folder" then
        cwd =  get_folder_name(cwd)
    else
    -- show 'smart' folder name
    -- This will show the full folder path unless a Git repo is active in the folder
    -- If a Git repo is active, it will only show the folder name
    -- This helps users avoid having a super long prompt
        local git_dir = plc.get_git_dir()
        if plc_prompt.useHomeSymbol and string.find(cwd, clink.get_env("HOME")) and git_dir ==nil then
            -- in both smart and full if we are in home, behave like a proper command line
            cwd = string.gsub(cwd, clink.get_env("HOME"), plc_prompt.homeSymbol)
        else
            -- either not in home or home not supported then check the smart path
            if plc_prompt.type == promptTypeSmart then
                if git_dir then
                    -- get the root git folder name and reappend any part of the directory that comes after
                    -- Ex: C:\Users\username\cmder-powerline-prompt\innerdir -> cmder-powerline-prompt\innerdir
                    local git_root_dir = plc.toParent(git_dir)
                    local appended_dir = string.sub(cwd, string.len(git_root_dir) + 1)
                    cwd = get_folder_name(git_root_dir)..appended_dir
                    if plc_prompt.gitSymbol and plc_prompt.gitSymbol ~= "" then
                        cwd = plc_prompt.gitSymbol.." "..cwd
                    end
                end
                -- if not git dir leave the full path
            end
        end
    end

    plc.addSegment(" "..dirStackDepth..cwd.." ", plc_prompt.textColor, plc_prompt.fillColor)
end

---
-- Add a prompt filter to capture the $+ pushd stack depth.
---
local plus_capture = clink.promptfilter(1)
function plus_capture:filter(prompt)
    extract_pushd_depth(prompt)
end

---
-- Register this addon with Clink
---
plc_prompt.init = init_config
plc.addModule(init, plc_prompt)
