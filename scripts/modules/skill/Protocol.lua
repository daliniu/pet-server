module(...,package.seeall)



--查看技能
CGSkillQuery = 
{
	{"heroName",      "string",      "英雄"},
}

GroupInfo = 
{
    {"groupId",     "int",      "技能组ID"},
    {"lv",     		"int",      "等级"},
    {"equipType",   "int",      "装备的位置"},
    {"isOpen",      "int",      "是否已开启"},
	{"exp",     	"int",      "等级经验"},
    --{"skillList",     "int",    "技能ID列表",	"repeated"},
}

GCSkillQuery = 
{
	{"heroName",      "string",      "英雄"},
    {"skillGroupList", GroupInfo,  "技能组列表",		"repeated"},
}

--技能升级
CGSkillUpgrade = 
{
	{"heroName",    "string",      "英雄"},
    {"groupId",     "int",         "技能组ID"},
    {"isOnce",     	"int",         "1表示一键强化,"},
}

GCSkillUpgrade = 
{
    {"ret",         "int",       "非0为非法码"},
	{"heroName",    "string",    "英雄"},
    {"skillGroupList", GroupInfo,  "技能组列表",		"repeated"},
}

--技能装配
CGSkillEquip = 
{
	{"heroName",    "string",     "英雄"},
    {"groupId",     "int",        "技能组ID"},
    {"equipType",   "int",      "装备的位置"},
}

GCSkillEquip = 
{
    {"ret",         "int",       "是否可装配,非0为非法码"},
	{"heroName",    "string",      "英雄"},
    {"skillGroupList", GroupInfo,  "技能组列表",		"repeated"},
}

CGSkillUnload = 
{
	{"heroName",    "string",     "英雄"},
    {"groupId",     "int",        "技能组ID"},
}
GCSkillUnload = 
{
    {"ret",         "int",       "非0为非法码"},
	{"heroName",    "string",      "英雄"},
    {"skillGroupList", GroupInfo,  "技能组列表",		"repeated"},
}
CGSkillExpUp = 
{
	{"heroName",    "string",     "英雄"},
    {"groupId",     "int",        "技能组ID"},
}

GCSkillExpUp = 
{
	{"ret",          "int",      "非0为非法码"},
	{"heroName",    "string",     "英雄"},
    {"groupId",     "int",        "技能组ID"},
	{"hasLvUp", 	 "int",      "是否升级了"},
	{"lv",      	 "int",      "级别"},
	{"exp",     	 "int",      "等级经验"},
}

GCSkillAll = 
{
    {"list", 		GCSkillQuery,  "技能组列表",		"repeated"},
}

CGSkillReset = {
	{"heroName",    "string",     "英雄"},
}
GCSkillReset = {}


--开启技能
CGSkillOpen = 
{
	{"heroName",    "string",      "英雄"},
    {"groupId",     "int",        "技能组ID"},
}

GCSkillOpen = 
{
    {"ret",         "int",       "非0为非法码"},
	{"heroName",    "string",      "英雄"},
    {"groupId",     "int",        "技能组ID"},
}



