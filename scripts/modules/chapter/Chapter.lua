module(...,package.seeall)

local ChapterConfig = require("config.ChapterConfig").Config
local LevelConfig = require("config.LevelConfig").Config
local FixRewardConfig = require("config.FixRewardConfig").Config
local FBConfig = require("config.FBConfig").Config
local ChapterDefine = require("modules.chapter.ChapterDefine")
local Msg = require("core.net.Msg")
local BagLogic = require("modules.bag.BagLogic")
local Levels = {}
local HeroManager = require("modules.hero.HeroManager")
local PublicLogic = require("modules.public.PublicLogic")
local Chapters = {}
local DB = require("core.db.DB")
local ns = 'rank'
local modName = "chapter"
-- db 结构 db = {[10101] = {%lasttime%,%cnt%}}    上次通关时间,当天的通关次数

debugFlag = false

RankList = RankList or {}


function updateRank(human)
	for k,v in pairs(RankList) do 
		if human:getAccount() == v.account then
			v.lv = human:getLv()
		end
	end
end
function onHumanLogin(hm,human)
	refreshInfo(human)
	if human.info.Chapter == nil then
		human.info.Chapter = {levelstart={},cycleReward={}}
	end
	sendChapterList(human)
end
function onHumanDBLoad(hm,human)
	if human.db.Chapter == nil then
		human.db.Chapter = {cdTime=0,levelList={},boxList={}}
	end

	--为了兼容旧账号
	-- if human.db.Chapter.cycleReward == nil then human.db.Chapter.cycleReward = {} end
	DB.dbSetMetatable(human.db.Chapter.levelList)
	DB.dbSetMetatable(human.db.Chapter.boxList)
	-- DB.dbSetMetatable(human.db.Chapter.cycleReward)
end
function onHumanLvUp(hm,event)
	local human = event.human
	updateRank(human)
end



local Hm = require("core.managers.HumanManager")
Hm:addEventListener(Hm.Event_HumanLogin,onHumanLogin)
Hm:addEventListener(Hm.Event_HumanDBLoad,onHumanDBLoad)
Hm:addEventListener(Hm.Event_HumanLvUp,onHumanLvUp)

function initDB()
	loadDB()
	--定时存库
	local timer = Timer.new(900000,-1)	--15分钟
	timer:setRunner(saveDB)
	timer:start()
end

function loadDB()
	local query = {module=modName}
    local pCursor = g_oMongoDB:SyncFind(ns,query)
    if not pCursor then
        return false
    end
    local Cursor = MongoDBCursor(pCursor)
	local row = {}
    if not Cursor:Next(row) then
		g_oMongoDB:SyncInsert(ns,{module=modName,rankList=RankList})
	else
		RankList = row.rankList
    end
	return true
end


function saveDB(isSync)
	local query = {module=modName}
	DB.Update(ns,query,{module=modName,rankList=RankList},isSync)
end


-- function setRank(human,levelId)
-- 	local star = getStar(human)
-- 	local rl = RankList
-- 	if #RankList > 0 and RankList[#RankList].star >= star and #RankList >= ChapterDefine.MAX_RANK then
-- 		return
-- 	end
-- 	local item = {bodyId=human.db.bodyId,account=human:getAccount(),charName=human:getName(),lv=human:getLv(),star=star,levelId=levelId}
-- 	if #RankList == 0 then
-- 		table.insert(RankList,item)
-- 	else
-- 		local bInserted = false
-- 		local oldIndex = 0 
-- 		for i=#RankList,1,-1 do 
-- 			if RankList[i].account == human:getAccount() then oldIndex = i end
-- 			if RankList[i].star > star then
-- 				table.insert(RankList,i+1,item)
-- 				bInserted = true
-- 				break
-- 			end
-- 		end
-- 		if bInserted == false then
-- 			table.insert(RankList,1,item)
-- 		end
-- 		if oldIndex > 0 then
-- 			table.remove(RankList,oldIndex+1)
-- 		end
-- 	end
-- 	if #RankList > ChapterDefine.MAX_RANK then
-- 		table.remove(RankList,#RankList)
-- 	end
-- end



function sendChapterDebugFlag(human,flag)
	local f = 0
	if flag == true then f = 1 end
	debugFlag = flag
	Msg.SendMsg(PacketID.GC_CHAPTER_DEBUGFLAG,human,f)
end
function sendChapterList(human)
	local levelList = {}
	for levelId,level in pairs(human.db.Chapter.levelList) do 
		for difficulty,l in ipairs(level) do
			local timesForDay = getTimesPerDay(human,levelId,difficulty)
			local buy_times = getBuyTimes(human,levelId,difficulty)
			table.insert(levelList,{levelId=levelId,difficulty=difficulty,time=l.time,timesForDay=timesForDay,buyTimes=buy_times,star=l.star})
		end
	end
	local boxList = human.db.Chapter.boxList or {}
	local blist = {}
	for chapterId,d in pairs(boxList) do
		for difficulty,box in pairs(d) do
			for boxId,received in pairs(box) do
				if received == 1 then
					table.insert(blist,{chapterId=chapterId,difficulty=difficulty,boxId=boxId})
				end
			end
		end
	end
	-- for chapterId,box in pairs(human.db.Chapter.boxList) do
	-- 	for _,b in pairs(box) do
	-- 		table.insert(boxList,{chapterId=b.chapterId,difficulty = b.difficulty,boxId=b.boxId})
	-- 	end
	-- end
	Msg.SendMsg(PacketID.GC_CHAPTER_LIST,human,blist,levelList,human.db.Chapter.fightHeroes)
end

function getHumanFightHeroes(human)
	return human.db.Chapter.fightHeroes
end
function getChapterId(levelId)
	local conf = LevelConfig[levelId]
	if conf then
		return conf[1].chapterId
	end
end

function getTimesPerDay(human,levelId,difficulty)
	local levelList = human.db.Chapter.levelList
	if levelList[levelId] and levelList[levelId][difficulty] then
		if not Util.isToday(levelList[levelId][difficulty].time) then
			levelList[levelId][difficulty].timesForDay = 0
		end
		return levelList[levelId][difficulty].timesForDay
	end
	return 0
end

function setTimesPerDay(human,levelId,difficulty,cnt)
	local levelList = human.db.Chapter.levelList
	if levelList[levelId] and levelList[levelId][difficulty] then
		if not Util.isToday(levelList[levelId][difficulty].time) then
			levelList[levelId][difficulty].timesForDay = 0
		end
		levelList[levelId][difficulty].time = os.time()
		levelList[levelId][difficulty].timesForDay = levelList[levelId][difficulty].timesForDay + cnt
	end
end


function getDB(human,levelId,difficulty)
	if human.db.Chapter.levelList[levelId] and human.db.Chapter.levelList[levelId][difficulty] then
		return human.db.Chapter.levelList[levelId][difficulty]
	end
end

function getBuyTimes(human,levelId,difficulty)
	-- 获得本关卡当天购买通关限额的次数
	local level = getDB(human,levelId,difficulty)
	if not Util.isToday(level.lastBuyTime) then
		level.buyTimes = 0
	end
	return level.buyTimes
end


-- function getStar(human)
-- 	-- 返回玩家所有星星数量
-- 	local star = 0
-- 	for levelId,level in pairs(human.db.Chapter.levelList) do 
-- 		for i=1,3 do 
-- 			if level[i] then
-- 				star = star + 1
-- 			end
-- 		end
-- 	end
-- 	return star
-- end

function getStar(human,chapterId,difficulty)
	local star = 0
	local levelList = human.db.Chapter.levelList
	for levelId,d in pairs(levelList) do
		if d[difficulty] then
			star = d[difficulty].star + star
		end
	end
	return star
end

function getTopLevel(human)
	local top = 0
	for cid=1,100 do 
		if ChapterConfig[cid] == nil then
			break
		end
		local first = getFirstLevel(cid)
		local last = getFinalLevel(cid)
		for levelId = first,last do 
			if isLevelPassed(human,levelId,1) then
				top = levelId
			end
		end
	end
	return top
end


function isLevelPassed(human,levelId,difficulty)
	local levelList = human.db.Chapter.levelList
	if levelList[levelId] and levelList[levelId][difficulty] then
		return true
	else
		return false
	end 
end

function getFirstLevel(chapterId)
	if ChapterConfig[chapterId] then
		return chapterId*100 + 1
	end
end

function getFinalLevel(chapterId)
	local levelId = getFirstLevel(chapterId)
	while true do
		if LevelConfig[levelId] then
			levelId = levelId + 1
		else
			break
		end
	end
	return levelId-1
end

function getLastLevelId(levelId)
	local chapterId = getChapterId(levelId)
	local firstLevelId = getFirstLevel(chapterId)
	if levelId == 101 then return end
	if firstLevelId == levelId then
		-- 自己就是章节的头一个关卡
		return getFinalLevel(chapterId-1)
	else
		return levelId-1
	end
end


function isLevelOpened(human,levelId,difficulty)
	-- 判断该副本是否开放
	local chapterId = getChapterId(levelId)

	if difficulty == 1 then
		if levelId == 101 then
			return true
		else
			local lastLevelId = getLastLevelId(levelId)
			return isLevelPassed(human,lastLevelId,difficulty)
		end
	else
		local first = getFirstLevel(chapterId)
		if first == levelId then
			local final = getFinalLevel(chapterId)
			return isLevelPassed(human,final,difficulty-1)
		else
			return isLevelPassed(human,levelId-1,difficulty)
		end
	end
end

function passLevel(human,levelId,difficulty,star)
	local levelList = human.db.Chapter.levelList
	if levelList[levelId] == nil then levelList[levelId] = {} end
	if levelList[levelId][difficulty] == nil then 
		levelList[levelId][difficulty] = {levelId = levelId,difficulty=difficulty,time=os.time(),timesForDay=1,star=star}
		return true
	else
		local db = levelList[levelId][difficulty]
		if Util.isToday(levelList[levelId][difficulty].time) then
			db.time = os.time()
			db.timesForDay = db.timesForDay + 1
		else
			db.time = os.time()
			db.timesForDay = 1
		end
		if db.star == nil then db.star = 0 end
		if star > db.star then
			db.star = star
		end
		return false
	end
end

function boxReward(human,chapterId,difficulty,boxId)
	local boxList = human.db.Chapter.boxList
	if boxList[chapterId] and boxList[chapterId][difficulty] and boxList[chapterId][difficulty] and boxList[chapterId][difficulty][boxId] and boxList[chapterId][difficulty][boxId] > 0 then
		return false
	else
		if boxList[chapterId] == nil then 
			boxList[chapterId] = {}
			for i=1,3 do
				boxList[chapterId][i] = {0,0,0}
			end
		end
		boxList[chapterId][difficulty][boxId] = 1
		return true
	end
end

function refreshInfo(human)
	-- local db = human.db.Chapter
	-- local info = human.info.Chapter
	-- if info.Chapter == nil then info.Chapter = {} end
	-- if info.Level == nil then info.Level = {} end
	-- for fbId,fb in pairs(db) do
	--     local levelId = FBConfig[fbId].levelId
	--     local chapterId = LevelConfig[levelId].chapterId
	--     local difficulty = FBConfig[fbId].difficulty
	-- 	if info.Level[levelId] == nil then info.Level[levelId] = {} end
	-- 	info.Level[difficulty] = fb
	-- 	if info.Chapter[chapterId] == nil then info.Chapter[chapterId] = {} end
	-- 	info.Chapter[levelId] = info.Level[levelId]
	-- end
end


function levelPassLogic(human,levelId,difficulty,isWipe,star,cnt,heroes)
	if isWipe then star = 1 end
	local conf = LevelConfig[levelId][difficulty]
	local function addReward(rtb,reward)
		for n,r in pairs(reward) do 
			if rtb[n] == nil then rtb[n] = 0 end
			rtb[n] = rtb[n] + r
		end
	end
	local reward = {}
	local totalPhy = 0
	for i=1,cnt do
		local rtb = {}
		local firstPass = passLevel(human,levelId,difficulty,star)
		if isWipe then
			human:decPhysics(conf.energy,CommonDefine.PHY_TYPE.DEC_CHAPTER_WIPE)
		else
			human:decPhysics(conf.energy,CommonDefine.PHY_TYPE.DEC_CHAPTER)
		end
		totalPhy = totalPhy + conf.energy
		-- 计算奖励
		
		--  固定奖励
		local lv = human:getLv()
		if FixRewardConfig[lv] == nil then
			lv = 100
		end
		if isWipe then
			addReward(rtb,FixRewardConfig[lv]['wipeReward'..difficulty])
		else
			addReward(rtb,FixRewardConfig[lv]['chapterReward'..difficulty])
		end

		-- 随机奖励
		local randReward = PublicLogic.randReward(conf.randReward)
		addReward(rtb,randReward)

		local cycleReward = PublicLogic.cycleReward(human,conf.cycleReward,human.info.Chapter.cycleReward)
		addReward(rtb,cycleReward)

		-- 首次通关的额外奖励
		if firstPass then
			addReward(rtb,conf.extraReward)
		end
		table.insert(reward,rtb)
	end
	-- if isWipe then
	-- 	local logTb = Log.getLogTb(LogId.CHAPTER_WIPE)
	-- 			logTb.account = human:getAccount()
	-- 			logTb.name = human:getName()
	-- 			logTb.pAccount = human:getPAccount()
	-- 			logTb.levelName = conf.levelTitle
	-- 			logTb.levelId = levelId
	-- 			logTb.difficulty = difficulty
	-- 			logTb.cnt = cnt
	-- 			logTb.physics = totalPhy
	-- 			logTb:save()
	-- else
	-- 	local logTb = Log.getLogTb(LogId.CHAPTER_END)
	-- 			logTb.account = human:getAccount()
	-- 			logTb.name = human:getName()
	-- 			logTb.pAccount = human:getPAccount()
	-- 			logTb.levelName = conf.levelTitle
	-- 			logTb.levelId = levelId
	-- 			logTb.difficulty = difficulty
	-- 			logTb.physics = totalPhy
	-- 			logTb.result = 1
	-- 			logTb:save()
	-- end
	return reward
end
