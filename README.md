# nodemcu-lcd1602
16x2 LCD I2C Lua Module for NodeMCU

## Required firmware modules
- bit
- i2c
- tmr

## Usage
```lua
local lcd = require("lcd1602")

-- may be different
scl = 1
sda = 2

i2c.setup(0, sda, scl, i2c.SLOW)
lcd.init(0x3F) -- may be different
lcd.print(0, 0, "Hello World.")
```
