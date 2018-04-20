module(...,package.seeall)

--查询
CGPowerQuery = 
{
}

Info = 
{
	{"powerId",     "int",      "力量ID"},
	{"lv",     		"int",      "等级"},
	{"exp",     	"int",      "等级经验"},
}

GCPowerQuery = 
{
	{"list",   		 Info,  "列表", "repeated"},
}

--开启神兵
CGPowerOpen = 
{
	{"powerId",      "int",      "力量Id"},
}

GCPowerOpen = 
{
	{"powerId",      "int",      "力量Id"},
	{"ret",          "int",      "非0为非法码"},
}

CGPowerUpgrade = 
{
	{"powerId",      "int",      "力量Id"},
}

GCPowerUpgrade= 
{
	{"ret",          "int",      "非0为非法码"},
	{"powerId",      "int",      "力量Id"},
	{"hasLvUp", 	 "int",       "是否升级了"},
	{"lv",      	 "int",      "级别"},
	{"exp",     	"int",      "等级经验"},
}



