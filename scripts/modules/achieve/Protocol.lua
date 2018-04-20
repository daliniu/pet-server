module(...,package.seeall)

--成就列表
AchieveTargetData = {
	{"param",				"int",					"当前参数",				"repeated"},
}

AchieveData = {
	{"id",					"int",					"成就ID"},
	{"targetList",			AchieveTargetData,		"目标数据",				"repeated"},
}

CGAchieveList = {
}

GCAchieveList = {
	{"unfinishList",		AchieveData,			"未完成列表",			"repeated"},
	{"commitList",			"int",					"可提交列表",			"repeated"},
	{"finishList",			"int",					"完成列表",				"repeated"},
}

--领取成就
RewardData = {
	{"rewardName",			"string",				"奖励类型 money/heroExp/charExp/其他为道具id"},
	{"cnt",					"int",					"奖励数量"},
}

CGAchieveGet = {
	{"id",					"int",					"成就ID"},
}

GCAchieveGet = {
	{"ret",					"int",					"返回码"},
	{"id",					"int",					"成就ID"},
	{"rewardList",			RewardData,				"奖励列表",				"repeated"},
}
