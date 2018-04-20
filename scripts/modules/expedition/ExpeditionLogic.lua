module(...,package.seeall)

local HeroManager = require("modules.hero.HeroManager")
local Define = require("modules.expedition.ExpeditionDefine")
local HumanManager = require("core.managers.HumanManager")
local Util = require("core.utils.Util")
local TreasureConfig = require("config.ExpeditionTreasureConfig").Config
local Config = require("config.ExpeditionConfig").Config
local ShopConfig = require("config.ExpeditionShopConfig").Config
local AddConfig = require("config.ExpeditionLvAddConfig").Config
local Arena = require("modules.arena.Arena")
local ResetConfig = require("config.ExpeditionResetConfig").Config[1]
local DB = require("modules.expedition.ExpeditionDB")
local HeroDefineConfig = require("config.HeroDefineConfig").Config
local Hero = require("modules.hero.Hero")
local PublicLogic = require("modules.public.PublicLogic")
local WineLogic = require("modules.guild.wine.WineLogic")
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")

local VipDefine = require("modules.vip.VipDefine")
local VipLogic = require("modules.vip.VipLogic")

function onHumanDBLoad(hm, human)
	DB.onHumanDBLoad(human)
end

function onHumanLogin(hm, human)
end

function onAddHero(hm, obj)
	local human = obj.human
	local db = human:getExpedition()
	if db.hasOpen == 1 then
		local hero = human:getHero(obj.heroName)
		if hero then
			local expeditionHero = {}
			expeditionHero.name = hero:getName()
			expeditionHero.hp = 100
			db.heroList[hero.name] = expeditionHero
		end
	end
end

function onHumanLvUp(hm, event)
	local human = event.human
	local db = human:getExpedition()
	local lv = event.objNum
	if PublicLogic.isModuleOpened(human, 'expedition') and db.hasOpen == 0 then
		db.hasOpen = 1
		db.lastResetTime = os.time()
		resetHeroAbout(human)
		decResetCount(human, 1)
	end
end

function resetHeroAbout(human)
	resetSelf(human)
	resetEnemy(human)
end

function resetSelf(human)
	local allHeros = HeroManager.getAllHeroes(human)
	local db = human:getExpedition()
	db.rage = 0
	db.assist = 300

	for k,v in pairs(db.heroList) do
		db.heroList[k] = nil
	end

	local tab = {}
	for index,hero in ipairs(allHeros) do
		local expeditionHero = {}
		expeditionHero.name = hero:getName()
		expeditionHero.hp = 100
		db.heroList[hero.name] = expeditionHero
	end
end

function resetEnemy(human)
	local db = human:getExpedition()
	for k,v in pairs(db.copyList) do
		db.copyList[k] = nil
	end

	local tab = {}
	local num = getExpeditionCount()
	local groupList = getGroupList(human)
	for i=1,num do
		local group = groupList[i]
		if group ~= nil then
			local obj = Arena.getArenaHuman(group.account)
			if obj ~= nil then
				local char = {}
				char.account = obj.db.account
				char.rage = 0
				if i == 1 then
					char.assist = 300
				else
					char.assist = 0
				end
				char.heroList = {}
				if group.fightList then
					for k,v in pairs(group.fightList) do
						local hero = obj:getHero(k)
						if hero ~= nil then
							local expeditionHero = {}
							expeditionHero.name = hero:getName()
							expeditionHero.pos = v.pos
							expeditionHero.exp = hero:getExp()
							expeditionHero.quality = hero:getQuality()
							if i < 6 then
								expeditionHero.lv = human:getLv() - 1
							elseif i < 11 then
								expeditionHero.lv = human:getLv()
							else
								expeditionHero.lv = human:getLv() + 1
							end
							expeditionHero.dyAttr = getDyAttr(human, i, hero.dyAttr)
							expeditionHero.hp = expeditionHero.dyAttr.maxHp
							expeditionHero.skillGroupList = getSkillList(human, i, hero:getSkillGroupList())
							char.heroList[hero.name] = expeditionHero
						end
					end
				end
				db.copyList[i] = char
			end
		end
	end
end

--获取敌方分组
function getGroupList(human)
	local humanList = Arena.getFrontEnemys(human:getAccount(), Define.FRONT_COUNT)
	local num = getExpeditionCount()
	local tab = {}
	local humanNum = #humanList
	local multiple = math.floor(humanNum / num)
	if multiple == 0 then
		--小于关卡数
		if humanNum > 0 then
			for i=1,num do
				local index = math.random(1, humanNum)
				table.insert(tab, humanList[index])
			end
		end
	else
		--超过关卡数
		for i=1,num do
			local index = (num - i) * multiple + math.random(1, multiple)
			table.insert(tab, humanList[index])
		end
	end
	return tab
end

--获取等级系数配置
function getAddConfig(human)
	local lv = human:getLv()
	for _,addConfig in pairs(AddConfig) do
		if lv >= addConfig.startLv and lv <= addConfig.endLv then
			return addConfig
		end
	end
	return nil
end

--获取动态属性
function getDyAttr(human, id, dyAttr)
	local attrList = ResetConfig.enemyAttr
	local tab = {} 
	for k,v in pairs(dyAttr) do
		tab[k] = v
	end
	Hero.dyAttr1(tab)
	
	local attrFactor = Config[id].attrFactor
	local config = getAddConfig(human)
	for _,attrName in pairs(attrList) do
		tab[attrName] = math.floor(config[attrName] * attrFactor + 0.5)
	end

	return tab
end

--获取技能
function getSkillList(human, id, skillList)
	local tab = {}
	local config = getAddConfig(human)
	local skillVal = 30
	if config ~= nil then
		skillVal = config.skillVal
	end
	local skillFactor = Config[id].skillFactor
	local skillSumVal = math.floor(skillVal * skillFactor + 0.5)
	for _,skillInfo in pairs(skillList) do
		local skillCopy = {}
		skillCopy.groupId = skillInfo.groupId
		skillCopy.lv = skillSumVal
		skillCopy.equipType = skillInfo.equipType
		skillCopy.isOpen = skillInfo.isOpen
		skillCopy.skillList = skillInfo.skillList
		table.insert(tab, skillCopy)
	end
	return tab
end


--远征关卡数
function getExpeditionCount()
	return Define.COPY_NUM
end

--设置商品已买
function setItemBuy(human, id)
	local db = human:getExpeditionShop()
	for _,item in pairs(db.itemlist) do
		if item.id == id then
			item.hasBuy = 1
		end
	end
end

--商品是否可买
function hasItemBuy(human, id)
	local db = human:getExpeditionShop()
	for _,item in pairs(db.itemlist) do
		if item.id == id then
			return item.hasBuy
		end
	end
	return 0
end

--刷新商店物品列表
function refreshShopList(human)
	local db = human:getExpeditionShop()
	local configList = Util.deepCopy(ShopConfig)
	local itemList = {}
	math.randomseed(os.time())
	for i=1,Define.SHOP_ITEM_COUNT do
		local item = randomItem(configList)
		--已经随机到的物品不参与随机
		configList[item.id] = nil

		local retItem = {}
		retItem.id = item.id
		retItem.count = item.count
		retItem.hasBuy = 0
		table.insert(itemList, retItem)
	end
	db.itemlist = itemList
	db.nextUpdate = getNextUpdateTime()
end

--刷新下一商店刷新时间
function getNextUpdateTime()
	local todayTime = Util.GetTodayTime()
	local curTime = os.time()
	for _,t in pairs(ResetConfig.resetTimeList) do
		local temp = todayTime + t * 3600
		if temp > curTime then
			return temp
		end
	end
	local nextDayTime = Util.GetNextDayTime() + ResetConfig.resetTimeList[1] * 3600
	return nextDayTime
end

--获取宝藏随机物品
function getRandomItem(type)
	local retList = {}
	local treasure = TreasureConfig[type]

	local itemList = {}
	for _,item in pairs(treasure.itemList) do
		local data = {}
		data.itemId = item[1]
		data.count = item[2]
		data.weight = item[3]
		table.insert(itemList, data)
	end
	math.randomseed(os.time())
	local itemCount = math.random(1, treasure.count)
	for i=1,itemCount do
		local item = randomItem(itemList)
		local retItem = {}
		retItem.itemId = item.itemId
		retItem.count = item.count
		table.insert(retList, retItem)	
	end
	return retList
end


--随机道具
--必须包含weight
function randomItem(itemList)
	local allWeight = 0
	for _,item in pairs(itemList) do
		allWeight = allWeight + item.weight
	end

	local weight = math.random(1, allWeight)

	local subWeight = 0
	for _,item in pairs(itemList) do
		subWeight = subWeight + item.weight
		if subWeight >= weight then
			return item
		end
	end

	return nil
end

--获取商品列表
function getShopList(human)
	local db = human:getExpeditionShop()
	local retList = {}
	for _,item in pairs(db.itemlist) do
		local data = {}
		data.shopId = item.id
		data.hasBuy = item.hasBuy
		table.insert(retList, data)
	end
	return retList
end

--获取已领取宝藏ID列表
function getHasGetTreasureList(human)
	local db = human:getExpedition()
	local retList = {}
	for id,_ in pairs(db.treasureList) do
		table.insert(retList, tonumber(id))
	end
	return retList
end

--是否已经领取过该宝藏
function hasGetThatTheasure(human, id)
	local db = human:getExpedition()
	return db.treasureList[tostring(id)] ~= nil
end

--是否已经通关
function hasSuccessExpedition(human, id)
	local db = human:getExpedition()
	return db.curId > id
end

--设置已领取宝藏
function setHasGetTreasure(human, id)
	local db = human:getExpedition()
	db.treasureList[tostring(id)] = 1
end

function getTreasureConfig(human, pos)
	for _,config in pairs(TreasureConfig) do
		if config.pos == pos and config.startLv <= human:getLv() and human:getLv() <= config.endLv then
			return config
		end
	end
end

--设置自己英雄属性
function setMyHeroAttrList(human, data, rage, assist)
	local db = human:getExpedition()
	db.rage = rage
	db.assist = assist
	for _,hpData in pairs(data) do
		local heroData = db.heroList[hpData.name]
		local hero = HeroManager.getHero(human, hpData.name)
		if heroData ~= nil and hero ~= nil then
			heroData.hp = math.floor(hpData.hp / hero.dyAttr.maxHp * 100)
			--if hero.hp > 0 then
			--	local curHero = human:getHero(hpData.name)
			--	hero.hp = math.floor(hero.hp + curHero.dyAttr.maxHp * (curHero.dyAttr.hpR / 100))
			--	if hero.hp > curHero.dyAttr.maxHp then
			--		hero.hp = curHero.dyAttr.maxHp
			--	end
			--end
		end
	end
end

--设置敌军英雄属性
function setEnemyHeroAttrList(human, data, rage, assist)
	local db = human:getExpedition()
	local copy = db.copyList[db.curId]
	if copy ~= nil then
		copy.rage = rage
		copy.assist = assist
		for _,hpData in pairs(data) do
			local hero = copy.heroList[hpData.name]
			if hero ~= nil then
				hero.hp = hpData.hp
			end
		end
	end
end


--获取当前关卡
function getCurExpedition(human)
	local db = human:getExpedition()
	local curEnemy = db.copyList[db.curId]
	return curEnemy
end

--清空昨日数据
function clearYesterdayData(human)
	local db = human:getExpedition()
	local curTime = os.time()
	if Util.IsSameDate(db.lastResetTime, curTime) == false then
		db.lastResetTime = curTime
		db.buyResetCount = 0
		db.shopRefreshCnt = 1
		db.hasResetCount = 0
		db.clearRage = 0
		db.clearAssist = 0
		db.clearHeroList = {}
		if db.clearCopyList then
			for k,v in pairs(db.clearCopyList) do
				db.clearCopyList[k] = nil
			end
		end
		if db.resetCount < ResetConfig.freeResetCount then
			resetExpeditionResetCount(human)
		end
	end
end

--重置重置次数
function resetExpeditionResetCount(human)
	local db = human:getExpedition()
	db.resetCount = ResetConfig.freeResetCount
end

--判断是否为最大重置次数
function hasMaxResetCount(human)
	local db = human:getExpedition()
	return db.resetCount >= ResetConfig.resetMaxCount
end

--判断是否已经为最大购买次数
function hasMaxBuyResetCount(human)
	local db = human:getExpedition()
	return db.buyResetCount >= getMaxBuyResetCount(human)
end

--获取最大重置购买次数
function getMaxBuyResetCount(human)
	return ResetConfig.chargeResetCount + VipLogic.getVipAddCount(human, VipDefine.VIP_EXPEDITION_RESET)
end

--判断是否够钱
function hasEnoughMoney(human, cost)
	return human:getRmb() >= cost
end

function incResetAndBuyCount(human)
	local db = human:getExpedition()
	db.resetCount = db.resetCount + 1
	db.buyResetCount = db.buyResetCount + 1  
end

--是否还有重置次数
function hasResetCountLeft(human)
	local db = human:getExpedition()
	return db.resetCount > 0
end

--是否还有宝藏未领取
function hasTreasureNotGet(human)
	local db = human:getExpedition()
	return (Util.GetTbNum(db.treasureList) + 1 < db.curId)
end

--
function incResetCount(human, count)
	local db = human:getExpedition()
	db.resetCount = db.resetCount + count
end

function decResetCount(human, count)
	local db = human:getExpedition()
	db.resetCount = db.resetCount - count
	db.hasResetCount = db.hasResetCount + count
	if db.hasResetCount == 1 then
		db.passId = 0
	end
end

function clearHasGetTreasureMark(human)
	local db = human:getExpedition()
	db.treasureList = {}
end

function resetToFirstExpedition(human)
	local db = human:getExpedition()
	db.curId = 1
end

function getCurShopRefreshCost(human)
	local shopRefreshList = ResetConfig.shopRefreshList
	local last = nil
	local len = #shopRefreshList
	for i=1,len do
		local v = shopRefreshList[i]
		if human:getExpedition().shopRefreshCnt < v[1] then
			break
		end
		last = v
	end
	return last[2]
end

function rewardClear(human)
	local db = human:getExpedition()
	if db.passId > 1 then
		local tb = {}
		for id=1,db.passId-1 do
			if hasGetThatTheasure(human, id) == false then
				local config = getTreasureConfig(human, id)
				if config then
					local rewardList = PublicLogic.randReward(config.rewardList)
					rewardList = WineLogic.wineBuffDeal(human,rewardList,"expedition")
					for k,v in pairs(rewardList) do
						if tb[k] == nil then
							tb[k] = v
						else
							tb[k] = tb[k] + v
						end
					end
					setHasGetTreasure(human, id)
				end
			end
		end
		PublicLogic.doReward(human, tb, {}, CommonDefine.ITEM_TYPE.ADD_EXPEDITION_REWARD)
	end
	human:sendHumanInfo()
end

function sendHeroListMsg(human)
	local db = human:getExpedition()
	local curEnemy = getCurExpedition(human)
	if curEnemy ~= nil then
		local tab = {}
		for _,hero in pairs(db.heroList) do
			table.insert(tab, hero)
		end
		return Msg.SendMsg(PacketID.GC_EXPEDITION_HERO_LIST, human, db.rage, db.assist, tab)
	end
end
