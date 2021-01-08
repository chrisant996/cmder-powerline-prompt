local segment_priority = plc_priority_versionControl or 61

-- Constants
local segmentColors = {
    clean = {
        fill = colorGreen,
        text = colorBlack
    },
    dirty = {
        fill = colorYellow,
        text = colorBlack
    },
    conflict = {
        fill = colorRed,
        text = colorBrightWhite
    },
    staged = {
        fill = colorMagenta,
        text = colorBlack
    },
    remote = {
        fill = colorCyan,
        text = colorBlack
    }
}

---
-- Finds out the name of the current branch
-- @return {nil|git branch name}
---
function get_git_branch(git_dir)
    git_dir = git_dir or get_git_dir()

    -- If git directory not found then we're probably outside of repo
    -- or something went wrong. The same is when head_file is nil
    local head_file = git_dir and io.open(joinPaths(git_dir, 'HEAD'))
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
function get_git_status()
    local file = io.popen("git --no-optional-locks status --porcelain 2>nul")
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
function git_ahead_behind_module()
    local file = io.popen("git rev-list --count --left-right @{upstream}...HEAD 2>nul")
    local ahead, behind = "0", "0"
    for line in file:lines() do
        ahead, behind = string.match(line, "(%d+).+(%d+)")
    end
    file:close()

    return ahead, behind
end

---
-- Gets the conflict status
-- @return {bool} indicating true for conflict, false for no conflicts
---
function get_git_conflict()
    local file = io.popen("git diff --name-only --diff-filter=U 2>nul")
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
-- Builds the segments table.
---
local function init()
    if not get_git_dir() then
        return {}
    end

    local branch = get_git_branch(git_dir)
    if not branch then
        return {}
    end

    local segment
    local segments = {}

    -- Local status
    local gitStatus = get_git_status()
    local gitConflict = get_git_conflict()
    segment = {}
    segment.text = " "..plc_git_branchSymbol.." "..branch.." "
    segment.textColor = segmentColors.clean.text
    segment.fillColor = segmentColors.clean.fill
    if gitConflict then
        segment.textColor = segmentColors.conflict.text
        segment.fillColor = segmentColors.conflict.fill
        if plc_git_conflictSymbol and #plc_git_conflictSymbol then
            segment.text = segment.text..plc_git_conflictSymbol.." "
        end
    elseif gitStatus and gitStatus.working then
        segment.textColor = segmentColors.dirty.text
        segment.fillColor = segmentColors.dirty.fill
        segment.text = add_details(segment.text, gitStatus.working)
    end
    table.insert(segments, segment)

    -- Staged status
	local showStaged = plc_git_staged
	if showStaged == nil then
		showStaged = true
	end
    if showStaged and gitStatus and gitStatus.staged then
        segment = {}
        segment.text = " "
        if plc_git_stagedSymbol and #plc_git_stagedSymbol then
            segment.text = segment.text..plc_git_stagedSymbol.." "
        end
        segment.textColor = segmentColors.staged.text
        segment.fillColor = segmentColors.staged.fill
        segment.text = add_details(segment.text, gitStatus.staged)
        table.insert(segments, segment)
    end

    -- Remote status (ahead/behind)
    if plc_git_aheadbehind then
        local ahead,behind = git_ahead_behind_module()
        if ahead ~= "0" or behind ~= "0" then
            segment = {}
            segment.text = " "
            if plc_git_aheadbehindSymbol and #plc_git_aheadbehindSymbol > 0 then
                segment.text = segment.text..plc_git_aheadbehindSymbol.." "
            end
            segment.textColor = segmentColors.remote.text
            segment.fillColor = segmentColors.remote.fill
            if ahead ~= "0" then
                segment.text = segment.text..plc_git_aheadcountSymbol..ahead.." "
            end
            if behind ~= "0" then
                segment.text = segment.text..plc_git_behindcountSymbol..behind.." "
            end
            table.insert(segments, segment)
        end
    end

    return segments
end

---
-- Builds the prompt.
---
local function build_prompt(prompt)
    for _,seg in ipairs(init()) do
        prompt = addSegment(seg.text, seg.textColor, seg.fillColor)
    end
    return prompt
end

-- Register this addon with Clink
local addAddonSegment = nil

---
-- Uses the segment properties to add a new segment to the prompt
---
if not clink.version_major then

    -- Old Clink API (v0.4.x)
    addAddonSegment = function ()
        build_prompt()
    end

    clink.prompt.register_filter(addAddonSegment, segment_priority)

else

    -- New Clink API (v1.x)
    addAddonSegment = clink.promptfilter(segment_priority)

    function addAddonSegment:filter(prompt)
        return build_prompt(prompt)
    end

end
