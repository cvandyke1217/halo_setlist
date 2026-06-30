-- frame_app.lua - on-device renderer for the Halo Setlist companion app.
--
-- The phone sends the current chord-chart cursor as a TxPlainText message
-- (flag 0x0a):
--   SETCHORD|<current>|<next>
-- e.g. SETCHORD|Em|G  (next is an empty string at the end of the song)
--
-- The device just renders the big current chord and the smaller "Next: X"
-- below it, shrinking text to fit the circular display.

local data = require('data.min')
local battery = require('battery.min')
local code = require('code.min')
local plain_text = require('plain_text.min')

local TEXT_FLAG = 0x0a   -- host -> device: SETCHORD payload
local CLEAR_FLAG = 0x10  -- host -> device: clear display

local CX = 128

local C_LABEL = 0xC0C0C0
local C_WHITE = 0xFFFFFF
local C_ACCENT = 0x33AAEE

-- The Halo display is a CIRCLE, not a square. Only pixels within this radius
-- of the center (128,128) are actually visible, so all text must fit inside
-- the chord of the circle at its vertical position or it gets clipped.
local SAFE_R = 116

-- Approx width of a glyph string at a given font size (PIL/default-ish metrics).
local function text_width(text, size)
    return #text * size * 0.58
end

-- Half-width of the visible circle at vertical coordinate y.
local function half_width_at(y)
    local dy = math.abs(y - 128)
    if dy >= SAFE_R then return 0 end
    return math.sqrt(SAFE_R * SAFE_R - dy * dy)
end

-- Largest font size <= max_size at which `text` fits the circle at baseline y.
local function fit_size(text, y, max_size, min_size)
    min_size = min_size or 10
    local size = max_size
    while size > min_size do
        -- a glyph row spans y .. y+size; the narrower end constrains us
        local hw = math.min(half_width_at(y), half_width_at(y + size))
        if text_width(text, size) <= 2 * hw then break end
        size = size - 1
    end
    return size
end

-- Draw text horizontally centered, shrinking and clamping to stay in the circle.
local function fit_text(text, y, max_size, color, min_size)
    local size = fit_size(text, y, max_size, min_size)
    frame.display.set_font(1, size)
    local hw = math.min(half_width_at(y), half_width_at(y + size))
    local w = text_width(text, size)
    local x = math.floor(CX - w / 2)
    local left = math.ceil(CX - hw)
    if x < left then x = left end
    frame.display.text(text, x, y, color)
    return size
end

local function split(s, sep)
    local out = {}
    for field in (s .. sep):gmatch('([^' .. sep .. ']*)' .. sep) do
        out[#out + 1] = field
    end
    return out
end

local function clear_display()
    frame.display.clear(0)
    frame.display.show()
end

local function draw_chord(parts)
    local current = parts[2] or '--'
    local next_chord = parts[3] or ''

    frame.display.clear(0)
    fit_text('NOW PLAYING', 34, 16, C_LABEL)
    fit_text(current, 90, 70, C_ACCENT)

    if next_chord ~= '' then
        fit_text('Next: ' .. next_chord, 196, 24, C_WHITE)
    else
        fit_text('End of song', 196, 20, C_LABEL)
    end

    frame.display.show()
end

local function render(payload)
    local parts = split(payload, '|')
    if parts[1] == 'SETCHORD' then draw_chord(parts) end
end

-- message parsers, keyed by message flag
local parsers = {}
parsers[TEXT_FLAG] = plain_text.parse_plain_text
parsers[CLEAR_FLAG] = code.parse_code

-- message handlers, keyed by message flag
local handlers = {}
handlers[TEXT_FLAG] = function(parsed)
    if parsed ~= nil and parsed.string ~= nil then render(parsed.string) end
end
handlers[CLEAR_FLAG] = function(_) clear_display() end

clear_display()
print('Halo Setlist app started')

local last_batt_update = 0

while true do
    local ok, err = pcall(function()
        local items = data.process_raw_items()
        for i = 1, #items do
            local flag = items[i][1]
            local raw = items[i][2]
            local parser = parsers[flag]
            if parser ~= nil then
                handlers[flag](parser(raw))
            end
        end

        last_batt_update = battery.send_batt_if_elapsed(last_batt_update, 120)
        frame.sleep(0.02)
    end)
    if not ok then
        print(err)
        clear_display()
        frame.sleep(0.04)
        break
    end
end
