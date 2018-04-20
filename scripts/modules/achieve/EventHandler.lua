module(...,package.seeall)

local Define = require("modules.achieve.AchieveDefine")
local Msg = require("core.net.Msg")
local Logic = require("modules.achieve.AchieveLogic")
local BagLogic = require("modules.bag.BagLogic")
local Config = require("config.AchieveConfig").Config

function onCGAchieveList(human)
	local db = human:getAchieve()
	if human:getLv() >= Define.ACHIEVE_OPEN_LV then
    	Msg.SendMsg(PacketID.GC_ACHIEVE_LIST, human, Logic.composeUnfinishList(human), Logic.composeCommitList(human), Logic.composeFinishList(human))
    	return
    end
end

function onCGAchieveGet(human, id)
	local db = human:getAchieve()
	if db:isFinish(id) == false and Logic.hasAchieveFinish(human, id) == true then
		local config = Config[id]
		local logTb = Log.getLogTb(LogId.ACHIEVE_GET)
		logTb.name = human:getName()
		logTb.account = human:getAccount()
		logTb.pAccount = human:getPAccount()
		logTb.achieveName = config.title
		logTb.achieveId = id
		logTb.lv = human:getLv()
		logTb:save()

		db:addFinish(id)
		db:delUnfinish(id)
		db:delCommit(id)
		local rewards,rtb = Logic.getRandRewardList(human, id)
		Msg.SendMsg(PacketID.GC_ACHIEVE_GET, human, Define.ERR_CODE.GetSuccess, id, rewards)
		human:sendHumanInfo()
		BagLogic.sendRewardTipsEx(human,rtb)
		return
	end
	Msg.SendMsg(PacketID.GC_ACHIEVE_GET, human, Define.ERR_CODE.GetFail, id, nil)
	return
end
