## awesome-brightness

### Description

Brightness (backlight) indicator+control widget for awesome window manager.

### Installation

Drop the script into your awesome config folder. Suggestion:

```bash
cd ~/.config/awesome
git clone https://github.com/coldfix/awesome-brightness.git
```


### Usage

In your `~/.config/awesome/rc.lua`:

```lua
-- load the module
local brightness = require("awesome-brightness.brightness")


-- instanciate the control
brightness_ctrl = brightness({channel="Master"})


-- add the widget to your wibox
right_layout:add(brightness_ctrl.widget)
```


### Requirements

* [awesome 3.5](http://awesome.naquadah.org/)
