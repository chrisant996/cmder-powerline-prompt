plc_versionControl = plc_versionControl or {}
plc_git = {}

local function init_config()
    plc_git.priority = plc_git.priority or plc_versionControl.priority or plc_priority_versionControl or 61

    -- Colors.
    plc_git.unknown_textColor = plc_git.unknown_textColor or colorBlack
    plc_git.unknown_fillColor = plc_git.unknown_fillColor or colorWhite
    plc_git.clean_textColor = plc_git.clean_textColor or plc_git_clean_textColor or colorBlack
    plc_git.clean_fillColor = plc_git.clean_fillColor or plc_git_clean_fillColor or colorGreen
    plc_git.dirty_textColor = plc_git.dirty_textColor or plc_git_dirty_textColor or colorBlack
    plc_git.dirty_fillColor = plc_git.dirty_fillColor or plc_git_dirty_fillColor or colorYellow
    plc_git.conflict_textColor = plc_git.conflict_textColor or plc_git_conflict_textColor or colorBrightWhite
    plc_git.conflict_fillColor = plc_git.conflict_fillColor or plc_git_conflict_fillColor or colorRed
    plc_git.staged_textColor = plc_git.staged_textColor or plc_git_staged_textColor or colorBlack
    plc_git.staged_fillColor = plc_git.staged_fillColor or plc_git_staged_fillColor or colorMagenta
    plc_git.remote_textColor = plc_git.remote_textColor or plc_git_remote_textColor or colorBlack
    plc_git.remote_fillColor = plc_git.remote_fillColor or plc_git_remote_fillColor or colorCyan

    -- Options.
    plc_git.status_details = plc.bool_config(plc_git.status_details, plc_git_status_details, false)
    plc_git.staged = plc.bool_config(plc_git.staged, plc_git_staged, true)
    plc_git.aheadbehind = plc.bool_config(plc_git.aheadbehind, plc_git_aheadbehind, false)

    -- Symbols.
    plc_git.branchSymbol = plc_git.branchSymbol or plc_versionControl.branchSymbol or plc_git_branchSymbol or ""
    plc_git.conflictSymbol = plc_git.conflictSymbol or plc_git_conflictSymbol or "!"
    plc_git.addcountSymbol = plc_git.addcountSymbol or plc_git_addcountSymbol or "+"
    plc_git.modifycountSymbol = plc_git.modifycountSymbol or plc_git_modifycountSymbol or "*"
    plc_git.deletecountSymbol = plc_git.deletecountSymbol or plc_git_deletecountSymbol or "-"
    plc_git.renamecountSymbol = plc_git.renamecountSymbol or plc_git_renamecountSymbol or "" -- Empty string counts renamed as modified.
    plc_git.summarycountSymbol = plc_git.summarycountSymbol or plc_git_summarycountSymbol or "±"
    plc_git.untrackedcountSymbol = plc_git.untrackedcountSymbol or plc_git_untrackedcountSymbol or "?"
    plc_git.aheadbehindSymbol = plc_git.aheadbehindSymbol or plc_git_aheadbehindSymbol or "" -- Optional symbol preceding the ahead/behind counts.
    plc_git.aheadcountSymbol = plc_git.aheadcountSymbol or plc_git_aheadcountSymbol or "↓"
    plc_git.behindcountSymbol = plc_git.behindcountSymbol or plc_git_behindcountSymbol or "↑"
    plc_git.stagedSymbol = plc_git.stagedSymbol or plc_git_stagedSymbol or "↗"
end

---
-- Support async prompt filtering when available.
---
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

    if plc_git.renamecountSymbol == "" then
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
-- Depending on plc_git.status_details this may show verbose counts for
-- operations, or a concise overall count.
---
local function add_details(text, details)
    if plc_git.status_details then
        if details.add > 0 then
            text = text..plc_git.addcountSymbol..details.add.." "
        end
        if details.modify > 0 then
            text = text..plc_git.modifycountSymbol..details.modify.." "
        end
        if details.delete > 0 then
            text = text..plc_git.deletecountSymbol..details.delete.." "
        end
        if (details.rename or 0) > 0 then
            text = text..plc_git.renamecountSymbol..details.rename.." "
        end
    else
        text = text..plc_git.summarycountSymbol..(details.add + details.modify + details.delete + (details.rename or 0)).." "
    end
    if (details.untracked or 0) > 0 then
        text = text..plc_git.untrackedcountSymbol..details.untracked.." "
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
    local git_dir = plc.get_git_dir()
    if not git_dir then
        return
    end

    local branch = get_git_branch(git_dir)
    if not branch then
        return
    end

    -- Discard cached info if from a different repro or branch.
    if (cached_info.git_dir ~= git_dir) or (cached_info.git_branch ~= branch) then
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
        text = " "..plc_git.branchSymbol..text
    end
    if gitConflict then
        textColor = plc_git.conflict_textColor
        fillColor = plc_git.conflict_fillColor
        if plc_git.conflictSymbol and #plc_git.conflictSymbol then
            text = text..plc_git.conflictSymbol.." "
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
    local showStaged = plc_git.staged
    if showStaged == nil then
        showStaged = true
    end
    if showStaged and gitStatus and gitStatus.staged then
        text = " "
        if plc_git.stagedSymbol and #plc_git.stagedSymbol then
            text = text..plc_git.stagedSymbol.." "
        end
        textColor = plc_git.staged_textColor
        fillColor = plc_git.staged_fillColor
        text = add_details(text, gitStatus.staged)
        plc.addSegment(text, textColor, fillColor)
    end

    -- Remote status (ahead/behind)
    if plc_git.aheadbehind then
        local ahead = info.ahead or "0"
        local behind = info.behind or "0"
        if ahead ~= "0" or behind ~= "0" then
            text = " "
            if plc_git.aheadbehindSymbol and #plc_git.aheadbehindSymbol > 0 then
                text = text..plc_git.aheadbehindSymbol.." "
            end
            textColor = plc_git.remote_textColor
            fillColor = plc_git.remote_fillColor
            if ahead ~= "0" then
                text = text..plc_git.aheadcountSymbol..ahead.." "
            end
            if behind ~= "0" then
                text = text..plc_git.behindcountSymbol..behind.." "
            end
            plc.addSegment(text, textColor, fillColor)
        end
    end
end

---
-- Register this addon with Clink
---
plc_git.init = init_config
plc.addModule(init, plc_git)
