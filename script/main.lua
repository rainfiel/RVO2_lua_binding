local ej = require "ejoy2d"
local ejoy2dx = require "ejoy2dx"
local fw = require "ejoy2d.framework"
local package = require "ejoy2dx.package"
local image = require "ejoy2dx.image"
local message = require "ejoy2dx.message"
local render = require "ejoy2dx.render"
local border = require "border"
-- local world = require "world"

render:fixed_adapter(500, 500)
local rvo_world = require "rvo_world"


if OS == "WINDOWS" then
	local keymap = require "ejoy2dx.keymap"
	local windows_hotkey = require "ejoy2dx.windows_hotkey"
	windows_hotkey:init()
	windows_hotkey.handlers.up[keymap.VK_A] = function(char, is_repeat)
		print("KEY A up", is_repeat)
	end
end

package:path(fw.WorkDir..[[/asset/?]])

local game = {frame=0}

function game.update()
	game.frame = game.frame + 1
	-- world.update(game.frame)
	rvo_world.update(game.frame)
end

function game.drawframe()
	ej.clear(0xFFFFFFFF)
	render:draw()
	rvo_world.draw()
end

function game.touch(what, x, y)
	if what == "END" then
		-- world.touch(x, y)
		rvo_world.touch(x, y)
	end
	return true
end

function game.message(...)
	message.on_message(...)
end

function game.handle_error(...)
end

function game.on_resume()
end

function game.on_pause()
end

function game.gesture()
end

ej.start(game)


