module(...,package.seeall)

CGArenaQuery = {
}

--英雄动态属性
HeroDyAttr = 
{
	{"maxHp","int","血量上限"},
	{"hpR","int","血量回复值"},
	{"assistR","int","援助回复值"},
	{"rageR","int","怒气回复值"},
	{"atkSpeed","int","攻速值"},
	{"atk","int","攻击值"},
	{"def","int","防御值"},
	{"crthit","int","暴击值"},
	{"antiCrthit","int","防爆值"},
	{"block","int","格挡值"},
	{"antiBlock","int","破挡值"},
	{"damage","int","真实伤害值"},
	{"rageRByHp","int","每损失1%血量获得的怒气值"},
	{"rageRByWin","int","战胜一个敌人获得的怒气值"},
	{"finalAtk","int","必杀攻击值"},
	{"finalDef","int","必杀防御值"},
	{"initRage","int","初始怒气值"},
}

GroupInfo = 
{
    {"groupId",     "int",      "技能组ID"},
    {"lv",     		"int",      "等级"},
    {"equipType",   "int",      "装备的位置"},
    {"isOpen",      "int",      "是否已开启"},
    --{"skillList",     "int",    "技能ID列表",	"repeated"},
}

EnemyHeroData ={
    {"name",      		"string",  			"名字"},
    {"exp",				"int",				"经验"},
    {"quality",			"int",				"品质"},
    {"lv",				"int",				"等级"},
    {"dyAttr",			HeroDyAttr,			"动态属性"},
    {"skillGroupList",		GroupInfo,			"技能列表",		"repeated"},
	{"gift",	"int", "天赋id", "repeated"}
}

EnemyData = {
	{"name",		"string",		"战队名称"},
	{"lv",			"int",		"战队等级"},
	{"icon",		"int",			"战队图标"},
	{"rank",		"int",		"排名"},
	{"guild",		"string",		"公会名"},
	{"win",			"int",			"胜场数"},
	{"fightVal",	"int",			"战斗力"},
	{"flowerCount",				"int",					"鲜花数"},
	{"fightList",	EnemyHeroData,	"出战阵容",		"repeated"},
}

HeroData = {
	{"name",	"string",	"英雄"},
	{"pos",	"int",	"位置"},
}

GCArenaQuery = {
	{"rank",		"int",		"排名"},
	{"fightList",	HeroData,	"出战阵容",		"repeated"},
	{"leftTimes",	"int",		"今日剩余次数"},
	{"maxTimes",	"int",		"今日最大挑战次数"},
	{"nextTime",	"int",		"距下次可挑战时间(秒)"},
	{"enemyList",		EnemyData,	"对方信息",		"repeated"}
}

CGArenaChangeHero = {
	{"fightList",	HeroData,	"出战阵容",		"repeated"},
}

GCArenaChangeHero = {
	{"fightList",	HeroData,	"出战阵容",		"repeated"},
}

CGArenaChangeEnemy = {
}

GCArenaChangeEnemy = {
	{"enemyList",		EnemyData,	"对方信息",		"repeated"}
}

RecordFightList = {
	{"name",	"string",	"英雄名"},
	{"pos",		"int",	"位置"},
	{"lv",	"int",	"英雄等级"},
	{"quality",	"int",	"品阶等级"},
	{"transferLv",	"int",	"力量等级"},
}

CGArenaFightRecord = {
}

FightRecord = {
	{"icon",	"int",	"战队图标"},
	{"name",	"string",	"战队名字"},
	{"lv",	"int",	"战队等级"},
	{"happened",	"int",		"发生时间"},
	{"lead",	"int",		"是否被挑战"},
	{"result",	"int",	"胜负"},
	{"rise",	"int",	"改变名次"},
	{"fightList",	RecordFightList,	"对手阵容", "repeated"},
	{"enemyList",	RecordFightList,	"对手阵容",	"repeated"},
}

GCArenaFightRecord = {
	{"records",		FightRecord,	"挑战记录",		"repeated"}
}

CGArenaFightBegin = {
	{"enemyPos",	"int",		"对手位置"}
}

GCArenaFightBegin = {
	{"retCode",		"int",		"进入竞技场返回码"},
	{"enemyPos",	"int",		"对手位置"}
}

CGArenaFightEnd = {
	{"result",		"int",		"竞技场结果"},
	{"enemyPos",	"int",		"对手位置"}
}

REWARD = 
{
	{"rewardName","string","奖励类型 money/heroExp/charExp/其他为道具id"},
	{"cnt","int","奖励数量"},
}

GCArenaFightEnd = {
	{"result",		"int",		"竞技场结果"},
	{"reward",REWARD,"奖励列表","repeated"},
}

CGArenaShopQuery = {
}

ArenaShopData = {
	{"id",		"int",		"商品id"},
	{"itemId",		"int",	"物品id"},
	{"cnt",		"int",		"物品数量"},
	{"buy",		"int",		"是否已经购买"},
	{"price",	"int",		"消耗"},
}

GCArenaShopQuery = {
	{"shopData",	ArenaShopData,	"商店物品",		"repeated"},
	{"refreshTimes",		"int",			"已经刷新次数"}
}

CGArenaShopRefresh = {
}

GCArenaShopRefresh = {
	{"ret",		"int",		"刷新返回码"}
}

CGArenaShopBuy = {
	{"id",		"int",		"商品id"}
}

GCArenaShopBuy = {
	{"id",		"int",		"商品id"},
	{"ret",		"int",		"购买返回码"}
}

CGArenaResetCd = {
}

GCArenaResetCd = {
	{"ret",		"int",		"返回码"}
}
