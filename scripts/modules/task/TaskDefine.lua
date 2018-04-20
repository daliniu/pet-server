module(..., package.seeall)

Status = {
	CanDo = 1,
	Finish = 2,
	CanJoin = 3,
	Failure = 4,
}

TASK_TEAM_LV		=	1	--战队等级
TASK_COLLECT		=	2 	--收集英雄
TASK_EQUIP_OPEN		=	3	--激活伙伴
TASK_EQUIP_LV_UP	=	4	--伙伴升级
TASK_CHAPTER		=	5 	--通关副本
TASK_OROCHI			=	6	--大蛇八杰
TASK_TRIAL			=	7	--闯关系统
TASK_EXPEDITION		=	8	--世界巡回赛
TASK_ARENA			=	9	--竞技场
TASK_STRENGTH		=	10	--力量
TASK_WEAPON			=	11	--神兵系统
TASK_SKILL_LV		=	12	--技能升级
TASK_HERO_LV		=	13		--英雄升级
TASK_MONSTER		=	14		--挑战指定怪物
TASK_BOSS			=	15		--挑战世界boss
TASK_TREASURE		=	16		--夺宝
TASK_PHYSICS		=	17		--领取体力
TASK_SHOP			=	18		--商店寻宝
TASK_CHAPTER_DIFFICUTY	= 19		--按难度打副本
TASK_VIP			= 20		--VIP领取XX
TASK_FLOWER_CNT			= 21		--赠送鲜花次数
TASK_TRAIN			= 22		--培养
TASK_FLOWER_GETCNT			= 23		--获得鲜花
TASK_WEAPON_QUA_UP = 24		--神兵升阶
TASK_OROCHI_ID = 25		--大蛇
TASK_TRIAL_ID = 26		--战役
TASK_HERO_BREAK = 27		--英雄突破
TASK_HERO_STAR = 28		--英雄升星
TASK_SKILL_OPEN = 29     --激活技能
TASK_TRAIN_UP = 30     --钻石培养
TASK_SPA = 31     --温泉
TASK_UP_EQUIP= 32     --强化装备
TASK_CRAZY= 33     --疯狂之源
TASK_TOP_ARENA = 34     --巅峰竞技场


TASK_TYPE_CONF = 
{
	[TASK_TEAM_LV] = {needAdd=false},
	[TASK_COLLECT] = {needAdd=true},
	[TASK_EQUIP_OPEN] = {needAdd=true},
	[TASK_EQUIP_LV_UP] = {needAdd=false},
	[TASK_CHAPTER] = {needAdd=true},
	[TASK_OROCHI] = {needAdd=false,needWin=true,anyId=true},
	[TASK_TRIAL] = {needAdd=true,needWin=true,anyId=true},
	[TASK_EXPEDITION] = {needAdd=false},
	[TASK_ARENA] = {needAdd=true},
	[TASK_STRENGTH] = {needAdd=true},
	[TASK_WEAPON] = {needAdd=false},
	[TASK_SKILL_LV] = {needAdd=true},
	[TASK_HERO_LV] = {needAdd=false},
	[TASK_MONSTER] = {needAdd=true},
	[TASK_BOSS]	= {needAdd=true},
	[TASK_TREASURE]	= {needAdd=true,needWin=true},
	[TASK_PHYSICS]	= {needAdd=false,autoFinish=true,isTime=true},
	[TASK_SHOP]	= {needAdd=true},

	[TASK_CHAPTER_DIFFICUTY] = {needAdd=true},
	[TASK_VIP]	= {needAdd=false,autoFinish=true},
	[TASK_FLOWER_CNT]	= {needAdd=true},
	[TASK_TRAIN]	= {needAdd=true},
	[TASK_FLOWER_GETCNT]	= {needAdd=true},
	[TASK_WEAPON_QUA_UP]	= {needAdd=false},
	[TASK_OROCHI_ID]	= {needAdd=false},
	[TASK_TRIAL_ID]	= {needAdd=false},
	[TASK_HERO_BREAK]	= {needAdd=true},
	[TASK_HERO_STAR]	= {needAdd=true},
	[TASK_SKILL_OPEN]	= {needAdd=true},
	[TASK_TRAIN_UP]     = {needAdd=true},     --钻石培养
	[TASK_SPA]     = {needAdd=true},  
	[TASK_UP_EQUIP]     = {needAdd=true},  
	[TASK_CRAZY]     = {needAdd=true},  
	[TASK_TOP_ARENA]     = {needAdd=true},  
	

	
}



ERR_CODE = 
{
	GetSuccess 	   			= 	0,
	GetFail					=	1,
}

ERR_TXT =
{
	[ERR_CODE.GetSuccess] 				= 	"领取成功",
	[ERR_CODE.GetFail] 					= 	"任务尚未完成",
}






 