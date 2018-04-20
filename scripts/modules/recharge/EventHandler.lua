module(...,package.seeall)
local RechargeLogic = require("modules.recharge.RechargeLogic")
local Msg = require("core.net.Msg")
local RechargeConstConfig = require("config.RechargeConstConfig").Config

function onCGRechargeQuery(human)
	onCGRechargeTime(human)
	human.db.rechargeDB:nextAct(RechargeLogic.getGenId())
	RechargeLogic.query(human)
end

function onCGRechargeGet(human,id)
	local ret,retCode = RechargeLogic.get(human,id)
	Msg.SendMsg(PacketID.GC_RECHARGE_GET,human,retCode)
end

function onCGRechargeTime(human)
	local beginTime = RechargeLogic.beginTime()
	local endTime = RechargeLogic.endTime()
	local getEndTime = RechargeLogic.getEndTime()
	local isOpen = 0
	if os.time() < getEndTime and os.time() >= beginTime then
		isOpen = 1
	end
	Msg.SendMsg(PacketID.GC_RECHARGE_TIME,human,beginTime,endTime,getEndTime,isOpen)
end
