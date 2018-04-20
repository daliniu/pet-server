module(...,package.seeall)

local Chapter = require("modules.chapter.Chapter")
local Util = require("core.utils.Util")
local ChapterConfig = require("config.ChapterConfig").Config
local LevelConfig = require("config.LevelConfig").Config
local FBConfig = require("config.FBConfig").Config
local PublicLogic = require("modules.public.PublicLogic")
local EventLogic = require("modules.event.EventLogic")
local HeroManager = require("modules.hero.HeroManager")
local ChapterDefine = require("modules.chapter.ChapterDefine")
local Msg = require("core.net.Msg")
local BagLogic = require("modules.bag.BagLogic")

local VipDefine = require("modules.vip.VipDefine")
local VipLogic = require("modules.vip.VipLogic")
local ShopLogic = require("modules.shop.ShopLogic")

function addReward(rtb,reward)
	for n,r in pairs(reward) do 
		if rtb[n] == nil then rtb[n] = 0 end
		rtb[n] = rtb[n] + r
	end
end

function onCGChapterFbStart(human,levelId,difficulty)
	if LevelConfig[levelId] == nil or LevelConfig[levelId][difficulty] == nil then
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_START,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_NOTPERMITTED)
    	return
    end
    local chapterId = Chapter.getChapterId(levelId)
    local cConfig = ChapterConfig[chapterId]
    local lConfig = LevelConfig[levelId][difficulty]
    local levelList = human.db.Chapter.levelList
    local info = human.info.Chapter
    if difficulty > 1 and (not Chapter.isLevelPassed(human,levelId,difficulty-1)) then 
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_START,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_OVERFLOW)
    	return
    end
    -- 判断战队等级限制	
    if human:getLv() < cConfig[1].charLevel then
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_START,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_LEVEL)
    	return
    end
	if not Chapter.debugFlag and not Chapter.isLevelOpened(human,levelId,difficulty) then
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_START,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_NOTOPENED)
    	return
    end
	-- -- 判断前置章节是否开启
	-- if cConfig.preChapterId > 0 and info.Chapter[cConfig.preChapterId] == nil then 
 --    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_START,human,fbId,ChapterDefine.RET_CHAPTER_NOTPERMITTED)
 --    	return
	-- end

	-- -- 判断本关卡前一个难度副本是否通关
	-- if difficulty > 1 and info.Level[difficulty -1] == nil then
 --    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_START,human,fbId,ChapterDefine.RET_CHAPTER_NOTPERMITTED)
 --    	return
	-- end

	-- 判断体力是否足够
	if human:getPhysics() < lConfig.energy then
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_START,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_PHYSICS)
    	return
	end

	-- 判断是否超过每日次数限制
	if lConfig.limitPerDay > 0 and Chapter.getTimesPerDay(human,levelId,difficulty) >= lConfig.limitPerDay and not Chapter.debugFlag then 
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_START,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_TIMES)
    	return
	end

	-- EventLogic.fbCallback(human,fbId)

	-- 设置当前本关卡已经开始战斗，结算时会检查这个配置
	-- if human.info.Chapter.levelstart == nil then
	-- 	human.info.Chapter.levelstart = {}
	-- end
	-- if human.info.Chapter.levelstart[levelId] == nil then
	-- 	human.info.Chapter.levelstart[levelId] = {}
	-- end
	-- human.info.Chapter.levelstart[levelId][difficulty] = 1



	-- 设置当前的副本
	human.db.Chapter.curLevelId = levelId
	human.db.Chapter.curDifficulty = difficulty
	human.db.Chapter.curSTime = os.time()
	local level
	if levelList[levelId] and levelList[levelId][difficulty] then
		level = {levelId=levelId,difficulty=difficulty,time=levelList[levelId][difficulty][1],timesPerDay=levelList[levelId][difficulty][2]}
	else
		level = {levelId=levelId,difficulty=difficulty,time=0,timesPerDay=0}
	end
    Msg.SendMsg(PacketID.GC_CHAPTER_FB_START,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_OK,level)

	local logTb = Log.getLogTb(LogId.CHAPTER_START)
			logTb.account = human:getAccount()
			logTb.channelId = human:getChannelId()
			logTb.name = human:getName()
			logTb.pAccount = human:getPAccount()
			logTb.levelName = lConfig.levelTitle
			logTb.levelId = levelId*10+difficulty
			logTb.difficulty = difficulty
			logTb:save()

end

function onCGChapterBuytimes(human,levelId,difficulty,no)
	if LevelConfig[levelId] == nil or LevelConfig[levelId][difficulty] == nil then
		Msg.SendMsg(PacketID.GC_CHAPTER_BUYTIMES,human,ChapterDefine.RET_CHAPTER_NOTPERMITTED, levelId,difficulty,no)
		return
	end
	local level= Chapter.getDB(human,levelId,difficulty)
	local curTimes = Chapter.getBuyTimes(human,levelId,difficulty)
	-- if curTimes >= no then
	-- 	Msg.SendMsg(PacketID.GC_CHAPTER_BUYTIMES,human,ChapterDefine.RET_CHAPTER_IGNORED,levelId,difficulty,no)
	-- 	return
	-- else
		-- 检查购买上限
		local buyLimit = VipLogic.getVipAddCount(human, VipDefine.VIP_CHAPTER_RESET)
		if curTimes >= buyLimit then
			Msg.SendMsg(PacketID.GC_CHAPTER_BUYTIMES,human,ChapterDefine.RET_CHAPTER_BUYTIMES,levelId,difficulty,curTimes)
			return
		end


		local targetTimes = curTimes + 1
		-- 获得本次购买的价格
		local  price = ShopLogic.getPriceByTimes(ChapterDefine.BUTTIMES_SHOPID,targetTimes)


		if human:getRmb() < price then
			Msg.SendMsg(PacketID.GC_CHAPTER_BUYTIMES,human,ChapterDefine.RET_CHAPTER_RMB, levelId,difficulty,targetTimes)
			return
		end
		level.buyTimes = targetTimes
		level.lastBuyTime = os.time()
		human:decRmb(price,nil,CommonDefine.RMB_TYPE.DEC_CHAPTER_BUYTIME)
		level.time = os.time()
		level.timesForDay = 0
		human:sendHumanInfo()
		Msg.SendMsg(PacketID.GC_CHAPTER_BUYTIMES,human,ChapterDefine.RET_CHAPTER_OK,levelId,difficulty,targetTimes)
	-- end
end


function onCGChapterFbEnd(human,levelId,difficulty,result,heroes,star)
	human.db.Chapter.fightHeroes = heroes
	local nowtime = os.time()
	local info = human.info.Chapter
	local levelList = human.db.Chapter.levelList
	local lConfig = LevelConfig[levelId][difficulty]
	if LevelConfig[levelId] == nil or LevelConfig[levelId][difficulty] == nil then
		Msg.SendMsg(PacketID.GC_CHAPTER_FB_END,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_NOTPERMITTED)
		return
	end

	if human.db.Chapter.curLevelId ~= levelId or human.db.Chapter.curDifficulty ~= difficulty then 
		Msg.SendMsg(PacketID.GC_CHAPTER_FB_END,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_NOTOPENED)
		return
	end

	if result == ChapterDefine.DEFEATED then
		-- 前端通关失败，后端简单处理，返回通过
		Msg.SendMsg(PacketID.GC_CHAPTER_FB_END,human,levelId,difficulty,ChapterDefine.DEFEATED)
		local conf = LevelConfig[levelId][difficulty]
		local logTb = Log.getLogTb(LogId.CHAPTER_END)
				logTb.account = human:getAccount()
				logTb.channelId = human:getChannelId()
				logTb.name = human:getName()
				logTb.pAccount = human:getPAccount()
				logTb.levelName = conf.levelTitle
				logTb.levelId = levelId*10+difficulty
				logTb.difficulty = difficulty
				logTb.physics = 0
				logTb.result = 0
				if human.db.Chapter.curSTime then
					logTb.costTime = nowtime - human.db.Chapter.curSTime 
				else
					logTb.costTime = 0
				end
				logTb:save()
	elseif result == ChapterDefine.WIN then
	    -- if difficulty > 1 and (not Chapter.isLevelPassed(human,levelId,difficulty-1)) then 
	    -- 	Msg.SendMsg(PacketID.GC_CHAPTER_FB_END,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_OVERFLOW)
	    -- 	return
	    -- end
	    local conf = LevelConfig[levelId][difficulty]
		-- 暂时忽略验证合法性，以后需要补上
		--~~~~~~~~~~~~~~~~~~~
		-- if human.info.Chapter.levelstart == nil or human.info.Chapter.levelstart[levelId] == nil or human.info.Chapter.levelstart[levelId][difficulty] == nil then
		-- 	Msg.SendMsg(PacketID.GC_CHAPTER_FB_END,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_IGNORED)
		-- 	return
		-- end
		-- human.info.Chapter.levelstart[levelId][difficulty] = nil


		-- if not Chapter.isLevelOpened(human,levelId,difficulty) then
	 --    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_END,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_NOTOPENED)
	 --    	return
	 --    end


		-- local t = os.time()
		-- local firstPass = Chapter.passLevel(human,levelId,difficulty,star)


		-- -- 减去体力
		-- human:decPhysics(conf.energy)


		-- -- 计算奖励
		-- local rtb = {}
		-- --  固定奖励

		-- addReward(rtb,conf.fixReward)

		-- -- 随机奖励
		-- local randReward = PublicLogic.randReward(conf.randReward)
		-- addReward(rtb,randReward)

		-- -- 首次通关的额外奖励
		-- if firstPass then
		-- 	addReward(rtb,conf.extraReward)
		-- 	-- Chapter.setRank(human,levelId)
		-- end
		-- PublicLogic.doReward(human,rtb,heroes)

		local reward = Chapter.levelPassLogic(human,levelId,difficulty,false,star,1,heroes)
		

		local rewardList = {}
		for n,r in pairs(reward[1]) do 
			table.insert(rewardList,{rewardName=tostring(n),cnt=r})
		end
		local level= Chapter.getDB(human,levelId,difficulty)
		
		
		Msg.SendMsg(PacketID.GC_CHAPTER_FB_END,human,levelId,difficulty,ChapterDefine.WIN,level,rewardList,star)
		PublicLogic.doReward(human,reward[1],heroes,CommonDefine.ITEM_TYPE.ADD_CHAPTER)
		HeroManager.sendHeroes(human,heroes)
		human:sendHumanInfo()
		-- HeroManager.sendAllHeroes(human)
		
		-- Chapter.sendChapterList(human)

		local temp = levelId * 10 + difficulty
		HumanManager:dispatchEvent(HumanManager.Event_Chapter,{human=human,objId=temp})
		local logTb = Log.getLogTb(LogId.CHAPTER_END)
				logTb.account = human:getAccount()
				logTb.channelId = human:getChannelId()
				logTb.name = human:getName()
				logTb.pAccount = human:getPAccount()
				logTb.levelName = conf.levelTitle
				logTb.levelId = levelId*10+difficulty
				logTb.difficulty = difficulty
				logTb.physics = conf.energy
				logTb.result = 1
				if human.db.Chapter.curSTime then
					logTb.costTime = nowtime - human.db.Chapter.curSTime 
				else
					logTb.costTime = 0
				end
				logTb:save()
	end
	-- info.curFB = nil
	-- info.curFBSTime = nil
end

function onCGChapterFbWipe(human,levelId,difficulty,cnt)
	if LevelConfig[levelId] == nil or LevelConfig[levelId][difficulty] == nil then
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_NOTPERMITTED)
    	return
    end
    local chapterId = Chapter.getChapterId(levelId)
    local cConfig = ChapterConfig[chapterId][difficulty]
    local lConfig = LevelConfig[levelId][difficulty]
    local db = human.db.Chapter
    local levelList = db.levelList
    local info = human.info.Chapter
    local wipeOpenLv = PublicLogic.getOpenLv("wipe")
    if human:getLv() < wipeOpenLv then
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_LILIAN_LEVEL)
    	return
    end

    -- 判断战队等级限制	
    if human:getLv() < cConfig.charLevel then
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_LEVEL)
    	return
    end

	-- 判断前置章节是否开启
	-- if cConfig.preChapterId > 0 and info.Chapter[cConfig.preChapterId] == nil then 
 --    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,fbId,ChapterDefine.RET_CHAPTER_NOTPERMITTED)
 --    	return
	-- end

	-- -- 判断本关卡前一个难度副本是否通关
	-- if difficulty > 1 and info.Level[difficulty -1] == nil then
 --    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,fbId,ChapterDefine.RET_CHAPTER_NOTPERMITTED)
 --    	return
	-- end

	-- 判断是否通过本关卡
	if not Chapter.isLevelPassed(human,levelId,difficulty) then
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_NOTPASSED)
    	return
	end


	-- 判断体力是否足够
	if human:getPhysics() < lConfig.energy*cnt then
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_PHYSICS)
    	return
	end


	-- 现在已经取消扫荡时间
	-- 判断扫荡冷却时间
	-- if db.cdTime == nil then db.cdTime = 0 end
	-- if db.cdTime + ChapterDefine.WIPE_CD > os.time() and not Chapter.debugFlag then 
 --    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_CDTIME)
 --    	return
	-- end


	-- 判断通过次数
	if not Chapter.debugFlag then
		if lConfig.limitPerDay > 0 and Chapter.getTimesPerDay(human,levelId,difficulty) + cnt > lConfig.limitPerDay then
	    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_TIMES)
	    	return
		end
	end

	-- 判断历练券数量
	local ticketCnt = BagLogic.getItemNum(human,ChapterDefine.WIPE_TICKET_ITEMID)
	if ticketCnt >= cnt then
		-- 减去历练券
		BagLogic.delItemByItemId(human,ChapterDefine.WIPE_TICKET_ITEMID,cnt,true,CommonDefine.ITEM_TYPE.DEC_CHAPTER_WIPE)
	elseif human:getRmb() >= cnt then
		-- 扣除钻石替代历练券
		human:decRmb(cnt,nil,CommonDefine.RMB_TYPE.DEC_CHAPTER_WIPE)
	else
    	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_RMB)
    	return
	end



	-- 可以开始扫荡
	-- 减去体力
	-- human:decPhysics(lConfig.energy*cnt)


	-- 减去通过次数
	-- Chapter.setTimesPerDay(human,levelId,difficulty,cnt)

	local reward = Chapter.levelPassLogic(human,levelId,difficulty,true,1,cnt)
	
	-- 计算奖励
	local rewardList = {}
	for i,rtb in ipairs(reward) do

		local re = {}
		for n,r in pairs(rtb) do 
			table.insert(re,{rewardName=n,cnt=r})
		end
		local charLv,percent = PublicLogic.doReward(human,rtb,nil,CommonDefine.ITEM_TYPE.ADD_CHAPTER_WIPE)
		table.insert(rewardList,{reward=re,charLv=charLv,charLvPercent=percent})
	end

	-- for n,r in pairs(rtb) do 
	-- 	table.insert(rewardList,{rewardName=tostring(n),cnt=r})
	-- end
	

	-- if not Chapter.debugFlag then
	-- 	db.cdTime = os.time()
	-- end
	local level
	if Chapter.debugFlag and not levelList[levelId][difficulty] then
		level = {levelId=levelId,time=0,timesForDay=0,difficulty=difficulty}
	else
		level = Chapter.getDB(human,levelId,difficulty)
	end
	local temp = levelId * 10 + difficulty
	HumanManager:dispatchEvent(HumanManager.Event_Chapter,{human=human,objId=temp,objNum=cnt})
	-- Chapter.sendChapterList(human)
	human:sendHumanInfo()
	Msg.SendMsg(PacketID.GC_CHAPTER_FB_WIPE,human,levelId,difficulty,ChapterDefine.RET_CHAPTER_OK,level,rewardList)
	local logTb = Log.getLogTb(LogId.CHAPTER_WIPE)
			logTb.account = human:getAccount()
			logTb.channelId = human:getChannelId()
			logTb.name = human:getName()
			logTb.pAccount = human:getPAccount()
			logTb.levelName = lConfig.levelTitle
			logTb.levelId = levelId*10+difficulty
			logTb.difficulty = difficulty
			logTb.cnt = cnt
			logTb.physics = lConfig.energy*cnt
			logTb:save()
end


function onCGChapterBoxReward(human,chapterId,difficulty,boxId)
	local db = human.db.Chapter
	if ChapterConfig[chapterId] == nil or ChapterConfig[chapterId][difficulty] == nil or boxId > 3 or boxId < 1 then 
		Msg.SendMsg(PacketID.GC_CHAPTER_BOX_REWARD,human,ChapterDefine.RET_CHAPTER_NOTPERMITTED)
		return
	end
	local cConfig = ChapterConfig[chapterId]
	local star = Chapter.getStar(human,chapter,difficulty)
	if star < cConfig[difficulty]['boxStar'..boxId] then
		Msg.SendMsg(PacketID.GC_CHAPTER_BOX_REWARD,human,ChapterDefine.RET_CHAPTER_STAR)
		return
	end
	if Chapter.boxReward(human,chapterId,difficulty,boxId) == true or Chapter.debugFlag then
		
		local reward = cConfig[difficulty]['boxReward'..boxId]
		PublicLogic.doReward(human,reward,nil,CommonDefine.ITEM_TYPE.ADD_CHAPTER_BOX)
		BagLogic.sendRewardTipsEx(human,reward)
		Msg.SendMsg(PacketID.GC_CHAPTER_BOX_REWARD,human,ChapterDefine.RET_CHAPTER_OK,chapterId,difficulty,boxId)
	else
		Msg.SendMsg(PacketID.GC_CHAPTER_BOX_REWARD,human,ChapterDefine.RET_CHAPTER_RECEIVED)
	end
end

function onCGChapterRank(human)
	local rank = Chapter.RankList
	Msg.SendMsg(PacketID.GC_CHAPTER_RANK,human,rank)
end

function onCGChapterDebugflag(human)
end

-- function onCGChapterClearcd(human,levelId,difficulty)
-- 	local db = human.db.Chapter
-- 	if human:getRmb() < ChapterDefine.WIPE_CD_RMB then
-- 		Msg.SendMsg(PacketID.GC_CHAPTER_CLEARCD,human,ChapterDefine.RET_CHAPTER_RMB,levelId,difficulty)
-- 		return
-- 	end
-- 	human:decRmb(ChapterDefine.WIPE_CD_RMB)
-- 	human.db.Chapter.cdTime = 0
-- 	Msg.SendMsg(PacketID.GC_CHAPTER_CLEARCD,human,ChapterDefine.RET_CHAPTER_OK,levelId,difficulty)
-- end
