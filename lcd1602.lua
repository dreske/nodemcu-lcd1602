local lcd = {}

local _address
local _backlight
local _displayfunction
local _displaycontrol
local _displaymode

local LCD_8BITMODE = 0x10
local LCD_4BITMODE = 0x00
local LCD_2LINE = 0x08
local LCD_1LINE = 0x00
local LCD_5x10DOTS = 0x04
local LCD_5x8DOTS = 0x00

local LCD_CLEARDISPLAY = 0x01
local LCD_RETURNHOME = 0x02
local LCD_ENTRYMODESET = 0x04
local LCD_DISPLAYCONTROL = 0x08
local LCD_SETDDRAMADDR = 0x80

local LCD_ENTRYRIGHT = 0x00
local LCD_ENTRYLEFT = 0x02
local LCD_ENTRYSHIFTINCREMENT = 0x01
local LCD_ENTRYSHIFTDECREMENT = 0x00

local LCD_DISPLAYON = 0x04
local LCD_CURSORON = 0x02
local LCD_BLINKON = 0x01

local LCD_BACKLIGHT = 0x08
local LCD_NOBACKLIGHT = 0x00



--- Writes the given data to the I2C bus
-- @param data the data
--
local function writeData(data)
    i2c.start(0)
    i2c.address(0, _address, i2c.TRANSMITTER)
    i2c.write(0, bit.bor(data, _backlight))
    i2c.stop(0)
end

--- Writes the given data and the enable pulse to the display
-- @param data the data to write
--
local function writeEnablePulse(data)
    writeData(bit.bor(data, 0x04))
    tmr.delay(1)

    writeData(bit.band(data, bit.bnot(0x04)))
    tmr.delay(50)
end

--- Writes 4 bits to the display and sends the enable pulse
-- @param value the data to write
--
local function write4Bits(value)
    writeData(value)
    writeEnablePulse(value)
end

--- Sends the given data to the display
-- @param value the data
-- @param mode the mode. May be 0 for a command, 1 for a register write
--
local function send(value, mode)
    local high = bit.band(value, 0xF0)
    local low = bit.lshift(bit.band(value, 0x0F), 4)
    write4Bits(bit.bor(high, mode))
    write4Bits(bit.bor(low, mode))
end

--- Sends a command to the display
-- @param value the command
--
local function command(value)
    send(value, 0)
end

--- Writes the display register
-- @param value the data to write
--
local function write(value)
    send(value, 1)
end

--- Toggles a single display control flag
-- @param flag the flag
-- @param enabled true if the flag should be enabled; false otherwise
--
local function displaycontrol(flag, enabled)
    if enabled == true then
        _displaycontrol = bit.bor(_displaycontrol, flag)
    else
        _displaycontrol = bit.band(_displaycontrol, bit.bnot(flag))
    end
    command(bit.bor(LCD_DISPLAYCONTROL, _displaycontrol))
end

--- Clears the display
--
function lcd.clear()
    command(LCD_CLEARDISPLAY)
    tmr.delay(2000)
end

function lcd.home()
    command(LCD_RETURNHOME)
    tmr.delay(2000)
end

--- Turns the backlight on or off
-- @param enabled true if the backlight should be enabled; false if not
--
function lcd.backlight(enabled)
    _backlight = enabled and LCD_BACKLIGHT or LCD_NOBACKLIGHT
    writeData(0)
end

--- Sets the cursor position
-- @param col the column
-- @param row the row
--
function lcd.cursorPosition(col, row)
    command(LCD_SETDDRAMADDR + (col + (row * 0x40)))
end

--- Turns the display on or off
-- @param enabled true if the display should be enabled; false if not
--
function lcd.display(enabled)
    displaycontrol(LCD_DISPLAYON, enabled)
end

--- Turns the cursor on or off
-- @param enabled true if the cursor should be enabled; false if not
--
function lcd.cursor(enabled)
    displaycontrol(LCD_CURSORON, enabled)
end

--- Turns the cursor blinking on or off
-- @param enabled true if the blinking cursor should be enabled; false if not
--
function lcd.blink(enabled)
    displaycontrol(LCD_BLINKON, enabled)
end

--- Initializes the LCD
-- @param address the I2C device address
--
function lcd.init(address)
    _address = address
    _backlight = LCD_BACKLIGHT
    _displayfunction = bit.bor(LCD_4BITMODE, LCD_2LINE, LCD_5x8DOTS)

    writeData(_backlight)
    tmr.delay(1000000)

    write4Bits(bit.lshift(0x03, 4))
    tmr.delay(4500)

    write4Bits(bit.lshift(0x03, 4))
    tmr.delay(4500)

    write4Bits(bit.lshift(0x03, 4))
    tmr.delay(150)

    write4Bits(bit.lshift(0x02, 4))
    command(bit.bor(0x20, _displayfunction))

    -- Default parameters for display initialization
    _displaycontrol = bit.bor(LCD_DISPLAYON)
    command(bit.bor(LCD_DISPLAYCONTROL, _displaycontrol))

    lcd.clear()

    _displaymode = bit.bor(LCD_ENTRYLEFT, LCD_ENTRYSHIFTDECREMENT)
    command(bit.bor(LCD_ENTRYMODESET, _displaymode))

    lcd.home()
end

--- Prints the given text to the specified cursor position
-- @param col the column
-- @param row the row
-- @param value the text to print
--
function lcd.print(col, row, value)
    lcd.cursorPosition(col, row)
    for i = 1, #value do
        write(value:byte(i))
    end
end


return lcd
