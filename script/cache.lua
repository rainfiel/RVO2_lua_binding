

local mt = {}
mt.__index = mt

function mt:init_cache()
	self.cache = {}
end

function mt:give_back(item)
	self.cache[item] = true
end

function mt:fetch(raw, item_mt)
	local item = next(self.cache)
	if not item then
		item = setmetatable(raw, item_mt)
		item:init()
	else
		self.cache[item] = nil
	end
	return item
end

return mt