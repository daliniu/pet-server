module(...,package.seeall)
local NewOpenLogic = require("modules.newopen.NewOpenLogic")

function new()
	local o = {}
	for i = 1,7 do
		table.insert(o,{rechargeNum = 0,rechargeGet = 0,loginGet= 1,discountGet = 0})
	end
	setmetatable(o,{__index = _M})
	return o
end

function setCurStatus(self,name,status)
	local day = NewOpenLogic.getCurOpenDay()
	setStatus(self,day,name,status)
end

function setStatus(self,day,name,status)
	if self[day] then
		self[day][name] = status
	end
end

function getCurStatus(self,name)
	local day = NewOpenLogic.getCurOpenDay()
	return getStatus(self,day,name)
end

function getStatus(self,day,name)
	if self[day] then
		return self[day][name]
	end
end
