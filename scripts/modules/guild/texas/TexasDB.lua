module(...,package.seeall)
local TexasLvConfig = require("config.TexasLvConfig").Config

function new()
	local db = {
		lv = 0,
		exp = 0,
		count = 0,
		reset = 0,
		curCards = {},
	}
	setmetatable(db,{__index = _M})
	return db
end

function setCurCards(self,cards)
	self.curCards = cards
end

function incExp(self,val)
	if self.lv >= #TexasLvConfig then
		local max = TexasLvConfig[#TexasLvConfig].exp
		self.exp = math.min(max,self.exp + val)
	else
		self.exp = self.exp + val
		self:checkLvUp()
	end
end

function checkLvUp(self)
	local preLv = self.lv
	if preLv >= #TexasLvConfig then
		return 
	end
	local cfg = TexasLvConfig[preLv+1]
	if not cfg then
		return
	end
	local exp = self.exp
	local nextExp = cfg.exp
	local nextLv = preLv
	while nextExp <= exp do
		cfg = TexasLvConfig[nextLv+1]
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
