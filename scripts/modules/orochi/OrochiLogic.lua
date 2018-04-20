module(...,package.seeall)

local CommonDefine = require("core.base.CommonDefine")
local Msg = require("core.net.Msg")
local BaseMath = require("modules.public.BaseMath")
local PublicLogic = require("modules.public.PublicLogic")
local MailManager = require("modules.mail.MailManager")

local Define = require("modules.orochi.OrochiDefine")
local PowerConfig = require("config.PowerConfig").Config
local OrochiConfig = require("config.OrochiConfig").Config
local OrochiRank = require("modules.orochi.OrochiRank")
local WineLogic = require("modules.guild.wine.WineLogic")
local HumanManager = require("core.managers.HumanManager")

function onHumanLogin(hm,human)
	resetByDay(human)
	sendLevelList(human)
end

--每天重置
function resetByDay(human,force)
	local db = human.db.orochi
	local today = os.date("%d")
	if force or db.resetDate ~= today then
		db:resetLevel()
		db:setLastLevelList()
		db.curDayLevelId = 0
		db.counter = 0
		db.resetCounter = 0
		db.resetDate = today
		return true
	end
	return false
end

function sendLevelList(human,isUpdate)
	local orochi = human.db.orochi
	local list = {}
	for levelId,v  in pairs(orochi.levelList) do
		list[#list+1] = {
			levelId = levelId,
			status = v.status,
			fightList = v.fightList,
		}
	end
	isUpdate = isUpdate and 1 or 0
	Msg.SendMsg(PacketID.GC_OROCHI_QUERY, human, orochi:getResetCounter() ,list,isUpdate,orochi.curDayLevelId)
end

function fight(human,levelId,fightList)
	local db = human.db.orochi 
	db:startLevel(levelId,fightList)
end

function fightEnd(human,res,levelId,isWipe)
	local db = human.db.orochi 
	local levelInfo = db:getLevel(levelId)
	if not levelInfo then
		return Define.ERR_CODE.INVALID_LEVEL
	end
	levelInfo.res = res
	if res == Define.FIGHT_SUCCESS then
		local startTime = levelInfo.startTime 
		local entryTime = os.time() - startTime
		if entryTime <= 0 and not isWipe then
			return Define.ERR_CODE.INVALID_LEVEL
		end
		db:updateLevel(levelId,entryTime)
	end
	return CommonDefine.OK
end

function sendReward(human,levelId)
	local randReward = OrochiConfig[levelId].reward
	local reward = PublicLogic.randReward(randReward)
	reward = WineLogic.wineBuffDeal(human,reward,"orochi")
	local rewardMsg = {}
	for name,cnt in pairs(reward) do
		rewardMsg[#rewardMsg + 1] = {rewardName=name,cnt=cnt}
	end
	local charLv,percent = PublicLogic.doReward(human,reward,{},CommonDefine.ITEM_TYPE.ADD_OROCHI)
	return rewardMsg,charLv,percent
end

function sendRankReward()
	for _,v in  pairs(OrochiRank.RankList) do
		local conf = OrochiConfig[v.levelId]
		MailManager.sysSendMailById(v.account,Define.RANK_MAIL_ID,conf.chiefAward,v.name)
	end
end

function resetLevel(human)
	local db = human.db.orochi
	db:setLastLevelList()
	db:resetLevel()
	db:incResetCounter()
end





