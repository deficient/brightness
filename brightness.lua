local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

-- Volume Control
-- based on ``xbacklight``!


-- alternative ways:
--  sudo setpci -s 00:02.0 F4.B=80
--  xgamma -gamma .75
--  xrandr --output LVDS1 --brightness 0.9
--  echo X > /sys/class/backlight/intel_backlight/brightness
--  xbacklight


------------------------------------------
-- Private utility functions
------------------------------------------

local function readcommand(command)
    local file = io.popen(command)
    local text = file:read('*all')
    file:close()
    return text
end

local function quote_arg(str)
    return "'" .. string.gsub(str, "'", "'\\''") .. "'"
end

local function quote_args(first, ...)
    if #{...} == 0 then
        return quote_arg(first)
    else
        return quote_arg(first), quote_args(...)
    end
end

local function make_argv(...)
    return table.concat({quote_args(...)}, " ")
end


------------------------------------------
-- Volume control interface
------------------------------------------

local vcontrol = {}

function vcontrol:new(args)
    return setmetatable({}, {__index = self}):init(args)
end

function vcontrol:init(args)
    self.cmd = "xbacklight"
    self.step = args.step or '5'

    self.widget = wibox.widget.textbox()
    self.widget.set_align("right")

    self.widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function() self:up() end),
        awful.button({ }, 3, function() self:down() end),
        awful.button({ }, 2, function() self:toggle() end)
    ))

    self.timer = gears.timer({ timeout = args.timeout or 3 })
    self.timer:connect_signal("timeout", function() self:get() end)
    self.timer:start()
    self:get()

    return self
end

function vcontrol:exec(...)
    return readcommand(make_argv(self.cmd, ...))
end

function vcontrol:get()
    local brightness = math.floor(0.5+tonumber(self:exec("-get")))
    self.widget:set_text(string.format(" [%3d] ", brightness))
    return brightness
end

function vcontrol:set(brightness)
    self:exec('-set', tostring(brightness))
    self:get()
end

function vcontrol:up()
    self:exec("-inc", self.step)
    self:get()
end

function vcontrol:down()
    self:exec("-dec", self.step)
    self:get()
end

function vcontrol:toggle()
    if self:get() >= 50 then
      self:set(0)
    else
      self:set(100)
    end
end

return setmetatable(vcontrol, {
  __call = vcontrol.new,
})

