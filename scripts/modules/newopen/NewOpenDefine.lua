module(...,package.seeall)

LOGIN_GET_RET = {
	kOk = 1,
	kHasGot = 2,
	kDataErr = 3,
}

RECHARGE_GET_RET = {
	kOk = 1,
	kHasGot = 2,
	kNotEnough = 3,
	kDataErr = 4,
}

DISCOUNT_BUY_RET = {
	kOk = 1,
	kHasBuy = 2,
	kSellOut = 3,
	kDataErr = 4,
	kNoRmb = 5,
	kLimit = 6,
	kTimeOut = 7,
}
