module(...,package.seeall)
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")

local EquipDefine = require("modules.equip.EquipDefine")
local EquipConfig = require("config.EquipConfig").Config
local EquipItemConfig = require("config.EquipItemConfig").Config
local EquipLvUpCostConfig = require("config.EquipLvUpCostConfig").Config
local EquipColorUpCostConfig = require("config.EquipColorUpCostConfig").Config
local EquipOpenLvConfig = require("config.EquipOpenLvConfig").Config
local BagLogic = require("modules.bag.BagLogic")

function sendEquipList(hero)
	local heroEquip = hero.db.equip
	Msg.SendMsg(PacketID.GC_EQUIP_LIST, hero:getHuman(), hero.name, heroEquip or {})
end

function onHumanLogin(hm, human)
	local heroes = human:getAllHeroes()
	local ret = {}
	for name,h in pairs(heroes) do 
		table.insert(ret, {heroName=h.name, list=h.db.equip})
	end
	Msg.SendMsg(PacketID.GC_EQUIP_LIST_ALL, human, ret)
	--Util.print_r(ret)
end

function lvUp(human, name, pos, cnt)
	assert(cnt==1 or cnt ==10)

	local hero = human:getHero(name)
	if not hero then
		return Msg.SendMsg(PacketID.GC_EQUIP_LV_UP, human, EquipDefine.ERR_CODE.Invalid)
	end

	if pos < 1 or pos > 4 then
		return Msg.SendMsg(PacketID.GC_EQUIP_LV_UP, human, EquipDefine.ERR_CODE.Invalid)
	end

	local db = hero.db.equip
	local equip = db[pos]

	if hero:getLv() < equip.lv + cnt then 
		return Msg.SendMsg(PacketID.GC_EQUIP_LV_UP, human, EquipDefine.ERR_CODE.HeroLvMax)
	end

	local id = equip.c * 1000 + equip.lv 
	local conf = EquipConfig[id]
	if not conf then
		return Msg.SendMsg(PacketID.GC_EQUIP_LV_UP, human, EquipDefine.ERR_CODE.Invalid)
	end

	local nextId = equip.c * 1000 + equip.lv + cnt 
	local nextConf = EquipConfig[nextId]
	if not nextConf then
		return Msg.SendMsg(PacketID.GC_EQUIP_LV_UP, human, EquipDefine.ERR_CODE.Max)
	end

	local openlv = EquipOpenLvConfig[pos].openlv 
	if hero:getLv() < openlv then
		return Msg.SendMsg(PacketID.GC_EQUIP_LV_UP, human, EquipDefine.ERR_CODE.NoOpen)
	end

	local cost = EquipLvUpCostConfig[equip.lv].cost
	if human:getMoney() < cost * cnt then
		return Msg.SendMsg(PacketID.GC_EQUIP_LV_UP, human, EquipDefine.ERR_CODE.NoMoney)
	end

	human:decMoney(cost * cnt, CommonDefine.MONEY_TYPE.DEC_EQUIP_LV)
	equip.lv = equip.lv + cnt 
	sendEquipList(hero)
	human:sendHumanInfo()
	hero:resetDyAttr()
	hero:sendDyAttr()
	HumanManager:dispatchEvent(HumanManager.Event_UpEquip,{human=human,objNum = cnt})
	return Msg.SendMsg(PacketID.GC_EQUIP_LV_UP, human, EquipDefine.ERR_CODE.Success)
end

function colorUp(human, name, pos)
	local hero = human:getHero(name)
	if not hero then
		return Msg.SendMsg(PacketID.GC_EQUIP_COLOR_UP, human, EquipDefine.ERR_CODE.Invalid)
	end

	if pos < 1 or pos > 4 then
		return Msg.SendMsg(PacketID.GC_EQUIP_COLOR_UP, human, EquipDefine.ERR_CODE.Invalid)
	end

	local db = hero.db.equip
	local equip = db[pos]

	local id = equip.c * 1000 + equip.lv 
	local conf = EquipConfig[id]
	if not conf then
		return Msg.SendMsg(PacketID.GC_EQUIP_COLOR_UP, human, EquipDefine.ERR_CODE.Invalid)
	end

	local nextId = (equip.c + 1) * 1000 + equip.lv 
	local nextConf = EquipConfig[nextId]
	if not nextConf then
		return Msg.SendMsg(PacketID.GC_EQUIP_COLOR_UP, human, EquipDefine.ERR_CODE.Max)
	end

	local openlv = EquipOpenLvConfig[pos].openlv 
	if hero:getLv() < openlv then
		return Msg.SendMsg(PacketID.GC_EQUIP_COLOR_UP, human, EquipDefine.ERR_CODE.NoOpen)
	end

	local colorCfg = EquipColorUpCostConfig[equip.c]
	local cost = colorCfg.cost
	if human:getMoney() < cost then
		return Msg.SendMsg(PacketID.GC_EQUIP_COLOR_UP, human, EquipDefine.ERR_CODE.NoMoney)
	end

	if BagLogic.getItemNum(human, EquipDefine.EQUIP_COLOR_ITEM) < colorCfg.need then
		return Msg.SendMsg(PacketID.GC_EQUIP_COLOR_UP, human, EquipDefine.ERR_CODE.NoMeterial)
	end

	BagLogic.delItemByItemId(human, EquipDefine.EQUIP_COLOR_ITEM, colorCfg.need, true, CommonDefine.ITEM_TYPE.DEC_EQUIP_COLOR)
	human:decMoney(cost, CommonDefine.MONEY_TYPE.DEC_EQUIP_LV)

	equip.c = equip.c + 1
	sendEquipList(hero)
	human:sendHumanInfo()
	hero:resetDyAttr()
	hero:sendDyAttr()

	--BagLogic.sendBagList(human)
	return Msg.SendMsg(PacketID.GC_EQUIP_COLOR_UP, human, EquipDefine.ERR_CODE.Success)
end


