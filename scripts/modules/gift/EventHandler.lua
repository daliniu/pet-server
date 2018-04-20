module(...,package.seeall)
local GiftLogic = require("modules.gift.GiftLogic")
local Msg = require("core.net.Msg")
--local BagDefine = require("modules.bag.BagDefine")
--local BagLogic = require("modules.bag.BagLogic")

function onCGGiftQuery(human)
	--StrengthLogic.query(human)
end

function onCGGiftActivate(human,name,index,buyCnt)
	GiftLogic.activate(human,name,index,buyCnt)
end
