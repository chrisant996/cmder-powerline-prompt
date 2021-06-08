plc_python = {}

local function init_config()
    plc_python.priority = plc_python.priority or 60

    -- Colors.
    plc_python.textColor = plc_python.textColor or plc_python_textColor or colorWhite
    plc_python.fillColor = plc_python.fillColor or plc_python_fillColor or colorCyan

    -- Options.
    plc_python.virtualEnvVariable = plc_python.virtualEnvVariable or plc_python_virtualEnvVariable or nil
    plc_python.alwaysShow = plc.bool_config(plc_python.alwaysShow, plc_python_alwaysShow, false)

    -- Symbols.
    plc_python.pythonSymbol = plc_python.pythonSymbol or plc_python_pythonSymbol or nil
end

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
    if plc_python.virtualEnvVariable then
        venv = get_virtual_env(plc_python.virtualEnvVariable)
    else
        venv = get_virtual_env()
    end
    if not venv then
        -- return early to avoid wasting time by calling get_py_files()!
        return
    end

    if not plc_python.alwaysShow and not get_py_files() then
        return
    end

    local text = " ["..venv.."] "
    if plc_python.pythonSymbol and plc_python.pythonSymbol ~= "" then
        text = " "..plc_python.pythonSymbol..text
    end

    plc.addSegment(text, plc_python.textColor, plc_python.fillColor)
end

---
-- Register this addon with Clink
---
plc_python.init = init_config
plc.addModule(init, plc_python)
