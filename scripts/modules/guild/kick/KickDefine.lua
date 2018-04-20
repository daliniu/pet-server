module(...,package.seeall)

GUILD_QUERY_RET = {
	kOk = 1,
	kNoGuild = 2,
}

MEMBER_QUERY_RET = {
	kOk = 1,
	kNoGuild = 2,
}

KICK_BEGIN_RET = {
	kOk = 1,
	kNoGuild = 2,
	kNoArena = 3,
	kNoCnt = 4, --今日次数不足
	kKickCD = 5,
}

WIN = 1
LOSE = 2

MAX_RECORD = 10

KICK_GUILD_NUM = 5
KICK_MEMBER_NUM = 5

KICK_DAYTIMES = 5
