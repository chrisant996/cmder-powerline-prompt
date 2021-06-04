plc_npm = {}
plc_npm.priority = 60
plc_npm.textColor = colorWhite
plc_npm.fillColor = colorCyan

local function get_package_json_file(path)
  if not path or path == '.' then path = clink.get_cwd() end

  local parent_path = plc.toParent(path)
  return io.open(plc.joinPaths(path, 'package.json')) or (parent_path ~= path and get_package_json_file(parent_path) or nil)
end

---
-- Builds the segment content.
---
local function init()
  local file = get_package_json_file()
  if file then
    local package_info = file:read('*a')
    file:close()

    local package_name = string.match(package_info, '"name"%s*:%s*"(%g-)"')
    if package_name == nil then
      package_name = ''
    end

    local package_version = string.match(package_info, '"version"%s*:%s*"(.-)"')
    if package_version == nil then
      package_version = ''
    end

    local text
    if plc_npm.npmSymbol then
      text = " "..plc_npm.npmSymbol.." "..package_name.."@"..package_version.." "
    else
      text = " "..package_name.."@"..package_version.." "
    end

    plc.addSegment(text, plc_npm.textColor, plc_npm.fillColor)
  end
end

---
-- Register this addon with Clink
---
plc.addModule(init, plc_npm)
