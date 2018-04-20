module(...,package.seeall)
local Msg = require("core.net.Msg")
local TrainLogic = require("modules.train.TrainLogic")

function onCGTrainQuery(human,name)
	TrainLogic.query(human,name)
end

function onCGTrain(human,name,mtype,cnt)
	local ret,retCode = TrainLogic.train(human,name,mtype,cnt)
	Msg.SendMsg(PacketID.GC_TRAIN, human, name,retCode)
end

function onCGTrainAdd(human,name)
	local ret,retCode = TrainLogic.add(human,name)
	Msg.SendMsg(PacketID.GC_TRAIN_ADD, human, name,retCode)
end
