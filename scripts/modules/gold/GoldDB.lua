module(...,package.seeall)

function new()
	local o = {
		cnt = 0,
		reset = 0,
	}
	setmetatable(o,{__index = _M})
	return o
end
