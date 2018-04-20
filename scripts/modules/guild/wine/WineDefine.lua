module(...,package.seeall)

WINE_QUERY_RET = {
	kOk = 1,
	kNoGuild = 2,
}

WINE_START_RET = {
	kOk = 1,
	kNoMoney = 2,
	kDataErr = 3,
	kNoGuild = 4,
	kNoCnt = 5,
}

WINE_DONATE_RET = {
	kOk = 1,
	kDataErr = 2,
	kNoGuild = 3,
}

WINE_BUFF_TIME = 3600
