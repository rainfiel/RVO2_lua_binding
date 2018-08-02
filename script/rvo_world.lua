
local render = require "ejoy2dx.render"
local image = require "ejoy2dx.image"
local rvo2 = require "ejoy2dx.rvo2.c"

rvo2.new_social()
rvo2.time_step(1/10)
rvo2.default_agent(15, 10, 5, 5, 10, 4)

local boids = {}

local boid_render = render:create(1001, "boid")

local function add_boid(x, y)
	local inst = rvo2.add_agent(x, y)
	local img = image:load_image("sniper.png")
	boid_render:show(img, 0, render.top_left)
	table.insert(boids, {inst=inst, x=x, y=y, img=img})

	img:ps(x, y, 0.2)
end

local function update(frame)
	rvo2.update()

	for k, v in ipairs(boids) do
		local x, y = rvo2.position(v.inst)
		v.img:ps(x, y, 0.2)
		v.x, v.y = x, y
		-- local rot = math.deg(math.atan(vy, vx))
		-- print(vy,vx, rot)
		-- v.img:sr(0.2, 0.2, rot)
	end
end

local function touch(x, y)
	x, y = render:screen_to_world(render:anchor(render.top_left), x, y)
	for k, v in ipairs(boids) do
		rvo2.pre_velocity(v.inst, x-v.x, y-v.y)
	end
end

add_boid(250, 255)
add_boid(255, 250)
add_boid(255, 255)
add_boid(260, 255)
add_boid(255, 260)

return {
	update = update,
	touch = touch,
}
