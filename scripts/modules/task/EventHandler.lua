module(...,package.seeall)

local Msg = require("core.net.Msg")

local Define = require("modules.task.TaskDefine")
local Logic = require("modules.task.TaskLogic")

function onCGTaskList(human)
	Logic.sendTaskList(human)
	return true
end

function onCGTaskGet(human, taskId)
	local ret = Logic.getTaskReward(human,taskId)
	return Msg.SendMsg(PacketID.GC_TASK_GET, human, ret , taskId)
end

function onCGTaskCheck(human)
	Logic.checkTask(human)
	return true
end

function onCGTaskJoin(human,taskId)
	print ("onCGTaskJoin")
	Logic.joinTask(human,taskId)
	Logic.sendTaskList(human)
	return Msg.SendMsg(PacketID.GC_TASK_JOIN, human, 1,taskId)
end


