local ej = require "ejoy2d"
local ejoy2dx = require "ejoy2dx"
local fw = require "ejoy2d.framework"
local package = require "ejoy2dx.package"
local image = require "ejoy2dx.image"
local message = require "ejoy2dx.message"
local render = require "ejoy2dx.render"
local border = require "border"
-- local world = require "world"

render:fixed_adapter(800, 600)
-- local rvo_world = require "rvo_world"

local ani_play = require "ejoy2dx.animation"
ani_play:init(30)

local bubbles = require "bubbles"
-- local animation = require "animation"
-- local ani = animation.new("bubble_pop_1.png", "b1", {TextureAnimation={frameWidth=512,frameHeight=512,startFrame=0,endFrame=5,numLoops=1}})
-- ani_play:play(ani.img)
-- ani.img.usr_data.anim:set_duration(0.5)
-- ani.img.usr_data.anim.num_loops = 1

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
	ani_play:update()

	-- ani.frame = (ani.frame or 0) + 0.3
	-- ani.img.frame = ani.frame//1
	game.frame = game.frame + 1
	-- world.update(game.frame)
	-- rvo_world.update(game.frame)
	bubbles.update()
end

function game.drawframe()
	ej.clear(0xFF008888)
	render:draw()
	-- rvo_world.draw()
	bubbles.draw()
end

function game.touch(what, x, y)
	-- if what == "BEGIN" then
	-- 	-- world.touch(x, y)
	-- 	-- rvo_world.touch(x, y)
	-- 	return bubbles.touch(x, y)
	-- end
	return false
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

function game.gesture(...)
	bubbles.gesture(...)
end

ej.start(game)


