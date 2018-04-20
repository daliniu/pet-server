module(...,package.seeall)

local Define = require("modules.achieve.AchieveDefine")
local AchieveConfig = require("config.AchieveConfig").Config
local HeroDefine = require("modules.hero.HeroDefine")
local HeroManager = require("modules.hero.HeroManager")
local DB = require("modules.achieve.AchieveDB")
local PublicLogic = require("modules.public.PublicLogic")
local Config = require("config.AchieveConfig").Config
local WeaponLogic = require("modules.weapon.WeaponLogic")
local Arena = require("modules.arena.Arena")
local StrengthLogic = require("modules.strength.StrengthLogic")
local DotLogic = require("modules.dot.DotLogic")
local DotDefine = require("modules.dot.DotDefine")

--目标配置，用于查找分类
AchieveTargetConfig = {}

function classifyConfig()
	for id,config in pairs(AchieveConfig) do
		local targetParam = config.param
		for _,target in pairs(targetParam) do
			local targetType = target[Define.ACHIEVE_PARAM_TYPE]
			local tab = AchieveTargetConfig[targetType]
			if tab == nil then
				tab = {}
				AchieveTargetConfig[targetType] = tab
			end
			table.insert(tab, config)
		end
	end

	for k,typeName in pairs(Define.ACHIEVE_TARGET_LIST) do
		if AchieveTargetConfig[typeName] ~= nil then
			table.sort(AchieveTargetConfig[typeName], function(a, b)
					return a.id < b.id
				end
			)
		end
	end
end

function addListener()
	local event2TaskType = {
		[Define.ACHIEVE_TEAM_LV] 	= HumanManager.Event_HumanLvUp,
		[Define.ACHIEVE_COLLECT] 	= HumanManager.Event_HeroCollect,
		[Define.ACHIEVE_ACTIVATE] 	= HumanManager.Event_PartnerActive,
		[Define.ACHIEVE_LV_UP] 		= HumanManager.Event_HeroLvUp,
		[Define.ACHIEVE_COPY] 		= HumanManager.Event_Chapter,
		[Define.ACHIEVE_OROCHI]	 	= HumanManager.Event_Orochi,
		[Define.ACHIEVE_TRIAL] 		= HumanManager.Event_Trial,
		[Define.ACHIEVE_EXPEDITION] = HumanManager.Event_Expedition,
		[Define.ACHIEVE_ARENA] 		= HumanManager.Event_Arena,
		[Define.ACHIEVE_POWER] 		= HumanManager.Event_PowerLvUp,
		[Define.ACHIEVE_WEAPON] 	= HumanManager.Event_WeaponLvUp,
	}
	for achieveType,eventType in ipairs(event2TaskType) do
		HumanManager:addEventListener(eventType, function(hm,event)
			changeAchieve(achieveType, event.human, event.objId)
			local db = event.human:getAchieve()
			if Util.GetTbNum(db.commitList) > 0 then
				DotLogic.sendSysDot(event.human, DotDefine.DOT_ACHIEVE)
			end
		end)
	end
end

function onHumanDBLoad(hm, human)
	DB.resetMetatable(human)
end

function onHumanLogin(hm, human)
	local db = human:getAchieve()
	if Util.GetTbNum(db.commitList) > 0 then
		DotLogic.sendSysDot(human, DotDefine.DOT_ACHIEVE)
	end
end

function composeFinishList(human)
	local db = human:getAchieve()
	--完成列表
	local finishTab = {}
	for id,_ in pairs(db.finishList) do
		table.insert(finishTab, id)
	end
	return finishTab
end

function composeCommitList(human)
	local db = human:getAchieve()
	--可提交列表
	local commitTab = {}
	for id,_ in pairs(db.commitList) do
		table.insert(commitTab, id)
	end
	return commitTab
end

function composeUnfinishList(human)
	local db = human:getAchieve()
	--未完成列表
	local unfinishList = {}
	for id,obj in pairs(db.unfinishList) do
		local tab = {}
		tab.id = id
		tab.targetList = {}
		for _,temp in pairs(obj) do
			local unfinish = {}
			unfinish.param = {}
			table.insert(unfinish.param, temp[Define.ACHIEVE_PARAM_TYPE])
			table.insert(unfinish.param, temp[Define.ACHIEVE_PARAM_ID])
			table.insert(unfinish.param, temp[Define.ACHIEVE_PARAM_COUNT])
			table.insert(tab.targetList, unfinish)
		end  

		table.insert(unfinishList, tab)
	end
	return unfinishList
end

function getRandRewardList(human, id)
	local rewardList = {}
	local config = Config[id]
	local rtb = {}
	if config ~= nil then
		-- 随机奖励
		local randReward = PublicLogic.randReward(config.reward)
		for n,r in pairs(randReward) do 
			if rtb[n] == nil then rtb[n] = 0 end
			rtb[n] = rtb[n] + r
		end

		PublicLogic.doReward(human,rtb,{}, CommonDefine.ITEM_TYPE.ADD_ACHIEVE_REWARD)
		for n,r in pairs(rtb) do 
			table.insert(rewardList,{rewardName=tostring(n),cnt=r})
		end
	end
	return rewardList,rtb
end

function changeAchieve(type, human, param)
	local typeName = Define.ACHIEVE_TARGET_LIST[type]
	if typeName ~= nil then
		local tab = AchieveTargetConfig[typeName]
		if tab then
			doAchieve(human, tab, param)
		end
	end
end

--param为附带参数(如通过某副本，则为副本ID)
function doAchieve(human, tab, param)
	local db = human:getAchieve()
	for _,config in pairs(tab) do
		hasAchieveFinish(human, config.id, param)
	end
end

function hasAchieveFinish(human, configId, param)
	local db = human:getAchieve()
	local isFinish = db:isCommit(configId)
	local config = Config[configId]
	if config ~= nil then
		local preObj = config.preNeed
		if (preObj.preId == nil or db:isCommit(preObj.preId) == true or db:isFinish(preObj.preId) == true)
			and (preObj.lv == nil or human:getLv() >= preObj.lv) 
			and (db:isCommit(config.id) == false and db:isFinish(config.id) == false) then
			isFinish = true
			local targetParam = config.param
			for _,target in pairs(targetParam) do
				local fun = FUN_LIST[target[Define.ACHIEVE_PARAM_TYPE]]
				isFinish = fun(human, config, target, param)
				if isFinish == false then
					--有未完成目标则为未完成成就
					break
				end
			end

			--完成成就
			if isFinish == true then
				db:delUnfinish(config.id)
				db:addCommit(config.id)

				local logTb = Log.getLogTb(LogId.ACHIEVE_FINISH)
				logTb.name = human:getName()
				logTb.account = human:getAccount()
				logTb.pAccount = human:getPAccount()
				logTb.achieveName = config.title
				logTb.achieveId = config.id
				logTb.lv = human:getLv()
				logTb:save()
			end
		end
	end
	return isFinish
end

function teamLv(human, config, target, param)
	local targetLv = target[Define.ACHIEVE_PARAM_COUNT]
	return (human:getLv() >= targetLv)
end

function collect(human, config, target, param)
	local quality = target[Define.ACHIEVE_PARAM_ID]
	local targetCount = target[Define.ACHIEVE_PARAM_COUNT]
	local curCount = HeroManager.getHeroCountByQuality(human, quality)
	return (curCount >= targetCount)
end

function activate(human, config, target, param)
	local targetCount = target[Define.ACHIEVE_PARAM_COUNT]
	local partnerList = human.db.partner
	return (Util.GetTbNum(partnerList) >= targetCount)
end

function heroLvUp(human, config, target, param)
	local lv = target[Define.ACHIEVE_PARAM_ID]
	local targetCount = target[Define.ACHIEVE_PARAM_COUNT]
	local curCount = 0
	local heroList = HeroManager.getAllHeroes(human)
	for _,hero in pairs(heroList) do
		if hero:getLv() >= lv then
			curCount = curCount + 1
		end
	end
	return (curCount >= targetCount)
end

function arena(human, config, target, param)
	--无排名
	local rank = Arena.getRank(human)
	if rank == 0 then
		return false
	end
	local targetCount = target[Define.ACHIEVE_PARAM_COUNT]
	return (rank <= targetCount)
end

function power(human, config, target, param)
	local targetCount = target[Define.ACHIEVE_PARAM_COUNT]
	return (StrengthLogic.getSumTransferLv(human) >= targetCount)
end

function weapon(human, config, target, param)
	local targetCount = target[Define.ACHIEVE_PARAM_COUNT]
	return (WeaponLogic.getSumLv(human) >= targetCount)
end

function copy(human, config, target, param)
	return commonCompare(human, config, target, tonumber(param), Define.ACHIEVE_COPY)
end

function orochi(human, config, target, param)
	return commonCompare(human, config, target, param, Define.ACHIEVE_OROCHI)
end

function trial(human, config, target, param)
	return commonCompare(human, config, target, param, Define.ACHIEVE_TRIAL)
end

function expedtion(human, config, target, param)
	return commonCompare(human, config, target, param, Define.ACHIEVE_EXPEDITION)
end

function commonCompare(human, config, target, param, type)
	local db = human:getAchieve()
	local isFinish = false
	local tab = db:getUnfinish(config.id)
	local id = target[Define.ACHIEVE_PARAM_ID]
	local count = target[Define.ACHIEVE_PARAM_COUNT]

	if tab == nil then
		tab = {}
		db:addUnfinish(config.id, tab)
	end

	local succCount = 0
	if id == param then
		local isSet = false
		for _,obj in pairs(tab) do
			if obj[Define.ACHIEVE_PARAM_TYPE] == type
				and obj[Define.ACHIEVE_PARAM_ID] == id then
				obj[Define.ACHIEVE_PARAM_COUNT] = obj[Define.ACHIEVE_PARAM_COUNT] + 1
				succCount = obj[Define.ACHIEVE_PARAM_COUNT]
				isSet = true
				break
			end
		end
		if isSet == false then
			succCount = 1
			table.insert(tab, {type, id, 1})			--type,copyId,count
		end
	end
	if succCount >= count then
		isFinish = true
	end

	return isFinish
end

FUN_LIST = {
	[Define.ACHIEVE_TEAM_LV] 	= teamLv,
	[Define.ACHIEVE_COLLECT] 	= collect,
	[Define.ACHIEVE_ACTIVATE] 	= activate,
	[Define.ACHIEVE_LV_UP] 		= heroLvUp,
	[Define.ACHIEVE_COPY]		= copy,
	[Define.ACHIEVE_OROCHI]		= orochi,
	[Define.ACHIEVE_TRIAL]		= trial,
	[Define.ACHIEVE_EXPEDITION]	= expedtion,
	[Define.ACHIEVE_ARENA]		= arena,
	[Define.ACHIEVE_POWER]		= power,
	[Define.ACHIEVE_WEAPON]		= weapon,
}
