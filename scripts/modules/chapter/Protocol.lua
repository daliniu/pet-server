module(...,package.seeall)


LEVEL = 
{
	{'difficulty','int','难度'},
	{"levelId","int","副本id"},
	{"time","int","上次通关或者扫荡时间"},
	{"timesForDay","int","当天通关或者扫荡次数"},
	{"buyTimes","int","当天购买的可通关次数的次数"},
	{"star","int","星级"},
}

BOX = {
	{"chapterId","int","章节id"},
	{"difficulty","int","困难id"},
	{"boxId","int","boxId"},
}
GCChapterList = 
{
	{"boxList",BOX,"已领取的宝箱列表","repeated"},
	{"levelList",LEVEL,"章节列表","repeated"},
	{'fightheroes',"string","出战英雄","repeated"},
}

CGChapterFbStart = 
{
	{"levelId","int","关卡id"},	
	{"difficulty","int","难度"},

}

GCChapterFbStart = 
{
	{"levelId","int","关卡id"},
	{"difficulty","int","难度"},
	{"ret","int","结果码"},
	{"level",LEVEL,"副本情况"},
}

CGChapterFbEnd = 
{
	{"levelId","int","关卡id"},
	{"difficulty","int","难度"},
	{"result","int","副本结果"},
	{"heroes","string","出战英雄","repeated"},
	{"star","int","星级"},
}

REWARD = 
{
	{"rewardName","string","奖励类型 money/heroExp/charExp/其他为道具id"},
	{"cnt","int","奖励数量"},
}

REWARDLIST =
{
	{"reward",REWARD,"一次扫荡产生的奖励","repeated"},
	{"charLv","int","奖励后的战队等级"},
	{"charLvPercent","int","奖励后战队当前等级经验条"},
}

GCChapterFbEnd = 
{
	{"levelId","int","关卡id"},
	{"difficulty","int","难度"},
	{"result","int","服务器端确认的副本结果"},
	{"level",LEVEL,"副本情况"},
	{"reward",REWARD,"奖励列表","repeated"},
	{"star","int","当次星级"},
}

CGChapterFbWipe = 
{
	{"levelId","int","关卡id"},
	{"difficulty","int","难度"},
	{"cnt","int","扫荡次数"},
}

GCChapterFbWipe = 
{
	{"levelId","int","关卡id"},
	{"difficulty","int","难度"},
	{"result","int","扫荡结果"},
	{"level",LEVEL,"副本情况"},
	{"rewardList",REWARDLIST,"奖励列表","repeated"},
}

CGChapterBoxReward = 
{
	{'chapterId',"int","要领取宝箱的章节id"},
	{'difficulty','int',"难度id"},
	{'boxId',"int","第几个宝箱"},
}

GCChapterBoxReward = 
{
	{'result',"int","领取结果"},
	{'chapterId',"int","要领取宝箱的章节id"},
	{'difficulty','int',"难度id"},
	{'boxId',"int","第几个宝箱"},
}

CGChapterRank = 
{
}

RANKITEM = 
{
	{'bodyId','int',"战队头像id"},
	{'charName',"string","战队名字"},
	{'lv',"int","战队等级"},
	{'star','int',"行星数量"},
	{'levelId','int',"关卡进度"},
}
GCChapterRank = 
{
	{"rankList",RANKITEM,"排行榜item","repeated"}
}
CGChapterDebugflag = 
{

}

GCChapterDebugflag = 
{
	{'debugFlag','int','调试开关 1=打开调试'},
}

CGChapterBuytimes = 
{
	{'levelId',"int","副本id"},
	{'difficulty','int','难度'},
	{'no',"int","第几次购买"},
}

GCChapterBuytimes = 
{
	{'result','int','结果'},
	{'levelId',"int","副本id"},
	{'difficulty','int','难度'},
	{'no',"int","第几次购买"},
}

-- CGChapterClearcd =
-- {
-- 	{"levelId","int","关卡id"},
-- 	{"difficulty","int","难度"},
-- }

-- GCChapterClearcd = 
-- {
-- 	{"result","int","结果"},
-- 	{"levelId","int","关卡id"},
-- 	{"difficulty","int","难度"},
-- }