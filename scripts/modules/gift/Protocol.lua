module(...,package.seeall)

CGGiftQuery = {
	--{"name", "string", "英雄标识"}
}

GiftData = {
	{"name", "string", "英雄名字"},
	{"id",	"int", "天赋id", "repeated"}
}

GCGiftQuery = {
	{"gift",	GiftData,	"天赋",	"repeated"}
}

CGGiftActivate = {
	{"name", "string", "英雄名字"},
	{"index","int","天赋下标"},
	{"buyCnt",	"int",	"购买次数"}
}

GCGiftActivate = {
	{"ret",	"int",	"返回结果"}
}

