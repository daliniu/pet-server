module(...,package.seeall)
local StrengthDefine = require("modules.strength.StrengthDefine")

function new()
	local o = {}
	setmetatable(o,{__index = _M})
	o:init()
	return o
end

function gridInit(cell)
	for i = 1,StrengthDefine.kMaxStrengthGridCap do
		cell.grids[i] = 0
	end
end

function init(self)
	self.id = 0			--力量id
	self.lv = 0			--力量品阶
	self.grids = {}		--力量材料
	self:gridInit()
end
