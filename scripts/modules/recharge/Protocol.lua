module(...,package.seeall)

CGRechargeTime = {
}

GCRechargeTime = {
	{"beginTime",					"int",					"活动开始时间"},
	{"endTime",					"int",					"活动截止时间"},
	{"getEndTime",				"int",					"领取截止时间"},
	{"isOpen",				"int",					"开启关闭"},
}

CGRechargeQuery = {
}

Status = {
	{"id",					"int",					"id"},
	{"state",				"int",					"1:不可领取2:可领取3:已领取"},
}
GCRechargeQuery = {
	{"num",					"int",					"已充值数"},
	{"status",				Status,					"领取状态",		"repeated"},
}

CGRechargeGet = {
	{"id",					"int",					"领取id"},
}

GCRechargeGet = {
	{"ret",					"int",					"返回码"},
}
