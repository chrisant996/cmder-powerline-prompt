plc_npm = {}

local function init_config()
  plc_npm.priority = plc_npm.priority or plc_priority_npm or 60

  -- Colors.
  plc_npm.textColor = plc_npm.textColor or plc_npm_textColor or colorWhite
  plc_npm.fillColor = plc_npm.fillColor or plc_npm_fillColor or colorCyan

  -- Symbols.
  plc_npm.npmSymbol = plc_npm.npmSymbol or plc_npm_npmSymbol or nil
end

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

    local text = " "..package_name.."@"..package_version.." "
    if plc_npm.npmSymbol and plc_npm.npmSymbol ~= "" then
      text = " "..plc_npm.npmSymbol..text
    end

    plc.addSegment(text, plc_npm.textColor, plc_npm.fillColor)
  end
end

---
-- Register this addon with Clink
---
plc_npm.init = init_config
plc.addModule(init, plc_npm)
