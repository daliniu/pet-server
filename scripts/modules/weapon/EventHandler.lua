module(...,package.seeall)

local Define = require("modules.weapon.WeaponDefine")
local Logic = require("modules.weapon.WeaponLogic")
local CfgQuality = require("config.WeaponQualityConfig").Config
local BagLogic = require("modules.bag.BagLogic")
local ItemConfig = require("config.ItemConfig").Config
local Msg = require("core.net.Msg")

-- 1=八尺琼勾玉   2=草雉剑   3=八尺镜

--神兵查询
function onCGWeaponQuery(human)
	Logic.sendWepList(human)
end

--激活神兵
function onCGWeaponOpen(human, wepId)
	local name = Define.WEP_NAME[wepId]
	if not name then
		return Msg.SendMsg(PacketID.GC_WEAPON_OPEN, human, wepId, Define.ERR_CODE.Invalid)
	end

	local wep = Logic.getWep(human, wepId)
	if wep then
		return Msg.SendMsg(PacketID.GC_WEAPON_OPEN, human, wepId, Define.ERR_CODE.OpenNo)
	end

	local cfg = Logic.getNeedConfig(wepId)
	local qualityCfg = Logic.getQualityConfig(0)
	local num = BagLogic.getItemNum(human, cfg.fragItem)
	local itemConfig = ItemConfig[cfg.fragItem]
	if num < qualityCfg.fragNeed then
		return Msg.SendMsg(PacketID.GC_WEAPON_OPEN, human, cfg.fragItem, Define.ERR_CODE.OpenNeedFrag)
	end
	
	BagLogic.delItemByItemId(human, cfg.fragItem, qualityCfg.fragNeed, true, CommonDefine.ITEM_TYPE.DEC_WEAPON_ACTIVE)

	table.insert(human.db.wep, {wid=wepId, lv=1, exp=0, q=1})
	Msg.SendMsg(PacketID.GC_WEAPON_OPEN, human, wepId, Define.ERR_CODE.Success)
	Logic.sendWepList(human)
	Logic.sendHeroDyAttr(human)

	HumanManager:dispatchEvent(HumanManager.Event_WeaponQualityUp,{human=human,objNum=human.db.wep.q})
	
	local logTb = Log.getLogTb(LogId.WEAPON_ACTIVE)
	logTb.name = human:getName()
	logTb.account = human:getAccount()
	logTb.pAccount = human:getPAccount()
	logTb.weaponName = name
	logTb.itemName = itemConfig.name
	logTb.itemCount = qualityCfg.fragNeed
	logTb:save()
end

--神兵升级
function onCGWeaponUpLv(human, wepId, item, count)
	local name = Define.WEP_NAME[wepId]
	if not name then
		return Msg.SendMsg(PacketID.GC_WEAPON_UP_LV, human, wepId, Define.ERR_CODE.Invalid, 0, 0, 0)
	end

	local wep = Logic.getWep(human, wepId)
	if not wep then
		return Msg.SendMsg(PacketID.GC_WEAPON_UP_LV, human, wepId, Define.ERR_CODE.Null, 0, 0, 0)
	end

	if wep.lv >= human:getLv() then
		return Msg.SendMsg(PacketID.GC_WEAPON_UP_LV, human, wepId, Define.ERR_CODE.UpLvHumanLv, 0, 0, 0)
	end

	local qualityCfg = Logic.getQualityConfig(wep.q)
	if wep.lv >= qualityCfg.maxLv then
		return Msg.SendMsg(PacketID.GC_WEAPON_UP_LV, human, wepId, Define.ERR_CODE.UpLvQualityLv, 0, 0, 0)
	end

	if wep.lv >= Define.WEAPON_MAX_LV then
		return Msg.SendMsg(PacketID.GC_WEAPON_UP_LV, human, wepId, Define.ERR_CODE.UpLvTop, 0, 0, 0)
	end

	local itemId = nil 
	for k, v in pairs(Define.WEP_UPLV_ITEM) do 
		local num = BagLogic.getItemNum(human, v)
		if v == item then
			if num >= count and count > 0 then 
				itemId = v
			end
			break
		end
	end
	if itemId == nil then
		return Msg.SendMsg(PacketID.GC_WEAPON_UP_LV, human, wepId, Define.ERR_CODE.UpLvNeedItem, 0, 0, 0)
	else
		local exp = ItemConfig[itemId].attr.wepExp * count 
		local lvBefore = wep.lv
		local hasLvUp = Logic.addExp(human, wepId, exp)
		local lv = wep.lv
		BagLogic.delItemByItemId(human, itemId, count, true, CommonDefine.ITEM_TYPE.DEC_WEAPON_LV_UP)
		Msg.SendMsg(PacketID.GC_WEAPON_UP_LV, human, itemId, Define.ERR_CODE.UpLvSuccess, hasLvUp, wepId, lv)
		Logic.sendWepList(human)

		if hasLvUp == 1 then
			Logic.sendHeroDyAttr(human)
			HumanManager:dispatchEvent(HumanManager.Event_WeaponLvUp,{human=human,objNum=lv})
		end

		local logTb = Log.getLogTb(LogId.WEAPON_LV_UP)
		logTb.name = human:getName()
		logTb.account = human:getAccount()
		logTb.pAccount = human:getPAccount()
		logTb.weaponName = name
		logTb.itemName = ItemConfig[itemId].name
		logTb.itemCount = count
		logTb.lvBefore = lvBefore
		logTb.lvAfter = lv
		logTb:save()
	end
end

--神兵升品
function onCGWeaponUpQuality(human, wepId)
	local name = Define.WEP_NAME[wepId]
	if not name then
		return Msg.SendMsg(PacketID.GC_WEAPON_UP_QUALITY, human, wepId, Define.ERR_CODE.Invalid)
	end

	local wep = Logic.getWep(human, wepId)
	if not wep then
		return Msg.SendMsg(PacketID.GC_WEAPON_UP_QUALITY, human, wepId, Define.ERR_CODE.Null)
	end

	local qualityCfg = Logic.getQualityConfig(wep.q)
	local nextQualityCfg = Logic.getQualityConfig(wep.q + 1)
	local cfg = Logic.getNeedConfig(wepId)
	if not nextQualityCfg then
		return Msg.SendMsg(PacketID.GC_WEAPON_UP_QUALITY, human, wepId, Define.ERR_CODE.UpQualityTop)
	end

	local num = BagLogic.getItemNum(human, cfg.fragItem)
	if num < qualityCfg.fragNeed then
		return Msg.SendMsg(PacketID.GC_WEAPON_UP_QUALITY, human, wepId, Define.ERR_CODE.UpQualityNeedFrag)
	end
	
	BagLogic.delItemByItemId(human, cfg.fragItem, qualityCfg.fragNeed, true, CommonDefine.ITEM_TYPE.DEC_WEAPON_QUALITY_UP)

	wep.q = wep.q + 1
	Msg.SendMsg(PacketID.GC_WEAPON_UP_QUALITY, human, wepId * 10000 + wep.q * 1000 + wep.lv, Define.ERR_CODE.UpQualitySuccess)
	Logic.sendWepList(human)
	Logic.sendHeroDyAttr(human)

	HumanManager:dispatchEvent(HumanManager.Event_WeaponQualityUp,{human=human,objNum=wep.q})

	local logTb = Log.getLogTb(LogId.WEAPON_QUALITY_UP)
	logTb.name = human:getName()
	logTb.account = human:getAccount()
	logTb.pAccount = human:getPAccount()
	logTb.weaponName = name
	logTb.itemName = ItemConfig[cfg.fragItem].name
	logTb.itemCount = cfg.fragItem
	logTb.qualityBefore = wep.q - 1
	logTb.qualityAfter = wep.q
	logTb:save()
end

