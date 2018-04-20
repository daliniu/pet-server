module(..., package.seeall)

--查询当前远征关卡
CGExpeditionQuery = {
}


GCExpeditionQuery = {
	{"id",				"int",				"远征编号"},
	{"tourCoin",		"int",				"巡回币"},
	{"count",			"int",				"今日剩余重置次数"},
	{"hasBuyCount",		"int",				"已购买重置次数"},
	{"hasResetCount",	"int",				"已经重置次数"},
	{"passId",			"int",				"扫荡ID"},
	{"hasGetList",		"int",				"已领取宝箱ID列表",		"repeated"},
}


--购买挑战次数
CGExpeditionBuyCount = {
}

GCExpeditionBuyCount = {
	{"retCode",			"int",				"返回码"},
}


--领取宝箱
ItemData = {
	{"itemId", 			"int", 				"物品id"},
	{"count", 			"int", 				"物品数量"},
}

CGExpeditionGetTreasure = {
	{"id", 				"int", 				"远征编号"},
}

GCExpeditionGetTreasure = {
	{"retCode",			"int",				"返回码"},
	{"id", 				"int",  			"远征编号"},
	{"money",			"int",				"金币"},
	{"tourCoin",		"int",				"巡回币"},
	{"itemList", 		ItemData,			"道具列表", 	"repeated"},
}

--重置远征进度
CGExpeditionReset = {
}

GCExpeditionReset = {
	{"retCode",			"int",				"返回码"},
	{"param",			"int",				"附带参数"},
}

--英雄动态属性
HeroDyAttr = 
{
	{"maxHp",			"int",				"血量上限"},
	{"hpR",				"int",				"血量回复值"},
	{"assist",			"int",				"援助回复值"},
	{"rageR",			"int",				"怒气回复值"},
	{"atkSpeed",		"int",				"攻速值"},
	{"atk",				"int",				"攻击值"},
	{"def",				"int",				"防御值"},
	{"crthit",			"int",				"暴击值"},
	{"antiCrthit",		"int",				"防爆值"},
	{"block",			"int",				"格挡值"},
	{"antiBlock",		"int",				"破挡值"},
	{"damage",			"int",				"真实伤害值"},
	{"rageRByHp",		"int",				"每损失1%血量获得的怒气值"},
	{"rageRByWin",		"int",				"战胜一个敌人获得的怒气值"},
	{"finalAtk",		"int",				"必杀攻击值"},
	{"finalDef",		"int",				"必杀防御值"},
	{"initRage",		"int",				"初始怒气值"},
}

GroupInfo = 
{
    {"groupId",     	"int",      		"技能组ID"},
    {"lv",     			"int",      		"等级"},
    {"equipType",   	"int",      		"装备的位置"},
    {"isOpen",      	"int",      		"是否已开启"},
    --{"skillList",     	"int",    			"技能ID列表",	"repeated"},
}

--打开挑战界面
HeroData = {
    {"name",      		"string",  			"名字"},
    {"pos",				"int",				"位置"},
    {"exp",				"int",				"经验"},
    {"quality",			"int",				"品质"},
    {"lv",				"int",				"等级"},
    {"hp",	  	  		"int",	 			"剩余血量"},
    {"dyAttr",			HeroDyAttr,			"动态属性"},
    {"skillGroupList",  GroupInfo,  		"技能列表",		"repeated"},
	{"gift",			"int", 				"天赋id", 		"repeated"}
}

CGExpeditionChallange = {
	{"next",			"int",				"是否下一关"},	
}

GCExpeditionChallange = {
	{"name", 			"string", 			"战队名"},
	{"lv",				"int",				"等级"},
	{"icon", 			"int", 				"头像"},
	{"guildName", 		"string", 			"公会名"},
	{"rage",	  		"int",	 			"能量"},
    {"assist",	  	  	"int",	 			"援助值"},
	{"enemyList", 		HeroData,			"敌军英雄",		"repeated"},
	{"next",			"int",				"是否下一关"},	
}

--打开选择入阵英雄界面
MyHeroData = {
	{"name",      		"string",  			"名字"},
	--{"order",     		"int",  	 		"次序"},
	--{"status",	  		"int",	 			"状态"},
	{"hp",	  	  		"int",	 			"剩余血量"},
 }

CGExpeditionHeroList = {
}

GCExpeditionHeroList = {
	{"rage",	  		"int",	 			"能量"},
	{"assist",	  	  	"int",	 			"援助值"},
	{"heroList", 		MyHeroData,			"英雄列表",		"repeated"},
}

--进入远征副本
CGExpeditionEnter = {
	{"orderList", 		"string", 			"英雄次序", 	"repeated"},
}

GCExpeditionEnter = {
	{"retCode",			"int",				"返回码"},
	{"orderList", 		"string", 			"英雄次序", 	"repeated"},
}


--返回远征商店列表
ShopData = {
	{"shopId", 			"int", 				"商品Id"},
	{"hasBuy", 			"int", 				"是否已经购买"},
}
CGExpeditionShopList = {
}

GCExpeditionShopList = {
	{"shopList", 		ShopData,			"道具列表", 	"repeated"},
	{"refreshTime",		"int",				"下一次刷新时间"},
	{"refreshCost",		"int",				"刷新消耗钻石数"},
}

--购买物品
CGExpeditionBuyItem = {
	{"id",				"int",				"id"},
}

GCExpeditionBuyItem = {
	{"retCode",			"int",				"返回码"},
	{"id",				"int",				"id"},
}

--刷新远征商店
CGExpeditionShopRefresh = {
}

GCExpeditionShopRefresh = {
	{"retCode",			"int",				"返回码"},
}

--副本结束
HeroHpData = {
	{"name",			"string",			"名字"},
	{"hp",	  	  		"int",	 			"剩余血量"},
}

CGExpeditionEnd = {
	{"result",			"int",				"结果"},
	{"myRage",	  		"int",	 			"自己的能量"},
	{"myAssist",	  	"int",	 			"自己的援助值"},
	{"myHeroHpList",	HeroHpData,			"自己的英雄血量列表",	"repeated"},
	{"enemyRage",	  	"int",	 			"敌方的能量"},
	{"enemyAssist",	  	"int",	 			"敌方的援助值"},
	{"enemyHeroHpList",	HeroHpData,			"敌方的英雄血量列表",	"repeated"},
}

GCExpeditionEnd = {
	{"retCode",			"int",				"返回码"},
}

--扫荡
CGExpeditionClear = {
}

GCExpeditionClear = {
	{"retCode",			"int",				"返回码"},
	{"passId",			"int",				"通关ID"},
}
