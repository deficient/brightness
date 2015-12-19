## awesome-brightness

### Description

Brightness (backlight) indicator+control widget for awesome window manager
based on ``xbacklight``.


### Installation

Drop the script into your awesome config folder. Suggestion:

```bash
cd ~/.config/awesome
git clone https://github.com/coldfix/awesome-brightness.git

sudo pacman -S xorg-xbacklight
```


### Usage

In your `~/.config/awesome/rc.lua`:

```lua
-- load the module
local brightness = require("awesome-brightness.brightness")


-- instanciate the control
brightness_ctrl = brightness({})


-- add the widget to your wibox
right_layout:add(brightness_ctrl.widget)
```


### Requirements

* [awesome 3.5](http://awesome.naquadah.org/)
