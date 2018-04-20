module(...,package.seeall)

CGShopQuery = {
    {"shopId",     "int",        "商品ID", "repeated"},
}
ShopCnt = {
    {"shopId",     "int",        "商品ID"},
    {"cnt",     "int",        "已经购买次数"},
}
GCShopQuery = {
    {"shopCnt",     ShopCnt,        "商品次数", "repeated"},
}

CGShopBuy = {
    {"shopId",     "int",        "商品ID"},
    {"num",     "int",        "数量"},
}

GCShopBuy = {
    {"shopId",     "int",        "商品ID"},
    {"ret",     "int",        "返回码"},
}

CGShopBuyVirtual = {
    {"shopId",     "int",        "商品ID"},
    {"params",     "int",        "参数列表",	"repeated"},
}

GCShopBuyVirtual = {
    {"shopId",     "int",        "商品ID"},
    {"ret",     "int",        "返回码"},
}

CGShopSell = {
    {"shopId",     "int",        "商品ID"},
    {"num",     "int",        "数量"},
}

GCShopSell = {
    {"ret",     "int",        "返回码"},
}

CGShopLotteryQuery = {
}

GCShopLotteryQuery = {
	{"commonfree",	"int",	"普通寻宝免费CD时间"},
	{"rarefree",	"int",	"稀有寻宝免费CD时间"},
	{"raretimes",	"int",	"稀有寻宝抽奖次数"},
	{"commonFreeTimes",	"int",	"普通寻宝今天免费次数"},
}

CGShopCommonOnce = {
}

GCShopCommonOnce = {
	{"retCode",  "int",		"返回码"},
	{"itemId",  "int",		"物品id"},
}

RareItem = {
	{"id",  "int",		"物品id"},
	{"num",  "int",		"物品数量"},
	{"disFrag",  "int",		"是否分解碎片"},
}

CGShopCommonTen = {
}

GCShopCommonTen = {
	{"retCode",  "int",		"返回码"},
	{"items",  RareItem,		"物品",		"repeated"},
}

CGShopRareOnce = {
}

GCShopRareOnce = {
	{"retCode",  "int",		"返回码"},
	{"item",  RareItem,		"物品"},
}

CGShopRareTen = {
	{"isCertain",	"int",	"是否特定抽"}
}

GCShopRareTen = {
	{"retCode",  "int",		"返回码"},
	{"items",  RareItem,		"物品",		"repeated"},
}

CGExchangeShopQuery = {
}

ExchangeShopData = {
	{"id",		"int",		"商品id"},
	{"itemId",		"int",	"物品id"},
	{"cnt",		"int",		"物品数量"},
	{"buy",		"int",		"是否已经购买"},
	{"price",	"int",		"消耗"},
}

GCExchangeShopQuery = {
	{"shopData",	ExchangeShopData,	"商店物品",		"repeated"},
	{"refreshTimes",		"int",			"已经刷新次数"}
}

CGExchangeShopBuy = {
	{"id",		"int",		"商品id"}
}
GCExchangeShopBuy = {
	{"id",		"int",		"商品id"},
	{"ret",		"int",		"购买返回码"}
}

CGExchangeShopRefresh = {
}

GCExchangeShopRefresh = {
	{"ret",		"int",		"刷新返回码"}
}
