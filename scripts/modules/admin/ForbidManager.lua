module(..., package.seeall)

local ns = "adminforbid"
local ChatDefine = require("modules.chat.ChatDefine")

local query={}

ForbidList = ForbidList or { ipList = {}, 
                             chatList = {}, 
                             accountList = {},
                             --nameList = {},
                           }

--检查是否过期
function delExpire()
	local curTime = os.time()
	local ipList = ForbidList.ipList
	local chatList = ForbidList.chatList
	local accountList = ForbidList.accountList
	for k,v in pairs(ipList) do
		if v <= curTime then
			--print("删除ip:", k)
			ipList[k] = nil
		end
	end
	for k,v in pairs(chatList) do
		if v <= curTime then
			--print("删除禁言:", k)
			chatList[k] = nil
		end
	end
	for k,v in pairs(accountList) do
		if v <= curTime then
			--print("删除账号:", k)
			accountList[k] = nil
		end
	end
end

--加载封禁列表
function init()
	local count = DB.Count(ns, {},true)
	local cursor = MongoDBCursor(pCursor)
	if count<=0 then
		DB.Insert(ns, ForbidList,true)
	end

	local pCursor = g_oMongoDB:SyncFind(ns,{})
	cursor = MongoDBCursor(pCursor)
	if not cursor:Next(ForbidList) then
		assert(nil, " Init ForbidList err")
		return false
	end

	delExpire()

	local saveTimer = Timer.new(ChatDefine.SAVE_FORBID_TIMER,-1)
	saveTimer:setRunner(save)
	saveTimer:start()

	return true
end

--存储封禁列表
function save(isSync)
	delExpire()
	query._id = ForbidList._id;
	DB.Update(ns,query,ForbidList,isSync)
end


function addIP(ip,uTime)
	local ipList = ForbidList.ipList
	ipList[ip] = uTime
end

function delIP(ip)
	local ipList = ForbidList.ipList
	if ipList[ip] then
		ipList[ip] = nil
	end
end

function getForbidIPTime(ip)
	local ipList = ForbidList.ipList
	return ipList[ip] or 0
end


function addAccount(account, uTime)
	local accountList = ForbidList.accountList
	accountList[account] = uTime
end

function delAccount(account)
	local accountList = ForbidList.accountList
	if accountList[account] then
		accountList[account] = nil
	end
end

function getForbidAccountTime(account)
	local accountList = ForbidList.accountList
	return accountList[account] or 0
end

function addChat(account, uTime)
	local chatList = ForbidList.chatList
	chatList[account] = uTime
end

function delChat(account)
	local chatList = ForbidList.chatList
	if chatList[account] then
		chatList[account] = nil
	end
end

function getForbidChatTime(account)
	local chatList = ForbidList.chatList
	return chatList[account] or 0
end

--禁角色
--[[
function addName(name, uTime)
	ForbidList.nameList[name] = uTime
end

function delName(name)
	local nameList = ForbidList.nameList
	if nameList[name] then
		nameList[name] = nil
	end
end

function getForbidNameTime(name)
	local nameList = ForbidList.nameList
	return nameList[name] or 0
end
--]]

function loginForbid(human)
	local curTime = os.time()
	--判断账号
	if curTime < getForbidAccountTime(human:getAccount()) then
		human:disconnect(CommonDefine.DISCONNECT_REASON_FORBID_ACCOUNT)
		return true
	end
	--判断角色
	--[[
	if curTime < getForbidNameTime(human:getName()) then
		human:disconnect(CommonDefine.DISCONNECT_REASON_FORBID_NAME)
		return true
	end
	--]]

	--判断IP
	local ip = _GetIP(human.id)
	if curTime < getForbidIPTime(ip) then
		human:disconnect(CommonDefine.DISCONNECT_REASON_FORBID_IP)
		return true
	end
	return false
end



