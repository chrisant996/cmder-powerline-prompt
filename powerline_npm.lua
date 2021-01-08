local segment_priority = plc_priority_npm or 60

local function get_package_json_dir(path)
  if not path or path == '.' then path = clink.get_cwd() end

  local json_file = joinPaths(path, 'package.json')
  if (clink.version_encoded or 0) > 10010020 then
    if os.isfile(json_file) then
      return true
    end
  else
    if io.open(json_file) then
      return true
    end
  end

  local parent_path = toParent(path)
  return (parent_path ~= "" and get_package_json_dir(parent_path) or nil)
end

-- * Segment object with these properties:
---- * isNeeded: sepcifies whether a segment should be added or not. For example: no Git segment is needed in a non-git folder
---- * text
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue
local segment = {
  isNeeded = false,
  text = "",
  textColor = colorWhite,
  fillColor = colorCyan
}

---
-- Sets the properties of the Segment object, and prepares for a segment to be added
---
local function init()
  segment.isNeeded = get_package_json_dir()
  if segment.isNeeded then
    local package_info = segment.isNeeded:read('*a')
    segment.isNeeded:close()

    local package_name = string.match(package_info, '"name"%s*:%s*"(%g-)"')
    if package_name == nil then
            package_name = ''
    end

    local package_version = string.match(package_info, '"version"%s*:%s*"(.-)"')
    if package_version == nil then
            package_version = ''
    end

    if plc_npm_npmSymbol then
      segment.text = " "..plc_npm_npmSymbol.." "..package_name.."@"..package_version.." "
    else
      segment.text = " "..package_name.."@"..package_version.." "
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
    if segment.isNeeded then 
      addSegment(segment.text, segment.textColor, segment.fillColor)
    end 
  end

  clink.prompt.register_filter(addAddonSegment, segment_priority)

else

  -- New Clink API (v1.x)
  addAddonSegment = clink.promptfilter(segment_priority)

  function addAddonSegment:filter(prompt)
    init()
    if segment.isNeeded then
      return addSegment(segment.text, segment.textColor, segment.fillColor)
    end
    return prompt
  end

end
