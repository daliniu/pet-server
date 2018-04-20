module(...,package.seeall)

function new()
	local o = {}
	setmetatable(o,{__index = _M})
	return o
end
