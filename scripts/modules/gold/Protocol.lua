module(...,package.seeall)

CostInfo = {
	{"gold",	"int",	"消耗钻石"},
	{"money",	"int",	"获得金币"},
	{"rate",	"int",	"暴击倍数"},
}

CGGoldBuy = {
}

GCGoldBuy = {
	{"ret",		"int",	"返回码"},
	{"costInfo",	CostInfo,	"获得钱币信息"},
}

CGGoldBuyTen = {
	{"cnt",		"int",	"购买次数"},
}

GCGoldBuyTen = {
	{"ret",		"int",	"返回码"},
	{"costInfo",	CostInfo,	"获得钱币信息",		"repeated"},
}

CGGoldBuyQuery = {
}

GCGoldBuyQuery = {
	{"cnt",		"int",	"购买次数"},
}
