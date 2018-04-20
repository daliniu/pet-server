module(...,package.seeall)

function new()
	local q = {
		dirty = {},
		queue = {},
		head = 1,
		tail = 1,
		pair = nil,
	}
	setmetatable(q, {__index = _M})
	return q
end

function push(self,rank)
	if self.pair then
		local pos = self.dirty[rank]
		local pairPos = self.dirty[self.pair]
		if pos then
			if pos ~= pairPos then
				for k,v in pairs(self.queue[pos]) do
					self.dirty[v] = pairPos
					table.insert(self.queue[pairPos],v)
				end
				self.queue[pos] = {}
				self.dirty[rank] = pairPos
			end
		else
			self.dirty[rank] = pairPos
			table.insert(self.queue[pairPos],rank)
		end
	else
		if not self.dirty[rank] then
			self.dirty[rank] = self.head
			self.queue[self.head] = {}
			table.insert(self.queue[self.head],rank)
			self.head = self.head + 1
		end
	end
	--print("ArenaSave::head"..self.head)
	--print("ArenaSave::tail"..self.tail)
	--print("self.dirty")
	--Util.print_r(self.dirty)
	--print("self.queue")
	--Util.print_r(self.queue)
	self.pair = rank
end

function pushEnd(self)
	self.pair = nil
end

function pop(self)
	local rankArr = self.queue[self.tail]
	for k,v in pairs(rankArr) do
		self.dirty[v] = nil
	end
	self.queue[self.tail] = nil
	self.tail = self.tail + 1
	--print("ArenaSave::head"..self.head)
	--print("ArenaSave::tail"..self.tail)
	--print("self.dirty")
	--Util.print_r(self.dirty)
	--print("self.queue")
	--Util.print_r(self.queue)
	return rankArr
end

function empty(self)
	return self.tail >= self.head
end
