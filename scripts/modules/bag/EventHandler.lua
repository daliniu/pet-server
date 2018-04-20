module(...,package.seeall)

local PacketID = require("PacketID")
local Msg = require("core.net.Msg")
local BagLogic = require("modules.bag.BagLogic")
local ItemCmd = require("modules.bag.ItemCmd")

function onCGBagSort(human)
end

function onCGBagQuery(human)
	BagLogic.sendBagList(human,true)
end

function onCGBagExpand(human)
end

function onCGItemSell(human,pos,cnt)
	BagLogic.sellItem(human,pos,cnt,CommonDefine.ITEM_TYPE.DEC_SELL_ITEM)
end

function onCGItemUse(human,pos,cnt,argList)
	local itemId,ret = ItemCmd.useItem(human,pos,cnt,argList)
	Msg.SendMsg(PacketID.GC_ITEM_USE,human,ret,itemId)
end
