module(...,package.seeall)

GUILD_BOSS_ID = 90501
GUILD_BOSS_MAX_ID = 90600

BOSS_REFRESH_HP_RATE = 1000   --血量刷新频率
--BOSS_HURT_RANK_RATE = 60 * 1000   --boss伤害排行榜
BOSS_HURT_RANK_RATE = 1000   --boss伤害排行榜
BOSS_DURING_TIME = 1800

BOSS_STATUS_START = 1
BOSS_STATUS_END = 2

BOSS_ENTER_CD = 120

BOSS_ENTER_RET = {
	kOk = 1,
	kNoGuild = 2,
	kActEnd = 3,
	kBossDie = 4,
	kBossEnterCD = 5,
}

BOSS_ENTER_QUERY_RET = {
	kOk = 1,
	kNoGuild = 2,
	kActEnd = 3,
	kBossDie = 4,
	kBossEnterCD = 5,
}

BOSS_HURT_RET = {
	kOk = 1,
	kNoGuild = 2,
	kNoBoss = 3,
}

BOSS_LEAVE_RET = {
	kOk = 1,
	kNoGuild = 2,
}

BOSS_REWARD_TYPE_HURT = 1
BOSS_REWARD_TYPE_RANK = 2
BOSS_REWARD_TYPE_LAST = 3

BOSS_MAIL_RANK			= 20	--排行榜奖励
BOSS_MAIL_HURT			= 21	--伤害奖励
BOSS_MAIL_LAST			= 22	--最后一击奖励
