module(...,package.seeall)

--查询
CGOrochiQuery = 
{
}

Info = 
{
	{"levelId",     "int",      "关卡ID"},
	{"status",     	"int",      "状态"},
	{"fightList",	"string",	"出战阵容",		"repeated"},
}

GCOrochiQuery = 
{
	{"resetCounter",     "int",      "挑战次数"},
	{"list",   		 Info,  	"已通关列表", "repeated"},
	{"isUpdate",    "int",      "是否只更新"},
	{"curDayLevelId",    "int",      "当天通关"},
}

--发起挑战
CGOrochiFight = 
{
	{"levelId",     "int",      "关卡ID"},
	{"fightList",	"string",	"出战阵容",		"repeated"},
}
GCOrochiFight = 
{
	{"ret",         "int",      "非0为非法码"},
	{"levelId",     "int",      "关卡ID"},
}

--挑战结果
CGOrochiFightEnd = 
{
	{"res",     	"int",      "战斗结果"},
	{"levelId",     "int",      "关卡ID"},
}

reward = 
{
	{"rewardName",  "string",	"奖励类型 money/heroExp/charExp/其他为道具id"},
	{"cnt",			"int",		"奖励数量"},
}
GCOrochiFightEnd = 
{
	{"ret",         "int",      "非0为非法码"},
	{"res",     	"int",      "战斗结果"},
	{"levelId",     "int",      "关卡ID"},
	{"entryTime",   "int",      "通关时间"},
	{"reward",		reward,		"奖励列表","repeated"},
	{"isChief",		"int",		"是否是霸主"},
}

--霸主榜单
CGOrochiRankQuery = 
{
}

RankItem = 
{
	{"levelId",     "int",      "关卡ID"},
	{"entryTime",   "int",      "通关时间"},
	{"name",    "string",   "玩家名字"},
	{"bodyId",      "int",      "头像ID"},
}
GCOrochiRankQuery = 
{
	{"list",   		 RankItem,  	"霸主榜", "repeated"},
}

--检查到点刷新
CGOrochiCheck = 
{
}

--大蛇重置
CGOrochiReset = {}
GCOrochiReset = {
	{"resetCounter",     "int",      "可重置次数"},
}

--扫荡
rewardList =
{
	{"reward",			reward,       "一次扫荡产生的奖励","repeated"},
	{"charLv",			"int","奖励后的战队等级"},
	{"charLvPercent",	"int","奖励后战队当前等级经验条"},
}
CGOrochiWipe = {}
GCOrochiWipe = {
	{"levelId",     	"int",        "关卡ID",		"repeated"},
	{"rewardList", 		rewardList,	  "奖励列表",   "repeated"},
}








