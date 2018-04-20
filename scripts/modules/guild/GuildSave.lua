module(...,package.seeall)

function new()
	local q = {
		dirty = {},
		queue = {},
		head = 1,
		tail = 1,
	}
	setmetatable(q, {__index = _M})
	return q
end

function push(self,id)
	if not self.dirty[id] then
		self.dirty[id] = true
		self.queue[self.head] = id
		self.head = self.head + 1
	end
	--print("ArenaSave::head"..self.head)
end

function pop(self)
	local id = self.queue[self.tail]
	self.dirty[id] = nil
	self.tail = self.tail + 1
	--print("ArenaSave::tail"..self.tail)
	return id
end

function empty(self)
	return self.tail >= self.head
end
