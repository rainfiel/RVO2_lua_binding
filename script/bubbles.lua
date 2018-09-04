local render = require "ejoy2dx.render"
local image = require "ejoy2dx.image"
local vector2 = require "ejoy2dx.vector2"
local rvo2 = require "ejoy2dx.rvo2.c"

rvo2.new_social()
rvo2.time_step(1/30)
rvo2.default_agent(1000, 10, 0.1, 0.1, 10, 18)
local neighbor_tor = 1

local boid_render = render:create(1002, "boid")

local bubble_res = {
	{PopAni=2, Path = [[BubbleAnimation_04.png]], Size=200,TextureAnimation={frameWidth=200,frameHeight=200,startFrame=0,endFrame=29,numLoops=1}},
	{Path = [[BubbleExplosion2.png]], Size=400,TextureAnimation={frameWidth=400,frameHeight=400,startFrame=0,endFrame=11,numLoops=1}},
	
	{PopAni=4, Path = [[BubbleAnimation_02.png]], Size=200,TextureAnimation={frameWidth=200,frameHeight=200,startFrame=0,endFrame=29,numLoops=1}},
	{Path = [[BubbleExplosion.png]], Size=400,TextureAnimation={frameWidth=400,frameHeight=400,startFrame=0,endFrame=11,numLoops=1}},

	{PopAni=6, Path = [[BubbleAnimation_03.png]], Size=200,TextureAnimation={frameWidth=200,frameHeight=200,startFrame=0,endFrame=29,numLoops=1}},
	{Path = [[BubbleExplosion.png]], Size=400,TextureAnimation={frameWidth=400,frameHeight=400,startFrame=0,endFrame=11,numLoops=1}},

	{PopAni=8, Path = [[BubbleAnimation_Transparent_6x5.png]], Size=200,TextureAnimation={frameWidth=200,frameHeight=200,startFrame=0,endFrame=29,numLoops=1}},
	{Path = [[BubbleExplosion2.png]], Size=400,TextureAnimation={frameWidth=400,frameHeight=400,startFrame=0,endFrame=11,numLoops=1}},

	{Path = [[bubble_pop_1.png]], Size=374,TextureAnimation={frameWidth=512,frameHeight=512,startFrame=0,endFrame=5,numLoops=1}},
}

local animation = require "animation"
local function new_bubble(t, r)
	local cfg = bubble_res[t or 7]
	local scale = r*2/cfg.Size
	local mat = {1024*scale, 0, 0, 1024*scale, 0, 0}
	local ani = animation.new(cfg.Path, string.format("b_%d", r//1), 
		cfg,
		{frame_mat=mat})
	return ani.img, cfg
end

local function bubble_pop(b, cb)
	boid_render:hide(b.img)
	local img, cfg = new_bubble(b.cfg.PopAni, b.r)
	boid_render:show(img, 0, render.center)
	img:ps(b.x, b.y)
	-- img.color = b.img.color
	-- img.usr_data.render.frame_delta = math.random()
	img.usr_data.render.ani_playonce = "hide_after_play"
	img.usr_data.render.ani_playonce_callback = cb
	b.img = img
end

local boids = {}
local boids_map = {}
local obstacles = {}
local colors = {0xAAFF0000, 0xAA00FF00, 0xAA0000FF}
-- local types = {3, 5, 7}
local types = {1, 1, 1}
local function add_boid(x, y, r, type)
	local inst = rvo2.add_agent(x, y)
	rvo2.radius(inst, r)
	rvo2.time_hori(inst, type == 0 and r/50000 or r/500)
	if type == 0 then
		rvo2.max_neighbors(inst, 20)
		rvo2.time_hori_obst(inst, r/50000)
	end
	-- rvo2.time_hori_obst(inst, 5)

	local img, cfg = new_bubble(types[type], r)
	img:ps(x, y)
	img.color = colors[type] or 0xFFFFFFFF
	boid_render:show(img, 0, render.center)
	return {type=type,inst=inst,x=x,y=y,r=r,r2=r*r,img=img,cfg=cfg}
end

local function rm_boid(inst)
	rvo2.position(inst, -9999-inst*100, -9999-inst*100)
	rvo2.max_speed(inst, 0)
	boids_map[inst] = nil
	for k, v in ipairs(boids) do
		if v.inst == inst then
			table.remove(boids, k)
			break
		end
	end
end

local function neighbors(boid, check_type, all, cnt)
	all = all or {}
	cnt = cnt or 0
	local num = rvo2.agent_neighbors_num(boid.inst)
	for k=1, num do
		local n = rvo2.get_agent_neighbor(boid.inst, k)
		local nb = boids_map[n]
		if not all[n] and (not check_type or nb.type == boid.type) then
			if math.abs(vector2.dist(nb.x, nb.y, boid.x, boid.y) - nb.r - boid.r) <= neighbor_tor then
				all[n] = nb
				cnt = cnt + 1
				all, cnt = neighbors(nb, check_type, all, cnt)
			end
		end
	end
	return all, cnt
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

local max_r = 0
for k=1, 250 do
	local x = math.random(-255, 250)
	local y = math.random(-255, 255)
	local r = math.random(5, 10)
	max_r = r * r + max_r
	local b = add_boid(x, y, r, #boids%3+1)
	rvo2.pre_velocity(b.inst, -x, -y)
	table.insert(boids, b)
	boids_map[b.inst] = b
end

print("max_r:", math.sqrt(max_r))

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

		if v.r_speed then
			v.r = v.r + v.r_speed
			if v.r >= v.r_target then
				v.r = v.r_target
				v.r_speed = nil
				v.img.usr_data.render.ani_playonce = true
			end
			rvo2.radius(v.inst, v.r)
			v.img:ps(v.x, v.y, v.r / v.r_target)
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
			if #boids == 1 then
				bubble_pop(v, function()
					rm_boid(v.inst)
				end)
				print("........radius:", v.r)
				return
			end
			local all, cnt = neighbors(v, true)
			if cnt >= 3 then
				local r = 0
				for m, n in pairs(all) do
					r = r + n.r2
					bubble_pop(n, function()
						rm_boid(n.inst)
					end)
				end

				r = math.sqrt(r)
				local b = add_boid(v.x, v.y, r, 0)
				b.r_speed = r / 30
				b.r_target = r
				b.r = 0
				rvo2.radius(v.inst, 0.01)
				b.img:ps(v.x, v.y, 0)
				rvo2.pre_velocity(b.inst, -x, -y)
				table.insert(boids, b)
				boids_map[b.inst] = b
			end
			-- rvo2.velocity(v.inst, 0, 0)
			-- rvo2.max_speed(v.inst)
			-- rvo2.radius(v.inst, rvo2.radius(v.inst) * 2)
			break
		end
	end
end

return {
	update = update,
	draw = draw,
	touch = touch
}
