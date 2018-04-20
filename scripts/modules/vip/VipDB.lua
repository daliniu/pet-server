module(..., package.seeall)
local Define = require("modules.vip.VipDefine")

function new()
	local db = {
		rechargeList = {},
		gift = {},
		dailyInfo = {},
		nextUpdateTime = 0,
	}


	setmetatable(db, {__index = _M})
	db:initDailyInfo()

	--数字做key,需要主动设置
	DB.dbSetMetatable(db.gift)
	DB.dbSetMetatable(db.rechargeList)

	return db
end

function initDailyInfo(self)
	for i=1,Define.VIP_MAX_LV do
		self.dailyInfo[i] = Define.VIP_DAILY_NO_ENOUGH	
	end
end

function setGiftBuy(self, vipLv)
	self.gift[vipLv] = 1
end

function hasGiftBuy(self, vipLv)
	return (self.gift[vipLv] ~= nil)
end

function getGiftBuyList(self)
	local tab = {}
	for k,v in pairs(self.gift) do
		table.insert(tab, k)
	end
	return tab
end

function setDailyGet(self, lv)
	self.dailyInfo[lv] = Define.VIP_DAILY_GET
end

function resetDailyGet(self, lv)
	self.dailyInfo[lv] = Define.VIP_DAILY_NO_GET
end

function hasGetDailyGift(self, lv)
	return (self.dailyInfo[lv] ~= Define.VIP_DAILY_NO_GET)
end

function addRechargeCount(self, id)
	local sid = tostring(id)
	if self.rechargeList[sid] == nil then
		self.rechargeList[sid] = 1
	else
		self.rechargeList[sid] = self.rechargeList[sid] + 1
	end
end

function resetMetatable(human)
	local db = human:getVip()

	--数字做key,需要主动设置
	DB.dbSetMetatable(db.gift)
	DB.dbSetMetatable(db.rechargeList)
end
