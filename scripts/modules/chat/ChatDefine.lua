module(...,package.seeall)

local ChatConfig = require("config.ChatConfig").Config

FALSE = 0
TRUE = 1

CHAT_MAX_CONTENT_LEN = 150      --发言最大字节数

--chat type
TYPE_SYSTEM  = 0 	 --系统
TYPE_WORLD   = 1     --世界
TYPE_PRIVATE = 2     --私聊
TYPE_GUILD   = 3	 --公会

CHAT_TIME_INTERVAL = {}		--聊天间隔
CHAT_TIMES = {}			--每天聊天次数
for chatType,v in ipairs(ChatConfig) do
	CHAT_TIME_INTERVAL[chatType] = v.interval
	CHAT_TIMES[chatType] = v.times
end

SAVE_FORBID_TIMER = 1800 * 1000

--留言限制条数
CHAT_BOX_LIMIT = {
	[TYPE_WORLD] = 20,
	[TYPE_PRIVATE] = 20,
	[TYPE_GUILD] = 20,
} 


--chat return code
ERR_CODE = 
{
	ADMIN_FORBID = 1,    --禁止发言
	CHAT_COOL_DOWN = 2, --处于CD时间
	TARGET_NOT_EXIST = 3, --对方不在线
	TALK_TO_SELF = 4, --不能对自己聊天
	TALK_TO_STRANGER = 5, --对方拒绝陌生人消息
	CONTENT_PASS = 6, --发言内容过长
	CHAT_TIMES_OVER = 7, --聊天次数过多
	NO_GUILD = 8,
}
ERR_TXT =
{
	[ERR_CODE.ADMIN_FORBID] = "禁止发言",
	[ERR_CODE.CHAT_COOL_DOWN] = "您说话太快了",
	[ERR_CODE.TARGET_NOT_EXIST] = "对方不在线",
	[ERR_CODE.TALK_TO_SELF] = "能对自己聊天",
	[ERR_CODE.TALK_TO_STRANGER] = "对方拒绝陌生人消息",
	[ERR_CODE.CONTENT_PASS] = "发言内容过长",
	[ERR_CODE.CHAT_TIMES_OVER] = "聊天次数过多",
	[ERR_CODE.NO_GUILD] = "没有帮会",
}



