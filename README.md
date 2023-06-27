## awesome-brightness

### Description

Brightness (backlight) indicator+control widget for awesome window manager
based on ``xbacklight`` or ``brightnessctl``.

Note that ``brightnessctl`` and ``acpilight`` seem to work better on some
laptops where ``xbacklight`` does not work!


### Installation

Drop the script into your awesome config folder. Suggestion:

```bash
cd ~/.config/awesome
git clone https://github.com/deficient/brightness.git

sudo pacman -S xorg-xbacklight

# or:

sudo pacman -S acpilight

# or:

sudo pacman -S brightnessctl
```


### Usage

In your `~/.config/awesome/rc.lua`:

```lua
-- load and instanciate module:
local brightness_ctrl = require("brightness") { }


-- add the widget to your wibox
right_layout:add(brightness_ctrl.widget)
```


### Usage options

Full example:

```lua
local brightness_ctrl = require("brightness") {
  backend = nil,
  step = 5,
  timeout = 3,
  levels = {1, 25, 50, 75, 100},
}
```

`backend`
Picks command with which to perform brightness queries and updates.
Allowed values are `nil` (meaning *autodetect*), `"xbacklight"` or
`"brightnessctl"`. Default: `nil`.

`step`
How many percentage points to increase or decrease the brightness level when
clicking the widget. Default: 3.

`timeout`
Interval in seconds at which to check the current brightness level and update
the widget text. Default: 5.

`levels`
Cycle through these brightness percentages on middle-click.
Default: ``{1, 25, 50, 75, 100}`.


### Troubleshooting

If you get errors on startup, try executing the following in a terminal:

```bash
xbacklight -get

# or

brightnessctl get
```

If you get the error "No outputs have backlight property", make sure you have
installed an appropriate display driver, e.g. for intel cards:

```bash
sudo pacman -S xf86-video-intel
```

You may need to restart afterwards.


### Requirements

* [awesome 4.0](http://awesome.naquadah.org/)
