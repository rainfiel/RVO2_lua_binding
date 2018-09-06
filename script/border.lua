
local fw = require "ejoy2d.framework"
local render = require "ejoy2dx.render"
local geo = require "ejoy2d.geometry"

local M = {}
local border_render = render:create(1000, "border")
-- border_render:show(M, render.top_left)

function M:draw()
	local tl = render:anchor(render.top_left)
	local tr = render:anchor(render.top_right)
	local dl = render:anchor(render.bottom_left)
	local dr = render:anchor(render.bottom_right)

	for i=-1, 1 do
		geo.line(tl.x, tl.y+i, tr.x, tr.y+i, 0xaa888888)
	end
	for i=-1, 1 do
		geo.line(tl.x+i, tl.y, dl.x+i, dl.y, 0xaa888888)
	end
	for i=-1, 1 do
		geo.line(dl.x, dl.y+i, dr.x, dr.y+i, 0xaa888888)
	end
	for i=-1, 1 do
		geo.line(tr.x+i, tr.y, dr.x+i, dr.y, 0xaa888888)
	end

	geo.box(0, 0, tl.x-1, dl.y, 0xaa444444)
	geo.box(tr.x+1, tr.y, fw.GameInfo.width - tr.x - 1, dl.y, 0xaa444444)
end

return {
	draw=draw
}
