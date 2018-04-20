module(..., package.seeall)

local DB = require("core.db.DB")
local Define = require("modules.orochi.OrochiDefine")

function new()
	local tab = {
		levelList = {},		--
		lastLevelList = {},
		curDayLevelId = 0,		--当天打的关卡
		counter = 0,		--挑战次数
		resetDate = 0,	--最近刷新挑战时间
		resetCounter = 0,
	}
	return tab
end

function setMeta(hm,human) 
	local db = human.db.orochi
	DB.dbSetMetatable(db.levelList)
	DB.dbSetMetatable(db.lastLevelList)
	setmetatable(db, {__index = _M})
end

function getLevel(self,levelId)
	return self.levelList[levelId]
end

--总挑战次数
function getCounter(self)
	return self.counter
end

--关卡次数
function getLevelCounter(self,levelId)
	local list = self.levelList[levelId]
	if not list then
		return 0
	end
	return list.counter
end

function updateLevel(self,levelId,entryTime)
	self.levelList[levelId] = self.levelList[levelId] or {}
	local list = self.levelList[levelId]
	--通关最好时间
	if not list.entryTime or list.entryTime > entryTime then
		list.entryTime = entryTime
	end
	list.status = Define.STATUS.HAD_PASS
	--通关次数
	list.counter = list.counter or 0
	list.counter = list.counter + 1
	--最近通关日期
	--list.lastDate = os.date("%d")
	--总次数
	self.counter = self.counter + 1
	--当天关卡
	if self.curDayLevelId < levelId then
		self.curDayLevelId = levelId
	end
end

function startLevel(self,levelId,fightList)
	self.levelList[levelId] = self.levelList[levelId] or {}
	self.levelList[levelId].levelId = levelId
	self.levelList[levelId].startTime = os.time()
	self.levelList[levelId].fightList = fightList 
end

function getEntryTime(self,levelId)
	return self.levelList[levelId].entryTime
end

function resetLevel(self)
	self.levelList = {}
	DB.dbSetMetatable(self.levelList)
end

function getResetCounter(self)
	return self.resetCounter
end

function incResetCounter(self)
	self.resetCounter = self.resetCounter + 1
end

function setLastLevelList(self)
	self.lastLevelList = Util.deepCopy(self.levelList)
	DB.dbSetMetatable(self.lastLevelList)
end





