module(...,package.seeall)
local PacketID = require("PacketID")
local Msg = require("core.net.Msg")
local ShopLogic = require("modules.shop.ShopLogic")

function onCGShopBuy(human,shopId,num)
	local ret,retCode = ShopLogic.buy(human,shopId,num)
	Msg.SendMsg(PacketID.GC_SHOP_BUY,human,shopId,retCode)
end

function onCGShopBuyVirtual(human,shopId,params)
	local ret,retCode = ShopLogic.buyVirtual(human,shopId,params)
	Msg.SendMsg(PacketID.GC_SHOP_BUY_VIRTUAL,human,shopId,retCode)
end

function onCGShopSell(human,shopId,num)
	local ret,retCode = ShopLogic.sell(human,shopId,num)
	Msg.SendMsg(PacketID.GC_SHOP_SELL,human,retCode)
end

function onCGShopLotteryQuery(human)
	ShopLogic.lotteryQuery(human)
end

function onCGShopCommonOnce(human)
	local ret,retCode,itemId = ShopLogic.commonOnce(human)
	Msg.SendMsg(PacketID.GC_SHOP_COMMON_ONCE,human,retCode,itemId)
end

function onCGShopCommonTen(human)
	local ret,retCode,itemIds = ShopLogic.commonTen(human)
	local retItems = {}
	if ret then
		for i = 1,#itemIds do
			table.insert(retItems,{id=itemIds[i][1],num=itemIds[i][2],disFrag=itemIds[i][3]})
		end
	end
	Msg.SendMsg(PacketID.GC_SHOP_COMMON_TEN,human,retCode,retItems)
end

function onCGShopRareOnce(human)
	local ret,retCode,itemId = ShopLogic.rareOnce(human)
	Msg.SendMsg(PacketID.GC_SHOP_RARE_ONCE,human,retCode,itemId)
end

function onCGShopRareTen(human,isCertain)
	local ret,retCode,itemIds = ShopLogic.rareTen(human,isCertain)
	local retItems = {}
	if ret then
		for i = 1,#itemIds do
			table.insert(retItems,{id=itemIds[i][1],num=itemIds[i][2],disFrag=itemIds[i][3]})
		end
	end
	Msg.SendMsg(PacketID.GC_SHOP_RARE_TEN,human,retCode,retItems)
end

function onCGShopQuery(human,shopCnt)
	if not Util.IsSameDate(human.db.shop.resetbuy,os.time()) then
		human.db.shop:resetBuy()
		human.db.shop.resetbuy = os.time()
	end
	ShopLogic.query(human,shopCnt)	
end

function onCGExchangeShopQuery(human)
	ShopLogic.exchangeShopQuery(human)
end

function onCGExchangeShopBuy(human,id)
	local canBuy,retCode = ShopLogic.exchangeShopBuy(human,id)
    Msg.SendMsg(PacketID.GC_EXCHANGE_SHOP_BUY,human,id,retCode)
end

function onCGExchangeShopRefresh(human)
	local canRefresh,retCode = ShopLogic.exchangeShopRefresh(human)
    Msg.SendMsg(PacketID.GC_EXCHANGE_SHOP_REFRESH,human,retCode)
end
