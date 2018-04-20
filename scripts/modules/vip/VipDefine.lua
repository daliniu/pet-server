module(..., package.seeall)

VIP_EXPEDITION_RESET 	= "expeditionResetCount"	--远征重置购买次数
VIP_CLEAR_TICKET		= "clearTicketCount"		--每次领取扫荡券数量
VIP_PHYSICS				= "physicsCount"			--体力购买次数
VIP_MONEY				= "moneyCount"				--购买金币次数
VIP_ARENA				= "arenaCount"				--购买竞技场次数
VIP_CHAPTER_RESET		= "chapterCount"			--重置关卡次数
VIP_FLOWER				= "flowerCount"				--鲜花次数
VIP_OROCHI				= "orochiCount"				--大蛇八杰付费挑战次数
VIP_TRIAL				= "trialCount"				--闯关购买次数
VIP_TREASURE_EXTEND		= "treasureExtendCount"		--夺宝延长占领
VIP_TREASURE_DOUBLE		= "treasureDoubleCount"		--夺宝双倍收益
VIP_TREASURE_SAFE		= "treasureSafeCount"		--夺宝保护时间
VIP_TREASURE_GRAB		= "treasureGrabCount"       --夺宝抢夺次数

VIP_MAX_LV				= 13--最大vip等级
VIP_RECHARGE_EXP		= 10--人民币折算vip升级经验比

VIP_DAILY_NO_GET		= 0	--未领取
VIP_DAILY_GET			= 1 --领取
VIP_DAILY_NO_ENOUGH		= 2 --未达条件

VIP_LEVEL_TIMES         = 5 -- 挑战次数

ERR_CODE = 
{
	OK					= 0,
	BUY_SUCCESS 		= 1, 
	BUY_FAIL 			= 2,
	BUY_GET				= 3,
	BUY_NO_MONEY		= 4,
	RECHARGE_SUCCESS	= 5,
	RECHARGE_FAIL		= 6,
	DAILY_SUCCESS		= 7,
	DAILY_FAIL			= 8,
	NOTPERMITTED        = 9,
	LIMIT 				= 10,

}

WIN       = 0
DEFEATED  = 1

ERR_TXT =
{
	[ERR_CODE.BUY_SUCCESS]		= "购买成功",
	[ERR_CODE.BUY_FAIL]			= "Vip等级不够",
	[ERR_CODE.BUY_GET]			= "已经购买过了",
	[ERR_CODE.BUY_NO_MONEY]		= "钱不够",
	[ERR_CODE.RECHARGE_SUCCESS] = "充值成功",
	[ERR_CODE.RECHARGE_FAIL]	= "充值失败",
	[ERR_CODE.DAILY_SUCCESS]	= "领取成功",
	[ERR_CODE.DAILY_FAIL]		= "领取失败",
}
