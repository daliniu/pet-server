module(...,package.seeall) 
local MysteryShop = require("modules.mystery.MysteryShop")
local Msg = require("core.net.Msg")
local EIGHT_OCLOCK = 3600 * 4

function onCGMysteryShopQuery(human,mtype)
	local now = os.time()
	local oClock = now - (now % 7200)
	local function updateMysteryData(human)
		human.db.mystery.lastDate = oClock
		human.db.mystery.shop = {}
		human.db.mystery.shop2 = {}
		human.db.mystery.refresh = 0
		human.db.mystery.refresh2 = 0
	end
	if oClock > human.db.mystery.lastDate then
		updateMysteryData(human)
	end
	MysteryShop.query(human,mtype)
end

function onCGMysteryShopRefresh(human,mtype)
	local ret,retCode = MysteryShop.refresh(human,mtype)
	Msg.SendMsg(PacketID.GC_MYSTERY_SHOP_REFRESH,human,retCode,mtype)
end

function onCGMysteryShopBuy(human,id,mtype)
	local ret,retCode = MysteryShop.buy(human,id,mtype)
	Msg.SendMsg(PacketID.GC_MYSTERY_SHOP_BUY,human,id,retCode,mtype)
end
