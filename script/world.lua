
local render = require "ejoy2dx.render"
local image = require "ejoy2dx.image"
local boid = require "ejoy2dx.boid.c"

local social = boid.new_social()
local boids = {}

local boid_render = render:create(1001, "boid")

local function add_boid(x, y)
	local inst = boid.add_life(social, x, y)
	local img = image:load_image("sniper.png")
	boid_render:show(img, 0, render.top_left)
	table.insert(boids, {inst=inst, x=x, y=y, img=img})

	boid.set_maxforce(inst, 0.1)
	boid.set_maxspeed(inst, 10/30)
	boid.set_neighbour_dist(inst, 50)
	boid.set_boid_seperation(inst, 10)
	boid.set_flock_ratio(inst, 100,100,100,100)
end

local function update(frame)
	boid.update(social)

	for k, v in ipairs(boids) do
		local x, y, vx, vy = boid.get_data(v.inst)
		v.img:ps(x, y, 0.2)
		local rot = math.deg(math.atan(vy, vx))
		print(vy,vx, rot)
		v.img:sr(0.2, 0.2, rot)
	end
end

local function touch(x, y)
	x, y = render:screen_to_world(render:anchor(render.top_left), x, y)
	for k, v in ipairs(boids) do
		boid.set_target(v.inst, x+k*4, y+k*4)
	end
end

add_boid(250, 255)
add_boid(255, 250)
add_boid(255, 255)

return {
	update = update,
	touch = touch,
}
