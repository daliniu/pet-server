module(...,package.seeall)

local Msg = require("core.net.Msg")
local CommonDefine = require("core.base.CommonDefine")
local PublicLogic = require("modules.public.PublicLogic")
local PublicDefine = require("modules.public.PublicDefine")
local BagLogic = require("modules.bag.BagLogic")
local ItemConfig = require("config.ItemConfig").Config

local Logic = require("modules.skill.SkillLogic")
local Define = require("modules.skill.SkillDefine")
local SkillConfig = require("config.SkillConfig").Config
local SkillGroupConfig = require("config.SkillGroupConfig").Config
local SkillExpConfig = require("config.SkillExpConfig").Config
local SkillUpConfig = require("config.SkillUpConfig").Config


--技能查询
function onCGSkillQuery(human,heroName)
	local hero = human:getHero(heroName)
    Logic.sendSkillGroupList(hero)
    return true
end

--技能升级
function onCGSkillUpgrade(human,heroName,groupId,isOnce)
	local ret = CommonDefine.OK
    local hero = human:getHero(heroName)
	local conf = SkillGroupConfig[groupId]
	--已开放
	if conf.openLv > hero:getLv() then
		ret = Define.ERROR_CODE.NO_SKILL
		return Msg.SendMsg(PacketID.GC_SKILL_UPGRADE,hero:getHuman(),ret)
	end
	local group = Logic.getSkillGroupById(hero,groupId)
	if not group then
		ret = Define.ERROR_CODE.NOT_HERO_SKILL
		return Msg.SendMsg(PacketID.GC_SKILL_UPGRADE,hero:getHuman(),ret)
	end
	--if Define.EXP_TYPE_MAP[conf.type] then 
	--	ret = Define.ERROR_CODE.ERROR_CONF
	--	return Msg.SendMsg(PacketID.GC_SKILL_UPGRADE,hero:getHuman(),ret)
	--end
	print("=========>",groupId)
	if ret == CommonDefine.OK then
		local logTb = Log.getLogTb(LogId.SKILL_LV_UP)
		logTb.money = 0
		local oldLv = group:getLv()
		local upLv = 1
		if isOnce == 1 then
			upLv = hero:getLv() - oldLv
		end
		if upLv == 0 then ret = Define.ERROR_CODE.EXCEED_HERO_LV end
		local fee = 0
		while (group:getLv() - oldLv) < upLv  do
			ret,fee = doUpgradeSkill(human,hero,group,logTb)
			fee = fee or 0
			if ret ~= CommonDefine.OK then
				break
			end
		end
		if oldLv ~= group:getLv() then
			--升级了
			--升级暴击
			for _,v in ipairs(Define.ExtralAddLvMap) do
				if math.random(100) <= v.per then
					group.lv = group.lv + v.lv
					if (group:getLv() - hero:getLv()) >= conf.heroLv then
						group.lv = hero:getLv() - conf.heroLv
					end
					break
				end
			end
			human:sendHumanInfo()
			hero:calcFight()
			HumanManager:dispatchEvent(HumanManager.Event_SkillLvUp,{human=human})
		end

		--强化大师推送属性
		if group:getLv() % 5 == 0 then
			hero:resetDyAttr()
			hero:sendDyAttr()
		end

		--日志
		logTb.account = human:getAccount()
		logTb.name = human:getName()
		logTb.pAccount = human:getPAccount()
		logTb.heroName = heroName
		logTb.lastLevel = oldLv
		logTb.level = group:getLv() 
		logTb.skillId = groupId
		logTb.rmb = 0
		local way = 1
		if isOnce  == 1 then way = 2 end
		logTb.way = way 
		logTb:save()
	end
	local listMsg = {}
	Logic.makeSkillGroupMsg(group,listMsg)
	return Msg.SendMsg(PacketID.GC_SKILL_UPGRADE,human,ret,heroName,listMsg)
end

function doUpgradeSkill(human,hero,group,logTb)
	local conf = SkillGroupConfig[group.groupId]
	local lv = group:getLv()
	--满级
	if lv >= conf.maxLv then
		return Define.ERROR_CODE.UPGRADE_MAX_LV
	end
	--不超过人物等级
	if (lv - hero:getLv()) >= conf.heroLv then
		return Define.ERROR_CODE.EXCEED_HERO_LV
	end
	--消耗货币
	local totalFee = group:getUpgradeCost()
	local costType = group:getCostType()
	print("========>",costType)
	if costType == "money" then
		--金币花费
		if totalFee > human:getMoney() then
			return Define.ERROR_CODE.NO_MONEY
		else
			logTb.money = logTb.money + totalFee
			human:decMoney(totalFee,CommonDefine.MONEY_TYPE.DEC_SKILL_UPGRADE)
		end
	elseif costType == "rage" then
		--怒气点
		if totalFee > human.db.skillRage then
			return Define.ERROR_CODE.NO_RAGE
		else
			human:decSkillRage(totalFee)
		end
	elseif costType == "assist" then
		--援助点
		if totalFee > human.db.skillAssist then
			return Define.ERROR_CODE.NO_ASSIST
		else
			human:decSkillAssist(totalFee)
		end
	else
		return Define.ERROR_CODE.ERROR_CONF
	end
	--消耗道具
	for itemId,itemType in pairs(conf.upItem) do
		local num = SkillUpConfig[lv]["upItem" .. itemType]
		if num and BagLogic.getItemNum(human,itemId) < num then 
			return Define.ERROR_CODE.UP_NEED_ITEM
		end
	end
	for itemId,itemType in pairs(conf.upItem) do
		local num = SkillUpConfig[lv]["upItem" .. itemType]
		if num then
			BagLogic.delItemByItemId(human,itemId,num,false,CommonDefine.ITEM_TYPE.DEC_SKILL_UPGRADE)
		end
	end
	BagLogic.sendBagList(human)

	group:incLv()
	return CommonDefine.OK,totalFee
end

--装备技能
function onCGSkillEquip(human,heroName,groupId,equipType)
	local ret = CommonDefine.OK
    local hero = human:getHero(heroName)
	local conf = SkillGroupConfig[groupId]
	--类型
	if equipType > 3 or equipType < 1 then
		ret = Define.ERROR_CODE.NOT_FIT_TYPE
		return Msg.SendMsg(PacketID.GC_SKILL_EQUIP,human,ret)
	end
	--
	local lastGroup = Logic.getSkillGroupByType(hero,conf.type,equipType)
	ret = Logic.equip(hero,equipType,groupId)
	--send
	local listMsg = {}
	if ret == CommonDefine.OK then
		local group = Logic.getSkillGroupById(hero,groupId)
		if lastGroup then
			Logic.makeSkillGroupMsg(lastGroup,listMsg)
		end
		Logic.makeSkillGroupMsg(group,listMsg)
		hero:resetDyAttr()
		hero:sendDyAttr()
	end
	return Msg.SendMsg(PacketID.GC_SKILL_EQUIP,human,ret,heroName,listMsg)
end

--卸下技能
function onCGSkillUnload(human,heroName,groupId)
	--[[
	local ret = CommonDefine.OK
    local hero = human:getHero(heroName)
	local conf = SkillGroupConfig[groupId]
	local group = Logic.getSkillGroupById(hero,groupId)
	if not group then
		ret = SkillDefine.ERROR_CODE.NOT_HERO_SKILL
		return Msg.SendMsg(PacketID.GC_SKILL_UPGRADE,human,ret)
	end
	group:equipSkillList()
	--send
	local listMsg = {}
	if ret == CommonDefine.OK then
		Logic.makeSkillGroupMsg(group,listMsg)
	end
	return Msg.SendMsg(PacketID.GC_SKILL_UNLOAD,human,ret,heroName,listMsg)
	--]]
end

--EXP升级
function onCGSkillExpUp(human, heroName ,groupId)
	local ret = CommonDefine.OK
    local hero = human:getHero(heroName)
	local group = Logic.getSkillGroupById(hero,groupId)
	local conf = SkillGroupConfig[groupId]
	if not Define.EXP_TYPE_MAP[conf.type] then 
	--if conf.type ~= Define.TYPE_FINAL and conf.type ~= Define.TYPE_ASSIST then
		ret = Define.ERROR_CODE.ERROR_CONF
	end
	--已满级
	if not Logic.getSkillUpExp(groupId,group.lv+1) then
		ret = Define.ERROR_CODE.UPGRADE_MAX_LV
	end
	--不超过人物等级
	if (group:getLv() - hero:getLv()) >= conf.heroLv then
		ret = Define.ERROR_CODE.EXCEED_HERO_LV
		return Msg.SendMsg(PacketID.GC_SKILL_UPGRADE,hero:getHuman(),ret)
	end
	local hasLvUp = 0
	if ret == CommonDefine.OK then
		local oldLv = group:getLv()
		--使用道具
		local itemId = Define.EXP_ITEM_ID
		local num = BagLogic.getItemNum(human, itemId)
		local exp = 0
		if num <= 0 then 
			ret = Define.ERROR_CODE.UP_NEED_ITEM
		else
			BagLogic.delItemByItemId(human,itemId,1,true,CommonDefine.ITEM_TYPE.DEC_SKILL_EXP)
    		local cfg = ItemConfig[itemId]
			exp = cfg.attr.skillExp or 0
			hasLvUp = Logic.addExp(hero,group,exp)
			hasLvUp = hasLvUp and 1 or 0
		end
		HumanManager:dispatchEvent(HumanManager.Event_SkillLvUp,{human=human})
		--
		local logTb = Log.getLogTb(LogId.SKILL_EXP_UP)
		logTb.account = human:getAccount()
		logTb.name = human:getName()
		logTb.pAccount = human:getPAccount()
		logTb.heroName = heroName
		logTb.lastLevel = oldLv
		logTb.level = group:getLv() 
		logTb.isLvUp = hasLvUp
		logTb.itemCnt = 1
		logTb.skillId = groupId
		logTb.exp = exp
		logTb.rmb = 0
		logTb.money = 0
		logTb.way = 1
		logTb:save()
	end
	Msg.SendMsg(PacketID.GC_SKILL_EXP_UP, human, ret, heroName , groupId ,hasLvUp, group.lv,group.exp)
end

local getReturnMoney = function(group)
	local cost = 0
	for i=2,group.lv do
		cost = cost + group:getUpgradeCost(i-1)
	end
	return math.floor(cost / 2)
end
function onCGSkillReset(human,heroName)
    local hero = human:getHero(heroName)
	local skillGroupList = hero:getSkillGroupList()
	local returnMoney = 0
	for _,group in pairs(skillGroupList) do
		local gtype = group:getConf().type
		if group.lv > 1 and gtype ~= Define.TYPE_FINAL and gtype ~= Define.TYPE_ASSIST then
			returnMoney = returnMoney + getReturnMoney(group) 
			group.lv = 1
		end
	end
	human:incMoney(returnMoney,CommonDefine.MONEY_TYPE.ADD_SKILL_RESET)
	human:sendHumanInfo()
	Logic.sendSkillGroupList(hero)
	return Msg.SendMsg(PacketID.GC_SKILL_RESET,human)
end



--开启技能
function onCGSkillOpen(human,heroName,groupId)
    local hero = human:getHero(heroName)
	local groupConf = SkillGroupConfig[groupId]
	if groupConf.hero ~= heroName then
		--是否是他的技能
		return Msg.SendMsg(PacketID.GC_SKILL_OPEN,human,Define.ERROR_CODE.NOT_HERO_SKILL)
	end
	local group = Logic.getSkillGroupById(hero,groupId)
	print("=======>",groupId,group)
	if group then
		--已开启
		return Msg.SendMsg(PacketID.GC_SKILL_OPEN,human,Define.ERROR_CODE.ERROR_CONF)
	end
	for itemId,itemNum in pairs(groupConf.openItem) do
		local num = BagLogic.getItemNum(human, itemId)
		if num < itemNum then 
			return Msg.SendMsg(PacketID.GC_SKILL_OPEN,human,Define.ERROR_CODE.UP_NEED_ITEM)
		end
	end
	for itemId,itemNum in pairs(groupConf.openItem) do
		BagLogic.delItemByItemId(human,itemId,itemNum,false,CommonDefine.ITEM_TYPE.DEC_SKILL_OPEN)
	end
	BagLogic.sendBagList(human)
	Logic.openSkillGroup(hero,groupId)
	HumanManager:dispatchEvent(HumanManager.Event_SkillOpen,{human=human})
	return Msg.SendMsg(PacketID.GC_SKILL_OPEN,human,CommonDefine.OK,heroName,groupId)
end










