plc_python = {}
plc_python.priority = 60
plc_python.textColor = colorWhite
plc_python.fillColor = colorCyan

---
 -- get the virtual env variable
---
local function get_virtual_env(env_var)

    local venv_path = false
    -- return the folder name of the current virtual env, or false
    local function get_virtual_env_var(var)
        env_path = clink.get_env(var)
        if env_path then
            return string.match(env_path, "[^\\/:]+$")
        else
            return false
        end
    end

    local venv = get_virtual_env_var(env_var) or get_virtual_env_var('VIRTUAL_ENV') or get_virtual_env_var('CONDA_DEFAULT_ENV') or false
    return venv
end

---
 -- check for python files in current directory
 -- or in any parent directory
---
local function get_py_files(path)
    local function has_py_files(dir)
        local getN = 0
        for n in pairs(os.globfiles("*.py")) do
            getN = getN + 1
        end
        return getN
    end

    dir = plc.toParent(path)

    files = has_py_files(dir) > 0
    return files
end

---
-- Builds the segment content.
---
local function init()
    local venv
    if plc_python_virtualEnvVariable then
        venv = get_virtual_env(plc_python_virtualEnvVariable)
    else
        venv = get_virtual_env()
    end
    if not venv then
        -- return early to avoid wasting time by calling get_py_files()!
        return
    end

    if not plc_python_alwaysShow and not get_py_files() then
        return
    end

    local text
    if plc_python_pythonSymbol then
        text = " "..plc_python_pythonSymbol.." ["..venv.."] "
    else
        text = " ["..venv.."] "
    end

    plc.addSegment(text, plc_python.textColor, plc_python.fillColor)
end

---
-- Register this addon with Clink
---
plc.add_module(init, plc_python)
