module(...,package.seeall)

local Msg = require("core.net.Msg")
local BagLogic = require("modules.bag.BagLogic")
local ItemConfig = require("config.ItemConfig").Config
local CommonDefine = require("core.base.CommonDefine")

local Define = require("modules.orochi.OrochiDefine")
local Logic = require("modules.orochi.OrochiLogic")
local OrochiRank = require("modules.orochi.OrochiRank")
local OrochiConfig = require("config.OrochiConfig").Config

local VipDefine = require("modules.vip.VipDefine")
local VipLogic = require("modules.vip.VipLogic")

--查询
function onCGOrochiQuery(human)
	Logic.resetByDay(human)
	Logic.sendLevelList(human)
end

--发起挑战
function onCGOrochiFight(human, levelId,fightList)
	local ret = CommonDefine.OK 
	local conf = OrochiConfig[levelId]
	if not conf then
		return Msg.SendMsg(PacketID.GC_OROCHI_FIGHT, human, Define.ERR_CODE.INVALID_LEVEL , levelId)
	end
	--挑战次数
	--if human.db.orochi:getCounter() >= (Define.MAX_COUNTER + VipLogic.getVipAddCount(human, VipDefine.VIP_OROCHI)) then
	--	ret = Define.ERR_CODE.MAX_COUNTER
	--end
	--[[
	--关卡次数
	if human.db.orochi:getLevelCounter(levelId) >= Define.MAX_LEVEL_COUNTER then
		ret = Define.ERR_CODE.MAX_LEVEL_COUNTER
	end
	--]]
	if conf.isOpen ~= 1 then
		ret = Define.ERR_CODE.INVALID_LEVEL
		return Msg.SendMsg(PacketID.GC_OROCHI_FIGHT, human, ret , levelId)
	end
	--关卡等级
	if conf.openLv > human:getLv() then
		ret = Define.ERR_CODE.NOT_OPEN_LV
		return Msg.SendMsg(PacketID.GC_OROCHI_FIGHT, human, ret , levelId)
	end
	--前置关卡
	if conf.preLevelId ~= 0 and not human.db.orochi:getLevel(conf.preLevelId) then
		ret = Define.ERR_CODE.NOT_PRE_LEVEL
		return Msg.SendMsg(PacketID.GC_OROCHI_FIGHT, human, ret , levelId)
	end
	local levelInfo = human.db.orochi:getLevel(levelId)
	if levelInfo and levelInfo.status == Define.STATUS.HAD_PASS then
		ret = Define.ERR_CODE.HAD_PASS
		return Msg.SendMsg(PacketID.GC_OROCHI_FIGHT, human, ret , levelId)
	end
	if ret == CommonDefine.OK then
		Logic.fight(human,levelId,fightList)
		--
		local logTb = Log.getLogTb(LogId.OROCHI_START)
		logTb.channelId = human:getChannelId()
		logTb.account = human:getAccount()
		logTb.name = human:getName()
		logTb.pAccount = human:getPAccount()
		logTb.levelId = levelId 
		logTb.leftCnt = 1
		logTb:save()
	end
	return Msg.SendMsg(PacketID.GC_OROCHI_FIGHT, human, ret , levelId)
end

--挑战结束
function onCGOrochiFightEnd(human, res ,levelId,killCnt)
	local conf = OrochiConfig[levelId]
	local ret = CommonDefine.OK
	if not conf then
		ret = Define.ERR_CODE.INVALID_LEVEL
	end
	local ret = Logic.fightEnd(human,res,levelId)
	local entryTime = 0
	local reward = {}
	local isChief = 0
	if ret == CommonDefine.OK and res == Define.FIGHT_SUCCESS then
		local levelInfo = human.db.orochi:getLevel(levelId)
		entryTime = levelInfo.entryTime
		reward = Logic.sendReward(human,levelId)
		--更新排行榜
		--[[
		local isUp = OrochiRank.updateRank(levelInfo,human)
		if isUp then
			isChief = 1
			--
			local logTb = Log.getLogTb(LogId.OROCHI_RANK)
			logTb.account = human:getAccount()
			logTb.name = human:getName()
			logTb.pAccount = human:getPAccount()
			logTb.levelId = levelId 
			logTb.costTime = entryTime
			logTb:save()
		end
		--]]
		--
		human:sendHumanInfo()
		Logic.sendLevelList(human,true)
		HumanManager:dispatchEvent(HumanManager.Event_Orochi,{human=human,objId=levelId,oType="fightWin"})
		HumanManager:dispatchEvent(HumanManager.Event_OrochiID,{human=human,objId = levelId})
	end
	--
	local logTb = Log.getLogTb(LogId.OROCHI_END)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.res = res 
	logTb.levelId = levelId 
	logTb.costTime = entryTime
	logTb.leftCnt = 1
	if res == Define.FIGHT_SUCCESS then
		logTb.leftCnt = 0
	end
	logTb.item = ""
	logTb:save()
	return Msg.SendMsg(PacketID.GC_OROCHI_FIGHT_END, human, ret , res , levelId , entryTime,reward,isChief)
end

--霸主榜单
function onCGOrochiRankQuery(human)
	local list = OrochiRank.RankList
	local msg = {}
	--Util.print_r(list)
	for _,v in pairs(list) do
		msg[#msg+1] = v
	end
	return Msg.SendMsg(PacketID.GC_OROCHI_RANK_QUERY, human, msg)
end

--function onCGOrochiChangeHero(human)
--end

function onCGOrochiCheck(human)
	local isReset = Logic.resetByDay(human)
	if isReset then
		Logic.sendLevelList(human)
	end
end


function onCGOrochiReset(human)
	local db = human.db.orochi
	local counter = db:getResetCounter()
	if counter < Define.MAX_RESET_COUNTER then
		Logic.resetLevel(human)
		Logic.sendLevelList(human)
	end
	return Msg.SendMsg(PacketID.GC_OROCHI_RESET, human, counter)
end

--扫荡
function onCGOrochiWipe(human)
	local db = human.db.orochi
	local levelList = {}
	local preLevelId = tonumber(db.curDayLevelId)
	repeat
		local preLevel = db:getLevel(preLevelId) 
		if preLevel and preLevel.status == Define.STATUS.HAD_PASS then
			break
		end
		levelList[#levelList+1] = preLevelId
		assert(OrochiConfig[preLevelId],"lost conf===>" .. preLevelId)
		preLevelId = OrochiConfig[preLevelId].preLevelId
	until preLevelId == 0 
	local rewardList = {}
	for _,levelId in ipairs(levelList) do
		print("wipe====>",levelId)
		local level = db.lastLevelList[levelId]
		Logic.fight(human,levelId,level.fightList)
		Logic.fightEnd(human,Define.FIGHT_SUCCESS,levelId,true)
		local reward,charLv,charLvPercent = Logic.sendReward(human,levelId)
		rewardList[#rewardList+1] = {
			reward=reward,
			charLv = charLv,
			charLvPercent = charLvPercent,
		}
	end
	Logic.sendLevelList(human,true)
	human:sendHumanInfo()
	return Msg.SendMsg(PacketID.GC_OROCHI_WIPE, human, levelList,rewardList)
end











