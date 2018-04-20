module(...,package.seeall)


local TDConfig = require("config.TreasureDefineConfig").Config

RET_OK = 0
RET_NOTPERMITTED = 1
RET_NOTFOUND = 2
RET_NOTENOUGH = 3
RET_TARGETPROTECTED = 4
RET_LIMITED = 5     
RET_OCCUPYING = 6
RET_ASSIST = 7
RET_LEVEL = 8
RET_ENERGYNOTENOUGH = 9
RET_OCCUPYTIMES = 10   -- 占领次数超出
RET_DOUBLETIMES = 11   -- 双倍收益次数超出
RET_SAFETIMES = 12     -- 保护次数超出
RET_INASSIST = 13 -- 自己已经有英雄协助这个框了，不能同时有两个英雄协助同一个矿
RET_FIGHTTIMES = 14  
RET_PREPARE = 15   -- 宝藏已被其他玩家占领

OCCUPYING_LIMIT_TIME = 180 -- 占领过程最长时间

REWARD_CYCLE = TDConfig[1].REWARD_CYCLE or 60  -- 奖励计算的周期 

MIN_MINE_CNT = TDConfig[1].MIN_MINE_CNT or 10  -- 最少夺宝区域数量 -- ????
MAX_MINE_CNT = TDConfig[1].MAX_MINE_CNT or 100  -- 最大夺宝区域数量-- ????
DEF_MINE_CNT = TDConfig[1].DEF_MINE_CNT or 100  -- 默认夺宝区域数量-- ????
FORCE_REFRESH_INTERVAL = TDConfig[1].FORCE_REFRESH_INTERVAL or 600 -- 强制刷新地图间隔
WIN       = 0
DEFEATED  = 1

OCCUPY_DURATION = TDConfig[1].OCCUPY_DURATION or 3600*4   -- 占领时长
-- OCCUPY_ENERGY = 0          -- 每次占领消耗经验

-- EXTEND_LIMIT_PER_MINE  =  1         -- 每个矿延长占领次数限制
-- EXTEND_RMB    =  5         -- ????
EXTEND_DURATION   = TDConfig[1].EXTEND_DURATION or 3600*4         -- 每次延长占领时长



MODE_FIGHT = 'fight' -- 出战
MODE_GUARD = 'guard' -- 调整阵型


-- ROB_RATE = 0.3        -- 可以掠夺的比例

-- LEVEL_LIMIT = 1      -- 战队等级限制

SAFE_DURATION = TDConfig[1].SAFE_DURATION or 3600*4  -- 保护时长
-- SAFE_RMB = 5            -- 一次保护消耗的钻石

DOUBLE_DURATION = TDConfig[1].DOUBLE_DURATION or 3600*4  -- 双倍收益小时数
-- DOUBLE_RMB      = 5       -- 双倍收益消耗的钻石

-- OCCUPY_LIMIT    = 5       -- 每日抢夺次数限制


MINE_STATUS = 
{
	Idle = 1,
	Occupying = 2,
	Occupied = 3,
}

MINE_RANK =
{
	[1] = {name='青铜矿',rate=1},
	[2] = {name='白银矿',rate=1.2},
	[3] = {name='黄金矿',rate=1.4},
}

MINE_NUM_PER_BATCH = 6  --每个界面矿的数量

-- MAP_REFRESH_INTERVAL = 5*60  -- 地图刷新间隔时间

MAX_MINE_PER_PLAYER = 2   -- 每个玩家最大可以拥有的宝藏数量
-- MAX_ASSIST_PER_PLAYER = 2 -- 每个玩家最大可以协助的宝藏数量
-- MAX_ASSIST_PER_MINE = 2 -- 每个宝藏最大可以协助数量

FIGHT_TIMES_PER_DAY = TDConfig[1].FIGHT_TIMES_PER_DAY or 5  -- 每日挑战次数
REFRESH_MAP_PER_DAY = TDConfig[1].REFRESH_MAP_PER_DAY or 5  -- 每日刷新地图次数
EXTEND_TIMES_PER_DAY = TDConfig[1].EXTEND_TIMES_PER_DAY or 3  -- 每日延长占领次数
SAFE_TIMES_PER_DAY = TDConfig[1].SAFE_TIMES_PER_DAY or 3  -- 每日保护次数
DOUBLE_TIMES_PER_DAY = TDConfig[1].DOUBLE_TIMES_PER_DAY or 3  -- 每日双倍收益次数

-- CMD_DISPATCH = 0
-- CMD_RETURN = 1

-- ASSIST_REWARD_RATE = 0.2     -- 协助的收益率

-- SAFETIME_SHOPID = 1006
-- DOUBLE_SHOPID = 1005
-- EXTEND_SHOPID = 1007


REC_OCCUPY_SUCCESS = 1        -- 占领成功
REC_ROB_SUCCESS = 2           -- 抢夺成功
REC_DEFENCE_SUCCESS =3        -- 防御成功
REC_DEFENCE_FAIL = 4          -- 防御失败
REC_FINISH = 5                -- 开采完毕

REC_TYPE_NAME = 
{
	[REC_OCCUPY_SUCCESS] = {name="占领成功"},
	[REC_ROB_SUCCESS] = {name = "抢夺成功"},
	[REC_DEFENCE_SUCCESS] = {name = "防御成功"},
	[REC_DEFENCE_FAIL] = {name = "防御失败"},
	[REC_FINISH] = {name = "开采完毕"},
}

REC_RESERVE_DAY = TDConfig[1].REC_RESERVE_DAY or 10          -- 收益记录保留天数
REC_RESERVE_CNT = TDConfig[1].REC_RESERVE_CNT or 30          -- 收益记录保留条数

DEF_BODY_ID = 5


Consume = {
	EXTEND = 1,
	SAFE = 2,
	DOUBLE = 3,
}

FINISH_MAIL_ID					= 5 --开采完毕邮件
DEFEATED_MAIL_ID				= 6 --防御失败邮件
ABANDON_MAIL_ID					= 7 --放弃宝藏邮件