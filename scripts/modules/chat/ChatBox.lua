module(...,package.seeall) 

local ChatDefine = require("modules.chat.ChatDefine")

WorldChatBox = WorldChatBox or {}
PrivateChatBox = PrivateChatBox or {}
GuildChatBox = GuildChatBox or {}

function addWorldChat(chatType,chatItem)
	if #WorldChatBox >= ChatDefine.CHAT_BOX_LIMIT[ChatDefine.TYPE_WORLD] then
		table.remove(WorldChatBox,1)
	end
	WorldChatBox[#WorldChatBox+1] = chatItem
end

--个人信箱
function addPrivateChat(account,chatItem)
	PrivateChatBox[account] = PrivateChatBox[account] or {}
	local list = PrivateChatBox[account] 
	if #list >= ChatDefine.CHAT_BOX_LIMIT[ChatDefine.TYPE_PRIVATE] then
		table.remove(list,1)
	end
	list[#list+1] = chatItem
end

function getPrivateChatBox(account)
	return PrivateChatBox[account]
end

function delPrivateChatBox(account)
	PrivateChatBox[account] = nil
end

function addGuildChat(guildName,chatItem)
	GuildChatBox[guildName] = GuildChatBox[guildName] or {}
	local list = GuildChatBox[guildName]
	if #list >= ChatDefine.CHAT_BOX_LIMIT[ChatDefine.TYPE_GUILD] then
		table.remove(list,1)
	end
	list[#list+1] = chatItem
end





