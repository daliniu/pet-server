module(...,package.seeall)

CGNewOpenQuery = {
}

RewardsDay = {
	{"day",		"int",	"天"},
	{"loginGet",	"int",	"当天登陆领取:0不可领取1未领取2已领取"},
	{"rechargeNum",	"int",	"当天充值数"},
	{"rechargeGet",	"int",	"当天充值领取:0未领取1已领取"},
	{"discountGet",	"int",	"当天半价领取:0未领取1已领取"},
	{"discountNum",	"int",	"当天半价购买人数"},
}

GCNewOpenQuery = {
	{"day",    "int", "天数"},
	{"rewards",	RewardsDay,	"领取状态",	"repeated"}
}

CGNewOpenTime = {
}

GCNewOpenTime = {
	{"beginTime",				"int",					"活动开始时间"},
	{"endTime",					"int",					"活动截止时间"},
	{"getEndTime",				"int",					"领取截止时间"},
	{"isOpen",				"int",					"开启关闭"},
}

CGNewLoginGet = {
	{"day",	"int",	"日期"},
}

GCNewLoginGet = {
	{"ret",	"int",	"返回码"},
}

CGNewRechargeGet = {
	{"day",	"int",	"日期"},
}

GCNewRechargeGet = {
	{"ret",	"int",	"返回码"},
}

CGNewDiscountBuy = {
	{"day",	"int",	"日期"},
}

GCNewDiscountBuy = {
	{"ret",	"int",	"返回码"},
}
