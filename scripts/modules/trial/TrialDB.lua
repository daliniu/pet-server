module(..., package.seeall)

local DB = require("core.db.DB")
local Define = require("modules.trial.TrialDefine")
local Config = require("config.TrialConfig").Config

function new()
	local tab = {
		levelList = {},		--已通关
		typeCounter = {},	--分类型统计
		--counter = 0,		--挑战总次数
		topScore = 0,		--最高得分
		resetTimes = 0,		--重置次数
		resetDate = 0,	    --最近刷新日期
		--checkTime = 0,	    --最近检查刷新时间
	}
	return tab
end

function setMeta(hm,human) 
	local db = human.db.trial
	DB.dbSetMetatable(db.levelList)
	DB.dbSetMetatable(db.typeCounter)
	setmetatable(db, {__index = _M})
end

function getLevel(self,levelId)
	return self.levelList[levelId]
end

--关卡类型次数
function getLevelTypeCounter(self,levelType)
	return self.typeCounter[levelType] or 0
end

--总重置次数
function getResetTimes(self)
	return self.resetTimes
end

function startLevel(self,levelId,fightList)
	self.levelList[levelId] = self.levelList[levelId] or {}
	self.levelList[levelId].startTime = os.time()
	self.levelList[levelId].fightList = fightList 
end

function updateLevel(self, res, levelId,entryTime)
	local levelType = Config[levelId].type
	self.levelList[levelId] = self.levelList[levelId] or {}
	local list = self.levelList[levelId]
	--通关最好时间
	if not list.entryTime or list.entryTime > entryTime then
		list.entryTime = entryTime
	end
	--通关次数
	list.counter = list.counter or 0
	list.counter = list.counter + 1
	list.status = Define.STATUS.HAD_PASS
	self.typeCounter[levelType] = self.typeCounter[levelType] or 0
	self.typeCounter[levelType] = self.typeCounter[levelType] + 1
	--最近通关日期
	--list.lastDate = os.date("%d")
	--最大杀怪数
	--list.killCnt = list.killCnt or 0
	--总次数
	--self.counter = self.counter + 1
end

--通关时间
function getEntryTime(self,levelId)
	return self.levelList[levelId].entryTime
end

function resetLevel(self)
	self.levelList = {}
	self.typeCounter = {}
	DB.dbSetMetatable(self.levelList)
	DB.dbSetMetatable(self.typeCounter)
end

function incResetTimes(self)
	self.resetTimes = self.resetTimes + 1
end





