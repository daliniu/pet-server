module(...,package.seeall)
TrainDefine = require("modules.train.TrainDefine")

function new()
	local o = {
		base = {},
		current = {},
	}
	for i = 1,#TrainDefine.ATTRS do
		local name = TrainDefine.ATTRS[i]
		table.insert(o.base,{name = name,val = 0})
		table.insert(o.current,{name = name,val = 0})
	end
	setmetatable(o,{__index = _M})
	return o
end

function init(heroDB)
	if not heroDB.train then
		heroDB.train = new()
	end
end

