module(...,package.seeall)

FRONT_COUNT			= 150	--前150名

ROLE_LV_LIMIT_MIN 	= 20	--远征最小开启等级

HERO_LV_LIMIT_MIN 	= 5		--英雄最小上阵等级

BATTLE_MIN_LV		= 10	--上阵最低等级

COPY_NUM			= 15	--关卡数量

TEAM_MEMBER_NUM		= 4 	--战队正式成员数(不包括援助)

SHOP_ITEM_COUNT				=	8		--商店物品数

SHOP_REFRESH_COST 			=	100		--刷新所需钻石

COPY_END_SUCCESS 			=	1 		--赢了
COPY_END_FAIL				=	0		--输了

OPEN_LV						= 	28		--开启等级

ITEM_ID						=   9901004	--巡回积分

NEXT_NO						=	0
NEXT_YES					=	1

ERR_CODE = 
{
	BuySuccess 	   			= 	0,
	BuyMaxBuyCount 			= 	1,		--已达到最大购买次数
	BuyMaxGetCount 			= 	2,		--已达到最大重置次数
	BuyNeedMoney  			= 	3,		--金币不足

	GetTreasureSuccess 		=	10,		--获取宝藏成功
	GetTreasureHasGet		=	11,		--已经领取过了
	GetTreasureNoPass		=	12,		--未通过上一关卡 
	GetTreasureNoPossible 	=	13,		--获取宝藏之不可能错误

	ResetSuccess			=	20,		--重置成功
	ResetHasTreasureNotGet	=	21,		--还有宝藏未领取
	ResetHasNotCount		=	22,		--重置次数不足

	EnterSuccess			=	30,		--进入成功
	EnterCD					=	31,		--援助CD内
	EnterDie				=	32,		--已经阵亡
	EnterNoHero				=	33,		--英雄不存在
	EnterFinish				=	34,		--远征已结束
	EnterNoPossiblel		=	35,		--不可能错误


	ShopSuccess				=	40,		--购买成功
	ShopBagFull				=	41,		--背包已满
	ShopGemNotEnought		=	42,		--宝石不够
	ShopItemNotExist		=	43,		--物品不存在
	ShopConfigError			=	44,		--远征商店配置id不存在
	ShopRefreshSuccess		=	45,		--刷新成功
	ShopRefreshNoMoney		=	46,		--金币不足
	ShopHasBuy				=	47,		--已经购买过了

	CopyEndSuccess			=	50,		--副本通关
	CopyEndFail				=	51,		--副本失败

	ClearSuccess			=	60,
	ClearFail				=	61,
}
ERR_TXT =
{
	[ERR_CODE.BuySuccess] 				= 	"购买成功！",
	[ERR_CODE.BuyMaxBuyCount] 			= 	"已达到最大购买次数！",
	[ERR_CODE.BuyMaxGetCount] 			= 	"已达到最大重置次数！",
	[ERR_CODE.BuyNeedMoney] 			= 	"钻石不足！",

	[ERR_CODE.GetTreasureSuccess] 		= 	"获取宝藏成功",
	[ERR_CODE.GetTreasureHasGet] 		= 	"已经领取过了",
	[ERR_CODE.GetTreasureNoPass] 		= 	"未通过上一关卡",
	[ERR_CODE.GetTreasureNoPossible] 	= 	"获取宝藏之不可能错误",

	[ERR_CODE.ResetSuccess]				=	"重置成功",
	[ERR_CODE.ResetHasTreasureNotGet]	=	"还有宝藏未领取",
	[ERR_CODE.ResetHasNotCount]			=	"重置次数不足",

	[ERR_CODE.EnterSuccess]				=	"进入成功",
	[ERR_CODE.EnterCD]					=	"援助CD时间内不能入阵",
	[ERR_CODE.EnterDie]					=	"不能选择阵亡英雄",
	[ERR_CODE.EnterNoHero]				=	"英雄不存在",
	[ERR_CODE.EnterFinish]				=	"远征已结束",
	[ERR_CODE.EnterNoPossiblel]			=	"远征之不可能错误",

	[ERR_CODE.ShopSuccess]				=	"购买成功",
	[ERR_CODE.ShopBagFull]				=	"背包已满",
	[ERR_CODE.ShopGemNotEnought]		=	"巡回币不足",
	[ERR_CODE.ShopItemNotExist]			=	"物品不存在",
	[ERR_CODE.ShopConfigError]			=	"远征商店配置id不存在",
	[ERR_CODE.ShopRefreshSuccess]		=	"刷新成功",
	[ERR_CODE.ShopRefreshNoMoney]		=	"钻石不足",
	[ERR_CODE.ShopHasBuy]				=	"已经购买过了",

	[ERR_CODE.CopyEndSuccess]			=	"副本通关",
	[ERR_CODE.CopyEndFail]				=	"副本失败",

	[ERR_CODE.ClearSuccess]				=	"扫荡成功",
	[ERR_CODE.ClearFail]				=	"扫荡失败",
}
