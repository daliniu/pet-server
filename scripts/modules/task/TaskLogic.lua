module(...,package.seeall)


local Msg = require("core.net.Msg")
local HeroDefine = require("modules.hero.HeroDefine")
local HeroManager = require("modules.hero.HeroManager")
local PublicLogic = require("modules.public.PublicLogic")
local HM  = require("core.managers.HumanManager")

local DB = require("modules.task.TaskDB")
local Define = require("modules.task.TaskDefine")
local Logic = require("modules.task.TaskLogic")
local Config = require("config.TaskConfig").Config
local BagDefine = require("modules.bag.BagDefine")
local BagLogic = require("modules.bag.BagLogic")
local VipLogic = require("modules.vip.VipLogic")
local VipDefine = require("modules.vip.VipDefine")
local OpenLogic = require("modules.newopen.NewOpenLogic")

--
--
--
--

TaskCallbackFun = {
	[Define.TASK_CHAPTER_DIFFICUTY] = "chapter",	
}

TaskGetFun = {
	[Define.TASK_PHYSICS] = "getPhysics",	
	[Define.TASK_VIP] = "getVIP",	
}

function onDBLoad(hm,human)
	DB.setMeta(human)
	findCanDoTask(human)
end

local taskCb = function(taskType,human,objId,objNum,event)
	print("taskCallback===========",taskType,objId,objNum)
	local fun = _M[TaskCallbackFun[taskType]]
	if fun then
		fun(taskType,human,objId,objNum,event)
	else
		objId = objId or 0
		objNum = objNum or 1
		oType = oType or ""
		callback(human,taskType,objId,objNum,event.oType)
	end
end
function addTaskListener()
	local event2TaskType = {
		HM.Event_HumanLvUp,
		HM.Event_HeroCollect,
		HM.Event_EquipOpen,
		HM.Event_EquipLvUp,
		HM.Event_Chapter,
		HM.Event_Orochi,
		HM.Event_Trial,
		HM.Event_Expedition,
		HM.Event_Arena,
		HM.Event_Strength,
		HM.Event_WeaponLvUp,
		HM.Event_SkillLvUp,
		HM.Event_HeroLvUp,
		HM.Event_MonsterDie,
		HM.Event_WorldBoss,
		HM.Event_Treasure,
		HM.Event_Physics,
		HM.Event_Shop,
		HM.Event_Chapter,
		"",		--
		HM.Event_SendFlower,
		HM.Event_Train,
		HM.Event_GetFlower,
		HM.Event_WeaponQualityUp,
		HM.Event_OrochiID,
		HM.Event_TrialID,
		HM.Event_HeroBreak,
		HM.Event_HeroStar,
		HM.Event_SkillOpen,
		HM.Event_TrainUp,
		HM.Event_Spa,
		HM.Event_UpEquip,
		HM.Event_Crazy,
		HM.Event_TopArena,

	}
	for taskType,eventType in ipairs(event2TaskType) do
		if eventType:len() > 0 then
			HM:addEventListener(eventType, function(hm,event) 
				taskCb(taskType,event.human,event.objId,event.objNum,event) 
			end)
		end
	end
end

function checkTask(human)
	local isDirty = findCanDoTask(human)
	if isDirty then
		sendTaskList(human)
	end
end

function onHumanLogin(hm,human)
	sendTaskList(human)
end

function findCanDoTask(human)
	local db = human.db.task
	local needRefresh = false
	local isDirty = false
    local now = os.time()
    local odds = math.random(0,9999)
	if os.date("%d",db.refreshTime) ~= os.date("%d") then
		needRefresh = true
		db.refreshTime = os.time()
		cleanOddsTask(human)
	end

	for taskId,v in pairs(Config) do
		if needRefresh and v.times >= 1 then
			--print("findCanDoTask===>nil:",taskId)
			db.taskList[taskId] = nil
		end
		local isAdd = false
		if not db.taskList[taskId] then
			if v.preTask == 0 and v.openLv <= human:getLv() and v.closeLv >= human:getLv() then 
				if v.taskWay ~= 3 then 
					--print("findCanDoTask===>taskId:",taskId)
					local task = addCanDoTask(human,taskId)
					if Define.TASK_TYPE_CONF[v.taskType].autoFinish then
						task.status = Define.Status.Finish
					end
				else
					local stime,stimeTable = Util.getTimeByString(v.startTime)
					local etime,etimeTable = Util.getTimeByString(v.endTime)
					--print("TimeCanDoTask===>taskId:",taskId,stime,etime,now,odds,v.odds,hasOddsTask(human))
					if stime <= now and etime >= now then 
						if v.odds == 0 then 
							local task = addCanDoTask(human,taskId)
							task.status = Define.Status.CanJoin
						elseif odds < v.odds and hasOddsTask(human) then  
							--print("OddsCanDoTask===>taskId:",taskId)
							local task = addCanDoTask(human,taskId)
						else
							odds = odds - v.odds
						end 
					end
				end
				isDirty = true
			end 
		end 
	end
	DB.setMeta(human)
	return isDirty
end

function sendTaskList(human,updateTaskList)
	local now = os.time()
	local list = {}
	local isUpdate = false
	if updateTaskList then
		isUpdate = true
		list = updateTaskList
	else
		local db = human.db.task
		list = db.taskList
	end
	local sendList = {}
	for taskId,v in pairs(list) do
		if v.time == nil then 
			v.time = 0
		end 
		print("==========taskId",v.taskId)

		local conf = Config[tonumber(v.taskId)]
		if v.status == Define.Status.CanDo and v.time > 0 then 
			local int = os.difftime(now,v.time);
			if int > conf.taskSecond then 
				v.status = Define.Status.Failure
			end 
		end
		if v.status == Define.Status.CanDo or (v.status == Define.Status.Finish and not v.isGet) or v.status == Define.Status.CanJoin or v.status == Define.Status.Failure then
			makeTaskMsg(v,sendList)	
		end
	end
	isUpdate = isUpdate and 1 or 0
	Msg.SendMsg(PacketID.GC_TASK_LIST, human, sendList,isUpdate)
end
 
function makeTaskMsg(task,list)
	list[#list + 1] = {
		taskId = task.taskId,
		status = task.status,
		objNum = task.objNum,
		time = task.time,
	}
end

function getTaskById(human,taskId)
	local db = human.db.task
	return db.taskList[taskId]
end

function cleanOddsTask( human )
	local db = human.db.task
	for taskId,v in pairs(db.taskList) do
		local conf = Config[tonumber(taskId)]
		if conf.odds > 0 then
			db.taskList[taskId] = nil
		end
	end
end

function hasOddsTask(human)
	local db = human.db.task
	for taskId,v in pairs(db.taskList) do
		local conf = Config[tonumber(taskId)]
		if conf.odds > 0 then
			return false
		end
	end
	return true
end

function getTaskListByType(human,taskType)
	local db = human.db.task
	local list = {}
	for taskId,v in pairs(db.taskList) do
		if v.status == taskType then
			list[taskId] = v
		end
	end
	return list
end

function callback(human,taskType,objId,objNum,oType)
	objNum = objNum or 1
	local db = human.db.task
	local taskList = db.taskList
	local isDirty = false
	local updateTaskList = {}
	for taskId,task in pairs(taskList) do
		if checkIsFinish(human,task,taskType,objId,objNum,oType,updateTaskList) then
			isDirty = true
		end
	end
	if isDirty then
		sendTaskList(human,updateTaskList)
	end
	return isDirty
end

function checkIsFinish(human,task,taskType,objId,objNum,oType,updateTaskList)
	local taskId = tonumber(task.taskId)
	local conf = Config[taskId]
	local now = os.time()
	if not conf then
		return false
	end
	local day = OpenLogic.getCurOpenDay()

	if conf.taskDay >0 and day >7 then
		return false
	end

	if conf.taskWay == 3 and conf.odds == 0 then 
		local int = os.difftime(now,task.time);
		if int >= conf.taskSecond then 
			return false
		end 
	end

	local taskTypeConf = Define.TASK_TYPE_CONF[taskType]
	if taskTypeConf.anyId then
		objId = conf.objId
	end
	if conf.taskType == taskType and task.status == Define.Status.CanDo and conf.objId == objId then
		if not taskTypeConf.needWin or oType == "fightWin" then
			if taskTypeConf.needAdd then
				task.objNum = task.objNum + objNum
			else
				task.objNum = objNum
			end
			if (conf.objNum <= task.objNum) then
				--finish
				task.status = Define.Status.Finish
				task.objNum = conf.objNum
				--
				local logTb = Log.getLogTb(LogId.FINISH_TASK)
				logTb.account = human:getAccount()
				logTb.name = human:getName()
				logTb.pAccount = human:getPAccount()
				logTb.level = human:getLv()
				logTb.taskLevel = conf.openLv
				logTb.taskId = conf.taskId
				logTb:save()
				--
				local nextTask = addNextTask(human,taskId)
				if nextTask then
					checkIsFinish(human,nextTask,taskTypeConf,objId,objNum,oType)
				end
			end
			updateTaskList[#updateTaskList+1] = task
			return true
		end
	end
	return false
end

function addNextTask(human,preTaskId)
	for taskId,v in pairs(Config) do
		if v.preTask == preTaskId then
			return addCanDoTask(human,taskId)
		end
	end
end

function addCanDoTask(human,taskId)
	local db = human.db.task
	local task = {
		taskId = taskId,
		status = Define.Status.CanDo, 
		objNum = 0,
		isGet = false,
		counter = 0,
		time = 0,
	}
	db.taskList[taskId] = task
	return task
end

function getTaskReward(human,taskId) 
	local ret = Define.ERR_CODE.GetSuccess
	local task = getTaskById(human,taskId) 
	local conf = Config[taskId]
	local fun = _M[TaskGetFun[conf.taskType]]
	if fun then
		ret = fun(human,task,conf)
	else
		if task.status == Define.Status.Finish and not isGetReward(human,taskId) then
			sendTaskReward(human,taskId)
		else
			ret = Define.ERR_CODE.GetFail
		end
	end
	if ret == Define.ERR_CODE.GetSuccess then
		Msg.SendMsg(PacketID.GC_TASK_DEL, human, taskId)
		--
		local logTb = Log.getLogTb(LogId.GET_TASK)
		logTb.account = human:getAccount()
		logTb.name = human:getName()
		logTb.pAccount = human:getPAccount()
		logTb.level = human:getLv()
		logTb.taskLevel = conf.openLv 
		logTb.taskId = taskId
		logTb:save()
	end
	return ret
end

function joinTask(human,taskId)
	local task = getTaskById(human,taskId) 
	local now = os.time()
	task.status = Define.Status.CanDo
	task.time = now
	return true
end

function sendTaskReward(human,taskId)
	local conf = Config[taskId]
	local randReward = conf.reward 
	local reward = PublicLogic.randReward(randReward)
	PublicLogic.doReward(human,reward,{},CommonDefine.ITEM_TYPE.ADD_TASK)
	human:sendHumanInfo()
	local task = getTaskById(human,taskId) 
	task.isGet = true
	BagLogic.sendRewardTipsEx(human,reward)
end

function isGetReward(human,taskId)
	local task = getTaskById(human,taskId) 
	return task.isGet
end

--[[
-- Task fun===============
--]]

--callback
function chapter(taskType,human,objId,objNum)
	local difficulty = objId % 10
	return callback(human,taskType,difficulty,objNum)
end

--getReward
function getPhysics(human,task,conf)
	if not isGetReward(human,task.taskId) then
		local nowTb = os.date("*t")
		if nowTb.hour >= conf.param.startH and nowTb.hour < conf.param.endH then
			sendTaskReward(human,task.taskId)
			return Define.ERR_CODE.GetSuccess
		end
	end
	return Define.ERR_CODE.GetFail
end

function getVIP(human,task,conf)
	if not isGetReward(human,task.taskId) then
		local cnt = VipLogic.getVipAddCount(human,VipDefine.VIP_CLEAR_TICKET)
		local reward = {[conf.param.itemId]=cnt}
		PublicLogic.doReward(human,reward,{},CommonDefine.ITEM_TYPE.ADD_TASK)
		BagLogic.sendRewardTipsEx(human,reward)
		human:sendHumanInfo()
		task.isGet = true
		return Define.ERR_CODE.GetSuccess
	end
	return Define.ERR_CODE.GetFail
end






