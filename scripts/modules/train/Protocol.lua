module(...,package.seeall)

CGTrainQuery = {
	{"name",	"string",	"英雄名"},
}

TrainAttr = {
	{"name",	"string",	"属性名"},
	{"val",		"int",	"属性值"},
}

GCTrainQuery = {
	{"name",	"string",	"英雄名"},
	{"base",	TrainAttr,		"培养初始值",	"repeated"},
	{"current",	TrainAttr,		"当前培养值",	"repeated"}
}

GCTrainQueryAll = {
	{"queryAll",		GCTrainQuery,	"英雄培养查询",		"repeated"}
}

CGTrain = {
	{"name",	"string",	"英雄名"},
	{"mtype",		"int",	"培养类型"},
	{"cnt",		"int",	"培养次数"},
}

GCTrain = {
	{"name",	"string",	"英雄名"},
	{"ret",		"int",	"返回码"},
}

CGTrainAdd = {
	{"name",	"string",	"英雄名"},
}

GCTrainAdd = {
	{"name",	"string",	"英雄名"},
	{"ret",		"int",	"返回码"},
}
