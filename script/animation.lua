
local utls = require "ejoy2dx.utls"
local image = require "ejoy2dx.image"
local blend = require "ejoy2dx.blend"
local cache_mt = require "cache"
local math = require "math"

local default_duration = 1
local frame_rate = utls.frame_rate

local AniCache = {}

local mt = {}
mt.__index = mt

function mt:init()
	-- print(">>>>>>>>>>>>>>new ani:", self.id)
	self:born()

	local img_cfg = self.img_cfg
	local sx, sy = self.render_cfg.scaleX or 1, self.render_cfg.scaleY or 1
	self.img = image:load_image(self.path, self.name, function(cfg, tx, ty, tw, th)
		self.width, self.height = tw, th
		self.row = math.floor(self.height / self.frame_height)
		self.col = math.floor(self.width / self.frame_width)

		-- print(self.frame_cnt, self.row, self.col, self.width, self.height, self.frame_width, self.frame_height, self.start_frame, self.end_frame)
		if self.frame_cnt > self.row * self.col then
			self.frame_cnt = self.row * self.col
		end
		--HACK
		if self.start_frame > self.end_frame then
			self.start_frame, self.end_frame = self.end_frame, self.start_frame
		end

		local key_x = (img_cfg and img_cfg.key_x or 0.5) or 0.5
		local key_y = (img_cfg and img_cfg.key_y or 0.5) or 0.5
		components = {}
		for i = 1, self.row do
			for j = 1, self.col do
				--zero base, top-left
				local idx = (i-1) * self.col + j - 1

				if idx >= self.start_frame and idx <= self.end_frame then
					local pid = image.add_picture_with_key(key_x, key_y, cfg,
									self.frame_width * (j-1), self.frame_height * (i-1),
									self.frame_width, self.frame_height, false, false, sx, sy)
					table.insert(components, {id=pid})
					tmp = pid
				end
			end
		end
		if #components == 1 then
			components = components[1]
		end
		if not components.id then
			assert(#components > 1, string.format("%d * %d", self.row, self.col))
		end
		image.add_component(cfg, components)

		local frame_mat = img_cfg and img_cfg.frame_mat or nil
		anis = {action="default"}
		for i=1, self.frame_cnt do
			--zero base
			local ani = {{index=i-1}}
			if frame_mat then
				ani[1].mat = frame_mat
			end
			table.insert(anis, ani)
		end
		image.add_animation(cfg, anis)

		-- if img_callback then
		-- 	img_callback(cfg, tx, ty, tw, th)
		-- end
	end)
end

function mt:born()
	local cfg = self.render_cfg.TextureAnimation
	self.frame_width, self.frame_height = tonumber(cfg.frameWidth), tonumber(cfg.frameHeight)
	self.start_frame, self.end_frame = tonumber(cfg.startFrame), tonumber(cfg.endFrame)

	self.loops = tonumber(cfg.numLoops)
	self.loops_count = self.loops
	self.random_start = cfg.randomizeStartTime == "true"

	self.frame_cnt = math.abs(self.end_frame - self.start_frame) + 1
	self.frame_delta = self.start_frame >= self.end_frame and -1 or 1

	self.default_time = tonumber(cfg.animationTimeMS or 1000) / 1000
	
	self:init_play_time()
	-- self.img.frame = self.start_frame
	self.end_callback = nil
	self.auto_release = false

	if self.img then	
		self.img.color = self.render_cfg.color or 0xFFFFFFFF
		self.img.action = "default"
		if self.render_cfg.blendMode then
			self.img.usr_data.render = self.img.usr_data.render or {}
			self.img.usr_data.render.blend_mode=self.render_cfg.blendMode
		end
	end
end

function mt:init_play_time()
	if self.random_start then
		self:set_time(self.default_time * (1+math.random()))
	else
		self:set_time(self.default_time)
	end
end

function mt:ps(x, y, scale)
	self.img:ps(x, y, scale or 1)
end

function mt:sr(rot)
	self.img:sr(rot)
end

function mt:test(...)
	return self.img:test(...)
end

function mt:set_time(seconds)
	self.time_ms = seconds
	self.time_ms = self.time_ms and tonumber(self.time_ms) or default_duration
	self.time_ms = self.time_ms == 0 and default_duration or self.time_ms
	self.time_per_frame = self.time_ms / self.frame_cnt
	self.timer = self.time_per_frame
end

function mt:play(loops)
	self.loops_count = loops and loops - 1 or self.loops
	self.img.frame = 0
	self.timer = self.time_per_frame
end

function mt:pause()
	self.timer = -1
end

function mt:stop()
	self.timer = -1
	if not self.exclusive then
		AniCache:give_back(self)
	end
end

function mt:is_playing()
	return self.timer > 0 or self.is_keep_last
end

function mt:one_shot()
	return self.loops == 0
end

function mt:keep_last()
	self.is_keep_last = true
	self.img.frame = self.img.frame_count - 1
end

function mt:update()
	if self.timer <= 0 or self.frame_cnt==1 then
		return true
	end
	self.timer = self.timer - frame_rate
	if self.timer <= 0 then
		local frame = self.img.frame + self.frame_delta
		self.img.frame = frame
		if frame % (self.img.frame_count - 1)==0 then
			if self.loops_count == 0 then
				self.timer = -1
				return false
			elseif self.loops_count > 0 then
				self.loops_count = self.loops_count - 1
			end
			self:init_play_time()
		end
		self.timer = self.time_per_frame
	end
	return true
end

-------------------------------------------------------------
AniCache.ani_cache = {}

function AniCache.new(path, name, cfg, img_cfg)
	local id = path..name
	local cache = AniCache.ani_cache[id]
	if not cache then
		cache = setmetatable({}, cache_mt)
		cache:init_cache()
		AniCache.ani_cache[id] = cache
	end
	local item = cache:fetch({id=id, path=path, name=name, render_cfg=cfg, img_cfg=img_cfg}, mt)
	item:born()
	return item
end

function AniCache:give_back(ani)
	local cache = self.ani_cache[ani.id]
	cache:give_back(ani)
end

return AniCache
