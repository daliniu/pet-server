module(...,package.seeall)
local LotteryConfig = require("config.LotteryConfig")
local ShopDefine = require("modules.shop.ShopDefine")

function new()
	local initCount = LotteryConfig.ConstantConfig[1].initCount
	local db = {
		buy = {},
		resetbuy = 0,
		commonfree = os.time(),
		commonFirst = 0,
		rareFirst = 0,
		costFirst = 0,
		rarefree = os.time(),
		raretimes = initCount,
		rareTenTimes = 0,
		commontimes = 0,
		commonFreeTimes = 0,
		resetFreeTimes = 0,
		certain = 0,
		exchangeShop = {},
		exchangeRefresh = 0,
		exchangeLastRefresh = 0,
	}
	setmetatable(db,{__index = _M}) 
	return db
end

function getBuyCnt(self,shopId)
	return self.buy[tostring(shopId)] or 0
end

function setBuyCnt(self,shopId,num)
	self.buy[tostring(shopId)] = num
	return true
end

function resetBuy(self)
	--self.commonFreeTimes = 0
	self.buy = {}
	return true
end
