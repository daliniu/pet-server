module(...,package.seeall)

CGDisconnect = {
	{"reason",    "int", "断开原因"},
}

GCDisconnect = {
	{"reason",    "int", "断开原因"},
}

CGAskLogin = {
	{"svrName",     "string", "服务器名"},               
	{"pAccount",     "string", "平台帐号"},                  
	{"channelId",	"int",	  "平台号"},
	{"authKey",     "string", "验证key"},
	{"timestamp",   "int",    "时间戳"}, 
	{"deviceId",     "string", "设备唯一ID"},
}

GCAskLogin = {
	{"result",     "int" ,"登录结果"},   
	{"account",    "string", "帐号"},                  
	{"name",       "string" ,"角色名字"},  
	{"svrName",    "string" ,"游戏服务器名称"},
	{"token",	   "string",   "登录序列"},                   
	{"isNew",   	"int" ,	"是否是新玩家,1/0"},   
	{"msvrIP",     "string" ,"跨服pk服ip"},   
	{"msvrPort",   "int" ,"跨服pk服port"},   
}

--起名
CGRename = {
	{"name",     "string", "名字"},                  
}
GCRename = {
	{"result",     "int" ,"结果"},   
	{"name",     "string", "名字"},                  
}

CGChangeBody = {
	{"bodyId",      "int" ,  "头像"},  
}
GCChangeBody = {
	{"result",     "int" ,"结果"},   
	{"bodyId",     "int" ,  "头像"},  
}

--登录后后端发到前端信息
Info = {
	{"name",        "string" ,"角色名字"},  
	{"timeServer",  "int" ,   "服务器当前时间"},                   
	{"createServer",  "int" ,   "服务器创建时间"},                   
	{"createDate",  "int" ,   "角色创建时间"},                   
	{"bodyId",      "int" ,  "头像"},  
	{"lv",     		"int" ,   "等级"},                  
	{"exp",      	"int" ,     "精力值"},                  
	{"money",       "int" ,   "银币"},                     
	{"rmb",      	"int" ,      "金币"},                  
	{"energy",      "int" ,   "精力值"},                  
	{"physics",     "int" ,   "体力值"},                  
	{"star",     	"int" ,   "星魂"},                  
	{"fame",     	"int" ,   "声望"},                  
	{"powerCoin",   "int" ,   "力量兑换币"},                  
	{"tourCoin",   	"int" ,   "巡回积分"},                  
	{"flowerCount", "int" ,   "鲜花数"},                  
	{"guildCoin", "int" ,   "公会声望"},                  
	{"exchangeCoin", "int" ,   "兑换积分"},                  
	{"peakCoin", 	"int" ,   "巅峰积分"},                  
	{"guildId",     "int" ,   "公会id"},
	{"guildCnt",     "int" ,   "公会进入次数"},
	{"vipLv",		"int",		"VIP等级"},
	{"recharge",	"int",		"充值数"},
	{"renameCnt",	"int",		"重命名次数"},
	--{"settings",    Settings ,   "设置",	"hash"}, 
	{"skillRage",	"int",		"技能怒气值"},
	{"skillAssist",	"int",		"技能援助值"},
}
GCHumanInfo = {
	{"info",		Info,	  "人物info",	"hash"}
}

--断线重连
CGReLogin = {
	{"svrName",     "string", "服务器名"},               
	{"account",     "string", "帐号"},                  
	{"channelId",	"int",	  "平台号"},
	{"authKey",     "string", "验证key"},
	{"token",	   "string",   "登录序列"},                   
	{"timestamp",   "int",    "时间戳"}, 
}

GCReLogin = {
	{"token",	   "string",   "登录序列"},                   
}


PushSetting = {
	{"id",     	"int" ,   "1表示开启"},                  
	{"isOpen",  "int" ,   "1表示开启"},
}
CGSettings = {
	{"music",		"int",		"1表示开启"},
	{"effect",		"int",		"1表示开启"},
	{"pushSettings", PushSetting,"推送设置",	"repeated"},
}
GCSettings = {
	{"music",		"int",		"1表示开启"},
	{"effect",		"int",		"1表示开启"},
	{"pushSettings", PushSetting,"推送设置",	"repeated"},
}

GCError = {
	{"err",	   "string",   "后端错误"},                   
}

GCAddPhysics = {
	{"physics",     "int" ,   "体力值"},                  
	{"timestamp",   "int",    "时间戳"}, 
}

GCKick = {
	{"reason",     "int" ,   "T人理由"},                  
}

GGHttp3rdLoginAuth = {
	{"msg",	   	"string",      "httpmsg"},                   
}

CGLoginAuth = {
	{"sign",     	"string", "需要签名的字符串"},               
	{"sdkInfo",   	"string", "验证sdk登录信息-json"}, 
}

GCLoginAuth = {
	{"authKey",     "string", "验证key"},
}

CGGiftCode = {
	{"code",     	"string", "礼品码"},               
	{"svrId",     	"string", "服务器"},               
}

GCGiftCode = {
	{"ret",			"int",			"返回码"},
	{"msg",  		"string", 		"返回信息"},               
}

--验证礼品激活码
GGHttpGiftCodeActive = {}
--充值上报
GGHttpStatPay = {}







