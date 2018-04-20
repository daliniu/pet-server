module(...,package.seeall)
local EquipDefine = require("modules.equip.EquipDefine")

function new()
	local o = {
		{lv=1,c=1},
		{lv=1,c=1},
		{lv=1,c=1},
		{lv=1,c=1},
	}
	setmetatable(o,{__index = _M})
	return o
end

function init(heroDB)
	if not heroDB.equip then
		heroDB.equip = new()
	end
end
