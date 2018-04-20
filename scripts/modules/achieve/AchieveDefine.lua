module(..., package.seeall)

ACHIEVE_OPEN_LV			=	1	--成就开启等级

ACHIEVE_TEAM_LV			=	1	--战队等级
ACHIEVE_COLLECT			=	2 	--收集英雄
ACHIEVE_ACTIVATE		=	3	--激活伙伴
ACHIEVE_LV_UP			=	4	--伙伴升级
ACHIEVE_COPY			=	5 	--通关副本
ACHIEVE_OROCHI			=	6	--大蛇八杰
ACHIEVE_TRIAL			=	7	--闯关系统
ACHIEVE_EXPEDITION		=	8	--世界巡回赛
ACHIEVE_ARENA			=	9	--竞技场
ACHIEVE_POWER			=	10	--力量系统
ACHIEVE_WEAPON			=	11	--神兵系统


ACHIEVE_PARAM_TYPE		=	1	--类型
ACHIEVE_PARAM_ID		=	2 	--ID
ACHIEVE_PARAM_COUNT		=	3	--数量		


ACHIEVE_TYPE_HERO		=	1	--英雄成就
ACHIEVE_TYPE_COPY		=	2 	--副本成就
ACHIEVE_TYPE_TEAM		=	3	--战队成就


ACHIEVE_TARGET_LIST = {
	[1] 	= ACHIEVE_TEAM_LV,			--战队等级
	[2] 	= ACHIEVE_COLLECT,			--收集英雄
	[3] 	= ACHIEVE_ACTIVATE,			--激活伙伴
	[4] 	= ACHIEVE_LV_UP,			--伙伴升级
	[5] 	= ACHIEVE_COPY,				--通关副本
	[6] 	= ACHIEVE_OROCHI,			--大蛇八杰
	[7] 	= ACHIEVE_TRIAL,			--闯关系统
	[8] 	= ACHIEVE_EXPEDITION,		--世界巡回赛
	[9] 	= ACHIEVE_ARENA,			--竞技场
	[10] 	= ACHIEVE_POWER,			--力量系统
	[11] 	= ACHIEVE_WEAPON,			--神兵系统
}

ERR_CODE = 
{
	GetSuccess 	   			= 	0,
	GetFail					=	1,
}

ERR_TXT =
{
	[ERR_CODE.GetSuccess] 				= 	"获取成功！",
	[ERR_CODE.GetFail] 					= 	"获取失败！",
}