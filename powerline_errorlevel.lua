-- NOTE:  This module only works on Clink v1.2.14 and higher, and only when
--        Clink's `cmd.get_errorlevel` setting is enabled (it's disabled by
--        default).

plc_errorlevel = {}

local function init_config()
    plc_errorlevel.priority = plc_errorlevel.priority or 80

    -- Colors.
    plc_errorlevel.textColor = plc_errorlevel.textColor or colorBrightRed
    plc_errorlevel.fillColor = plc_errorlevel.fillColor or colorBlack

    -- Options.
    plc_errorlevel.showAlways = plc.bool_config(plc_errorlevel.showAlways, false)
    plc_errorlevel.showHexOver255 = plc.bool_config(plc_errorlevel.showHexOver255, false)

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

    local text
    if plc_errorlevel.showHexOver255 and math.abs(value) > 255 then
        local lo = bit32.band(value, 0xffff)
        local hi = bit32.rshift(value, 16)
        local hex
        if hi > 0 then
            hex = string.format("%x", hi)..string.format("%04.4x", lo)
        else
            hex = string.format("%x", lo)
        end
        text = " 0x"..hex.." "
    else
        text = " "..value.." "
    end
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

