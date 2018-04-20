module(...,package.seeall) 

function new()
	local o = {
		shop = {},
		refresh = 0,
		lastDate = 0,
	}
	setmetatable(o,{__index = _M})
	return o
end
