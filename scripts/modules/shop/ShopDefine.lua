module(...,package.seeall)

SHOP_BUY_RET = {
	kOk = 1,
	kDataErr = 2,
	kDayLimited = 3,
	kDateLimited = 4,
	kBagFull = 5,
	kNotRmb = 6,
	kNotMoney = 7,
	kNotPowerCoin = 8,
}

SHOP_SELL_RET = {
	kOk = 1,
	kDataErr = 2,
	kNoItem = 3,
}

K_SHOP_BUY_RMB = 1
K_SHOP_BUY_MONEY = 2
K_SHOP_BUY_POWERCOIN = 3

COST_NAME = {
	[1] = "钻石",
	[2] = "金币",
	[3] = "力量币",
}

COMMON_ONCE_RET = {
	kOk = 1,
	kNoItem = 2,
}

COMMON_TEN_RET = {
	kOk = 1,
	kNoGold = 2,
}

RARE_ONCE_RET = {
	kOk = 1,
	kNoGold = 2,
	kRandomHeroFail = 3
}

RARE_TEN_RET = {
	kOk = 1,
	kNoGold = 2,
}

EXCHANGE_BUY = {
	kOk = 1,
	kErrData = 2,
	kHasBuy = 3,
	kNoCoin = 4,
}
EXCHANGE_REFRESH = {
	kOk = 1,
	kNoTimes = 2,
	kErrData = 3,
	kNoCoin = 4,
}

RARE_TEN = 10

K_SHOP_VIRTUAL_MONEY_ID = 1001
K_SHOP_VIRTUAL_PHY_ID = 1002
K_SHOP_VIRTUAL_ARENA_ID = 1003
K_SHOP_VIRTUAL_TREASUREDOUBLE_ID = 1005
K_SHOP_VIRTUAL_TREASURESAFE_ID = 1006
K_SHOP_VIRTUAL_TREASUREEXTEND_ID = 1007
K_SHOP_VIRTUAL_TREASUREGRAB_ID = 1008


MAX_EXCHANGE_SHOP_NUM = 8
MAX_EXCHANGE_SHOP_REFRESH_TIMES = 1000
K_SHOP_VIRTUAL_TREASUREFIGHT_ID = 1013
K_SHOP_VIRTUAL_TREASUREREFRESHMAP_ID = 1014
K_SHOP_VIRTUAL_VIPLEVELTIMES = 1015