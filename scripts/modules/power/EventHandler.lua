module(...,package.seeall)

local Msg = require("core.net.Msg")
local BagLogic = require("modules.bag.BagLogic")
local ItemConfig = require("config.ItemConfig").Config
local CommonDefine = require("core.base.CommonDefine")

local Define = require("modules.power.PowerDefine")
local Logic = require("modules.power.PowerLogic")
local PowerConfig = require("config.PowerConfig").Config

--查询
function onCGPowerQuery(human)
	Logic.sendPowerList(human)
end

--激活
function onCGPowerOpen(human, powerId)
	local ret = Define.ERR_CODE.Success
	local cfg = PowerConfig[powerId]
	if not cfg then
		ret = Define.ERR_CODE.Invalid
	end
	local power = Logic.getPower(human, powerId)
	if power then
		ret = Define.ERR_CODE.OpenNo
	end
	--消耗
	if human:getStar() <= cfg.openStar then
		ret = Define.ERR_CODE.OpenNeedStar
	end
	if ret == Define.ERR_CODE.Success then
		human:decStar(cfg.openStar)
		Logic.addPower(human,powerId)
	end
	return Msg.SendMsg(PacketID.GC_POWER_OPEN, human, powerId, ret)
end

--神兵升级
function onCGPowerUpgrade(human, powerId)
	local ret = Define.ERR_CODE.UpLvSuccess
	local cfg = PowerConfig[powerId]
	if not cfg then
		ret = Define.ERR_CODE.Invalid
	end
	local power = Logic.getPower(human, powerId)
	if not power then
		ret = Define.ERR_CODE.Null
	end
	if power.lv >= Define.MAX_LV then
		ret = Define.ERR_CODE.UpLvTop
	end
	if human:getStar() < cfg.upStar then
		ret = Define.ERR_CODE.UpLvNeedStar
	end
	local num = BagLogic.getItemNum(human, cfg.itemId)
	if num <= 0 then 
		--ret = Define.ERR_CODE.UpLvNeedItem
	end
	local hasLvUp = 0
	if ret == Define.ERR_CODE.UpLvSuccess then
		local exp = 0
		--消耗星星
		human:decStar(cfg.upStar)
		exp = exp + cfg.upStar * 10
		--使用道具
		--BagLogic.delItemByItemId(human,cfg.itemId,1)
		--exp = exp + ItemConfig[itemId].attr.powerExp
		hasLvUp = Logic.addExp(human, powerId, exp)
		--人物刷新
		power = Logic.getPower(human, powerId)
		human:sendHumanInfo()
		--英雄属性刷新
		if hasLvUp == 1 then
			HumanManager:dispatchEvent(HumanManager.Event_PowerLvUp,{human=human,objId=powerId,objNum=power.lv})
			Logic.refreshHero(human,powerId)
		end
	end
	Msg.SendMsg(PacketID.GC_POWER_UPGRADE, human, Define.ERR_CODE.UpLvSuccess, powerId ,hasLvUp, power.lv,power.exp)
end




