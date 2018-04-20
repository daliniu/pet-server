module(...,package.seeall)

local Msg = require("core.net.Msg")
local BagLogic = require("modules.bag.BagLogic")
local ItemConfig = require("config.ItemConfig").Config
local CommonDefine = require("core.base.CommonDefine")
local PublicLogic = require("modules.public.PublicLogic")

local Define = require("modules.trial.TrialDefine")
local Logic = require("modules.trial.TrialLogic")
local Rank = require("modules.trial.TrialRank")
local Config = require("config.TrialConfig").Config

local VipDefine = require("modules.vip.VipDefine")
local VipLogic = require("modules.vip.VipLogic")

--查询
function onCGTrialQuery(human)
	Logic.resetByDay(human)
	Logic.sendLevelList(human)
end

--发起挑战
function onCGTrialFight(human, levelId,fightList)
	local ret = CommonDefine.OK 
	local conf = Config[levelId]
	local db = human.db.trial 
	if not conf then
		ret = Define.ERR_CODE.INVALID_LEVEL
	end
	if #fightList > 4 then
		return true
	end
	--[[
	local levelInfo = db:getLevel(levelId)
	if levelInfo and levelInfo.res == Define.FIGHT_SUCCESS then
		ret = Define.ERR_CODE.HAD_PASS
	end
	--]]
	--关卡类型次数
	local counter = db:getLevelTypeCounter(conf.type) 
	if counter >= Define.MAX_LEVEL_COUNTER then
		ret = Define.ERR_CODE.MAX_LEVEL_COUNTER
	end
	--关卡等级
	if conf.openLv > human:getLv() then
		ret = Define.ERR_CODE.NOT_OPEN_LV
	end
	--前置关卡
	if conf.preLevelId ~= 0 and not db:getLevel(conf.preLevelId) then
		ret = Define.ERR_CODE.NOT_PRE_LEVEL
	end
	if ret == CommonDefine.OK then
		Logic.fight(human,levelId,fightList)
		--
		local logTb = Log.getLogTb(LogId.TRIAL_START)
		logTb.channelId = human:getChannelId()
		logTb.account = human:getAccount()
		logTb.name = human:getName()
		logTb.pAccount = human:getPAccount()
		logTb.levelId = levelId 
		logTb.leftCnt = counter 
		logTb:save()
	end
	return Msg.SendMsg(PacketID.GC_TRIAL_FIGHT, human, ret , levelId)
end

--挑战结束
function onCGTrialFightEnd(human, res ,levelId)
	local conf = Config[levelId]
	local ret = CommonDefine.OK
	if not conf then
		ret = Define.ERR_CODE.INVALID_LEVEL
	end
	local db = human.db.trial 
	local levelInfo = db:getLevel(levelId) 
	if not levelInfo then
		ret = Define.ERR_CODE.INVALID_LEVEL
	end
	--关卡类型次数
	local counter = db:getLevelTypeCounter(conf.type) 
	if counter >= Define.MAX_LEVEL_COUNTER then
		ret = Define.ERR_CODE.MAX_LEVEL_COUNTER
	end
	local startTime = levelInfo.startTime 
	local entryTime = os.time() - startTime
	if entryTime <= 0 then
		ret = Define.ERR_CODE.INVALID_LEVEL
	end
	local reward = {}
	if ret == CommonDefine.OK and res == Define.FIGHT_SUCCESS then
		--更新DB
		db:updateLevel(res,levelId,entryTime)
		--[[
		--屏蔽排行榜
		local score = Logic.getTotalScore(human)
		--rank
		if human:getLv() >= Define.MIN_RANK_LV then
			local topScore = Logic.getTopScore(human)
			if score > topScore then
				Logic.setTopScore(human,score)
				local db = human.db.trial 
				Rank.updateRank(score,db:getLevel(levelId).fightList,human)
			end
		end
		--]]
		--奖励
		reward = Logic.sendReward(human,levelId)
		--refresh
		Logic.sendLevelList(human,levelId)
		--human info
		human:sendHumanInfo()
		HumanManager:dispatchEvent(HumanManager.Event_Trial,{human=human,objId=levelId,oType="fightWin"})
		HumanManager:dispatchEvent(HumanManager.Event_TrialID,{human=human,objId=levelId})
	end
	--
	local logTb = Log.getLogTb(LogId.TRIAL_END)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.res = res 
	logTb.levelId = levelId 
	logTb.leftCnt = db:getLevelTypeCounter(conf.type) 
	logTb.item = ""
	logTb:save()
	return Msg.SendMsg(PacketID.GC_TRIAL_FIGHT_END, human, ret , res , levelId , entryTime,reward)
end

--霸主榜单
function onCGTrialRankQuery(human)
	local list = Rank.RankList
	local msg = {}
	--Util.print_r(list)
	for _,v in pairs(list) do
		msg[#msg+1] = v
	end
	return Msg.SendMsg(PacketID.GC_TRIAL_RANK_QUERY, human, msg , Logic.getTopScore(human))
end

function onCGTrialReset(human)
	--[[
	--屏蔽
	local ret = CommonDefine.OK
	local db = human.db.trial
	local isReset = Logic.resetByDay(human)
	if db:getResetTimes() >= (Define.MAX_RESET_TIMES + VipLogic.getVipAddCount(human, VipDefine.VIP_TRIAL)) then
		ret = Define.ERR_CODE.MAX_RESET
	else
		db:incResetTimes()
		db:resetLevel()
	end
	Msg.SendMsg(PacketID.GC_TRIAL_RESET, human, ret)
	Logic.sendLevelList(human,not isReset)
	return true
	--]]
end

function onCGTrialCheck(human)
	local isReset = Logic.resetByDay(human)
	if isReset then
		Msg.SendMsg(PacketID.GC_TRIAL_RESET, human, CommonDefine.OK)
		Logic.sendLevelList(human)
	end
end




