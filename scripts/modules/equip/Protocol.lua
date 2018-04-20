module(...,package.seeall)

--查询装备
CGEquipList= {
	{"heroName",      "string",      "英雄"},
}

EquipData = {
	{"c",		"int",		"品质"},
	{"lv",			"int",		"等级"},
}

GCEquipList = {
	{"heroName",      "string",      "英雄"},
    {"list",   EquipData,  "装备列表",		"repeated"},
}

--装备升等级
CGEquipLvUp = {
	{"heroName",      "string",      "英雄"},
	{"pos",      "int",      "装备槽位"},
	{"cnt",      "int",      "强化次数"},
}

GCEquipLvUp= {
	{"err",      "int",      "进阶返回码"},
}

--装备升品质
CGEquipColorUp = {
	{"heroName",      "string",      "英雄"},
	{"pos",      "int",      "装备槽位"},
}

GCEquipColorUp = {
	{"err",      "int",      "合成返回码"},
}

GCEquipListAll = {
    {"list",   GCEquipList,  "所有英雄装备列表",		"repeated"},
}
