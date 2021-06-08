plc_maven = {}

local function init_config()
  plc_maven.priority = plc_maven.priority or 60

  -- Colors.
  plc_maven.textColor = plc_maven.textColor or colorWhite
  plc_maven.fillColor = plc_maven.fillColor or colorCyan

  -- Symbols.
  plc_maven.mavenSymbol = plc_maven.mavenSymbol or plc_mvn_mvnSymbol or "mvn:"
end

local function get_pom_xml_dir(path)
  if not path or path == '.' then path = clink.get_cwd() end

  local pom_file = plc.joinPaths(path, 'pom.xml')
  -- More efficient than opening the file.
  if os.isfile(pom_file) then
    return true
  end

  local parent_path = plc.toParent(path)
  return (parent_path ~= "" and get_pom_xml_dir(parent_path) or nil)
end

---
-- Builds the segment content.
---
local function init()
  if get_pom_xml_dir() then
    local handle = io.popen('xmllint --xpath "//*[local-name()=\'project\']/*[local-name()=\'groupId\']/text()" pom.xml 2>NUL')
    local package_group = handle:read("*a")
    handle:close()
    if package_group == nil or package_group == '' then
      local parent_handle = io.popen('xmllint --xpath "//*[local-name()=\'project\']/*[local-name()=\'parent\']/*[local-name()=\'groupId\']/text()" pom.xml 2>NUL')
      package_group = parent_handle:read("*a")
      parent_handle:close()

      if package_group == nil or package_group == '' then
        package_group = ''
      end
    end

    handle = io.popen('xmllint --xpath "//*[local-name()=\'project\']/*[local-name()=\'artifactId\']/text()" pom.xml 2>NUL')
    local package_artifact = handle:read("*a")
    handle:close()
    if package_artifact == nil or package_artifact == '' then
            package_artifact = ''
    end

    handle = io.popen('xmllint --xpath "//*[local-name()=\'project\']/*[local-name()=\'version\']/text()" pom.xml 2>NUL')
    local package_version = handle:read("*a")
    handle:close()
    if package_version == nil or package_version == '' then
      local parent_handle = io.popen('xmllint --xpath "//*[local-name()=\'project\']/*[local-name()=\'parent\']/*[local-name()=\'version\']/text()" pom.xml 2>NUL')
      package_version = parent_handle:read("*a")
      parent_handle:close()

      if package_version == nil or package_version == '' then
        package_version = ''
      end
    end

    local text = " "..package_group..":"..package_artifact..":"..package_version.." "
    if plc_maven.mavenSymbol and plc_maven.mavenSymbol ~= "" then
      text = " "..plc_maven.mavenSymbol..text
    end
    plc.addSegment(text, plc_maven.textColor, plc_maven.fillColor)
  end
end

---
-- Register this addon with Clink
---
plc_maven.init = init_config
plc.addModule(init, plc_maven)
