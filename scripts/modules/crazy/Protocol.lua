module(...,package.seeall)

GCCrazyNotify = {
	{"op",		"int",		"操作,1表示开启，2表示关闭"},
}

CGCrazyQuery = {
}

--[[
Rank = {
	{"name",	"string",	"名字"}
}
--]]
--排行榜
RankData = {
	{"rank",					"int",				"排名"},
	{"name",					"string",			"战队名"},
	{"icon",					"int",				"战队头像"},
	{"lv",						"int",				"战队等级"},
	{"harm",					"int",				"伤害"},
	{"guild",					"string",			"公会名"},
}

BossData = {
	{"isDie",	"int",	"是否死亡"},
	{"harm",	"int",	"已经扣血数"},
}

GCCrazyQuery = {
	{"isOpen",		"int",		"是否已开启"},
	--{"leftTime",	"int",		"剩余时间"},
	{"harm",		"int",		"伤害"},
	{"rank",		RankData,		"排名",		"repeated"},
	{"boss",		BossData,		"boss状态",		"repeated"}
}

CGCrazyRank = {
}

GCCrazyRank = {
	{"rankList",				RankData,			"排行列表",			"repeated"},
}


CGCrazyFight = {
	--{"index",				int,			"挑战下标",		},
}

GCCrazyFight = {
}

CGCrazySumit = {
	--{"index",				int,			"挑战下标",		},
	{"isDie",				"int",			"是否死亡",		},
	{"harm",				"int",			"伤害",		},
	{"heroList",			"string",		"英雄列表",		"repeated"}
}

--查看阵容
HeroData = {
	{"name",					"string",			"英雄名"},
	{"lv",						"int",				"等级"},
	{"quality",					"int",				"品阶"},
}

CGCrazyCheckTeam = {
	{"rank",					"int",				"排名"},
}

GCCrazyCheckTeam = {
	{"rank",					"int",				"排名"},
	{"fighting",				"int",				"战斗力"},
	{"flowerCount",				"int",				"鲜花数"},
	{"heroList",				HeroData,			"英雄列表",			"repeated"},
}

