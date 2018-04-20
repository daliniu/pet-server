module(..., package.seeall)

local Logic = require("modules.admin.AdminLogic")
local Json = require("core.utils.Json")
local ChannelConfig = require("config.ChannelConfig").Config

--[[
UrlMap = {
    pay = Logic.pay,					 --充值
    onlineplayer = Logic.onlinePlayer,   --请求全服在线玩家信息
    playerByScene = Logic.playerByScene,  ---by tanjie 请求某场景中的玩家
    addForbidChat = Logic.addForbidChat,  --禁言
    delForbidChat = Logic.delForbidChat,
}
--]]
UrlInputMap = {
	uid="pAccount",
	role_id="account",
	rolename="name",
	role_name="name",
}
function parseInput(oJsonInput)
	for k,v in pairs(UrlInputMap) do
		if oJsonInput[k] and oJsonInput[k]:len() > 0 then
			oJsonInput[v] = oJsonInput[k]
		end
	end
	if oJsonInput.pAccount and oJsonInput.pAccount:len() > 0 and not oJsonInput.account then
		--平台账号转游戏账号
		local svrName = Config.SVRNAME 
		if oJsonInput.server_id then
			svrName = "[" .. oJsonInput.server_id .. "]"
		end
		local channel = ""
		if oJsonInput.platform and oJsonInput.platform:len() > 0 then
			for k,v in pairs(ChannelConfig) do
				if v.channelName == oJsonInput.platform then
					channel = "[" .. v.channelId .. "]"
					break
				end
			end
		end
		oJsonInput.account = svrName .. channel .. oJsonInput.pAccount
	end
end

function HandleHttpRequest(oJsonInput)
	if oJsonInput.q ~= "auth" and not Config.ISTESTCLIENT then
		--验证超时
		if not oJsonInput.ts or  (os.time() - oJsonInput.ts) > 300 then
			--_SendHttpResponse("{\"code\":-2,\"message\":\"timeout\"}")
			--return false
		end
	end
	local handler = Logic[oJsonInput.q]
	if handler then
		parseInput(oJsonInput)
		_SendHttpResponse(handler(oJsonInput))
	else
		_SendHttpResponse("500")
	end
end

--密钥验证
function checkMd5(oJsonInput)
	local tmp = {}
	for k,v in pairs(oJsonInput) do
		if k ~= "ticket" then
			tmp[#tmp+1] = k
		end
	end
	table.sort(tmp)
	local _flag = ""
	for _,v in ipairs(tmp) do
		--print("k:"..v..",v:"..oJsonInput[v])
		_flag = _flag .. oJsonInput[v]
	end
	_flag = _flag .. Config.ADMIN_KEY
	if _md5(_flag) ~= oJsonInput.ticket then
		return false
	end
	return true      
end

function HttpReqDispatch(input)
	print("HttpReqDispatch===========>",input)
	local kvTb = Util.parseUrl(input)
	if not kvTb then
		return false
	end
	--local oJsonInput = Json.Decode(input)
	local co = coroutine.create(HandleHttpRequest)
	local ret,msgOrTid = coroutine.resume(co, kvTb)
	if not ret then 
		local errMsg = "HttpReqDispatch error \n".. tostring(msgOrTid)
		errMsg = errMsg .. debug.traceback(co)
		LogErr("error",errMsg)
		print("--------------------------------------------")
		print(errMsg)
		print("--------------------------------------------")
	else
		if msgOrTid and type(msgOrTid) == "number" then
			DB.DBTManager[msgOrTid] = co
		end
	end
	return ret
end

_G["HttpReqDispatch"] = HttpReqDispatch
for k, v in pairs(Config.ADMIN_IP_LIST) do
	_RegisterAdminIp(v)
end



