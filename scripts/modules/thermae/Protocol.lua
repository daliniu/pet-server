module(...,package.seeall)

--温泉开启关闭通知
GCThermaeNotify = {
	{"op",		"int",		"操作,1表示开启，2表示关闭"},
}

CGThermaeQuery = {
}

Bathing = {
	{"heroName",					"string",			"英雄名"},
}

ItemData = {
	{"itemId",		"int",	"道具id"},
	{"cnt",		"int",	"道具个数"},
}

GCThermaeQuery = {
	{"isOpen",		"int",		"是否已开启"},
	{"leftTime",	"int",		"剩余时间"},
	{"bathing",		Bathing,		"温泉数据",	"repeated"},
	{"money",		"int",		"金币"},
	{"rmb",		"int",		"钻石"},
	{"item",	ItemData,	"道具",	"repeated"}
}

CGThermaeBath = {
	{"heroName",	"string",		"英雄名"},
}

GCThermaeBath = {
}

CGThermaeEndBath = {
}

GCThermaeEndBath = {
}


