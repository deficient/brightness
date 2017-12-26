## awesome-brightness

### Description

Brightness (backlight) indicator+control widget for awesome window manager
based on ``xbacklight``.


### Installation

Drop the script into your awesome config folder. Suggestion:

```bash
cd ~/.config/awesome
git clone https://github.com/deficient/brightness.git

sudo pacman -S xorg-xbacklight
```


### Usage

In your `~/.config/awesome/rc.lua`:

```lua
-- load the module
local brightness = require("brightness")


-- instanciate the control
brightness_ctrl = brightness({})


-- add the widget to your wibox
right_layout:add(brightness_ctrl.widget)
```

### Troubleshooting

If you get errors on startup, try executing the following in a terminal:

```bash
xbacklight -get
```

If you get the error "No outputs have backlight property", make sure you have
installed an appropriate display driver, e.g. for intel cards:

```bash
sudo pacman -S xf86-video-intel
```

You may need to restart afterwards.


### Requirements

* [awesome 4.0](http://awesome.naquadah.org/) or possibly 3.5
