module(...,package.seeall)

CGActivityInfo = 
{
	{"activityId","int","活动id"},
}

ACTIVITY = 
{
	{"status",'int','状态,0:未达成;1:以达成未领取;2:以领取'},
}
GCActivityInfo = 
{
	{"result","int","结果"},
	{"activityId","int","活动ID"},
	{"activity",ACTIVITY,"活动","repeated"},
}

CGActivityReward = 
{
	{"activityId","int","活动id"},
	{"id","int","活动奖励id"},
}

GCActivityReward = 
{
	{"result","int","结果"},
	{"activityId","int","活动id"},
	{"id","int","活动奖励id"},
	{"timestamp","int","时间戳"},
}

CGActivityTip = 
{
	{"activityId","int","活动id"},
	{"id","int","活动奖励id"},
}

GCActivityTip = 
{
	{"activityId","int","活动id"},
	{"id","int","活动奖励id"},
}

CGActivityMonthcardbuy = 
{
}

GCActivityMonthcardbuy = 
{
	{"result","int","结果"},
}

CGActivityMonthcardInfo = 
{

}

MONTHCARDINFO = 
{
	{"monthCardEndDay","int","月卡结束时间"},
	{"lastReceiveTime","int","上次领取时间"},
}
GCActivityMonthcardInfo = 
{
	{"monthCardInfo",MONTHCARDINFO,"月卡信息","repeated"},
	{"newBuy","int","是否是新的购买"},
}

CGActivityMonthcardReceive = 
{
	{"monthCardId","int","第几个月卡"},
}
GCActivityMonthcardReceive = 
{
	{"result","int","结果"},
	{"monthCardId","int","第几个月卡"},
}

CGActivityFoundationBuy = 
{

}

GCActivityFoundationBuy = 
{
	{"result","int","结果"},
	{"result2","int","结果2"},
}

CGActivityMonthcardReceive = 
{
	{"monthCardId","int","第几个月卡"},
}
GCActivityMonthcardReceive = 
{
	{"result","int","结果"},
	{"monthCardId","int","第几个月卡"},
}



CGActivityVipBuy = 
{
	{"id","int","vip id"},
}
GCActivityVipBuy = 
{
	{"id","int","vip id"},
	{"result","int","result"},
}

CGActivityVip = 
{
	{"id","int","vip id"},
}
GCActivityVip = 
{
	{"id","int","vip id"},
	{"status","int","状态"},
}


CGWheelOpen = 
{
}
GCWheelRet = 
{
    {"ret", "int", "轮盘结果"},
}
CGWheelClose = 
{
}
WheelData = 
{
    {"cname", "string", "玩家名"},
	{"id", "int", "轮盘奖励id"},
}
CGWheelQuery =
{
}
GCWheelInfo = 
{
    {"list", WheelData, "轮盘中奖列表", "repeated"},
}


CGActivityDb = 
{

}

ACTIVITYDB = {
	{"opened","int","是否开启"},
	{"minLv","int","最小等级"},
	{"maxLv","int","最大等级"},
	{"type","int","活动类型"},
	{"openDay","int","openDay"},
	{"startTime","string","生效时间"},
	{"endTime","string","失效时间"},
}
GCActivityDb = 
{
	{"actId","int","actId"},
	{"actDb",ACTIVITYDB,""},
}