module(..., package.seeall)

--查询阵容
CGPeakTeamCheck = {
}

GCPeakTeamCheck = {
	{"isStart",					"int",					"是否开启"},
	{"heroNameList",			"string",				"阵容列表",			"repeated"},
	{"coolTime",				"int",					"冷却时间"},
	{"score",					"int",					"积分"},
	{"resetCost",				"int",					"重置消费"},
}

--确定阵容
CGPeakTeamConfirm = {
	{"heroNameList",			"string",				"阵容列表",			"repeated"},
}

GCPeakTeamConfirm = {
	{"retCode",					"int",					"返回码"},	
	{"heroNameList",			"string",				"阵容列表",			"repeated"},
}

--搜索
HeroInfo = {
	{"name",					"string",				"名字"},
	{"lv",						"int",					"等级"},
	{"quality",					"int",					"品阶"},
}

CGPeakSearch = {
}

GCPeakSearch = {
	{"name",					"string",				"角色名"},
	{"heroList",				HeroInfo,				"英雄列表",			"repeated"},
}

--取消
CGPeakCancel = {
}

GCPeakCancel = {
}


--重置
CGPeakResetSearch = {
}

GCPeakResetSearch = {
	{"retCode",					"int",					"返回码"},
	{"resetCost",				"int",					"重置消费"},
}

--操作敌方英雄
CGPeakCtrlEnemy = {
	{"heroNameList",			"string",				"英雄阵容",			"repeated"},
}

GCPeakCtrlEnemy = {
	{"retCode",					"int",					"返回码"},
}

--操作敌方英雄确认
CGPeakCtrlEnemyConfirm = {
	{"heroNameList",			"string",				"阵容列表",			"repeated"},
}

GCPeakCtrlEnemyConfirm = {
	{"isRobt",					"int",					"是否为机器人"},
	{"heroNameList",			"string",				"阵容列表",			"repeated"},
	{"enemyNameList",			"string",				"阵容列表",			"repeated"},
}

--准备
HeroDyAttr = 
{
	{"maxHp",					"int",					"血量上限"},
	{"hpR",						"int",					"血量回复值"},
	{"assist",					"int",					"援助回复值"},
	{"rageR",					"int",					"怒气回复值"},
	{"atkSpeed",				"int",					"攻速值"},
	{"atk",						"int",					"攻击值"},
	{"def",						"int",					"防御值"},
	{"crthit",					"int",					"暴击值"},
	{"antiCrthit",				"int",					"防爆值"},
	{"block",					"int",					"格挡值"},
	{"antiBlock",				"int",					"破挡值"},
	{"damage",					"int",					"真实伤害值"},
	{"rageRByHp",				"int",					"每损失1%血量获得的怒气值"},
	{"rageRByWin",				"int",					"战胜一个敌人获得的怒气值"},
	{"finalAtk",				"int",					"必杀攻击值"},
	{"finalDef",				"int",					"必杀防御值"},
	{"initRage",				"int",					"初始怒气值"},
}

GroupInfo = 
{
    {"groupId",     			"int",      			"技能组ID"},
    {"lv",     					"int",      			"等级"},
    {"equipType",   			"int",      			"装备的位置"},
    {"isOpen",      			"int",      			"是否已开启"},
}

HeroData = {
    {"name",      				"string",  				"名字"},
    {"pos",						"int",					"位置"},
    {"exp",						"int",					"经验"},
    {"quality",					"int",					"品质"},
    {"lv",						"int",					"等级"},
    {"hp",	  	  				"int",	 				"剩余血量"},
    {"dyAttr",					HeroDyAttr,				"动态属性"},
    {"skillGroupList",  		GroupInfo,  			"技能列表",			"repeated"},
	{"gift",					"int", 					"天赋id", 			"repeated"}
}

CGPeakReadyGo = {
	{"heroNameList",			"string",				"英雄列表",			"repeated"},
}

GCPeakReadyGo = {
	{"seed",					"int",					"随机种子"},
	{"dir",						"int",					"方位"},
	{"heroNameList",			"string",				"英雄列表",			"repeated"},
	{"enemyList", 				HeroData,				"敌军英雄",			"repeated"},
}

--对战记录
RecordFightList = {
	{"name",					"string",				"英雄名"},
	{"pos",						"int",					"位置"},
	{"lv",						"int",					"英雄等级"},
	{"quality",					"int",					"品阶等级"},
}

FightRecord = {
	{"icon",					"int",					"战队图标"},
	{"name",					"string",				"战队名字"},
	{"lv",						"int",					"战队等级"},
	{"result",					"int",					"胜负"},
	{"fightList",				RecordFightList,		"对手阵容", 		"repeated"},
	{"enemyList",				RecordFightList,		"对手阵容",			"repeated"},
}

--挑战记录
CGPeakFightRecord = {
}

GCPeakFightRecord = {
	{"records",					FightRecord,			"挑战记录",			"repeated"}
}

--逃跑
CGPeakFail = {
}

GCPeakFail = {
}

--结束
CGPeakEnd = {
	{"isSuccess",				"int",					"是否胜利"},
}

GCPeakEnd = {
	{"isSuccess",				"int",					"是否胜利"},
}

--商店
ShopData = {
	{"shopId", 					"int", 					"商品Id"},
	{"hasBuy", 					"int", 					"是否已经购买"},
}
CGPeakShopList = {
}

GCPeakShopList = {
	{"shopList", 				ShopData,				"道具列表", 		"repeated"},
	{"refreshTime",				"int",					"下一次刷新时间"},
	{"refreshCost",				"int",					"刷新消耗钻石数"},
}

--购买物品
CGPeakBuyItem = {
	{"id",						"int",					"id"},
}

GCPeakBuyItem = {
	{"retCode",					"int",					"返回码"},
	{"id",						"int",					"id"},
	{"score",					"int",					"积分"},
}

--刷新商店
CGPeakShopRefresh = {
}

GCPeakShopRefresh = {
	{"retCode",					"int",					"返回码"},
}
