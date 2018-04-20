module(...,package.seeall)

function new()
	local db = {
		unfinishList = {},			--未完成列表
		commitList = {},			--可提交列表
		finishList = {},			--完成列表
	}
	setmetatable(db,{__index = _M})

	--数字做key,需要主动设置
	DB.dbSetMetatable(db.unfinishList)
	DB.dbSetMetatable(db.commitList)
	DB.dbSetMetatable(db.finishList)

	return db 
end

function resetMetatable(human)
	local db = human:getAchieve()
	--setmetatable(db, {__index = _M})

	--数字做key,需要主动设置
	DB.dbSetMetatable(db.unfinishList)
	DB.dbSetMetatable(db.commitList)
	DB.dbSetMetatable(db.finishList)
end

function addFinish(self, id)
	self.finishList[id] = 1
end

function isFinish(self, id)
	return (self.finishList[id] ~= nil)
end

function addUnfinish(self, id, tab)
	self.unfinishList[id] = tab
end

function getUnfinish(self, id)
	return self.unfinishList[id]
end

function delUnfinish(self, id)
	self.unfinishList[id] = nil
end

function addCommit(self, id)
	self.commitList[id] = 1
end

function isCommit(self, id)
	return self.commitList[id] ~= nil
end

function delCommit(self, id)
	self.commitList[id] = nil
end