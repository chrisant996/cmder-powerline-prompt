plc_versionControl = plc_versionControl or {}
plc_hg = {}

local function init_config()
    plc_hg.priority = plc_hg.priority or plc_versionControl.priority or plc_priority_versionControl or 61

    -- Colors.
    plc_hg.branch_textColor = plc_hg.branch_textColor or plc_hg_branch_textColor or colorBlack
    plc_hg.branch_fillColor = plc_hg.branch_fillColor or plc_hg_branch_fillColor or colorGreen
    plc_hg.dirty_textColor = plc_hg.dirty_textColor or plc_hg_dirty_textColor or colorWhite
    plc_hg.dirty_fillColor = plc_hg.dirty_fillColor or plc_hg_dirty_fillColor or colorRed

    -- Symbols.
    plc_hg.branchSymbol = plc_hg.branchSymbol or plc_versionControl.branchSymbol or plc_git_branchSymbol or ""
    plc_hg.changesSymbol = plc_hg.changesSymbol or plc_hg_changesSymbol or "*"
end

--- Copied from clink.lua in %CMDER_ROOT%\vendor.
 -- Resolves closest directory location for specified directory.
 -- Navigates subsequently up one level and tries to find specified directory.
 -- @param  {string} path    Path to directory will be checked. If not provided
 --                          current directory will be used
 -- @param  {string} dirname Directory name to search for
 -- @return {string} Path to specified directory or nil if such dir not found
local function get_dir_contains(path, dirname)

    -- Checks if provided directory contains hg directory
    local function has_specified_dir(path, specified_dir)
        if path == nil then path = '.' end
        local found_dirs = clink.find_dirs(plc.joinPaths(path, specified_dir))
        if #found_dirs > 0 then return true end
        return false
    end

    -- Set default path to current directory
    if path == nil then path = '.' end

    -- If we're already have .hg directory here, then return current path
    if has_specified_dir(path, dirname) then
        return plc.joinPaths(path, dirname)
    else
        -- Otherwise go up one level and make a recursive call
        local parent_path = plc.toParent(path)
        if parent_path == "" then
            return nil
        else
            return get_dir_contains(parent_path, dirname)
        end
    end
end

-- Copied from clink.lua in %CMDER_ROOT%\vendor.
local function get_hg_dir(path)
    return get_dir_contains(path, '.hg')
end

-- * The segments{} table will hold values for each prompt segment to be (sequentially) displayed
---- * text
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue

local segments = {}

---
-- Build the segment content.
---
local function init()
    if get_hg_dir() then
        -- we're inside of hg repo, read branch and status
        local pipe = io.popen("hg branch 2>&1")
        local output = pipe:read('*all')
        local rc = { pipe:close() }

        -- strip the trailing newline from the branch name
        local n = #output
        while n > 0 and output:find("^%s", n) do n = n - 1 end
        local branch = output:sub(1, n)

        if branch ~= nil and
                string.sub(branch,1,7) ~= "abort: " and             -- not an HG working copy
                (not string.find(branch, "is not recognized")) then -- 'hg' not in path
            -- Branch segment
            local text = " " .. branch .. " "
            if not plc_simple then
                text = " " .. plc_hg.branchSymbol .. text
            end
            plc.addSegment(text, plc_hg.branch_textColor, plc_hg.branch_fillColor)

            -- Dirty segment
            local pipe = io.popen("hg status -amrd 2>&1")
            local output = pipe:read('*all')
            local rc = { pipe:close() }
            if output ~= nil and output ~= "" then
                plc.addSegment(" " .. plc_hg.changesSymbol .. " ", plc_hg.dirty_textColor, plc_hg.dirty_fillColor)
            end
        end
    end
end

---
-- Register this addon with Clink
---
plc_hg.init = init_config
plc.addModule(init, plc_hg)
