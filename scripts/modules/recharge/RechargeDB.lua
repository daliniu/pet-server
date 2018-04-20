module(...,package.seeall)

function new()
	local o = {
		got = {},
		num = 0,
		id = 0,
	}
	setmetatable(o,{__index = _M})
	return o
end

function addNum(self,val)
	self.num = self.num + val
end

function getNum(self)
	return self.num
end

function nextAct(self,id)
	if self.id ~= id then
		self.id = id
		self.num = 0
		self.got = {}
	end
end
