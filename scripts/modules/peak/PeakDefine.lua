module(..., package.seeall)

HERO_COUNT			= 8		--英雄阵容数
HERO_DEL_COUNT		= 3		--去掉英雄数
SEARCH_TIME			= 5		--搜索时间
CRONTAB_PEAK		= 8
SEARCH_CHECK_RATE	= 1000

OP_DISSELECT		= 0
OP_SELECT			= 1

HUMAN				= 0
ROBOT				= 1

RESULT_FAIL			= 0
RESULT_SUCCESS		= 1
RESULT_ING			= 2
RESULT_RUN			= 3

TEAM_HERO_COUNT		= 4
TEAM_HERO_SELECT	= 5	

FIGHT_RECORD_COUNT	= 30	--最大记录数

DIR_LEFT			= 1
DIR_RIGHT			= 2

END_FAIL			= 0
END_SUCCESS			= 1

SHOP_ITEM_COUNT		=	8		--商店物品数

ERR_CODE = 
{
	CONFIRM_SUCCESS 		= 1, 
	CONFIRM_FAIL			= 2,

	RESET_SUCCESS			= 11,
	RESET_NO_MONEY			= 12,
	RESET_NO_IN_COOL_TIME	= 13,

	ShopSuccess				= 20,		--购买成功
	ShopBagFull				= 21,		--背包已满
	ShopGemNotEnought		= 22,		--积分不够
	ShopItemNotExist		= 23,		--物品不存在
	ShopConfigError			= 24,		--巅峰商店配置id不存在
	ShopRefreshSuccess		= 25,		--刷新成功
	ShopRefreshNoMoney		= 26,		--金币不足
	ShopHasBuy				= 27,		--已经购买过了
}

ERR_TXT =
{
	[ERR_CODE.CONFIRM_SUCCESS]			= "调整阵容成功",
	[ERR_CODE.CONFIRM_FAIL]				= "选择的英雄个数不足",
	[ERR_CODE.RESET_SUCCESS]			= "重置成功",
	[ERR_CODE.RESET_NO_MONEY]			= "不够钱",
	[ERR_CODE.RESET_NO_MONEY]			= "不够钱",
	[ERR_CODE.RESET_NO_IN_COOL_TIME]	= "不在冷却时间内",


	[ERR_CODE.ShopSuccess]				= "购买成功",
	[ERR_CODE.ShopBagFull]				= "背包已满",
	[ERR_CODE.ShopGemNotEnought]		= "巅峰币不足",
	[ERR_CODE.ShopItemNotExist]			= "物品不存在",
	[ERR_CODE.ShopConfigError]			= "巅峰商店配置id不存在",
	[ERR_CODE.ShopRefreshSuccess]		= "刷新成功",
	[ERR_CODE.ShopRefreshNoMoney]		= "钻石不足",
	[ERR_CODE.ShopHasBuy]				= "已经购买过了",
}
