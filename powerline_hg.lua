local segment_priority = plc_priority_versionControl or 61

-- Constants
plc_hg_branch_textColor = colorBlack
plc_hg_branch_fillColor = colorGreen
plc_hg_dirty_textColor = colorWhite
plc_hg_dirty_fillColor = colorRed

--- copied from clink.lua
 -- Resolves closest directory location for specified directory.
 -- Navigates subsequently up one level and tries to find specified directory
 -- @param  {string} path    Path to directory will be checked. If not provided
 --                          current directory will be used
 -- @param  {string} dirname Directory name to search for
 -- @return {string} Path to specified directory or nil if such dir not found
local function get_dir_contains(path, dirname)

    -- Checks if provided directory contains hg directory
    local function has_specified_dir(path, specified_dir)
        if path == nil then path = '.' end
        local found_dirs = clink.find_dirs(joinPaths(path, specified_dir))
        if #found_dirs > 0 then return true end
        return false
    end

    -- Set default path to current directory
    if path == nil then path = '.' end

    -- If we're already have .hg directory here, then return current path
    if has_specified_dir(path, dirname) then
        return joinPaths(path, dirname)
    else
        -- Otherwise go up one level and make a recursive call
        local parent_path = toParent(path)
        if parent_path == "" then
            return nil
        else
            return get_dir_contains(parent_path, dirname)
        end
    end
end

-- copied from clink.lua
-- clink.lua is saved under %CMDER_ROOT%\vendor
 function get_hg_dir(path)
    return get_dir_contains(path, '.hg')
end

-- * The segments{} table will hold values for each prompt segment to be (sequentially) displayed
---- * text
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue

local segments = {}

---
-- Sets the properties of the Segment object, and prepares for a segment to be added
---
local function init()
    segments = {}

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
            table.insert(segments, {" " .. plc_git_branchSymbol .. " " .. branch .. " ", plc_hg_branch_textColor, plc_hg_branch_fillColor})
            local pipe = io.popen("hg status -amrd 2>&1")
            local output = pipe:read('*all')
            local rc = { pipe:close() }
            if output ~= nil and output ~= "" then
                -- Dirty segment
                table.insert(segments, {" " .. plc_hg_changesSymbol .. " ",  plc_hg_dirty_textColor,  plc_hg_dirty_fillColor})
            end
        end
    end
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
        for i = 1, #segments do
            addSegment(segments[i][1], segments[i][2], segments[i][3])
        end
    end 

    clink.prompt.register_filter(addAddonSegment, segment_priority)

else

    -- New Clink API (v1.x)
    addAddonSegment = clink.promptfilter(segment_priority)

    function addAddonSegment:filter(prompt)
        init()
        for i = 1, #segments do
            return addSegment(segments[i][1], segments[i][2], segments[i][3])
        end
        return prompt
    end

end
