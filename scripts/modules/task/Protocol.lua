module(...,package.seeall)


CGTaskList = 
{
}

TaskItem = 
{
	{"taskId",				"int",					"任务ID"},
	{"status",				"int",					"任务状态"},
	{"objNum",				"int",					"数量"},
	{"time",                 "int",                  "接受时间"},
}
GCTaskList = 
{
	{"taskList",			TaskItem,				"任务列表",			"repeated"},
	{"isUpdate",    		"int",      			"是否只更新"},
}

GCTaskDel = {
	{"taskId",				"int",					"任务ID"},
}

CGTaskGet = {
	{"taskId",				"int",					"任务ID"},
}

GCTaskGet = 
{
	{"ret",					"int",					"返回码"},
	{"taskId",				"int",					"任务ID"},
}

CGTaskJoin = 
{
	{"taskId",				"int",					"任务ID"},
}

GCTaskJoin = 
{
	{"ret",					"int",					"返回码"},
	{"taskId",				"int",					"任务ID"},
}

--检查有可做任务，12点刷新
CGTaskCheck = 
{ 
}





