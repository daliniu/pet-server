module(...,package.seeall)
local StrengthDefine = require("modules.strength.StrengthDefine")
local StrengthCell = require("modules.strength.StrengthCell")

function new()
	local o = {
		transferLv = 0,		--转职等级
		cells = {}			--力量属性
	}
	for k = 1,StrengthDefine.kMaxStrengthCellCap do
		o.cells[k] = StrengthCell.new()
	end
	setmetatable(o,{__index = _M})
	return o
end

function init(heroDB)
	if not heroDB.strength then
		heroDB.strength = new()
	end
end
