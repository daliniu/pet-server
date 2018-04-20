module(...,package.seeall)

LogId={
	LOGIN=1,	--登录日志
	LOGOUT=2,	--登出日志
	ONLINE=3,	--每分钟在线日志
	NEWER=4,	--创建角色日志
	INC_RMB=5,	--钻石获得
	DEC_RMB=6,	--钻石消费
	INC_MONEY=7,	--金币获得
	DEC_MONEY=8,	--金币消费
	INC_PHY=9,	--体力获得
	DEC_PHY=10,	--体力消费
	ADD_ITEM=11,	--物品获得
	DEC_ITEM=12,	--物品失去
	FINISH_TASK=13,	--完成任务
	GET_TASK=14,	--领取任务奖励
	LV_UP=15,	--战队升级
	SKILL_LV_UP=16,	--强化普通技能
	SKILL_EXP_UP=17,	--强化必杀/援助技能
	TRIAL_START=18,	--进入战役
	TRIAL_END=19,	--结束战役
	OROCHI_START=20,	--进入大蛇
	OROCHI_END=21,	--大蛇结束
	OROCHI_RANK=22,	--大蛇上榜
	RE_NAME=23,	--更名
	HERO_STARUP=24,	--英雄升星
	HERO_COMPOSE=25,	--英雄合成
	HERO_LEVELUP=26,	--英雄升级
	HERO_=27,	--英雄进阶
	CHAPTER_START=28,	--进入关卡
	CHAPTER_END=29,	--退出关卡
	CHAPTER_WIPE=30,	--关卡扫荡
	CHAPTER_ITEM=31,	--关卡掉落
	SHOP_COST=32,	--商城消费
	SEND_MAIL=33,	--邮件
	RECV_MAIL=34,	--邮件
	GEM_EQUIP=35,	--宝石装备
	GEM_COMPOSE=36,	--宝石合成
	PARTNER_COMPOSE=37,	--宿命合成
	SHOP_BUY=38,	--商城购买
	SHOP_SELL=39,	--物品出售
	ARENA=40,	--竞技场
	ARENA_SHOP=41,	--竞技场商城
	ARENA_REFRESH=42,	--竞技场商城刷新
	MYSTERY_SHOP=43,	--神秘商店
	MYSTERY_SHOP_REFRESH=44,	--神秘商店刷新
	LOTTERY_COMMON=45,	--普通寻宝
	LOTTERY_RARE=46,	--稀有寻宝
	GUILD=47,	--公会状态
	GUILD_CREATE=48,	--公会创建
	GUILD_SHOP=49,	--公会商店
	GUILD_KICK=50,	--公会踢馆
	TEXAS_DROP=51,	--德州掉落
	TEXAS_RANK=52,	--公会德州排行
	WINE_COST=53,	--调酒消耗
	WINE_DROP=54,	--调酒掉落
	GUILD_FAME=55,	--公会声望
	GUILD_LVUP=56,	--公会升级
	TEXAS_DONATE=57,	--德州贡献
	WINE_DONATE=58,	--酒吧贡献
	VIP_LV=59,	--Vip等级
	ACHIEVE_OPEN=60,	--成就开启
	ACHIEVE_FINISH=61,	--成就达成
	ACHIEVE_GET=62,	--成就领取
	EXPEDITION=63,	--世界巡回赛
	EXPEDITION_DROP=64,	--世界巡回赛掉落
	EXPEDITION_SHOP=65,	--世界巡回赛商城
	EXPEDITION_REFRESH=66,	--世界巡回赛商城刷新
	BOSS_LAST_HIT=67,	--世界BOSS最后一击
	BOSS_HURT_RECORD=68,	--世界BOSS伤害流水
	WEAPON_ACTIVE=69,	--神兵激活
	WEAPON_QUALITY_UP=70,	--神兵升阶
	WEAPON_LV_UP=71,	--神兵充能
	FLOWER_SEND=72,	--鲜花赠送
	FLOWER_RECEIVE=73,	--鲜花收取
	GUIDE=74,	--引导
	PAY=75,	--充值
	GET_GIFT=76,	--礼包兑换
}


LogTpl={
	[1]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"ip","varchar",64,"用户登录ip",},
		{"kickOld","int",11,"是否是T掉在线(1=true,0=false)",},
		{"status","int",11,"用户状态",},
		{"level","tinyint",3,"用户等级",},
		{"isNew","char",1,"是否是新用户",},
		{"deviceId","varchar",100,"设备唯一ID",},
	},
	[2]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"level","tinyint",3,"等级",},
		{"reason","tinyint",3,"退出码",},
		{"loginTime","int",11,"登录时间",},
		{"dayTime","int",11,"当日在线时长(秒)",},
		{"aliveTime","int",11,"本次在线时长（秒）",},
		{"recharge","int",11,"历史充值数",},
		{"leftRmb","int",11,"剩余钻石(元宝)",},
		{"leftMoney","int",11,"剩余金钱",},
	},
	[3]={
		{"online","smallint",5,"在线人数",},
	},
	[4]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
	},
	[5]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"rmb","int",11,"获得数",},
		{"leftRmb","int",11,"剩余钻石",},
		{"way","int",11,"获得类型",},
	},
	[6]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"rmb","int",11,"钻石",},
		{"leftRmb","int",11,"剩余钻石",},
		{"way","int",11,"消费类型",},
		{"note","varchar",800,"备注（如道具列表）",},
	},
	[7]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"money","int",11,"金币",},
		{"leftMoney","int",11,"剩余金币",},
		{"way","int",11,"途径",},
	},
	[8]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"money","int",11,"金币",},
		{"leftMoney","int",11,"剩余金币",},
		{"way","int",11,"途径",},
		{"note","varchar",800,"备注（如道具列表）",},
	},
	[9]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"phy","int",11,"体力",},
		{"leftPhy","int",11,"剩余体力",},
		{"way","int",11,"获得类型",},
	},
	[10]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"phy","int",11,"体力",},
		{"leftPhy","int",11,"剩余体力",},
		{"way","int",11,"消费类型",},
	},
	[11]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"level","tinyint",3,"等级",},
		{"itemId","int",11,"物品ID",},
		{"cnt","int",11,"物品数量",},
		{"leftCnt","int",11,"剩余个数",},
		{"way","int",11,"获得途径",},
	},
	[12]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"level","tinyint",3,"等级",},
		{"itemId","int",11,"物品ID",},
		{"cnt","int",11,"物品数量",},
		{"leftCnt","int",11,"剩余个数",},
		{"way","int",11,"消耗途径",},
	},
	[13]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"level","tinyint",3,"玩家等级",},
		{"taskLevel","tinyint",3,"任务等级",},
		{"taskId","int",11,"任务id",},
	},
	[14]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"level","tinyint",3,"玩家等级",},
		{"taskLevel","tinyint",3,"任务等级",},
		{"taskId","int",11,"任务id",},
	},
	[15]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"lastLevel","tinyint",3,"升级前的等级",},
		{"level","tinyint",3,"最新等级",},
	},
	[16]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"heroName","varchar",64,"英雄名",},
		{"lastLevel","tinyint",3,"升级前的等级",},
		{"level","tinyint",3,"最新等级",},
		{"skillId","int",3,"技能ID",},
		{"rmb","int",64,"消耗钻石",},
		{"money","int",64,"消耗金币",},
		{"way","int",64,"升级方式（1普通,2一键)",},
	},
	[17]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"heroName","char",64,"英雄名",},
		{"lastLevel","tinyint",3,"使用前的等级",},
		{"level","tinyint",3,"最新等级",},
		{"isLvUp","tinyint",3,"是否升级了(1=true,0=false)",},
		{"itemCnt","tinyint",3,"消耗技能书数量",},
		{"skillId","int",3,"技能ID",},
		{"exp","int",64,"获得的经验",},
		{"postExp","int",64,"使用后经验",},
		{"rmb","int",64,"消耗钻石",},
		{"money","int",64,"消耗金币",},
		{"way","int",64,"升级方式（1普通,2一键)",},
	},
	[18]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"levelId","int",3,"关卡ID",},
		{"leftCnt","int",64,"剩余可进入次数",},
	},
	[19]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"res","int",64,"战斗结果（1=胜利，2=失败）",},
		{"levelId","int",3,"关卡ID",},
		{"leftCnt","int",64,"剩余可进入次数",},
		{"item","varchar",100,"掉落（文本）",},
	},
	[20]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"levelId","int",3,"关卡ID",},
		{"leftCnt","int",64,"剩余可进入次数",},
	},
	[21]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"res","int",64,"战斗结果（1=胜利，2=失败）",},
		{"levelId","int",3,"关卡ID",},
		{"costTime","int",64,"通关时间",},
		{"leftCnt","int",64,"剩余可进入次数",},
		{"item","varchar",100,"掉落（文本）",},
	},
	[22]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"levelId","int",3,"关卡ID",},
		{"costTime","int",64,"通关时间",},
	},
	[23]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"newName","varchar",64,"新名字",},
		{"rmb","int",11,"消耗的钻石",},
		{"money","int",11,"消耗的金币",},
	},
	[24]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"heroName","varchar",64,"英雄名",},
		{"rmb","int",11,"消耗的钻石",},
		{"money","int",11,"消耗的金币",},
		{"fragName","varchar",64,"消耗的英雄碎片名称",},
		{"fragNum","int",11,"消耗的英雄碎片数量",},
		{"prevStar","int",11,"升星前星级",},
		{"postStar","int",11,"升星后星级",},
	},
	[25]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"heroName","varchar",64,"英雄名",},
		{"rmb","int",11,"消耗的钻石",},
		{"money","int",11,"消耗的金币",},
		{"fragName","varchar",64,"消耗的英雄碎片名称",},
		{"fragNum","int",11,"消耗的英雄碎片数量",},
	},
	[26]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"heroName","varchar",64,"英雄名",},
		{"itemName","varchar",64,"消耗的物品名称",},
		{"itemNum","int",11,"消耗的物品数量",},
		{"rmb","int",11,"消耗的钻石",},
		{"money","int",11,"消耗的金币",},
		{"incExp","int",11,"增加的经验",},
		{"postExp","int",11,"使用后的经验",},
		{"isLvUp","tinyint",3,"是否升级了(1=true,0=false)",},
		{"prevLevel","int",11,"使用前等级",},
		{"postLevel","int",11,"使用后等级",},
	},
	[27]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"heroName","varchar",64,"英雄名",},
		{"rmb","int",11,"消耗的钻石",},
		{"money","int",11,"消耗的金币",},
		{"prev","int",11,"进阶前品阶",},
		{"post","int",11,"进阶后品阶",},
	},
	[28]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"levelName","varchar",64,"副本名称",},
		{"levelId","int",11,"副本id",},
		{"difficulty","tinyint",1,"难度（1:简单;2:噩梦;3:地狱）",},
	},
	[29]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"levelName","varchar",64,"副本名称",},
		{"levelId","int",11,"副本id",},
		{"difficulty","tinyint",1,"难度（1:简单;2:噩梦;3:地狱）",},
		{"result","tinyint",3,"战斗结果（0:失败;1:一星通过;2:二星通过;3:三星通过）",},
		{"physics","int",11,"扣除的体力",},
		{"costTime","int",11,"消耗的时间（秒）",},
	},
	[30]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"levelName","varchar",64,"副本名称",},
		{"levelId","int",11,"副本id",},
		{"difficulty","tinyint",3,"难度（1:简单;2:噩梦;3:地狱）",},
		{"cnt","int",11,"扫荡次数",},
		{"physics","int",11,"扣除的体力",},
	},
	[31]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"levelName","varchar",64,"副本名称",},
		{"levelId","int",11,"副本id",},
		{"difficulty","tinyint",3,"难度（1:简单;2:噩梦;3:地狱）",},
		{"source","tinyint",3,"来源（1:挑战;2:扫荡）",},
		{"itemName","varchar",64,"获得物品名称",},
		{"itemId","int",11,"获得物品id",},
		{"cnt","int",11,"获得物品数量",},
	},
	[32]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"shopName","varchar",64,"商店名称",},
		{"itemName","varchar",64,"物品名称",},
		{"buyCnt","int",11,"购买数量",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
	},
	[33]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"sendAccount","varchar",64,"发件人帐号",},
		{"sendCharName","varchar",64,"发件人角色名",},
		{"recvAccount","varchar",64,"接收人帐号",},
		{"recvCharName","varchar",64,"接收人名称",},
		{"content","varchar",2000,"邮件内容",},
		{"title","varchar",64,"邮件标题",},
		{"attachId","int",11,"邮件附件道具名称",},
		{"attachNum","int",11,"邮件附件道具数量",},
		{"source","varchar",64,"邮件来源",},
	},
	[34]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"recvAccount","varchar",64,"接收人帐号",},
		{"recvCharName","varchar",64,"接收人名称",},
		{"sendAccount","varchar",64,"发件人帐号",},
		{"sendCharName","varchar",64,"发件人角色名",},
		{"content","varchar",500,"邮件内容",},
		{"title","varchar",64,"邮件标题",},
		{"attach","int",11,"是否提取附件",},
	},
	[35]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"heroName","varchar",64,"英雄名字",},
		{"gemName","varchar",64,"宝石名字",},
		{"gemNum","int",11,"消耗宝石数量",},
		{"gemLeft","int",11,"剩余宝石数量",},
	},
	[36]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"leftCnt","int",11,"剩余宝石数量",},
		{"gemName","varchar",64,"合成宝石名称",},
	},
	[37]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"item1Name","varchar",64,"消耗物品1名称",},
		{"item1Num","int",11,"消耗物品1数量",},
		{"item2Name","varchar",64,"消耗物品2名称",},
		{"item2Num","int",11,"消耗物品2数量",},
		{"item3Name","varchar",64,"消耗物品3名称",},
		{"item3Num","int",11,"消耗物品3数量",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"partnerName","varchar",64,"合成宿命名称",},
	},
	[38]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"itemName","varchar",64,"物品名称",},
		{"itemNum","int",11,"物品数量",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
	},
	[39]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"itemName","varchar",64,"物品名称",},
		{"itemNum","int",11,"出售数量",},
		{"costName","varchar",64,"出售货币名称",},
		{"costNum","int",11,"出售货币数量",},
		{"leftNum","int",11,"剩余物品数量",},
	},
	[40]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"charName","varchar",64,"对手名称",},
		{"charAccount","varchar",64,"对手账号",},
		{"type","int",11,"挑战类型（发起挑战1/被挑战0）",},
		{"result","int",11,"挑战结果（胜利1/失败0）",},
		{"rank","int",11,"挑战后排名",},
	},
	[41]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"itemName","varchar",64,"物品名称",},
		{"itemNum","int",11,"数量",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"costLeft","varchar",64,"剩余货币数量",},
	},
	[42]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"cnt","int",11,"今日第几次刷新",},
	},
	[43]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"itemName","varchar",64,"物品名称",},
		{"itemNum","int",11,"物品数量",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"costLeft","int",11,"剩余货币数量",},
	},
	[44]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"cnt","int",11,"今日第几次刷新",},
	},
	[45]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"itemName","varchar",500,"获得道具",},
		{"itemNum","varchar",64,"数量",},
		{"source","int",11,"来源（抽1次1/抽10次0）",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
	},
	[46]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"itemName","varchar",500,"获得道具",},
		{"itemNum","int",11,"数量",},
		{"source","int",11,"来源（抽1次1/抽10次0）",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
	},
	[47]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"mType","int",11,"申请1/通过2/退出3/解散4公会",},
		{"guildName","varchar",64,"公会名称",},
		{"guildId","int",11,"公会id",},
	},
	[48]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"guildName","varchar",64,"公会名称",},
		{"guildId","int",11,"公会id",},
	},
	[49]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"itemName","varchar",64,"物品名称",},
		{"itemNum","int",11,"物品数量",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"costLeft","int",11,"剩余货币数量",},
	},
	[50]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"charName","varchar",64,"对手名称",},
		{"charAccount","varchar",64,"对手账号",},
		{"result","int",11,"挑战结果（胜利1/失败2）",},
		{"startType","int",11,"类型（开始1/结束0）",},
	},
	[51]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"cnt","int",11,"次数（第x次）",},
		{"itemName","varchar",64,"物品名称",},
		{"itemNum","varchar",64,"物品数量",},
		{"card1","int",11,"牌1",},
		{"card2","int",11,"牌2",},
		{"card3","int",11,"牌3",},
		{"card4","int",11,"牌4",},
		{"card5","int",11,"牌5",},
	},
	[52]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"rank","varchar",64,"对手名称",},
		{"card1","int",11,"牌1",},
		{"card2","int",11,"牌2",},
		{"card3","int",11,"牌3",},
		{"card4","int",11,"牌4",},
		{"card5","int",11,"牌5",},
	},
	[53]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"cnt","int",11,"次数",},
		{"mType","int",11,"选择类型",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"itemName","varchar",512,"物品名称",},
		{"itemNum","int",11,"物品数量",},
	},
	[54]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"cnt","int",11,"次数",},
		{"itemName","varchar",64,"物品名称",},
		{"itemNum","int",11,"物品数量",},
	},
	[55]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"source","int",11,"获取途径（调酒1、踢馆2）",},
		{"itemName","varchar",64,"捐赠道具",},
		{"itemNum","int",11,"捐赠道具数量",},
		{"fame","int",11,"获得声望",},
	},
	[56]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"guildName","varchar",64,"公会名称",},
		{"guildId","int",11,"公会id",},
		{"oldLv","int",11,"升级前等级",},
		{"newLv","int",11,"升级后等级",},
	},
	[57]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"guildName","varchar",64,"公会名称",},
		{"guildId","int",11,"公会id",},
		{"lv","int",11,"等级",},
		{"exp","int",11,"贡献博彩经验",},
	},
	[58]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"guildName","varchar",64,"公会名称",},
		{"guildId","int",11,"公会id",},
		{"lv","int",11,"等级",},
		{"exp","int",11,"贡献博彩经验",},
	},
	[59]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"recharge","int",64,"充值金额",},
		{"vipLvBefore","int",11,"充值前Vip等级",},
		{"vipLvAfter","int",11,"充值后Vip等级",},
	},
	[60]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"achieveName","varchar",64,"成就名称",},
		{"achieveId","int",11,"成就ID",},
		{"lv","int",11,"战队等级",},
	},
	[61]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"achieveName","varchar",64,"成就名称",},
		{"achieveId","int",11,"成就ID",},
		{"lv","int",11,"战队等级",},
	},
	[62]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"achieveName","varchar",64,"成就名称",},
		{"achieveId","int",11,"成就ID",},
		{"lv","int",11,"战队等级",},
	},
	[63]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"expeditionName","varchar",64,"副本名称",},
		{"expeditionId","int",11,"副本ID",},
		{"result","int",11,"战斗结果(0输/1赢)",},
	},
	[64]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"expeditionName","varchar",64,"副本名称",},
		{"expeditionId","int",11,"副本ID",},
		{"itemName","varchar",64,"物品名称",},
		{"itemCount","varchar",64,"物品数量",},
	},
	[65]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"itemName","varchar",64,"物品名称",},
		{"itemNum","int",11,"数量",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"costLeft","varchar",64,"剩余货币数量",},
	},
	[66]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"cnt","int",11,"今日第几次刷新",},
	},
	[67]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"hurt","int",11,"伤害",},
	},
	[68]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"hurt","int",11,"伤害",},
		{"hurtSum","int",11,"累积伤害",},
	},
	[69]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"weaponName","varchar",64,"神兵名称",},
		{"itemName","int",11,"消耗道具名称",},
		{"itemCount","int",11,"消耗道具数量",},
	},
	[70]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"weaponName","varchar",64,"神兵名称",},
		{"itemName","int",11,"消耗道具名称",},
		{"itemCount","int",11,"消耗道具数量",},
		{"qualityBefore","int",11,"升阶前等阶",},
		{"qualityAfter","int",11,"升阶后等阶",},
	},
	[71]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"weaponName","varchar",64,"神兵名称",},
		{"itemName","int",11,"消耗道具名称",},
		{"itemCount","int",11,"消耗道具数量",},
		{"lvBefore","int",11,"升阶前等级",},
		{"lvAfter","int",11,"升阶后等级",},
	},
	[72]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"receiverName","varchar",64,"被赠送人名称",},
		{"receiverAccount","varchar",64,"被赠送人账号",},
		{"costName","varchar",64,"消耗货币名称",},
		{"costNum","int",11,"消耗货币数量",},
		{"getName","varchar",64,"获得货币名称",},
		{"getNum","int",11,"获得货币数量",},
		{"leftCount","int",11,"剩余鲜花奖励次数",},
	},
	[73]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"senderName","varchar",64,"赠送人名称",},
		{"senderAccount","varchar",64,"赠送人账号",},
		{"flowerNum","int",11,"获得鲜花数",},
		{"getName","varchar",64,"获得货币名称",},
		{"getNum","int",11,"获得货币数量",},
	},
	[74]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"guideId","int",11,"引导序号",},
	},
	[75]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"orderId","varchar",20,"订单号",},
		{"rmb","int",11,"钻石",},
		{"recharge","int",11,"人民币(单位：分)",},
		{"rechargeType","int",11,"货币类型",},
		{"lv","int",11,"等级",},
		{"channel","varchar",20,"充值渠道",},
		{"goodId","int",11,"商品Id",},
		{"goodNum","int",11,"商品数量",},
		{"type","int",11,"充值类型1正常，2测试，3福利",},
		{"status","int",11,"充值结果1成功，2角色不存在，3失败",},
	},
	[76]={
		{"account","char",64,"用户账号",},
		{"name","char",64,"用户角色名",},
		{"pAccount","varchar",64,"平台账号",},
		{"giftCode","varchar",50,"礼包码",},
		{"rmb","int",11,"钻石",},
		{"recharge","int",11,"人民币(单位：分)",},
		{"rechargeType","int",11,"货币类型",},
		{"lv","int",11,"等级",},
		{"channel","varchar",20,"充值渠道",},
		{"goodId","int",11,"商品Id",},
		{"goodNum","int",11,"商品数量",},
		{"type","int",11,"充值类型1正常，2测试，3福利",},
		{"status","int",11,"充值结果1成功，2角色不存在，3失败",},
	},
}

