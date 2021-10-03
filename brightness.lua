--[[

Brightness control
==================

based on `xbacklight`!

alternative ways to control brightness:
    sudo setpci -s 00:02.0 F4.B=80
    xgamma -gamma .75
    xrandr --output LVDS1 --brightness 0.9
    echo X > /sys/class/backlight/intel_backlight/brightness
    xbacklight

--]]

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")

local timer = gears.timer or timer


------------------------------------------
-- Private utility functions
------------------------------------------

local function warning(text)
    if naughty then
        naughty.notify {
            title = "Brightness Control",
            text = text,
            preset = naughty.config.presets.normal,
        }
    end
end

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

local function exec(...)
    return readcommand(make_argv(...))
end


------------------------------------------
-- Backend: brightnessctl
------------------------------------------

local backends = {}

backends.brightnessctl = {
    cmd = "brightnessctl",
    _max = nil,

    supported = function(self)
        return self:max() ~= nil
    end,

    get = function(self)
        local level = tonumber(exec(self.cmd, "get"))
        return self:to_percent(level)
    end,

    set = function(self, percent)
        local level = self:from_percent(percent)
        exec(self.cmd, "set", tostring(level))
    end,

    up = function(self, step)
        self:set(math.min(self:get() + step, 100))
    end,

    down = function(self, step)
        self:set(math.max(self:get() - step, 0))
    end,

    to_percent = function(self, value)
        return value * 100 / self:max()
    end,

    from_percent = function(self, percent)
        return math.floor(percent * self:max() / 100)
    end,

    max = function(self)
        if self._max == nil then
            self._max = tonumber(exec(self.cmd, "max"))
        end
        return self._max
    end,
}

------------------------------------------
-- Backend: xbacklight
------------------------------------------

backends.xbacklight = {
    cmd = "xbacklight",

    supported = function(self)
        return self:get() ~= nil
    end,

    get = function(self)
        return tonumber(exec(self.cmd, "-get"))
    end,

    set = function(self, value)
        exec(self.cmd, "-set", tostring(value))
    end,

    up = function(self)
        exec(self.cmd, "-inc", tostring(step))
    end,

    down = function(self)
        exec(self.cmd, "-dec", tostring(step))
    end,
}


------------------------------------------
-- Volume control interface
------------------------------------------
local vcontrol = { backends = backends }

function vcontrol:new(args)
    return setmetatable({}, {__index = self}):init(args)
end

function vcontrol:init(args)
    -- determine backend
    local backend = args.backend

    if type(backend) == "string" then
        backend = backends[backend]
        if backend == nil then
            warning("Unknown backend: " .. args.backend)
        end
    end

    if backend == nil then
        if backends.brightnessctl:supported() then
            backend = backends.brightnessctl
        elseif backends.xbacklight:supported() then
            backend = backends.xbacklight
        else
            warning("Neither brightnessctl nor xbacklight seems to work")
        end
    end

    self.backend = backend
    self.step = tonumber(args.step or '5')

    self.widget = wibox.widget.textbox()
    self.widget.set_align("right")

    self.widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function() self:up() end),
        awful.button({ }, 3, function() self:down() end),
        awful.button({ }, 2, function() self:toggle() end),
        awful.button({ }, 4, function() self:up(1) end),
        awful.button({ }, 5, function() self:down(1) end)
    ))

    self.timer = timer({ timeout = args.timeout or 3 })
    self.timer:connect_signal("timeout", function() self:get() end)
    self.timer:start()
    self:get()

    return self
end

function vcontrol:exec(...)
    return readcommand(make_argv(self.cmd, ...))
end

function vcontrol:get()
    local brightness = math.floor(0.5 + self.backend:get())
    self.widget:set_text(string.format(" [%3d] ", brightness))
    return brightness
end

function vcontrol:set(brightness)
    self.backend:set(brightness)
    self:get()
end

function vcontrol:up(step)
    self.backend:up(step or self.step)
    self:get()
end

function vcontrol:down(step)
    self.backend:down(step or self.step)
    self:get()
end

function vcontrol:toggle()
    if self:get() >= 50 then
      self:set(1)
    else
      self:set(100)
    end
end

return setmetatable(vcontrol, {
  __call = vcontrol.new,
})
