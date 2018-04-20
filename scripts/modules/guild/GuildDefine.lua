module(...,package.seeall)

SAVEDB_INTERVAL = 300

GUILD_START_ID = 10000

GUILD_LEADER = 1	--会长
GUILD_SENIOR = 2	--长老
GUILD_NORMAL = 3	--帮众

GUILD_CREATE_RET = {
	kOk = 1,		--创建成功
	kNameExist = 2,	--公会名已经存在
	kHasGuild = 3,	--已经在公会中
	kNotLv = 4,		--等级不够
	kNotRmb = 5,		--金币不够
	kNameInVaild = 6,		--名字无效
	kNameLen = 7,		--名字长度不符
}

GUILD_APPLY_RET = {
	kOk = 1,		--申请成功
	kHasGuild = 2,	--已经在公会中
	kNotExist = 3,	--公会不存在
	kGuildCD = 4,	--加入公会冷却中
	kHasApply = 5, --已经申请过
}

GUILD_APPLY_CANCEL_RET = {
	kOk = 1,		--取消申请成功
	kNotExist = 2,	--公会不存在
	kHasGuild = 3,	--已经在公会中
}

GUILD_APPLY_QUERY = {
	kOk = 1,		--查询成功
	kNotGuild = 2,	--不在公会中
	kNoAuth = 3,	--没有权限
}

GUILD_MEMBER_QUERY = {
	kOk = 1,		--查询成功
	kNotGuild = 2,	--不在公会中
}

GUILD_ACCEPT = {
	kAgree = 1,		--同意
	kReject= 2,		--拒绝
}

GUILD_ACCEPT_RET = {
	kOk = 1,	--操作成功
	kNoGuild = 2,	--没有公会
	kNoMember= 3,	--不是公会成员
	kNoAuth = 4,	--没有权限
	kMaxMem = 5,	--人数已满
	kHasGuild = 6,	--对方已经有公会
}

GUILD_MEM_OPERATE = {
	kAppoint = 1,		--任命长老
	kPassto  = 2,		--转交会长
	kKickoff = 3,		--踢出公会 
	kRemove  = 4,		--卸任长老
}

GUILD_MEM_OPERATE_RET = {
	kOk = 1,			--操作成功
	kNoGuild = 2,		--没有公会
	kNoMember = 3,		--对象不是公会成员
	kNoAuth = 4,		--没有权限
	kNoOperateOwn= 5,		--不能对自己操作
	kMaxSenior = 6,		--达到最大长老数量
}

GUILD_QUIT_RET = {
	kOk = 1,			--操作成功
	kNoGuild = 2,		--没有公会
	kNotExist = 3,		--公会不存在
	kNoMember = 4,		--对象不是公会成员
	kErrLeader = 5,		--会长不能退出公会
}

GUILD_DESTROY_RET = {
	kOk = 1,			--操作成功
	kNoGuild = 2,		--没有公会
	kNotExist = 3,	--公会不存在
	kNoMember = 4,		--对象不是公会成员
	kErrLeader = 5,		--只有会长能解散公会
	kHasMember = 6,		--不可解散公会
}
GUILD_MOD_ANNOUNCE_RET = {
	kOk = 1,			--操作成功
	kFail = 2,			--操作失败
	kSensitive = 3,			--有敏感词
}

GUILD_APPLYING = 1
GUILD_NOTAPPLY = 2

MAX_ACTIVE_GUILD_RANK = 30

QUIT_GUILD_CD = 3600
