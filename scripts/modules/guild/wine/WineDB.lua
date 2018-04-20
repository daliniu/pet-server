module(...,package.seeall)
local WineLvConfig = require("config.WineConfig").WineLvConfig
local DB = require("core.db.DB")

function new()
	local db = {
		lv = 1,
		exp = 0,
		cnt = 0,	--今日调酒次数
		reset = 0,
		buff = {},	--当前拥有的酒buff
	}
	DB.dbSetMetatable(db.buff)
	setmetatable(db,{__index = _M})
	return db
end

function incExp(self,val)
	if self.lv >= #WineLvConfig then
		local max = WineLvConfig[#WineLvConfig].exp
		self.exp = math.min(max,self.exp + val)
	else
		self.exp = self.exp + val
		self:checkLvUp()
	end
end

function checkLvUp(self)
	local preLv = self.lv
	if preLv >= #WineLvConfig then
		return 
	end
	local cfg = WineLvConfig[preLv+1]
	if not cfg then
		return
	end
	local exp = self.exp
	local nextExp = cfg.exp
	local nextLv = preLv
	while nextExp <= exp do
		cfg = WineLvConfig[nextLv+1]
		if not cfg then
			break
		end
		exp = exp - nextExp
		nextLv = nextLv + 1
		nextExp = cfg.exp
	end
	self.exp = exp  
	if preLv ~= nextLv then
		self.lv = nextLv
	end
end


