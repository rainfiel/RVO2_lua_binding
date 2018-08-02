
local render = require "ejoy2dx.render"
local image = require "ejoy2dx.image"
local rvo2 = require "ejoy2dx.rvo2.c"
local geo = require "ejoy2d.geometry"

rvo2.new_social()
rvo2.time_step(1/10)
rvo2.default_agent(40, 10, 1, 1, 10, 8)

local boids = {}
local obstacles = {}

local boid_render = render:create(1001, "boid")

local function add_boid(x, y)
	local inst = rvo2.add_agent(x, y)
	local img = image:load_image("sniper.png")
	boid_render:show(img, 0, render.top_left)
	table.insert(boids, {inst=inst, x=x, y=y, img=img})

	img:ps(x, y, 0.2)
end

local function add_obstacle(...)
	local id = rvo2.add_obstacle(...)
	if id < 0 then return end
	local o = {inst=id, vert={...}, polygon={}}
	for i=1, #o.vert//2 do
		local x, y = render:world_to_screen(render:anchor(render.top_left), o.vert[2*i-1], o.vert[2*i])
		print(x, y)
		table.insert(o.polygon, x)
		table.insert(o.polygon, y)
	end
	table.insert(obstacles, o)
end

local function draw()
	for k, v in ipairs(obstacles) do
		geo.polygon(v.polygon, 0xFFFF0000)
	end
end

local function update(frame)
	rvo2.update()

	for k, v in ipairs(boids) do
		local x, y = rvo2.position(v.inst)
		v.img:ps(x, y, 0.4)
		v.x, v.y = x, y

		local vx, vy = rvo2.velocity(v.inst)
		local rot = math.deg(math.atan(vy, vx))
		-- print(vy,vx, rot)
		v.img:sr(0.4, 0.4, rot)
	end
end

local function touch(x, y)
	x, y = render:screen_to_world(render:anchor(render.top_left), x, y)
	for k, v in ipairs(boids) do
		rvo2.pre_velocity(v.inst, x-v.x, y-v.y)
	end
end

add_obstacle(200, 200, 250, 200, 250, 250, 200, 250)
add_obstacle(280, 200, 330, 200, 330, 250, 280, 250)
rvo2.process_obstacle()

add_boid(250, 255)
add_boid(255, 250)
add_boid(255, 255)
add_boid(260, 255)
add_boid(255, 260)
add_boid(251, 252)
add_boid(253, 254)
add_boid(255, 256)
add_boid(260, 251)
add_boid(252, 262)

return {
	draw = draw,
	update = update,
	touch = touch,
}
