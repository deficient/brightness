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
local gtable = require("gears.table")
local naughty = require("naughty")

local timer = gears.timer or timer
local exec = awful.spawn.easy_async


------------------------------------------
-- Private utility functions
------------------------------------------

local function warning(text)
    if not naughty then return end
    local args = {
        title = "Brightness Control",
        preset = naughty.config.presets.normal,
    }
    if naughty.notification then
        args.message = text
        naughty.notification(args)
    else
        args.text = text
        naughty.notify(args)
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
        return tonumber(readcommand("brightnessctl --class=backlight max")) ~= nil
    end,

    parse_output = function(self, output)
        -- dev,class,curr,percent,max
        local _, _, _, percent, _ = output:match("(.*),(.*),(%d*),(%d*)%%,(%d*)")
        return tonumber(percent)
    end,

    get = function(self, callback)
        exec({ self.cmd, "--class=backlight", "-m", "info" }, function(output)
            callback(self:parse_output(output))
        end)
    end,

    set = function(self, percent, callback)
        exec({ self.cmd, "--class=backlight", "-m", "set", percent .. "%" }, function(output)
            callback(self:parse_output(output))
        end)
    end,

    up = function(self, step, callback)
        exec({ self.cmd, "--class=backlight", "-m", "set", step .. "%+" }, function(output)
            callback(self:parse_output(output))
        end)
    end,

    down = function(self, step, callback)
        exec({ self.cmd, "--class=backlight", "-m", "set", step .. "%-" }, function(output)
            callback(self:parse_output(output))
        end)
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
-- Brightness control interface
------------------------------------------
local bcontrol = { backends = backends }

function bcontrol:new(args)
    return setmetatable({}, {__index = self}):init(args)
end

function bcontrol:init(args)
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

    self.is_valid = backend ~= nil
    self.backend = backend
    self.step = tonumber(args.step or '5')
    self.levels = args.levels or {1, 25, 50, 75, 100}

    self.widget = wibox.widget.textbox()

    if self.is_valid then
        self.widget:buttons(gtable.join(
            awful.button({ }, 1, function() self:up() end),
            awful.button({ }, 3, function() self:down() end),
            awful.button({ }, 2, function() self:toggle() end),
            awful.button({ }, 4, function() self:up(1) end),
            awful.button({ }, 5, function() self:down(1) end)
        ))

        self.timer = timer({
            timeout = args.timeout or 3,
            callback = function() self:update() end,
            autostart = true,
            call_now = true
        })
    end

    return self
end

function bcontrol:set_text(value)
    local brightness = math.floor(0.5 + value)
    self.widget:set_text(string.format(" [%3d] ", brightness))
end

function bcontrol:update(opt_value)
    if opt_value and string.match(opt_value, "%S+") then
        self:set_text(opt_value)
    else
        self.backend:get(function(...) self:set_text(...) end)
    end
end

function bcontrol:set(brightness, callback)
    self.backend:set(brightness, callback or function(...) self:update(...) end)
end

function bcontrol:up(step, callback)
    self.backend:up(step or self.step, callback or function(...) self:update(...) end)
end

function bcontrol:down(step, callback)
    self.backend:down(step or self.step, callback or function(...) self:update(...) end)
end

function bcontrol:toggle()
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

return setmetatable(bcontrol, {
  __call = bcontrol.new,
})
-- vim: set ts=4 sw=4 et:
