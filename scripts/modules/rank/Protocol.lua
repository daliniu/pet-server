module(...,package.seeall)

--查询排行榜
RankData = {
	{"name",					"string",				"名字"},
	{"lv",						"int",					"等级"},
	{"icon",					"string",				"头像"},
	{"fight",					"int",					"战斗力"},
	{"flowerCount",				"int",					"鲜花数"},
	{"quality",					"int",					"星级"},
}

CGRankList = {
	{"type",					"int",					"查询类型"},
}

GCRankList = {
	{"rankList",				RankData,				"排行列表",			"repeated"},
}

--查询个人信息
HeroInfo = {
	{"name",					"string",				"名字"},
	{"lv",						"int",					"等级"},
	{"quality",					"int",					"品阶"},
}
RankInfo = {
	{"rank",					"int",					"排行"},
	{"bodyId",					"string",				"头像"},
	{"lv",						"int",					"等级"},
	{"name",					"string",				"名字"},
	{"fightVal",				"int",					"战斗力"},
	{"win",						"int",					"赢数"},
	{"guild",					"string",				"公会"},
	{"flowerCount",				"int",					"鲜花数"},
	{"fightList",				HeroInfo,				"英雄",				"repeated"},
}

CGRankCheck = {
	{"type",					"int",					"查询类型"},
	{"rank",					"int",					"排行"},
}

GCRankCheck = {
	{"info",					RankInfo,				"个人信息"},
}
