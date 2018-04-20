module(...,package.seeall) 

MysteryShopData = {
	{"id",		"int",		"商品id"},
	{"itemId",		"int",	"物品id"},
	{"cnt",		"int",		"物品数量"},
	{"buy",		"int",		"是否已经购买"},
	{"price",	"int",		"消耗"},
}

GCMysteryShopQuery = {
	{"shopData",	MysteryShopData,	"商店物品",		"repeated"},
	{"refreshTimes",		"int",			"已经刷新次数"},
	{"mtype",		"int",			"商店下标"}
}

CGMysteryShopQuery = {
	{"mtype",		"int",			"商店下标"}
}

GCMysteryShopRefresh = {
	{"ret",		"int",		"刷新返回码"},
	{"mtype",		"int",			"商店下标"}
}

CGMysteryShopRefresh = {
	{"mtype",		"int",			"商店下标"}
}

GCMysteryShopBuy = {
	{"id",		"int",		"商品id"},
	{"ret",		"int",		"购买返回码"},
	{"mtype",		"int",			"商店下标"}
}

CGMysteryShopBuy = {
	{"id",		"int",		"商品id"},
	{"mtype",		"int",			"商店下标"}
}
