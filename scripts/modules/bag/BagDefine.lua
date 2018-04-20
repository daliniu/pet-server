module(...,package.seeall)

kCols = 4		--一排有多少个格子

BAG_OP = {
	kSendAll = 1,	--发送全部
	kSendLocal = 2,	--发送变化
}

USE_ITEM = {
	kItemUseOk = 0,		--道具使用成功
	kItemNotExist = 1,	--道具不存在
	kItemCanNotUse = 2,	--道具不能使用
	kItemNotEnoughGrid = 3,	--格子不够用
}

--道具分类号
ITEM_TYPE= {
	kEquip = 1101,	--小伙伴装备
	kHeroLvUp = 1201,	--英雄经验丹
	kWeaponLvUp = 1202,	--神兵经验丹
	kHero = 1401,	--英雄卡片
	kHeroFrag = 1402,	--英雄碎片
	kWeapon = 1501,		--神兵
	kWeaponFrag = 1502,	--神兵碎片
	kPartnerFrag = 1602,	--小伙伴碎片
	kPartnerLvupFrag = 1603,	--小伙伴升阶碎片
	kStrengthFrag = 1702,		--力量道具碎片
}

BAG_GRID_OP = {
	kAdd = 1,
	kChange = 2,
	kDel = 3,
}

REWARD_TIPS = {
	kSell = 1,
	kCompose = 2,
	kBuy = 3,
	kGet = 4,
	kGuildWine = 5,
	kGuildDonate = 6,
	kGetGift = 7,	--兑换礼品
}


ITEM_MONEY = 9901001
ITEM_RMB = 9901002
ITEM_PHY = 9901006
ITEM_BREAK = 2103001
ITEM_TALENT = 2102001
ITEM_BLACK_ATTR = 2101005
ITEM_EQUIP_UP = 2104001

ITEM_DRUG_ID = {
	[1] = 1201001,
	[2] = 1201002,
	[3] = 1201003,
}
