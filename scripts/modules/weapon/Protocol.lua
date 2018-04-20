module(...,package.seeall)

--查询神兵
CGWeaponQuery = 
{
}

WeaponInfo = 
{
    {"wepId",     "int",      "神兵ID"},
    {"lv",     "int",      "等级"},
    {"exp",     "int",      "等级经验"},
    {"quality",   "int",      "品级"},
}

GCWeaponQuery = 
{
    {"list",   WeaponInfo,  "神兵列表", "repeated"},
}

--开启神兵
CGWeaponOpen = 
{
    {"wepId",      "int",      "神兵Id"},
}

GCWeaponOpen = 
{
    {"id",      "int",      "返回码附带Id"},
    {"ret",         "int",       "非0为非法码"},
}

--神兵升级
CGWeaponUpLv= 
{
    {"wepId",      "int",      "神兵Id"},
	{"itemId",		"int",		"物品Id"},
	{"count",		"int",		"数量"},
}

GCWeaponUpLv= 
{
    {"id",      "int",      "返回码附带Id"},
    {"ret",         "int",       "非0为非法码"},
    {"hasLvUp", "int",      "是否升级了"},
    {"wepId",   "int",          "神兵ID"},
    {"lv",      "int",      "级别"},
}

--神兵升品
CGWeaponUpQuality = 
{
    {"wepId",      "int",      "神兵Id"},
}

GCWeaponUpQuality = 
{
    {"id",      "int",      "返回码附带Id"},
    {"ret",         "int",       "非0为非法码"},
}
