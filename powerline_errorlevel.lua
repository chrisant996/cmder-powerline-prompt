plc_errorlevel = {}

local function init_config()
    plc_errorlevel.priority = plc_errorlevel.priority or 80

    -- Colors.
    plc_errorlevel.textColor = plc_errorlevel.textColor or colorBrightRed
    plc_errorlevel.fillColor = plc_errorlevel.fillColor or colorBlack

    -- Options.
    plc_errorlevel.showAlways = plc.bool_config(plc_errorlevel.showAlways, false)

    -- Symbols.
    plc_errorlevel.symbol = plc_errorlevel.symbol or "exit"
end

---
-- Builds the segment content.
---
local function init()
    local value = os.geterrorlevel()
    if not plc_errorlevel.showAlways and value == 0 then
        return
    end

    local text = " "..value.." "
    if plc_errorlevel.symbol and plc_errorlevel.symbol ~= "" then
        text = " "..plc_errorlevel.symbol..text
    end

    plc.addSegment(text, plc_errorlevel.textColor, plc_errorlevel.fillColor)
end

---
-- Register this addon with Clink
---
if os.geterrorlevel then

    plc_errorlevel.init = init_config
    plc.addModule(init, plc_errorlevel)

end

