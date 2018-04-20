module(...,package.seeall)

local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local Define = require("modules.peak.PeakDefine")
local PeakRobotConfig = require("config.PeakRobotConfig").Config
local PeakConfig = require("config.PeakConfig").Config[1]
local SkillLogic = require("modules.skill.SkillLogic")
local PeakRobot = require("modules.peak.PeakRobot")
local Crontab = require("modules.public.Crontab")
local HeroManager = require("modules.hero.HeroManager")
local Hero = require("modules.hero.Hero")
local ShopConfig = require("config.PeakShopConfig").Config

_isStart = _isStart or false
_startTime = _startTime or nil
_searchTimer = _searchTimer or nil
_robotList = _robotList or {}
_fightList = _fightList or {}
_searchList = _searchList or {}

function init()
	initRobotData()
	initListener()
end

function initRobotData()
	_robotList = {}
	for _,config in pairs(PeakRobotConfig) do
		local robot = PeakRobot.new(config.id) 
		_robotList[config.id] = robot
	end
end

function initListener()
	HumanManager:addEventListener(HumanManager.Event_HumanDisconnect, onHumanDisconnect)
	Crontab.AddEventListener(Define.CRONTAB_PEAK, onOpenPeak)
end

function onHumanDisconnect(hm, human)
	if _isStart then
		local target = getCurTarget(human)
		if target and target.result == Define.RESULT_ING then
			target.result = Define.RESULT_FAIL
			dealWithScore(human, Define.RESULT_RUN)
			if target.isRobot ~= Define.ROBOT then
				local enemy = HumanManager.getOnline(target.account)
				if enemy and enemy.db.isOnline then
					local enemyTarget = getCurTarget(enemy)
					if enemyTarget.result == Define.RESULT_ING then
						enemyTarget.result = Define.RESULT_SUCCESS	
						dealWithScore(enemy, Define.RESULT_SUCCESS)
						Msg.SendMsg(PacketID.GC_PEAK_FAIL, enemy)
					end
				end
			end
		end
	end
end

function onOpenPeak()
	startPeak()
end

function startPeak()
	_isStart = true
	_startTime = os.time()
	_leftTime = PeakConfig.continueTime

	_searchTimer = Timer.new(Define.SEARCH_CHECK_RATE, -1)
	_searchTimer:setRunner(onTimer)
	_searchTimer:start()
end

function onTimer()
	if _isStart == true then
		judgeIsEnd()
		searching()
	end
end
function judgeIsEnd()
	if os.time() - _startTime >= _leftTime then
		endPeak()
	end
end

function searching()
	local curTime = os.time()
	for	k,tab in pairs(_searchList) do
		local tabLen = #tab
		for i=1,tabLen do
			local record = tab[i]
			local human = HumanManager.getOnline(record.account)
			if human then
				print('fuck fuck searching account = ' .. record.account)
				if curTime >= record.time then
					print('enter fuck ============== robotId = ' .. record.robotId)
					local robot = _robotList[record.robotId]
					local infoList = getRobotInfoList(record.robotId)
					Msg.SendMsg(PacketID.GC_PEAK_SEARCH, human, robot.name, infoList)
					addFightRecord(human, {
						isRobot=Define.ROBOT,
						account=robot.account,
						name=robot.name,
						lv=robot.lv,
						bodyId=robot.bodyId,
						heroNameList=getHumanFightList(human),
						enemyNameList=getRobotRandomNameList(record.robotId),
						heroInfoList=getHumanInfoList(human),
						enemyInfoList=infoList,
						result=Define.RESULT_ING,
					})
					HumanManager:dispatchEvent(HumanManager.Event_TopArena,{human=human,objNum = 1})

					refreshCoolTime(human)
					table.remove(tab, i)
					i = i - 1
					tabLen = #tab
					if tabLen == 0 then
						break
					end
				end
			else
				table.remove(tab, i)
				i = i - 1
				tabLen = #tab
				if tabLen == 0 then
					break
				end
			end
		end
	end
end

function endPeak()
	_isStart = false
	_searchList = {}
end

function addPlayerToFightList(human, heroNameList)
	local fightVal = getTeamFight(human)
	_fightList[human:getAccount()] = {account=human:getAccount(),fight=fightVal}
end

function getTeamFight(human)
	local fight = 0
	local heroNameList = human:getPeak():getTeam()
	for _,name in pairs(heroNameList) do
		local hero = human.getHero(human, name)
		fight = fight + hero:getFight()
	end
	return fight
end

function isInCoolTime(human)
	local db = human:getPeak()
	if db:getCoolTime() > os.time() then
		return true
	else
		return false
	end
end

function isStart()
	return _isStart
end

function refreshCoolTime(human)
	local db = human:getPeak()
	db:setCoolTime(os.time()+PeakConfig.coolTime)
end

function getSearchingPlayer(human)
	local robotId = getRobotId(human)	
	local target = getTargetPlayer(human, _searchList[robotId])
	if target then
		local enemy = HumanManager.getOnline(target.account)
		if enemy then
			addFightRecord(human, target)
			addFightRecord(enemy, {
				isRobot=Define.HUMAN,
				account=human:getAccount(),
				name=human:getName(),
				lv=human:getLv(),
				bodyId=human:getBodyId(),
				heroNameList=getHumanFightList(enemy),
				enemyNameList=getHumanFightList(human),
				heroInfoList=getHumanInfoList(enemy),
				enemyInfoList=getHumanInfoList(human),
				result=Define.RESULT_ING,
			})
			return target
		else
			addPlayerToSearchList(human)
		end
	else
		addPlayerToSearchList(human)
	end
end

function getHumanInfoList(human)
	local infoList = {}
	local heroNameList = getHumanFightList(human)
	for _,name in ipairs(heroNameList) do
		local data = {}
		local hero = human:getHero(name)
		data.name = hero:getName()
		data.lv = hero:getLv()
		data.quality = hero:getQuality()
		table.insert(infoList, data)
	end
	return infoList
end

function getRobotInfoList(robotId)
	local infoList = {}
	local robot = _robotList[robotId]
	print('robotId =====================' .. robotId)
	for name,hero in pairs(robot:getAllHero()) do
		local data = {}
		data.name = name
		data.lv = hero.lv
		data.quality = hero.quality
		table.insert(infoList, data)
	end
	Util.print_r(infoList)
	return infoList
end

function getRobotRandomNameList(robotId)
	local heroNameList = getRobotFightList(robotId)
	return getRandomHeroNameList(heroNameList, Define.TEAM_HERO_SELECT)
end

function getRobotFightList(robotId)
	local config = PeakRobotConfig[robotId]
	local heroNameList = {}
	for i=1,Define.HERO_COUNT do
		table.insert(heroNameList, config['hero' .. i])
	end
	return heroNameList
end

function getHumanRandomNameList(human)
	local heroNameList = getHumanFightList(human)
	return getRandomHeroNameList(heroNameList, Define.TEAM_HERO_SELECT)
end

function getHumanFightList(human)
	local heroNameList = human:getPeak():getTeam()
	return heroNameList
end

function getRandomHeroNameList(heroNameList, leftCnt)
	local copyList = Util.deepCopy(heroNameList)
	local ret = {}
	for i=1,leftCnt do
		local len = #copyList
		local index = math.random(1, len)	
		local name = table.remove(copyList, index)
		table.insert(ret, name)
	end
	return ret
end

function addFightRecord(human,target)
	local db = human:getPeak()
	local tb = {
		account=target.account,
		isRobot=target.isRobot,
		name=target.name,
		lv=target.lv,
		bodyId=target.bodyId,
		heroNameList=target.heroNameList,
		enemyNameList=target.enemyNameList,
		heroInfoList=target.heroInfoList,
		enemyInfoList=target.enemyInfoList,
		result=target.result,
	}	
	if #db.fightRecordList >= Define.FIGHT_RECORD_COUNT then
		table.remove(db.fightRecordList, 1)
	end
	table.insert(db.fightRecordList, tb)
end

function getCurTarget(human)
	local db = human:getPeak()
	local target = db.fightRecordList[#db.fightRecordList]
	return target
end

function getTargetPlayer(human, tb)
	if tb then
		while #tb > 0 do
			local record = table.remove(tb, 1)
			local enemy = HumanManager.getOnline(record.account)
			if enemy and enemy.db.isOnline == 1 then
				local heroNameList = getHumanFightList(enemy)
				local ret = {
					bodyId=enemy:getBodyId(),
					name=enemy:getName(),
					lv=enemy:getLv(),
					account=enemy:getAccount(),
					isRobot=Define.HUMAN,
					heroNameList=getHumanFightList(human),
					enemyNameList=getHumanFightList(enemy),
					heroInfoList=getHumanInfoList(human),
					enemyInfoList=getHumanInfoList(enemy),
					result=Define.RESULT_ING,
				}
				--for _,name in ipairs(heroNameList) do
				--	local hero = HeroManager.getHero(human, name)
				--	local info = {name=hero:getName(),lv=hero:getLv(),quality=hero:getQuality()}
				--	table.insert(ret.heroList, info)	
				--end
				return ret
			end
		end
	end
end

function addPlayerToSearchList(human)
	delPlayerToSearchList(human)

	local robotId = getRobotId(human)
	if _searchList[robotId] == nil then
		_searchList[robotId] = {}
	end
	local searchRobotTime = os.time() + Define.SEARCH_TIME
	table.insert(_searchList[robotId], {account=human:getAccount(),robotId=robotId,fight=fightVal,time=searchRobotTime})
end

function getRobotId(human)
	local fightVal = getTeamFight(human)
	local robotId = 1
	for _,config in ipairs(PeakRobotConfig) do
		if fightVal >= config.startFight and fightVal <= config.endFight then
			robotId = config.id
			break
		end
	end
	return robotId
end

function delPlayerToSearchList(human)
	for _,tab in pairs(_searchList) do
		local len = #tab
		for i=1,len do
			if tab[i].account == human:getAccount() then
				table.remove(tab, i)
				break
			end
		end
	end
end

function getCurResetCost(human)
	local db = human:getPeak()
	local cost = PeakConfig.resetCost
	local last = nil
	local len = #cost
	for i=1,len do
		local v = cost[i]
		if db:getResetCount() < v[1] then
			break
		end
		last = v
	end
	return last[2]
end

function getHumanHeroList(human)
	local heroList = {}		
	local target = getCurTarget(human)
	print('humanName ========================' .. human:getName())
	Util.print_r(target)
	for _,name in ipairs(target.heroNameList) do
		local hero = human:getHero(name)
		print('heroName ===========================' .. name)
		if hero then
			local data = {}
			data.name = hero:getName()
			data.exp = hero:getExp()
			data.quality = hero:getQuality()
			data.lv = hero:getLv()
			data.dyAttr = Util.deepCopy(hero.dyAttr)
			Hero.dyAttr1(data.dyAttr)
			local groupList = hero:getSkillGroupList()
			local groupMsg = {}
			for _,group in pairs(groupList) do
				SkillLogic.makeSkillGroupMsg(group,groupMsg)
			end
			data.skillGroupList = groupMsg 
			data.gift = hero:getGift()
			table.insert(heroList, data)
		end
	end
	return heroList
end

function getRobotHeroList(target)
	local robotId = target.account
	local heroList = {}
	local robot = _robotList[robotId]
	target.enemyNameList = getRandomHeroNameList(target.enemyNameList, Define.TEAM_HERO_COUNT)
	for _,name in ipairs(target.enemyNameList) do
		local data = {}
		local h = robot:getHero(name)
		data.name = name
		data.exp = 0
		data.quality = h.quality
		data.lv = h.lv
		data.dyAttr = Util.deepCopy(h.dyAttr)
		Hero.dyAttr1(data.dyAttr)	
		data.skillGroupList = Util.deepCopy(h.skillgroup)
		data.gift = {}
		table.insert(heroList, data)
	end
	return heroList
end

function getFightRecordList(human)
	local recordList = {}
	local db = human:getPeak()
	local list = db.fightRecordList
	for _,record in ipairs(list) do
		local tb = {}
		tb.icon = record.bodyId
		tb.name = record.name
		tb.lv = record.lv
		tb.result = record.result

		if #record.heroNameList >= 4 then
			local fightNameList = {}
			for i=1,4 do
				local name = record.heroNameList[i]
				table.insert(fightNameList, name)
			end
			record.heroNameList = fightNameList
		end
		tb.fightList = getHeroInfoList(record.heroNameList, record.heroInfoList)

		if #record.enemyNameList >= 4 then
			local enemyNameList = {}
			for i=1,4 do
				local name = record.enemyNameList[i]
				table.insert(enemyNameList, name)
			end
			record.enemyNameList = enemyNameList
		end
		tb.enemyList = getHeroInfoList(record.enemyNameList, record.enemyInfoList) 

		table.insert(recordList, tb)
	end
	return recordList
end

function getHeroInfoList(nameList, list)
	local tb = {}
	local len = #nameList
	for i=1,len do
		local name = nameList[i]
		for _,info in ipairs(list) do
			if info.name == name then
				local copy = Util.deepCopy(info)
				if i ~= len then
					copy.pos = i
				else
					copy.pos = 4
				end
				table.insert(tb, Util.deepCopy(info))
			end
		end
	end
	return tb
end

function dealWithScore(human, result)
	local db = human:getPeak()
	if result == Define.RESULT_SUCCESS then
		db:setScore(db:getScore() + PeakConfig.successScore)
		human:incPeakCoin(PeakConfig.successScore)
	elseif result == Define.RESULT_FAIL then
		db:setScore(db:getScore() + PeakConfig.failScore)
		human:incPeakCoin(PeakConfig.failScore)
	elseif result == Define.RESULT_RUN then
		db:setScore(db:getScore() + PeakConfig.runScore)
		human:incPeakCoin(PeakConfig.runScore)
	end
	human:sendHumanInfo()
end

function getCurShopRefreshCost(human)
	local shopRefreshList = PeakConfig.shopRefreshList
	local last = nil
	local len = #shopRefreshList
	for i=1,len do
		local v = shopRefreshList[i]
		if human:getPeak().shopRefreshCnt < v[1] then
			break
		end
		last = v
	end
	return last[2]
end

--设置商品已买
function setItemBuy(human, id)
	local db = human:getPeak()
	for _,item in pairs(db.itemlist) do
		if item.id == id then
			item.hasBuy = 1
		end
	end
end

--商品是否可买
function hasItemBuy(human, id)
	local db = human:getPeak()
	for _,item in pairs(db.itemlist) do
		if item.id == id then
			return item.hasBuy
		end
	end
	return 0
end

--刷新商店物品列表
function refreshShopList(human)
	local db = human:getPeak()
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
	for _,t in pairs(PeakConfig.resetTimeList) do
		local temp = todayTime + t * 3600
		if temp > curTime then
			return temp
		end
	end
	local nextDayTime = Util.GetNextDayTime() + PeakConfig.resetTimeList[1] * 3600
	return nextDayTime
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
	local db = human:getPeak()
	local retList = {}
	for _,item in pairs(db.itemlist) do
		local data = {}
		data.shopId = item.id
		data.hasBuy = item.hasBuy
		table.insert(retList, data)
	end
	return retList
end

--清空昨日数据
function clearYesterdayData(human)
	local db = human:getPeak()
	local curTime = os.time()
	if Util.IsSameDate(db.lastResetTime, curTime) == false then
		db.lastResetTime = curTime
		db.shopRefreshCnt = 1
		db.resetCount = 1
	end
end
