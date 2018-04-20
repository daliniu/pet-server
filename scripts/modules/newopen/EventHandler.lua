module(...,package.seeall)
local NewOpenLogic = require("modules.newopen.NewOpenLogic")
local NewOpenConstConfig = require("config.NewOpenConstConfig").Config
local Msg = require("core.net.Msg")

function onCGNewOpenQuery(human)
	print("onCGNewOpenQuery")
	NewOpenLogic.query(human)
end

function onCGNewOpenTime(human)
	local beginTime = Config.newServerTime
	--local endTime = Config.newServerTime + NewOpenConstConfig[1].endTime * 24 * 3600
	--local getEndTime = Config.newServerTime + NewOpenConstConfig[1].getEndTime * 24 * 3600
	local endTime = Util.getToday0Clock(Config.newServerTime) + NewOpenConstConfig[1].endTime * 24 * 3600
	local getEndTime = Util.getToday0Clock(Config.newServerTime) + NewOpenConstConfig[1].getEndTime * 24 * 3600
	local isOpen = 0
	if os.time() < getEndTime and os.time() >= beginTime then
		isOpen = 1
	end
	Msg.SendMsg(PacketID.GC_NEW_OPEN_TIME,human,beginTime,endTime,getEndTime,isOpen)
end

function onCGNewLoginGet(human,day)
	local ret,retCode = NewOpenLogic.loginGetFunc(human,day)
	Msg.SendMsg(PacketID.GC_NEW_LOGIN_GET,human,retCode)
end

function onCGNewRechargeGet(human,day)
	local ret,retCode = NewOpenLogic.rechargeGetFunc(human,day)
	Msg.SendMsg(PacketID.GC_NEW_RECHARGE_GET,human,retCode)
end

function onCGNewDiscountBuy(human,day)
	local ret,retCode = NewOpenLogic.discountBuy(human,day)
	Msg.SendMsg(PacketID.GC_NEW_DISCOUNT_BUY,human,retCode)
end
