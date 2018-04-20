module(...,package.seeall)

RECHARGE_GET_RET = {
	kOk = 1,		--领取成功
	kHasGot = 2,		--已经领取过
	kDataErr = 3,	--数据错误
	kNotEnough = 4,	--累计充值不足
	kEndTime = 5,	--活动截止
}
