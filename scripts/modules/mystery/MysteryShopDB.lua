module(...,package.seeall) 

function new()
	local o = {
		shop = {},
		shop2 = {},
		refresh = 0,
		refresh2 = 0,
		lastDate = 0,
	}
	setmetatable(o,{__index = _M})
	return o
end
