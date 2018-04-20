module(..., package.seeall)

function new()
	local db = {
		score = 0,				--总积分(不消耗)
		coolTime = 0,			--冷却时间
		team = {},				--阵容
		resetCount = 1,			--重置次数
		fightRecordList = {},	--对战记录

		lastResetTime = 0,		--上一次刷新重置次数时间
		shopRefreshCnt = 1,
		nextUpdate = 0,			--下一次刷新时间
		itemlist = {},			--物品列表
	}

	setmetatable(db, {__index = _M})
	return db
end

function getTeam(self)
	return self.team
end

function setTeam(self, val)
	self.team = val 
end

function setCoolTime(self, val)
	self.coolTime = val
end

function getCoolTime(self)
	return self.coolTime
end

function setScore(self, val)
	self.score = val
end

function getScore(self)
	return self.score
end

function setResetCount(self, val)
	self.resetCount = val
end

function getResetCount(self)
	return self.resetCount
end
