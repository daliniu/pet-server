module(...,package.seeall)

GridData = {
    {"id",      "int",  "静态表id"},
    {"pos",     "int",  "格子位置"},
    {"cnt",		"int",	"物品数量"},
    {"mtype",	"int",	"物品操作类型：1增2改3删"},
}

--请求背包数据
CGBagQuery = {
}

--- 背包 ---
--向前端发送道具列表
GCBagList = {
    {"op",      "int",		"背包更新操作码"},
    {"bagData", GridData,	"背包数组",		"repeated"},
}

--排序
CGBagSort = {
}

--扩充
CGBagExpand = {
}

GCBagExpand = {
	{"cap",	"int",	"扩充结果"}	--不需要操作码，有返回必定成功，失败情况前端已经过滤
}

--卖道具
CGItemSell = {
	{"pos",	"int",	"道具在背包的位置"},
	{"cnt",	"int",	"个数"}
}

GCItemSell = {
	{"money",	"int",	"出卖道具获得的钱"}
}

--使用道具
CGItemUse = {
	{"pos",	"int",	"道具在背包的位置"},
	{"cnt",	"int",	"个数"},
	{"argList",	"string",	"前端参数",	"repeated"},
}

GCItemUse = {
	{"ret",		"int",	"使用结果"},
	{"itemId",	"int",	"使用的道具Id"},
}

Reward = {
	{"titleId",	"int",	"标题id"},
	{"id",	"int",	"道具id"},
	{"num",	"int",	"道具数量"},
}

GCRewardTips = {
	{"rewards", 	Reward,		"奖励提示",		"repeated"}
}
