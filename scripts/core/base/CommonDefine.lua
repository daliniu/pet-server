module("CommonDefine",package.seeall)

--本文件只放全局通用的常量定义
--那些功能模块的错误码，返回码等写到各自的模块定义文件中去

OK = 0

--- human enum ---
HUMAN_MAX_LEVEL = 80 --最大等级


-- 断开连接错误码
DISCONNECT_REASON_ANOTHER_CHAR_LOGIN    = 1        -- 角色在其它地方上线
DISCONNECT_REASON_CHANGE_TO_CROSS_SCENE = 2     -- 角色从游戏服切换到跨服副本服 游戏服断开连接
DISCONNECT_REASON_CROSS_SCENE_GAMING    = 3        -- 角色正在跨服副本中 无法登录 请先断开原连接
DISCONNECT_REASON_ADMIN_KICK            = 4                -- 管理后台踢人
DISCONNECT_REASON_SERVER_FULL           = 5               -- 服务器人满
DISCONNECT_REASON_FORBID_ACCOUNT        = 6            -- 帐号被禁止登陆
DISCONNECT_REASON_FORBID_NAME           = 7               -- 角色被禁止登陆
DISCONNECT_REASON_FORBID_IP             =  8            -- IP被禁止登陆
DISCONNECT_REASON_CROSS_ACCOUNT_ERR     = 50        -- 错误帐号（登录中间服）
DISCONNECT_REASON_SERVER_CLOSE          = 9              -- 服务器关闭
DISCONNECT_REASON_AUTH_FAIL             = 10              -- 验证失败
DISCONNECT_REASON_3RD_AUTH_FAIL         = 11          -- 第三方验证失败
-- 100 开始是c++层的错误码
DISCONNECT_REASON_CLIENT = 100                  -- client主动断开
DISCONNECT_REASON_TIMEOUT = 101                 -- 长时间没有发包断开
DISCONNECT_REASON_PACKET_ERR = 102              -- 发送非法包断开

PAY_SUCCESS = 1		--充值成功
PAY_NO_CHAR = 2		--角色不存在
PAY_FAIL	= 3		--充值失败
PAY_NO_ITEM = 4     --没有定义这个商品

-- money type
MONEY_NIL               = 0     -- 预留空
MONEY_COPPER_COIN       = 1     -- 铜币

--产出和消耗类型命名规则：X XXX XX 
--第一位为类型，1:获得，2:失去。中间2位为模块ID，后面两位为流水号
--模块定义：
-- gm 01
-- skill 02 
-- character 03
-- orochi 04
-- task 05
-- trial 06
-- chapter 07
-- treasure 08
-- hero 09
-- activity 10
-- item 11
-- shop 12
-- arena 13
-- guild 14
-- mail 15
-- mystery 16
-- partner 17
-- strength 18
-- gold 19
-- expedition 20
-- vip 21
-- achieve 22
-- flower 23
-- weapon 24
-- train 25
-- guide 26
-- admin 27
-- newopen 28
-- exchangeShop 29
-- equip 30 
-- peak 31
-- viplevel 32
ITEM_TYPE = 
{
    ADD = 10000, -- 获得类型开始
	--gm
	ADD_GM = 10101,	--gm指令获得
	--item
	ADD_USE_ITEM = 10201,	--使用道具
	--character 03
	ADD_GIFT_CODE = 10301,	--礼包获得
	--orochi 04
	ADD_OROCHI = 10401,		--挑战大蛇获得
	--task 05
	ADD_TASK = 10501,		--任务获得
	--trial 06
	ADD_TRIAL = 10601,		--挑战战役获得

    --chapter 07
    ADD_CHAPTER = 10701,     --关卡挑战获得
    ADD_CHAPTER_WIPE = 10702,--关卡扫荡获得
    ADD_CHAPTER_BOX  = 10703,--关卡宝箱获得

    --treasure 08
    ADD_TREASURE_MINE = 10801,  -- 挖矿获得
    ADD_TREASURE_OCCUPY = 10802, --占领获得
    ADD_TREASURE_ASSIST = 10803, --协助获得

    -- hero 09
    ADD_HERO_EXCHANGE = 10901,  -- 积分换碎片

    ADD_ACTIVITY = 11001, -- 活动获得
    ADD_ACTIVITY_SIGN_IN = 11002, -- 签到活动获得
    --virFunc 11
	ADD_VIRFUNC = 11101,	--使用虚拟道具获得

	--shop 12
	ADD_SHOP_BUY = 11201,	--商城获得
	ADD_COMMON_ONCE = 11202,	--普通抽一次
	ADD_COMMON_TEN = 11203,	--普通抽十次
	ADD_RARE_ONCE = 11204,	--稀有抽一次
	ADD_RARE_TEN = 11205,	--稀有抽十次

	--arena 13
	ADD_ARENA_SHOP = 11301,	--竞技场商店 
	--guild 14
	ADD_GUILD_KICK = 11401,	--公会踢馆获得
	ADD_GUILD_SHOP = 11402,	--公会商店获得
	ADD_GUILD_TEXAS = 11403,	--公会德州获得
	ADD_GUILD_WINE = 11404,	--公会调酒获得
	ADD_GUILD_WINE_DONATE = 11405,	--公会酒捐献获得
	--mail 15
	ADD_MAIL = 11501, --邮件获得
	--mystery 16
	ADD_MYSTERY_SHOP = 11601, --神秘商店获得
	--partner 17
	ADD_PARTNER_COMPOSE = 11701, --伙伴合成获得
	--strength 18
	ADD_STRENGTH_COMPOSE = 11801, --力量合成获得

	--expedition
	ADD_EXPEDITION_BUY	= 12001, --巡回赛商店
	ADD_EXPEDITION_REWARD = 12002, --巡回赛奖励

	--vip
	ADD_VIP_GIFT		= 12101, --vip礼包

	--achieve
	ADD_ACHIEVE_REWARD	= 12201, --成就奖励

	--flower
	ADD_FLOWER_REWARD	= 12301, --送花奖励

	--recharge
	ADD_RECHARGE_GET = 12301, --累计充值奖励

	--guide
	ADD_GUIDE_ITEM	= 12601, --引导奖励

	ADD_THERMAE = 12701,	--温泉

	--newopen
	ADD_NEW_OPEN_LOGIN = 12801, --开服7天登陆
	ADD_NEW_OPEN_RECHARGE = 12802, --开服7天充值
	ADD_NEW_OPEN_DISCOUNT = 12803, --开服7天半价

	--exchangeShop
	ADD_EXCHANGE_SHOP = 12901,	--兑换积分获得

	--peak
	ADD_PEAK_SHOP	= 13101, --巅峰兑换

	-- viplevel VIP副本
	ADD_VIPLEVEL_REWARD = 13201, -- vip副本奖励
	
	DEC = 20000, -- 失去类型开始
	--skill 
	DEC_SKILL_EXP	= 20201,	 --技能经验升级消耗
	DEC_SKILL_OPEN	= 20202,	 --技能激活消耗
	DEC_SKILL_UPGRADE	= 20202,	 --技能升级消耗
    --chapter
    DEC_CHAPTER     = 20701,     --关卡挑战消耗道具
    DEC_CHAPTER_WIPE = 20702,   --关卡扫荡消耗道具

    --hero
    DEC_HERO_LVUP = 20901,    -- 英雄升级
    DEC_HERO_STARUP = 20902,    -- 英雄升星
    DEC_HERO_COMPOSE = 20903,    -- 英雄合成
    DEC_HERO_BT = 20904,        -- 英雄突破

	--weapon
	DEC_WEAPON_QUALITY_UP = 22401, --神兵升品
	DEC_WEAPON_LV_UP	= 22402, --神兵升级
	DEC_WEAPON_ACTIVE 	= 22403, --神兵激活

	--item
	DEC_SELL_ITEM = 21101,  --出售物品
	DEC_USE_ITEM = 21102,  --物品使用
	--shop
	DEC_SHOP_SELL = 21201, --商店出售
	--guild
	DEC_GUILD_REFRESH = 21401, --公会刷新
	DEC_GUILD_WINE = 21402, --公会调酒
	--mystery 
	DEC_MYSTERY_REFRESH = 21601, --神秘商店
	--partner
	DEC_PARTNER_COMPOSE = 21701, --宿命合成
	DEC_PARTNER_EQUIP = 21702, --宿命装备
	DEC_PARTNER_ACTIVE = 21703, --宿命激活
	--strength
	DEC_STRENGTH_EQUIP = 21801, --宝石装备
	DEC_STRENGTH_COMPOSE = 21802, --宝石合成
	--train
	DEC_TRAIN = 22501, --培养
	--admin
	DEC_ADMIN = 22701, --后台删除
	--equip
	DEC_EQUIP_COLOR = 23002, --装备升品质

}

MAIL_TYPE = {
	SEND = 10000,	--
}

PHY_TYPE = 
{
    ADD = 10000, -- 获得类型开始
	--gm
	ADD_GM = 10101,	--gm指令获得
	--character 03
	ADD_HUMAN_UP = 10301, --战队升级
	ADD_OFFLINE = 10302,  --离线补偿
	ADD_TIMER = 10303,    --定时回复体力
	--orochi 04
	ADD_OROCHI = 10401,		--挑战大蛇获得
	--task 05
	ADD_TASK = 10501,		--任务获得
	--trial 06
	ADD_TRIAL = 10601,		--挑战战役获得

    --chapter 07
    ADD_CHAPTER = 10701,     --关卡挑战获得
    ADD_CHAPTER_WIPE = 10702,--关卡扫荡获得
    ADD_CHAPTER_BOX  = 10703,--关卡宝箱获得

    ADD_ACTIVITY = 11001, -- 活动获得
    ADD_ACTIVITY_SIGN_IN = 11002, -- 签到活动获得

	--item
    ADD_VIRFUNC = 11101, -- 使用虚拟道具获得
    ADD_USE_ITEM = 11102, -- 使用道具获得

	DEC = 20000, -- 失去类型开始
    DEC_CHAPTER = 20701,     --关卡挑战获得
    DEC_CHAPTER_WIPE = 20702,--关卡扫荡获得
    DEC_TREASURE_OCCUPY = 20801, -- 夺宝消耗
}
RMB_TYPE = 
{
    ADD = 10000, -- 获得类型开始
	--gm 01
	ADD_GM = 10101,	--gm指令获得
	--orochi 04
	ADD_OROCHI = 10401,		--挑战大蛇获得
	--task 05
	ADD_TASK = 10501,		--任务获得
	--trial 06
	ADD_TRIAL = 10601,		--挑战战役获得

    --chapter 07
    ADD_CHAPTER = 10701,     --关卡挑战获得
    ADD_CHAPTER_WIPE = 10702,--关卡扫荡获得
    ADD_CHAPTER_BOX  = 10703,--关卡宝箱获得

    ADD_ACTIVITY = 11001, -- 活动获得
    ADD_ACTIVITY_SIGN_IN = 11002, -- 签到活动获得
    ADD_ACTIVITY_MONTHCARD = 11003, -- 月卡活动

	--item 11
    ADD_VIRFUNC = 11101, -- 使用虚拟物品获得

	--guild
	ADD_GUILD_PAPER = 11401, --公会红包

	--vip
	ADD_VIP		= 12101, --vip

	ADD_THERMAE = 12201,	--温泉

	--admin
	ADD_ADMIN = 12701, 	--后台发钻石

	DEC = 20000, -- 失去类型开始
	--character 03
	DEC_RENAME = 20301, 	--改名消耗

    DEC_CHAPTER = 20701,     --关卡挑战获得
    DEC_CHAPTER_WIPE = 20702,--关卡扫荡获得
    DEC_CHAPTER_BUYTIME = 20703,--关卡购买次数

    DEC_TREASURE_SAFE = 20801,   --夺宝保护时间
    DEC_TREASURE_DOUBLE = 20802, --夺宝双倍收益
    DEC_TREASURE_EXTEND = 20803, --夺宝延长占领

    DEC_ACTIVITY_FOUNDATION = 21001, --开服基金
    DEC_ACTIVITY_VIPGIFT = 21002,  -- vip礼包
    DEC_ACTIVITY_WHEEL = 21003, -- 轮盘

	--arena 
	DEC_ARENA_RESETCD = 21301, --竞技场cd重置
	DEC_ARENA_SHOP_REFRESH = 21302, --竞技场商店刷新
	--gold
	DEC_GOLD_BUY = 21901,  --点金
	DEC_GOLD_BUY_TEN = 21902,  --点金十次
	--guild
	DEC_GUILD_CREATE = 21401, --创建公会
	DEC_GUILD_SHOP_REFRESH = 21402, --公会商店刷新
	DEC_GUILD_PAPER_SEND = 21403, --公会红包发送
	--mystery
	DEC_MYSTERY_BUY = 21601, --神秘商店购买
	DEC_MYSTERY_REFRESH = 21602, --神秘商店刷新
	--strength
	DEC_STR_COMPOSE = 21802, --宝石合成
	--shop
	DEC_SHOP_BUY = 21201, --商店
	DEC_RARE_ONCE = 21202, --稀有抽一次
	DEC_RARE_TEN = 21203, --商店抽十次

	--expedition
	DEC_EXPEDITION_BUY = 22001, --远征购买重置次数
	DEC_EXPEDITION_SHOP_REFRESH = 22002, --远征商店刷新  

	--flower
	DEC_FLOWER_SEND = 22301,--送花

	--vip
	DEC_VIP_GIFT	= 22101,--vip购买礼包

	--train
	DEC_TRAIN = 22501,--培养
	--newopen
	DEC_NEW_OPEN_DISCOUNT = 22801,--开服7天半价
	--exchange
	DEC_EXCHANGE_SHOP_REFRESH = 22901,--兑换商城刷新
	--peak
	DEC_PEAK_RESET_SEARCH = 23101,--重置搜索
	DEC_PEAK_SHOP_REFRESH = 23101,
}
--金币消费类型
MONEY_TYPE = 
{
    ADD = 10000, -- 获得类型开始
	--gm
	ADD_GM = 10101,	--gm指令获得
	--skill 02
	ADD_SKILL_RESET = 10201, --重置技能返还
	--orochi 04
	ADD_OROCHI = 10401,		--挑战大蛇获得
	--task 05
	ADD_TASK = 10501,		--任务获得
	--trial 06
	ADD_TRIAL = 10601,		--挑战战役获得

    --chapter 07
    ADD_CHAPTER = 10701,     --关卡挑战获得
    ADD_CHAPTER_WIPE = 10702,--关卡扫荡获得
    ADD_CHAPTER_BOX  = 10703,--关卡宝箱获得

    ADD_ACTIVITY = 11001, -- 活动获得
    ADD_ACTIVITY_SIGN_IN = 11002, -- 签到活动获得

	--item
    ADD_VIRFUNC = 11101,--虚拟物品使用获得
	ADD_USE_ITEM = 11102,	--使用道具
	ADD_SELL_ITEM = 11103,	--出售道具
	--gold
    ADD_GOLD_BUY = 11901,--点金一次
    ADD_GOLD_BUY_TEN = 11902,--点金十次

	--guide
	ADD_GUIDE_MONEY = 12601,
	ADD_THERMAE = 12701,	--温泉

	DEC = 20000, -- 失去类型开始
	--gm
	DEC_GM = 20101,		--GM指令失去
	--skill 
	DEC_SKILL_UPGRADE	= 20201,	 --技能升级消耗

    --chapter
    DEC_CHAPTER = 20701,     --关卡挑战获得
    DEC_CHAPTER_WIPE = 20702,--关卡扫荡获得

    --hero
    DEC_HERO_STARUP = 20901,    -- 英雄升星
    DEC_HERO_BT = 20902,        -- 英雄突破
	DEC_HERO_GIFT = 20903,		-- 英雄天赋

	--guild
    DEC_GUILD_WINE = 21401,    -- 公会调酒消耗
	--mystery
    DEC_MYSTERY = 21601,    -- 神秘商店消耗
	--shop
    DEC_SHOP_BUY = 21201,    -- 商店购买消耗
	--strength
	DEC_STR_COMPOSE = 21802, --宝石合成
	--flower
	DEC_FLOWER_SEND	= 22301, --送花
	--train
	DEC_TRAIN = 22501, --培养
	--equip
	DEC_EQUIP_LV = 23001, --装备升等级
	DEC_EQUIP_COLOR = 23002, --装备升品质
}


return CommonDefine


