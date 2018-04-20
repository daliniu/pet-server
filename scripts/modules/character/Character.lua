module(...,package.seeall)
local PacketID = require("PacketID")
local CharacterDefine = require("modules.character.CharacterDefine")
local Msg = require("core.net.Msg")
local Util = require("core.utils.Util")
local CommonDefine = require("core.base.CommonDefine")

function sendGCAskLogin(humanOrFD,result,isNew)
	if result ~= CommonDefine.OK then
		assert(type(humanOrFD) == "number","#1 argument must be fd number when result is not ASK_LOGIN_OK")
		Msg.SendMsgByFD(PacketID.GC_ASK_LOGIN,humanOrFD,result)
	else
		assert(type(humanOrFD) == "table","#1 argument must be human object when result is ASK_LOGIN_OK")
	    Msg.SendMsg(PacketID.GC_ASK_LOGIN,humanOrFD,result,humanOrFD:getAccount(),humanOrFD:getName(),humanOrFD:getSvrName(),humanOrFD:getToken(),isNew,Config.MSVRIP,Config.MSVRPORT)
	end
	print("send GCAskLogin result="..result)
end

function sendGCDisconnect(humanOrFD,ret)
	print("sendGCDisconnect==>",ret)
	if type(humanOrFD) == "number" then 
		Msg.SendMsgByFD(PacketID.GC_DISCONNECT,humanOrFD)
	else
		Msg.SendMsg(PacketID.GC_DISCONNECT,humanOrFD)
	end
end




