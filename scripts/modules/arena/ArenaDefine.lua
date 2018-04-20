module(...,package.seeall)

MAX_SHOP_REFRESH_TIMES = 1000

WIN = 1
LOSE = 2

LEAD = 1
PASSIVE = 2

MAX_ARENA_RECORD = 30

ARENA_BEGIN = {
	kOk = 0,		--成功开始竞技场
	kLeftTimes = 1,	--超过今日次数
	kCdTime = 2,	--挑战CD中
	kNoEnemy = 3,	--对手数据错误
	kEnemying  = 4,	--对手正在竞技场中
}

ARENA_BUY = {
	kOk = 0,		--购买成功	
	kNoFame = 1,	--声望不足
	kHasBuy = 2,	--已经购买过
	kFullBag = 3,	--背包空间不足
	kErrData= 4,	--数据异常
}

ARENA_REFRESH = {
	kOk = 0,		--刷新成功
	kNoTimes = 1,	--刷新次数不足
	kNoFame = 2,	--声望不足
	kErrData= 3,	--数据异常
}

ARENA_RESETCD = {
	kOk = 1,		--重置cd成功
	kNoFame = 2,	--声望不足
}

MAX_ARENA_SHOP_NUM = 8

REWARD = {
	[WIN]= 10,
	[LOSE]= 5,
}

MAX_FIGHTVAL_RANK = 30
MAX_POS_RANK = 30
