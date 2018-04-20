module(...,package.seeall)

--世界boss查询
CGWorldBossQuery = {
}


GCWorldBossQuery = {
	{"hasStart",				"int",				"是否已经开始"},
	{"countDownTime",			"int",				"开启倒计时"},
	{"coolTime",				"int",				"冷却时间"},
	{"hurt",					"int",				"伤害"},
}

--挑战
CGWorldBossEnter = {
	{"heroNameList",			"string",			"英雄列表",			"repeated"},
}

GCWorldBossEnter = {
	{"retCode",					"int",				"返回码"},
	{"hp",						"int",				"boss血量"},
	{"heroNameList",			"string",			"英雄列表",			"repeated"},
}

--排行榜
RankData = {
	{"rank",					"int",				"排名"},
	{"name",					"string",			"战队名"},
	{"icon",					"int",				"战队头像"},
	{"lv",						"int",				"战队等级"},
	{"hurt",					"int",				"伤害"},
	{"guild",					"string",			"公会名"},
}

CGWorldBossRank = {
}

GCWorldBossRank = {
	{"rankList",				RankData,			"排行列表",			"repeated"},
}

--查看阵容
HeroData = {
	{"name",					"string",			"英雄名"},
	{"lv",						"int",				"等级"},
	{"quality",					"int",				"品阶"},
}

CGWorldBossCheckTeam = {
	{"rank",					"int",				"排名"},
}

GCWorldBossCheckTeam = {
	{"rank",					"int",				"排名"},
	{"fighting",				"int",				"战斗力"},
	{"flowerCount",				"int",				"鲜花数"},
	{"heroList",				HeroData,			"英雄列表",			"repeated"},
}

--伤血
CGWorldBossHurtHp = {
	{"hurtHp",					"int",				"伤害"},
}

--boss hp 刷新
GCWorldBossRefreshHp = {
	{"hp",						"int",				"血量"},
}

--世界boss开启
GCWorldBossOpen = {
}

--世界boss结束
GCWorldBossEnd = {
	{"endType",					"int",				"结束类型"},
}

--退出战斗场景
CGWorldBossLeaveCopy = {
}
