module(..., package.seeall)

RecordData = {
	{"name",						"string",					"赠送者"},
	{"flowerType",					"int",						"花类型"},
	{"giveTime",					"int",						"赠送时间"},
}

--打开送花界面
CostData = {
	{"cost",						"int",						"价格"},
	{"costType",					"int",						"货币类型"},
}

CGFlowerGiveOpen = {
	{"index",						"string",					"索引"},
	{"fromType",					"int",						"送花入口"},
}

GCFlowerGiveOpen = {
	{"index",						"string",					"索引"},
	{"fromType",					"int",						"送花入口"},
	{"bodyId",						"int",						"战队头像"},
	{"name",						"string",					"战队名字"},
	{"flowerCount",					"int",						"鲜花数"},
	{"hasGive",						"int",						"是否赠送过"},
	{"rewardLeftCount",				"int",						"奖励次数"},
	{"tipShow",						"int",						"是否显示今日提示"},
	{"giveRecordList",				RecordData,					"赠送记录",				"repeated"},
	{"costList",					CostData,					"价格列表",				"repeated"},
}

--个人送花记录界面
CGFlowerPersonal = {
}

GCFlowerPersonal = {
	{"rewardLeftCount",				"int",						"奖励次数"},
	{"giveRecordList",				RecordData,					"赠送记录",				"repeated"},
	{"receiveRecordList",			RecordData,					"收花记录",				"repeated"},
}

--送花
CGFlowerGive = {
	{"index",						"string",					"索引"},
	{"fromType",					"int",						"送花入口"},
	{"flowerType",					"int",						"赠送类型"},
	{"tipShow",						"int",						"是否显示今日提示"},
}

GCFlowerGive = {
	{"retCode",						"int",						"返回码"},
	{"msg",							"string",					"返回信息"},
}

--收到鲜花
GCFlowerGet = {}
