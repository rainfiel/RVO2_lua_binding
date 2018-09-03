local render = require "ejoy2dx.render"
local image = require "ejoy2dx.image"
local vector2 = require "ejoy2dx.vector2"
local rvo2 = require "ejoy2dx.rvo2.c"

rvo2.new_social()
rvo2.time_step(1/30)
rvo2.default_agent(1000, 10, 0.1, 0.1, 10, 18)

local boid_render = render:create(1002, "boid")

local animation = require "animation"
local function new_bubble(t, r)
	local scale = r*2/374
	local mat = {1024*scale, 0, 0, 1024*scale, 0, 0}
	local ani = animation.new(t or "bubble_pop_1.png", string.format("b_%d", r//1), 
		{TextureAnimation={frameWidth=512,frameHeight=512,startFrame=0,endFrame=5,numLoops=1}},
		{frame_mat=mat})
	return ani.img
end

local function bubble_pop(img, cb)
	img.usr_data.render.frame_delta = 0.8
	img.usr_data.render.ani_playonce = "hide_after_play"
	img.usr_data.render.ani_playonce_callback = cb
end

local boids = {}
local obstacles = {}
local function add_boid(x, y, r)
	local inst = rvo2.add_agent(x, y)
	rvo2.radius(inst, r)
	rvo2.time_hori(inst, r/500)
	-- rvo2.time_hori_obst(inst, 5)
	local img = new_bubble(nil, r)
	img:ps(x, y)
	boid_render:show(img, 0, render.center)
	return {inst=inst,x=x,y=y,r=r,r2=r*r,img=img}
end

local function rm_boid(inst)
	rvo2.position(inst, -9999, -9999)
	rvo2.max_speed(inst, 0)
end

local function add_obstacle(...)
	local id = rvo2.add_obstacle(...)
	if id < 0 then return end
	local o = {inst=id, vert={...}, polygon={}}
	for i=1, #o.vert//2 do
		local x, y = render:world_to_screen(render:anchor(render.top_left), o.vert[2*i-1], o.vert[2*i])
		table.insert(o.polygon, x)
		table.insert(o.polygon, y)
	end
	table.insert(obstacles, o)
end


-- add_obstacle(0, 1.732,  2, -1.732, -2, -1.732)
-- rvo2.process_obstacle()

local colors = {0xFFFF0000, 0xFF00FF00, 0xFF0000FF}
for k=1, 250 do
	local x = math.random(-255, 250)
	local y = math.random(-255, 255)
	local r = math.random(5, 10)
	local b = add_boid(x, y, r)
	-- b.img.color = colors[b.inst%3 + 1]
	rvo2.pre_velocity(b.inst, -x, -y)
	table.insert(boids, b)
end

local freeze_radius = 0
local function update(frame)
	rvo2.update()

	for k, v in ipairs(boids) do
		local x, y = rvo2.position(v.inst)
		local r2 = vector2.dist2(x, y, v.x, v.y)
		if x ~= v.x or y ~= v.y then
			v.img:ps(x, y)
			v.x, v.y = x, y

			if not v.arrived then
				if vector2.dist2(x, y, 0, 0) <= v.r2 then
					v.arrived = true
					v.core = true
				end
			end
		elseif v.arrived then
			-- print(v.inst, rvo2.agent_neighbors_num(v.inst))
		else
			v.arrived = true
		end

		-- if v.core then
		-- 	for x=1, 10 do
		-- 		print("........:", x, rvo2.get_agent_neighbor(v.inst, x))
		-- 	end
		-- end

		-- if not v.arrived then
			rvo2.pre_velocity(v.inst, -x, -y)
		-- else
		-- 	rvo2.velocity(v.inst, 0, 0)
		-- 	rvo2.max_speed(v.inst, 0)
		-- 	v.img.color = 0xFFFF0000
		-- end
		-- local vx, vy = rvo2.velocity(v.inst)
		-- local rot = math.deg(math.atan(vy, vx))
		-- -- print(vy,vx, rot)
		-- v.img:sr(0.4, 0.4, rot)
	end
end

local function draw()
	for k, v in ipairs(obstacles) do
		geo.polygon(v.polygon, 0xFFFF0000)
	end
end

local function touch(x, y)
	x, y = render:screen_to_world(render:anchor(render.center), x, y)
	-- for k, v in ipairs(boids) do
	-- 	rvo2.pre_velocity(v.inst, x-v.x, y-v.y)
	-- end
	for k, v in ipairs(boids) do
		if vector2.dist2(x, y, v.x, v.y) <= v.r2 then
			-- bubble_pop(v.img, function()
			-- 	rm_boid(v.inst)
			-- end)
			rvo2.velocity(v.inst, 0, 0)
			rvo2.max_speed(v.inst)
			rvo2.radius(v.inst, rvo2.radius(v.inst) * 2)
			break
		end
	end
end

return {
	update = update,
	draw = draw,
	touch = touch
}