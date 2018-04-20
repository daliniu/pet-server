module(...,package.seeall)
local StrengthLogic = require("modules.strength.StrengthLogic")
local Msg = require("core.net.Msg")
local BagDefine = require("modules.bag.BagDefine")
local BagLogic = require("modules.bag.BagLogic")

function onCGStrengthQuery(human)
	StrengthLogic.query(human)
end

function onCGStrengthLvUp(human,heroName,cellPos)
	local ret,retCode = StrengthLogic.lvUp(human,heroName,cellPos)
	Msg.SendMsg(PacketID.GC_STRENGTH_LV_UP,human,retCode,heroName,cellPos)
end

function onCGStrengthTransfer(human,heroName)
	local ret,retCode = StrengthLogic.transfer(human,heroName)
	Msg.SendMsg(PacketID.GC_STRENGTH_TRANSFER,human,retCode,heroName)
end

function onCGStrengthEquip(human,heroName,cellPos,gridPos)
	local ret,retCode = StrengthLogic.equip(human,heroName,cellPos,gridPos)
	Msg.SendMsg(PacketID.GC_STRENGTH_EQUIP,human,heroName,cellPos,gridPos,retCode)
end

function onCGMaterialCompose(human,itemId)
	local ret,retCode = StrengthLogic.compose(human,itemId)
	Msg.SendMsg(PacketID.GC_MATERIAL_COMPOSE,human,retCode)
end

function onCGStrengthFragCompose(human,id)
	local ret,retCode = StrengthLogic.compose(human,id)
	if ret then
		local rewards = {{titleId = BagDefine.REWARD_TIPS.kCompose,id = id,num = 1}}
		BagLogic.sendRewardTips(human,rewards)
	end
	Msg.SendMsg(PacketID.GC_STRENGTH_FRAG_COMPOSE,human,retCode)
end

function onCGStrengthQuickEquip(human,name)
	local ret,retCode,arr = StrengthLogic.quickEquip(human,name)
	Msg.SendMsg(PacketID.GC_STRENGTH_QUICK_EQUIP,human,name,retCode,arr)
end
