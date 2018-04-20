module(...,package.seeall)

CGStrengthQuery = {
	{"name", "string", "英雄标识"}
}

StrengthGrid = {
	{"id",		"int",		"材料id"},
}

StrengthCell = {
	{"id",		"int",		"力量id"},
	{"lv",		"int",		"力量品阶"},	
	{"grids",	StrengthGrid,	"力量材料",		"repeated"}
}

GCStrengthQuery= {
	{"name", "string", "英雄标识"},
	{"transferLv",		"int",		"转职等级"},
	{"cells",	StrengthCell,	"力量",		"repeated"}
}

GCStrengthAll = {
    {"list", 		GCStrengthQuery,  "力量查询列表",		"repeated"},
}

CGStrengthLvUp = {
	{"name", "string", "英雄标识"},
	{"cellPos",		"int",		"要转职的力量"},
}
GCStrengthLvUp = {
	{"ret",		"int",		"力量进阶返回码"},
	{"name", "string", "英雄标识"},
	{"cellPos",		"int",		"要转职的力量"},
}

CGStrengthTransfer = {
	{"name", "string", "英雄标识"},
}
GCStrengthTransfer = {
	{"ret",		"int",		"力量转职返回码"},
	{"name", "string", "英雄标识"},
}

CGStrengthEquip = {
	{"name",		"string",	"英雄"},
	{"cellPos",		"int",		"力量位置"},
	{"gridPos",		"int",		"力量格子位置"},	
}

GCStrengthEquip = {
	{"name",		"string",	"英雄"},
	{"cellPos",		"int",		"力量位置"},
	{"gridPos",		"int",		"力量格子位置"},	
	{"ret",		"int",		"装备材料返回码"}
}

CGMaterialCompose = {
	{"id",		"int",		"需要合成的材料id"}
}

GCMaterialCompose = {
	{"ret",		"int",		"合成材料返回码"}
}

CGStrengthFragCompose = {
	{"id",		"int",		"碎片id"}
}

GCStrengthFragCompose = {
	{"ret",		"int",		"合成材料返回码"}
}

CGStrengthQuickEquip = {
	{"name", "string", "英雄标识"}
}

Pos = {
	{"cell",	"int",		"格子cell"},
	{"grid",	"int",		"格子grid"},
}

GCStrengthQuickEquip = {
	{"name", "string", "英雄标识"},
	{"ret",		"int",		"装备材料返回码"},
	{"pos",		Pos,		"一键装备返回格子",	"repeated"}
}
