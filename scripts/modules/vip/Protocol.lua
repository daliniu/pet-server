module(..., package.seeall)

--充值
CGVipRecharge = {
	{"count",						"int",						"充值数"},
}

GCVipRecharge = {
	{"ret",							"int",						"返回码"},
	{"count",						"int",						"充值数"},
}

--购买礼包
CGVipBuyGift = {
	{"vipLv",						"int",						"vip等级"},
}

GCVipBuyGift = {
	{"retCode",						"int",						"返回码"},
	{"lv",							"int",						"购买等级"},
}

--查看vip
CGVipCheck = {
}

GCVipCheck = {
	{"recharge",					"int",						"充值数"},
	{"rechargeList",				"int",						"可充值选项列表",		"repeated"},
	{"giftBuyList",					"int",						"已买礼包列表",			"repeated"},
	{"dailyInfo",					"int",						"领取日常领取信息",		"repeated"},
}

--领取Vip日常
CGVipGetDaily = {
	{"vipLv",						"int",						"vip等级"},
}

GCVipGetDaily = {
	{"retCode",						"int",						"返回码"},
	{"vipLv",						"int",						"vip等级"},
}

CGVipLevelStart = {
	{"levelId","int","vip副本id"},

}

GCVipLevelStart = {
	{"retCode","int","错误码"},
	{"levelId","int","vip副本id"},
}

CGVipLevelEnd = {
	{"levelId","int","vip副本id"},
	{"result","int","副本结果"},
	{"heroes","string","出战英雄","repeated"},
}
REWARD = 
{
	{"rewardName","string","奖励类型 money/heroExp/charExp/其他为道具id"},
	{"cnt","int","奖励数量"},
}
GCVipLevelEnd = {
	{"retCode","int","错误码"},
	{"levelId","int","vip副本id"},
	{"result","int","副本结果"},
	{"reward",REWARD,"奖励列表","repeated"},
	{"heroes","string","出战英雄","repeated"},
}

CGVipLevelInfo = {
	
}

GCVipLevelInfo = {
	{"retCode","int","错误码"},
	{"times","int","挑战次数"},
}