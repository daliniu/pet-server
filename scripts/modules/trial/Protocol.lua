module(...,package.seeall)

--查询
CGTrialQuery = 
{
}

Info = 
{
	{"levelId",     "int",      "关卡ID"},
	{"status",     	"int",      "状态"},
	{"fightList",	"string",	"出战阵容",		"repeated"},
}
TypeCounter = {
	{"type",     	"int",      "关卡类型"},
	{"counter",     "int",      "次数"},
}

GCTrialQuery = 
{
	{"list",   		 Info,  	"关卡列表", "repeated"},
	{"typeCounter",  TypeCounter, "挑战次数","repeated"},
	--{"resetTimes",   "int",      "重置次数"},
}

--发起挑战
CGTrialFight = 
{
	{"levelId",     "int",      "关卡ID"},
	{"fightList",	"string",	"出战阵容",		"repeated"},
}
GCTrialFight = 
{
	{"ret",         "int",      "非0为非法码"},
	{"levelId",     "int",      "关卡ID"},
}

--挑战结果
CGTrialFightEnd = 
{
	{"res",     	"int",      "战斗结果"},
	{"levelId",     "int",      "关卡ID"},
	--{"killCnt",     "int",      "杀死的怪物数"},
}

reward = 
{
	{"rewardName",  "string",	"奖励类型 money/heroExp/charExp/其他为道具id"},
	{"cnt",			"int",		"奖励数量"},
}
GCTrialFightEnd = 
{
	{"ret",         "int",      "非0为非法码"},
	{"res",     	"int",      "战斗结果"},
	{"levelId",     "int",      "关卡ID"},
	{"entryTime",   "int",      "通关时间"},
	{"reward",		reward,		"奖励列表","repeated"},
	--{"isChief",		"int",		"是否是霸主"},
}

--霸主榜单
CGTrialRankQuery = 
{
}

RankItem = 
{
	{"score",   	"int",      "总分"},
	{"name",    "string",   "玩家名字"},
	{"bodyId",      "int",      "头像ID"},
	{"lv",      	"int",      "等级"},
}
GCTrialRankQuery = 
{
	{"list",   		RankItem,  	"霸主榜", "repeated"},
	{"score",   	"int",      "我的分数"},
}

CGTrialReset = {}
GCTrialReset = 
{
	{"ret",         "int",      "非0为非法码"},
}


--检查到点刷新
CGTrialCheck = 
{
}





