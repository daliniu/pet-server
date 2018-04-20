module(...,package.seeall)
local GoldLogic = require("modules.gold.GoldLogic")
local Msg = require("core.net.Msg")

function onCGGoldBuy(human)
	local ret,retCode,data = GoldLogic.buy(human)
	Msg.SendMsg(PacketID.GC_GOLD_BUY,human,retCode,data)
end

function onCGGoldBuyTen(human,cnt)
	local ret,retCode,data = GoldLogic.buyTen(human,cnt)
	Msg.SendMsg(PacketID.GC_GOLD_BUY_TEN,human,retCode,data)
end

function onCGGoldBuyQuery(human)
	GoldLogic.query(human)
end
