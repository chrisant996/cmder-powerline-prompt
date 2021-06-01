plc_versionControl = plc_versionControl or {}
plc_versionControl.priority = plc_versionControl.priority or 61

plc_git = {}
plc_git.unknown_textColor = colorBlack
plc_git.unknown_fillColor = colorWhite
plc_git.clean_textColor = colorBlack
plc_git.clean_fillColor = colorGreen
plc_git.dirty_textColor = colorBlack
plc_git.dirty_fillColor = colorYellow
plc_git.conflict_textColor = colorBrightWhite
plc_git.conflict_fillColor = colorRed
plc_git.staged_textColor = colorBlack
plc_git.staged_fillColor = colorMagenta
plc_git.remote_textColor = colorBlack
plc_git.remote_fillColor = colorCyan

local use_coroutines = clink.promptcoroutine and true or false

local io_popenyield_maybe = use_coroutines and io.popenyield or io.popen
local function clink_promptcoroutine(func)
    if use_coroutines then
        return clink.promptcoroutine(func)
    else
        return func()
    end
end

---
-- Finds out the name of the current branch
-- @return {nil|git branch name}
---
local function get_git_branch(git_dir)
    git_dir = git_dir or plc.get_git_dir()

    -- If git directory not found then we're probably outside of repo
    -- or something went wrong. The same is when head_file is nil
    local head_file = git_dir and io.open(plc.joinPaths(git_dir, 'HEAD'))
    if not head_file then return end

    local HEAD = head_file:read()
    head_file:close()

    -- if HEAD matches branch expression, then we're on named branch
    -- otherwise it is a detached commit
    local branch_name = HEAD:match('ref: refs/heads/(.+)')

    return branch_name or 'HEAD detached at '..HEAD:sub(1, 7)
end

---
-- Gets the status of working dir
-- @return nil for clean, or a table with dirty counts.
---
local function get_git_status()
    local file = io_popenyield_maybe("git --no-optional-locks status --porcelain 2>nul")
    local w_add, w_mod, w_del, w_unt = 0, 0, 0, 0
    local s_add, s_mod, s_del, s_ren = 0, 0, 0, 0

    for line in file:lines() do
        local kindStaged, kind = string.match(line, "(.)(.) ")

        if kind == "A" then
            w_add = w_add + 1
        elseif kind == "M" then
            w_mod = w_mod + 1
        elseif kind == "D" then
            w_del = w_del + 1
        elseif kind == "?" then
            w_unt = w_unt + 1
        end

        if kindStaged == "A" then
            s_add = s_add + 1
        elseif kindStaged == "M" then
            s_mod = s_mod + 1
        elseif kindStaged == "D" then
            s_del = s_del + 1
        elseif kindStaged == "R" then
            s_ren = s_ren + 1
        end
    end
    file:close()

    if plc_git_renamecountSymbol == "" then
        s_mod = s_mod + s_ren
        s_ren = 0
    end

    local working
    local staged

    if w_add + w_mod + w_del + w_unt > 0 then
        working = {}
        working.add = w_add
        working.modify = w_mod
        working.delete = w_del
        working.untracked = w_unt
    end

    if s_add + s_mod + s_del + s_ren > 0 then
        staged = {}
        staged.add = s_add
        staged.modify = s_mod
        staged.delete = s_del
        staged.rename = s_ren
    end

    local status
    if working or staged then
        status = {}
        status.working = working
        status.staged = staged
    end
    return status
end

---
-- Gets the number of commits ahead/behind from upstream.
---
local function git_ahead_behind_module()
    local file = io_popenyield_maybe("git rev-list --count --left-right @{upstream}...HEAD 2>nul")
    local ahead, behind = "0", "0"
    for line in file:lines() do
        ahead, behind = string.match(line, "(%d+)[^%d]+(%d+)")
    end
    file:close()

    return ahead, behind
end

---
-- Gets the conflict status
-- @return {bool} indicating true for conflict, false for no conflicts
---
local function get_git_conflict()
    local file = io_popenyield_maybe("git diff --name-only --diff-filter=U 2>nul")
    for line in file:lines() do
        file:close()
        return true;
    end
    file:close()
    return false
end

-- * Table of segment objects with these properties:
---- * text:      Text to show.
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue
local segments = {}

---
-- Add status details to the segment text.
-- Depending on plc_git_status_details this may show verbose counts for
-- operations, or a concise overall count.
---
local function add_details(text, details)
    if plc_git_status_details then
        if details.add > 0 then
            text = text..plc_git_addcountSymbol..details.add.." "
        end
        if details.modify > 0 then
            text = text..plc_git_modifycountSymbol..details.modify.." "
        end
        if details.delete > 0 then
            text = text..plc_git_deletecountSymbol..details.delete.." "
        end
        if (details.rename or 0) > 0 then
            text = text..plc_git_renamecountSymbol..details.rename.." "
        end
    else
        text = text..plc_git_summarycountSymbol..(details.add + details.modify + details.delete + (details.rename or 0)).." "
    end
    if (details.untracked or 0) > 0 then
        text = text..plc_git_untrackedcountSymbol..details.untracked.." "
    end
    return text
end

---
-- Coroutine to make prompt more responsive.
---
local function collect_git_info()
    local status = get_git_status()
    local conflict = get_git_conflict()
    local ahead, behind = git_ahead_behind_module()
    return { status=status, conflict=conflict, ahead=ahead, behind=behind, finished=true }
end

---
-- Builds the segments.
---
local cached_info = {}
local function init()
    if not plc.get_git_dir() then
        return
    end

    local branch = get_git_branch(git_dir)
    if not branch then
        return
    end

    -- Discard cached info if from a different repro or branch.
    if cached_info.git_dir ~= git_dir or cached_info.git_branch ~= branch then
        cached_info = {}
        cached_info.git_dir = git_dir
        cached_info.git_branch = branch
    end

    -- Use coroutine if supported, otherwise run directly.
    local info = clink_promptcoroutine(collect_git_info)

    -- Use cached info until coroutine is finished.
    if not info then
        info = cached_info.git_info or {}
    else
        cached_info.git_info = info
    end

    -- Local status
    local gitStatus = info.status
    local gitConflict = info.conflict
    local gitUnknown = not info.finished
    local text = " "..branch.." "
    local textColor = plc_git.clean_textColor
    local fillColor = plc_git.clean_fillColor
    if not plc_simple then
        text = " "..plc_git_branchSymbol..text
    end
    if gitConflict then
        textColor = plc_git.conflict_textColor
        fillColor = plc_git.conflict_fillColor
        if plc_git_conflictSymbol and #plc_git_conflictSymbol then
            text = text..plc_git_conflictSymbol.." "
        end
    elseif gitStatus and gitStatus.working then
        textColor = plc_git.dirty_textColor
        fillColor = plc_git.dirty_fillColor
        text = add_details(text, gitStatus.working)
    elseif gitUnknown then
        textColor = plc_git.unknown_textColor
        fillColor = plc_git.unknown_fillColor
    end
    plc.addSegment(text, textColor, fillColor)

    -- Staged status
	local showStaged = plc_git_staged
	if showStaged == nil then
		showStaged = true
	end
    if showStaged and gitStatus and gitStatus.staged then
        text = " "
        if plc_git_stagedSymbol and #plc_git_stagedSymbol then
            text = text..plc_git_stagedSymbol.." "
        end
        textColor = plc_git.staged_textColor
        fillColor = plc_git.staged_fillColor
        text = add_details(text, gitStatus.staged)
        plc.addSegment(text, textColor, fillColor)
    end

    -- Remote status (ahead/behind)
    if plc_git_aheadbehind then
        local ahead = info.ahead or "0"
        local behind = info.behind or "0"
        if ahead ~= "0" or behind ~= "0" then
            text = " "
            if plc_git_aheadbehindSymbol and #plc_git_aheadbehindSymbol > 0 then
                text = text..plc_git_aheadbehindSymbol.." "
            end
            textColor = plc_git.remote_textColor
            fillColor = plc_git.remote_fillColor
            if ahead ~= "0" then
                text = text..plc_git_aheadcountSymbol..ahead.." "
            end
            if behind ~= "0" then
                text = text..plc_git_behindcountSymbol..behind.." "
            end
            plc.addSegment(text, textColor, fillColor)
        end
    end
end

---
-- Register this addon with Clink
---
plc.add_module(init, plc_versionControl)
