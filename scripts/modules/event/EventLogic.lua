module(...,package.seeall)


local Msg = require("core.net.Msg")
local PublicLogic = require("modules.public.PublicLogic")
local HM = require("core.managers.HumanManager")

local Config = require("config.EventConfig").Config
local Define = require("modules.event.EventDefine")


--
--
--
--
--
function onDBLoad(hm,human)
	local list = human.db.event
	DB.dbSetMetatable(list)
end

function sendEvent(human,eventId)
	local conf = Config[eventId]
	local reward = PublicLogic.randReward(conf.reward)
	if next(reward) then
		Msg.SendMsg(PacketID.GC_EVENT_NOTICE, human, eventId)
		PublicLogic.doReward(human,reward)
		human:sendHumanInfo()
	end
end

function fbCallback(human,objId)
	local eventId = Define.EVENT_FB
	local list = human.db.event
	list[eventId] = list[eventId] or {}
	objId = tostring(objId)
	if not list[eventId][objId] then
		sendEvent(human,eventId)
		list[eventId][objId] = 1
	end
end

HM:addEventListener(HM.Event_HumanDBLoad, onDBLoad)


