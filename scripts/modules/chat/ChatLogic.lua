module(...,package.seeall) 

local PacketID = require("PacketID")
local DB = require("core.db.DB")
local Msg = require("core.net.Msg")
local GuildManager = require("modules.guild.GuildManager")
local CommonDefine = require("core.base.CommonDefine")

local ChatDefine = require("modules.chat.ChatDefine")
local ChatBox = require("modules.chat.ChatBox")
local Protocol = require("modules.chat.Protocol")

local SensitiveFilter = require("modules.public.SensitiveFilter")

local ForbidManager = require("modules.admin.ForbidManager")
--
--
--
function dbLoad(hm,human)
	local chat = human.db.chat
	chat.refreshDate = chat.refreshDate or 0
	chat.chatTimes = chat.chatTimes or {}
	DB.dbSetMetatable(chat.chatTimes)
end


function getChatTimes(human,chatType)
	local chat = human.db.chat
	local today = os.date("%d")
	if chat.refreshDate ~= today then
		chat.chatTimes[chatType] = 0
		chat.refreshDate = today
	end
	return chat.chatTimes[chatType] or 0
end

function incChatTimes(human,chatType)
	local chat = human.db.chat
	chat.chatTimes[chatType] = chat.chatTimes[chatType] or 0
	chat.chatTimes[chatType] = chat.chatTimes[chatType] + 1
end

function canChat(human, chatType, content, targetAccount)
    if ForbidManager.getForbidChatTime(human:getAccount()) > os.time() then
        return ChatDefine.ERR_CODE.ADMIN_FORBID
    end
	--聊天内容
    local len = string.len(content)
    if len < 1 or len > ChatDefine.CHAT_MAX_CONTENT_LEN then
		return ChatDefine.ERR_CODE.CONTENT_PASS
    end
	--聊天间隔
	if os.time() - human:getLastChat(ChatDefine.TYPE_WORLD) < ChatDefine.CHAT_TIME_INTERVAL[chatType] then
		return ChatDefine.ERR_CODE.CHAT_COOL_DOWN
	end
	--聊天次数
	if ChatDefine.CHAT_TIMES[chatType] ~= 0 and getChatTimes(human,chatType) >= ChatDefine.CHAT_TIMES[chatType] then
		return ChatDefine.ERR_CODE.CHAT_TIMES_OVER
	end
	--对自己说
	if targetAccount and targetAccount == human:getAccount() then
		return ChatDefine.ERR_CODE.TALK_TO_SELF
	end
    if chatType == ChatDefine.TYPE_PRIVATE then
		--私聊
        --local tarHuman = HumanManager.onlineName[targetName]
        --if tarHuman == nil then
		--	return ChatDefine.ERR_CODE.TARGET_NOT_EXIST
        --end
	elseif chatType == ChatDefine.TYPE_GUILD then
		--帮会聊天
		if human:getGuildId() == 0 then
			return ChatDefine.ERR_CODE.NO_GUILD
		end
    end
    return CommonDefine.OK
end

function doCost(human, chatType)
    return true
end


function doChat(human, chatType, content, targetAccount)
    --Dispatcher.TraceMsg(sMsg)
    print("doChat  type="..chatType.." content="..content)
	local guild = GuildManager.getGuildNameByGuildId(human:getGuildId())
    --local repContent = SensitiveFilter.filterSensitiveWord(content)
	local repContent = content
    if chatType == ChatDefine.TYPE_WORLD then
		local chatItem = {chatType,human:getName(),human:getAccount(),repContent,"",human:getLv(),os.time(),guild,human:getBodyId()}
		ChatBox.addWorldChat(chatType,chatItem)
        Msg.WorldBroadCast(PacketID.GC_CHAT,CommonDefine.OK,unpack(chatItem))
    elseif chatType == ChatDefine.TYPE_PRIVATE then
        local tarHuman = HumanManager.getOnline(targetAccount)
		local tarName = ""
		local chatItem = {chatType,human:getName(),human:getAccount(),repContent,tarName,human:getLv(),os.time(),guild,human:getBodyId()}
        if tarHuman then
			tarName = tarHuman:getName()
        	local ret = Msg.SendMsg(PacketID.GC_CHAT,tarHuman,CommonDefine.OK,unpack(chatItem))
			if not ret then
				ChatBox.addPrivateChat(targetAccount,chatItem)
			end
		else
			ChatBox.addPrivateChat(targetAccount,chatItem)
        end
	elseif chatType == ChatDefine.TYPE_GUILD then
		--帮会聊天
		local ret,retCode,me,memberlist = GuildManager.memberQuery(human)
		if ret then
			local fdList = {}
			for _,mem in pairs(memberlist) do
				local tarHuman = HumanManager.getOnline(mem.account)
				if tarHuman and tarHuman.fd then
					fdList[#fdList+1] = tarHuman.fd 
				end
			end
			if next(fdList) then
				local chatItem = {chatType,human:getName(),human:getAccount(),content,tarName,human:getLv(),os.time(),guild,human:getBodyId()} 
        		Msg.UserBroadCast(PacketID.GC_CHAT,fdList,CommonDefine.OK,chatType,human:getName(),human:getAccount(),content,tarName,human:getLv(),os.time(),guild,human:getBodyId())
				ChatBox.addGuildChat(guild,chatItem)
			end
		end
    end
    human:setLastChat(chatType)
	incChatTimes(human,chatType)
    return true
end

local function makeChatMsg(msg,item)
	for k,v in ipairs(Protocol.ChatItem) do
		msg[v[1]] = item[k]
	end
end
function onHumanLogin(hm,human)
	local msg = {}
	--world
	for _,v in ipairs(ChatBox.WorldChatBox) do
		msg[#msg+1] = {}
		makeChatMsg(msg[#msg],v)
	end
	--private
	local plist = ChatBox.getPrivateChatBox(human:getAccount())
	if plist then
		for _,v in ipairs(plist) do
			msg[#msg+1] = {}
			makeChatMsg(msg[#msg],v)
		end
		ChatBox.delPrivateChatBox(human:getAccount())
	end
	--guild
	local guildName = GuildManager.getGuildNameByGuildId(human:getGuildId())
	if guildName and ChatBox.GuildChatBox[guildName] then
		for _,v in ipairs(ChatBox.GuildChatBox[guildName]) do
			msg[#msg+1] = {}
			makeChatMsg(msg[#msg],v)
		end
	end
	Msg.SendMsg(PacketID.GC_CHAT_BOX,human,msg)
end









