module(...,package.seeall)


CGHandbookInfo = 
{

}

HBINFO = 
{
	{"name","string","图鉴名称 hero/item"},
	{"status","int","图鉴奖励状态,0:已领取;2:已领取","repeated"},
}

GCHandbookInfo = 
{
	{"info",HBINFO,"图鉴","repeated"},
}

CGHandbookReward = 
{
	{"name","string","图鉴类型 hero英雄图鉴 item道具图鉴"},
	{"id","int","奖励id"},
}

GCHandbookReward = 
{
	{"result","int","结果"},
	{"name","string","图鉴类型 hero英雄图鉴 item道具图鉴"},
	{"id","int","奖励id"},
}

CGHandbookItemlib = 
{

}

GCHandbookItemlib = 
{
	{"itemId","int","lib中的ItemId","repeated"},
}
