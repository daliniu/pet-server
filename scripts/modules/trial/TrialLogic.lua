module(...,package.seeall)

local CommonDefine = require("core.base.CommonDefine")
local Msg = require("core.net.Msg")
local BaseMath = require("modules.public.BaseMath")
local PublicLogic = require("modules.public.PublicLogic")

local Define = require("modules.trial.TrialDefine")
local Config = require("config.TrialConfig").Config
local WineLogic = require("modules.guild.wine.WineLogic")

function onHumanLogin(hm,human)
	if resetByDay(human) then
		--断线重登时需要推送
		Msg.SendMsg(PacketID.GC_TRIAL_RESET, human, CommonDefine.OK)
	end
	sendLevelList(human)
end

--每天重置
function resetByDay(human,force)
	local db = human.db.trial 
	local today = os.date("%d")
	if force or db.resetDate ~= today then
		db:resetLevel()
		db.resetTimes = 0
		db.resetDate = today
		return true
	end
	return false
end


function sendLevelList(human,targetId)
	local db = human.db.trial 
	local list = {}
	for levelId,v  in pairs(db.levelList) do
		if not targetId or targetId == levelId then
			list[#list+1] = {
				levelId = levelId,
				status = v.status,
				fightList = v.fightList,
			}
		end
	end
	local tlist = {}
	for type,counter in pairs(db.typeCounter) do
		tlist[#tlist+1] = {
			type = type,
			counter = counter,
		}
	end
	Msg.SendMsg(PacketID.GC_TRIAL_QUERY, human, list,tlist)
end

function fight(human,levelId,fightList)
	local db = human.db.trial 
	db:startLevel(levelId,fightList)
end

function sendReward(human,levelId)
	local conf = Config[levelId]
	local rewardMsg = {}
	for _,rd in ipairs(conf.reward) do
		local reward = PublicLogic.randReward(rd)
		reward = WineLogic.wineBuffDeal(human,reward,"trial")
		for name,cnt in pairs(reward) do
			rewardMsg[#rewardMsg + 1] = {rewardName=name,cnt=cnt}
		end
		PublicLogic.doReward(human,reward,{},CommonDefine.ITEM_TYPE.ADD_TRIAL)
	end
	return rewardMsg
end

--杀死过的怪获得分值
function getTotalScore(human)
	local db = human.db.trial 
	local total = 0
	for levelId,v in pairs(db.levelList) do
		local conf = Config[tonumber(levelId)]
		assert(conf,"lost conf=====>",levelId)
		for i=1,v.killCnt do
			local score = conf.score[i]
			if score then
				total = total + score
			end
		end
	end
	return total
end

function setTopScore(human,score)
	local db = human.db.trial 
	db.topScore = score
end

function getTopScore(human)
	local db = human.db.trial 
	return db.topScore or 0
end

function addTrialTime(human,levelType)
	local db = human.db.trial 
	db.typeCounter[levelType] = db.typeCounter[levelType] or 0
	db.typeCounter[levelType] = db.typeCounter[levelType] - 1
	sendLevelList(human)
end




