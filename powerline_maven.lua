local function get_pom_xml_dir(path)
  if not path or path == '.' then path = clink.get_cwd() end

  local pom_file = joinPaths(path, 'pom.xml')
  if (clink.version_encoded or 0) >= 10010000 then
    -- More efficient than opening the file.
    if os.isfile(pom_file) then
      return true
    end
  else
    if io.open(pom_file) then
      return true
    end
  end

  local parent_path = toParent(path)
  return (parent_path ~= "" and get_pom_xml_dir(parent_path) or nil)
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
  segment.isNeeded = get_pom_xml_dir()
  if segment.isNeeded then
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

    if plc_mvn_mvnSymbol then
      segment.text = " "..plc_mvn_mvnSymbol.." "..package_group..":"..package_artifact..":"..package_version.." "
    else
      segment.text = " mvn: "..package_group..":"..package_artifact..":"..package_version.." "
    end
  end
end

---
-- Uses the segment properties to add a new segment to the prompt
---
local function addAddonSegment()
  init()
  if segment.isNeeded then
      addSegment(segment.text, segment.textColor, segment.fillColor)
  end
end

-- Register this addon with Clink
clink.prompt.register_filter(addAddonSegment, 60)