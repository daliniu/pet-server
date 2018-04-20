module(...,package.seeall)

CGAnnounceQuery = {
}

Announce = {
	{"id",         "string", "id"},
	{"type",       "int", "公告类型"},
	{"pos",        "int", "公告位置"},
	{"startTime",  "int", "开启时间"},
	{"endTime",    "int", "结束时间"},
	{"hour",       "int", "定时时间"},
	{"min",        "int", "定时时间"},
	{"interval",   "int", "循环间隔"},
	{"title",      "string", "标题"},
	{"content",    "string", "内容"},
}

GCAnnounceQuery = {
	{"list",    	Announce, "公告","repeated"},
}

GCAnnounceAdd = {
	{"list",    	Announce, "公告","repeated"},
}

GCAnnounceDel = {
	{"id",         "string", "id"},
}


