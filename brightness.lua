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

    sw.cmd = "xbacklight"
    sw.step = args.step or '20'

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
    local brightness = math.floor(tonumber(self:exec("-get")))
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

function vcontrol.mt:__call(...)
    return vcontrol.new(...)
end

return setmetatable(vcontrol, vcontrol.mt)

