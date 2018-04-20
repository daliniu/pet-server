module("Network", package.seeall)

local PacketID = require("PacketID")
local ObjectManager = require("core.managers.ObjectManager")

local ProtoTemplate = {}
ProtoName = {}
ProtoHandler = {} --包含所有GC协议的handler

function protoName2PacketId(str)
	res = str:sub(1, 2) .. "_"
	for i = 3, #str do
		if str:byte(i, i) < 97 and 96 < str:byte(i - 1, i - 1) then
			res = res .. "_"
		end
		res = res .. str:sub(i, i):upper()
	end
	return res
end

local function RegisterProto(packetId, template, protoName, protoHandler)
	if not ProtoTemplate[packetId] then
        print("Register packetId:", packetId, protoName, protoHandler)
		ProtoTemplate[packetId] = template
		ProtoName[packetId] = protoName 
		ProtoHandler[packetId] = protoHandler
		ProtoTemplateToTree(packetId, template) --向c++层注册协议模版
	end
end

--注册模块协议（模版，处理回调）
function RegisterOneModuleProtos(moduleName)
	local EventHandler = require("modules."..moduleName .. ".EventHandler")
	local Protocol = require("modules."..moduleName .. ".Protocol")
	for protoName, template in pairs(Protocol) do
		local prefix = protoName:sub(1, 2)
		if prefix == "CG" or prefix == "GC" or prefix == "GG" then
			local pName= protoName2PacketId(protoName)
			local packetId = PacketID[pName]
			assert(packetId, pName .. " not exist")
			local handler = EventHandler["on" .. protoName]
			--必须处理CG，GG 协议
			assert(prefix == "GC" or handler, protoName .. " handler is nil !")
			RegisterProto(packetId, template, pName, handler)
		end
	end
end

function HandlerPacket(fd, packetId, sn, ...)
	local handler = ProtoHandler[packetId]    
	if handler then 
		if Config.ISMOBDEBUG then
			local mobdebug = require('mobdebug')
			mobdebug.off()
			mobdebug.on()
		end
		Util.tick_start()
		local ret
		if packetId == PacketID.CG_ASK_LOGIN or packetId == PacketID.CG_RE_LOGIN or packetId == PacketID.CG_LOGIN_AUTH or  packetId < 10000 then
			 ret = handler(fd, sn, ...)  
		else
			local human = ObjectManager.getByFD(fd)  
			if not human or human.typeId ~= ObjectManager.OBJ_TYPE_HUMAN then
				LogErr("error", "Packet:" .. packetId .. " has not human handler", fd)
				return false;
			end 
			ret = handler(human, ...)  
		end
		Util.tick_end_packet(packetId)
		return ret
	else
		LogErr("error", "Packet:" .. packetId .. " has not handler");
		return false;
	end
end

function MsgDispatch(fd, packetId, sn, ...)
	print("recv:" .. packetId .. "  " .. ProtoName[packetId])
	local handler = ProtoHandler[packetId]    
	if handler then 
		local co = coroutine.create(HandlerPacket)
		local ret,tid = coroutine.resume(co, fd, packetId, sn, ...)
		if not ret then 
			local errMsg = "coroutine fail \n" .. tostring(tid)
			errMsg = errMsg .. debug.traceback(co)
			LogErr("error",errMsg)
			print("--------------------------------------------")
			print(errMsg)
			print("--------------------------------------------")

			if Config.ISTESTCLIENT then
				local Msg = require("core.net.Msg")
				Msg.SendMsgByFD(PacketID.GC_ERROR, fd, errMsg)
			end
		end

		if tid and type(tid) == "number" then 
			DB.DBTManager[tid] = co
		end
		return true
	else
		LogErr("error", "Packet:" .. packetId .. "has not handler");
		return false
	end
end

function resetProtocol()
	ProtoTemplate = {}
	ProtoName = {}
	ProtoHandler = {} 
end


_G["MsgDispatch"] = MsgDispatch
if Config.ISSYNC then
	_G["MsgDispatch"] = HandlerPacket
end
