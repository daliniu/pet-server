module(...,package.seeall)

function new()
	local db = {
		taskList = {},	--{[taskId]={status=1,objId=1,objNum=对象数量,isGet=是否已领,counter=次数,time = 接受时间}}
		refreshTime = 0,
	}
	return db 
end

function setMeta(human)
	local db = human.db.task
	setmetatable(db, {__index = _M})
	DB.dbSetMetatable(db.taskList)
end





