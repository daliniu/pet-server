module(...,package.seeall)

BOSS_ID					=	90301	--世界bossId
BOSS_SYSTEM_DEC_HP_RATE = 	1000	--扣血频率(毫秒)
BOSS_CONTINUE_TIME		=	1800	--BOSS持续时间(秒)
BOSS_OPEN_LV			=	30		--开启等级
BOSS_BATTLE_TIME		=	120		--战斗冷却时间(秒)
BOSS_RANK_SORT_TIME		=	10 		--排序时间(秒)
BOSS_RANK_COUNT			=	10 		--需要显示的排行数

BOSS_REWARD_TYPE_HURT	= 1		--伤害奖励
BOSS_REWARD_TYPE_RANK	= 2		--排行奖励
BOSS_REWARD_TYPE_LAST	= 3		--最后一击奖励

BOSS_END_DIE			= 1		--打死
BOSS_END_TIME_OUT		= 2		--时间结束

BOSS_MAIL_RANK			= 10	--排行榜奖励
BOSS_MAIL_HURT			= 11	--伤害奖励
BOSS_MAIL_LAST			= 12	--最后一击奖励

ERR_CODE = 
{
	ENTER_SUCCESS 	= 0,
	ENTER_NO_HERO 	= 1,			--必须得放入英雄
	ENTER_NO_LV		= 2,			--不够级别
	ENTER_COOL_TIME = 3,			--冷却时间未到
	ENTER_NOT_START = 4,			--世界boss未开启
}

ERR_TXT =
{
	[ERR_CODE.ENTER_SUCCESS] 	= "进入成功！",
	[ERR_CODE.ENTER_NO_HERO] 	= "必须得放入英雄",
	[ERR_CODE.ENTER_NO_LV]		= "不够级别",
	[ERR_CODE.ENTER_COOL_TIME]	= "冷却时间未到",
	[ERR_CODE.ENTER_NOT_START] 	= "世界boss未开启",  
}
