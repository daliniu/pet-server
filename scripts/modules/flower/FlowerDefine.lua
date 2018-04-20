module(...,package.seeall) 
FLOWER_SEND_COUNT 	= 0		--每日可获得奖励赠送鲜花数
FLOWER_RANK_COUNT	= 30	--排行榜数据


FLOWER_TYPE_ONE	  	= 1		--一枝花
FLOWER_TYPE_NINE	= 2		--九枝花
FLOWER_TYPE_NINE_N	= 3		--九九花

FLOWER_FROM_TYPE_TALK			= 1 --聊天频道
FLOWER_FROM_TYPE_GUILD			= 2	--帮会
FLOWER_FROM_TYPE_RANK_ARENA		= 3 --竞技场排行榜
FLOWER_FROM_TYPE_RANK_FIGHT		= 4 --战斗力排行榜
FLOWER_FROM_TYPE_RANK_FLOWER	= 5 --鲜花排行榜
FLOWER_FROM_TYPE_BOSS			= 6 --世界Boss
FLOWER_FROM_TYPE_TRIAL			= 7 --闯关
FLOWER_FROM_TYPE_ARENA			= 8 --竞技场
FLOWER_FROM_TYPE_CRAZY			= 9 --疯狂之源
FLOWER_FROM_TYPE_ACC			= 10--账号

FLOWER_MAIL_ID					= 16 --鲜花邮件

FLOWER_LIMIT_LV					= 12
FLOWER_LIMIT_RECEIVE_COUNT		= 20
FLOWER_LIMIT_SHOW_COUNT			= 6

FLOWER_PHY_MAX					= 50 --被增者可获得最大体力
FLOWER_COST_TYPE_MONEY			= 1
FLOWER_COST_TYPE_RMB			= 2

FLOWER_COST_CURRENCY			= 1
FLOWER_COST_SECTION				= 2
FLOWER_COST_COST				= 3

ERR_CODE = 
{
	GiveSuccess 	   			= 	0,	--成功
	GiveFailMoney				=	1,	--金币不足
	GiveFailRmb					= 	2,	--钻石不足
	GiveFailVipNoLevel			=	3,	--vip等级不够
	GiveFailNoFlowerType		=	4,	--鲜花类型错误
	GiveFailNoGive				=	5,	--不能再赠送
	GiveFailNoPlayer			=	6,	--玩家不存在
	GiveFailNoSelf				=	7,	--不能是自己
	GiveFailNoLv				=	8,  --战队等级不足
}

ERR_TXT =
{
	[ERR_CODE.GiveSuccess] 				= 	"获取成功！",
	[ERR_CODE.GiveFailMoney] 			= 	"金币不足！",
	[ERR_CODE.GiveFailRmb] 				= 	"钻石不足！",
	[ERR_CODE.GiveFailVipNoLevel] 		= 	"Vip等级不够！",
	[ERR_CODE.GiveFailNoFlowerType] 	= 	"鲜花类型错误！",
	[ERR_CODE.GiveFailNoGive]			=	"只能赠送一次",
	[ERR_CODE.GiveFailNoPlayer]			=	"玩家不存在",
	[ERR_CODE.GiveFailNoSelf]			=	"鲜花只能赠送给其他玩家",
	[ERR_CODE.GiveFailNoLv]				=	"战队等级不足",
}
