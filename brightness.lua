local awful = require("awful")
local wibox = require("wibox")

-- Volume Control

-- vcontrol.mt: module (class) metatable
-- vcontrol.wmt: widget (instance) metatable
local vcontrol = { mt = {}, wmt = {} }
vcontrol.wmt.__index = vcontrol


-- alternative ways:
--  sudo setpci -s 00:02.0 F4.B=80
--  xgamma -gamma .75
--  xrandr --output LVDS1 --brightness 0.9
--  echo X > /sys/class/backlight/intel_backlight/brightness
--  xbacklight


------------------------------------------
-- Private utility functions
------------------------------------------

function fg(color, text)
    if color == nil then
        return text
    else
        return '<span color="' .. color .. '">' .. text .. '</span>'
    end
end

local function readcommand(command)
    local file = io.popen(command)
    local text = file:read('*all')
    file:close()
    return text
end

local function readfile(command)
    local file = io.open(command)
    local text = file:read('*all')
    file:close()
    return text
end

local function writefile(filename, text)
  local file = io.open(filename, 'w')
  file:write(text)
  file:close()
end

local function quote(str)
    return "'" .. string.gsub(str, "'", "'\\''") .. "'"
end

local function arg(first, ...)
    if #{...} == 0 then
        return quote(first)
    else
        return quote(first), arg(...)
    end
end

local function argv(...)
    return table.concat({arg(...)}, " ")
end


------------------------------------------
-- Volume control interface
------------------------------------------

function vcontrol.new(args)
    local sw = setmetatable({}, vcontrol.wmt)

    sw.path = args.path or "/sys/class/backlight/intel_backlight"
    sw.max_brightness = args.max_brightness or math.floor(tonumber(readfile(sw.path .. "/max_brightness")))
    sw.step = args.step or math.ceil(0.2 * sw.max_brightness)

    sw.widget = wibox.widget.textbox()
    sw.widget.set_align("right")

    sw.widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function() sw:up() end),
        awful.button({ }, 3, function() sw:down() end),
        awful.button({ }, 2, function() sw:toggle() end)
    ))

    sw.timer = timer({ timeout = args.timeout or 3 })
    sw.timer:connect_signal("timeout", function() sw:get() end)
    sw.timer:start()
    sw:get()

    return sw
end

function vcontrol:exec(...)
    return readcommand(argv(self.cmd, ...))
end

function vcontrol:get()
    local absolute_brightness = tonumber(readfile(self.path .. "/brightness"))
    local relative_brightness = absolute_brightness / self.max_brightness
    local percentage = math.floor(100*relative_brightness)
    self.widget:set_text(string.format(" [%3d] ", percentage))
    return percentage
end

function vcontrol:set(percentage)
    percentage = math.max(percentage, 0)
    percentage = math.min(percentage, 100)
    brightness = percentage*self.max_brightness/100
    writefile(self.path .. "/brightness", tostring(brightness))
    self:get()
end

function vcontrol:up()
    self:set(self:get() + self.step)
    self:get()
end

function vcontrol:down()
    self:set(self:get() - self.step)
    self:get()
end

function vcontrol:toggle()
    if self:get() >= 50 then
      self:set(0)
    else
      self:set(100)
    end
end

function vcontrol.mt:__call(...)
    return vcontrol.new(...)
end

return setmetatable(vcontrol, vcontrol.mt)

