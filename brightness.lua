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
local exec = awful.spawn.easy_async


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
    -- I know, you should *never* use `io.popen`, but it's called at most once
    -- per backend through the whole awesome session… I promise!
    local file = io.popen(command)
    local text = file:read('*all')
    file:close()
    return text
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

    get = function(self, callback)
        exec({self.cmd, "get"}, function(output)
            local level = tonumber(output)
            callback(self:to_percent(level))
        end)
    end,

    set = function(self, percent, callback)
        local level = self:from_percent(percent)
        exec({self.cmd, "set", tostring(level)}, callback)
    end,

    up = function(self, step, callback)
        self:get(function(value)
            self:set(math.min(value + step, 100), callback)
        end)
    end,

    down = function(self, step, callback)
        self:get(function(value)
            self:set(math.max(value - step, 0), callback)
        end)
    end,

    to_percent = function(self, value)
        return value * 100 / self:max()
    end,

    from_percent = function(self, percent)
        return math.floor(percent * self:max() / 100)
    end,

    max = function(self)
        if self._max == nil then
            self._max = tonumber(readcommand("brightnessctl max"))
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
        return tonumber(readcommand("xbacklight -get")) ~= nil
    end,

    get = function(self, callback)
        exec({self.cmd, "-get"}, function(output)
            callback(tonumber(output))
        end)
    end,

    set = function(self, value, callback)
        exec({self.cmd, "-set", tostring(value)}, callback)
    end,

    up = function(self, step, callback)
        exec({self.cmd, "-inc", tostring(step)}, callback)
    end,

    down = function(self, step, callback)
        exec({self.cmd, "-dec", tostring(step)}, callback)
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
            backend = nil
            warning("Neither brightnessctl nor xbacklight seems to work")
        end
    end

    self.backend = backend
    self.step = tonumber(args.step or '5')
    self.levels = args.levels or {1, 25, 50, 75, 100}

    if backend == nil then
        self.widget = nil
        self.timer = nil
    else
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
        self.timer:connect_signal("timeout", function() self:update() end)
        self.timer:start()
        self:update()
    end

    return self
end

function vcontrol:update()
    self.backend:get(function(value)
        local brightness = math.floor(0.5 + value)
        self.widget:set_text(string.format(" [%3d] ", brightness))
        return brightness
    end)
end

function vcontrol:set(brightness, callback)
    self.backend:set(brightness, callback or function() self:update() end)
end

function vcontrol:up(step, callback)
    self.backend:up(step or self.step, callback or function() self:update() end)
end

function vcontrol:down(step, callback)
    self.backend:down(step or self.step, callback or function() self:update() end)
end

function vcontrol:toggle()
    self.backend:get(function(value)
        local ilevel = 1
        for i, lv in ipairs(self.levels) do
            if math.abs(lv - value) < math.abs(self.levels[ilevel] - value) then
                ilevel = i
            end
        end
        self:set(self.levels[ilevel % #(self.levels) + 1])
    end)
end

return setmetatable(vcontrol, {
  __call = vcontrol.new,
})
