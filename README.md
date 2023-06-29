## awesome-brightness

### Description

Brightness indicator/control widget for [awesome wm](https://awesomewm.org/)
based on ``xbacklight`` or ``brightnessctl``.


### Dependencies:

The module requires either of the programs `xbacklight` or `brightnessctl` to work.
On archlinux, the corresponding system packages are called:

- [acpilight](https://archlinux.org/packages/extra/any/acpilight/) or
  [xorg-xbacklight](https://archlinux.org/packages/extra/x86_64/xorg-xbacklight/) for `xbacklight`
- [brightnessctl](https://archlinux.org/packages/extra/x86_64/brightnessctl/) for `brightnessctl`

Note that ``brightnessctl`` and ``acpilight`` seem to work better on some
laptops where ``xorg-xbacklight`` does not work!


### Installation

Drop the script into your awesome config folder. Suggestion:

```bash
cd ~/.config/awesome
git clone https://github.com/deficient/brightness.git
```


### Usage

In your `~/.config/awesome/rc.lua`:

```lua
-- Import and instanciate:
local brightness_ctrl = require("brightness") {
    -- pass options here
}

-- Add widget to the wibox:
s.mywibox:setup {
    ...,
    { -- Right widgets
        ...,
        brightness_ctrl.widget,
    },
}
```

Note that you need to pass `.widget` to the wibox, not the instance itself!

The flag `brightness_ctrl.is_valid` indicates successful initialization.


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

If you get errors on startup, try executing `xbacklight -get` or
`brightnessctl -c backlight get` in a terminal.

If you get the error "No outputs have backlight property", make sure you have
installed an appropriate display driver, e.g. for intel cards:

```bash
sudo pacman -S xf86-video-intel
```

You may need to restart afterwards.


### Requirements

* [awesome 4.0](http://awesome.naquadah.org/)
