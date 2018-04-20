module(..., package.seeall)    

CGChat = 
{
    {"type",        "int",        "聊天类型"},
    {"content",     "string",     "聊天内容"},
    {"account",     "string",     "私聊对象账号"},
} 

GCChat = 
{
	{"ret",         "int",         "非0为非法码"},
    {"type",        "int",         "聊天类型"},
    {"senderName",  "string",      "发送者姓名"},
    {"senderAccount",  "string",   "发送者账号"},
    {"content",     "string",      "聊天内容"},
    {"receiverName","string",      "接收者姓名"},
    {"lv",          "int",         "等级"},
    {"time",        "int",         "时间"},
	{"guildName",	"string",	   "公会名字"},
	{"bodyId",		"int",	   	   "头像"},
}

ChatItem = 
{                     
    {"type",        "int",         "聊天类型"},
    {"senderName",  "string",      "发送者姓名"},
    {"senderAccount",  "string",   "发送者账号"},
    {"content",     "string",      "聊天内容"},
    {"receiverName","string",      "接收者姓名"},
    {"lv",          "int",         "等级"},
    {"time",        "int",         "时间"},
	{"guildName",	"string",	   "公会名字"},
	{"bodyId",		"int",	   	   "头像"},
} 
GCChatBox = 
{                     
	{"chatBox",		ChatItem,		"留言列表","repeated"}
} 




