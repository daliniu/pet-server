module(...,package.seeall)

HeroData = {
	{"name",	"string",	"英雄"},
}

CardData = {
	{"name",	"string",	"玩家名字"},
	{"cards",	"int",	"牌组",		"repeated"},
}

CGGuildSearch = {
	{"searchId",	"int",		"搜索公会id"}
}

GuildData = {
	{"id",		"int",	"公会id"},
	{"name",	"string",	"公会名"},
	{"lv",		"int",	"公会等级"},
	{"num",		"int",	"公会人数"},
	{"icon",	"int",	"公会图标"},
	{"announce","string",	"公会宣言"},
	{"apply",	"int",	"申请状态"}
}

GCGuildSearch = {
	{"guildlist",	GuildData,	"公会搜索结果列表",		"repeated"}
}

CGGuildCreate = {
	{"name",	"string",	"公会名"}
}

GCGuildCreate = {
	{"result",	"int",	"公会创建结果"}
}

CGGuildQuery = {
}

GCGuildQuery = {
	{"guildlist",	GuildData,	"公会列表",		"repeated"}
}

CGGuildApply = {
	{"id",		"int",		"申请公会id"},
}

GCGuildApply = {
	{"id",		"int",		"申请公会id"},
	{"ret",		"int",		"申请公会返回码"}
}
CGGuildApplyCancel = {
	{"id",		"int",		"取消申请公会id"},
}

GCGuildApplyCancel = {
	{"id",		"int",		"取消申请公会id"},
	{"ret",		"int",		"取消申请公会返回码"}
}

Applyer = {
	{"id",			"int",		"成员id"},
	{"name",		"string",	"角色名"},
	{"lv",			"int",		"角色等级"},
	{"icon",		"int",		"角色图标"},
}

CGGuildApplyQuery = {
}

GCGuildApplyQuery = {
	{"ret",				"int",		"查询返回码"},
	{"applyers",		Applyer,	"申请列表",		"repeated"}
}

Member = {
	{"id",			"int",		"成员id"},
	{"name",		"string",	"成员名"},
	{"account",		"string",	"成员帐号"},
	{"lv",			"int",		"成员等级"},
	{"icon",		"int",		"成员图标"},
	{"pos",			"int",		"成员职位"},
	{"lastLogin",	"int",		"最后上线时间"},
}

CGGuildMemberQuery= {
}

GCGuildMemberQuery= {
	{"ret",			"int",		"查询返回码"},
	{"id",			"int",		"自己的成员id"},
	{"members",		Member,		"成员列表",		"repeated"}
}

CGGuildAccept= {
	{"id",		"int",		"申请成员id"},
	{"op",		"int",		"操作类型：1同意2拒绝"}
}

GCGuildAccept = {
	{"retCode",		"int",		"申请成员操作返回码"}
}

CGGuildMemOperate = {
	{"id",		"int",		"成员id"},
	{"op",		"int",		"操作类型：1任命长老2转交会长3踢出公会4卸任长老"}
}

GCGuildMemOperate = {
	{"retCode",		"int",		"成员操作返回码"}
}

CGGuildInfoQuery = {
}

GCGuildInfoQuery = {
	{"id",		"int",		"公会id"},
	{"name",	"string",		"公会名字"},
	{"lv",		"int",		"公会等级"},
	{"icon",		"int",		"公会图标"},
	{"announce","string",	"公会宣言"},
	{"num",		"int",		"成员数量"},
	{"active",	"int",		"活跃度"},
	{"pos",		"int",		"职务"},
}

CGGuildModAnnounce = {
	{"announce",	"string",	"公会宣言"}
}
GCGuildModAnnounce = {
	{"announce",	"string",	"公会宣言"},
	{"ret",		"int",		"返回码"}
}

CGGuildQuit = {
}

GCGuildQuit = {
	{"ret",		"int",		"退出公会返回码"}
}

CGGuildDestroy = {
}

GCGuildDestroy = {
	{"ret",		"int",		"解散公会返回码"}
}

GCTexasQuery = {
	{"lv",		"int",	"等级"},
	{"exp",		"int",	"经验"},
	{"cnt",		"int",	"今日次数"},
	{"weekTop",	CardData,	"本周最高牌组"},
	{"curCards",	"int",	"当前牌组",		"repeated"},
	{"isRefresh",	"int",	"是否刷新"}
}

CGTexasQuery = {
}

GCTexasStart = {
	{"ret",	"int",	"返回码"}
}

CGTexasStart = {
}

GCTexasRank = {
	{"rankData",	CardData,	"排行榜数据",	"repeated"}
}

CGTexasRank = {
}

KickGuildData = {
	{"id",		"int",	"公会id"},
	{"name",	"string",	"公会名"},
	{"rank",	"int",	"公会排名"},
	{"fightVal",	"int",	"战斗力"},
}

GCKickGuild = {
	{"guildData",	KickGuildData,	"公会",		"repeated"},
	{"cnt",		"int",	"今日次数"},
	{"fightList",	HeroData,	"出战阵容",		"repeated"},
}

CGKickGuild = {
}

RecordFightList = {
	{"name",	"string",	"英雄名"},
	{"pos",		"int",	"位置"},
	{"lv",	"int",	"英雄等级"},
	{"quality",	"int",	"品阶等级"},
	{"transferLv",	"int",	"力量等级"},
}

KickRecord = {
	{"myGuildName",	"string",	"公会名"},
	{"myGuildLv",	"int",	"公会等级"},
	{"charName",	"string",	"战队名"},
	{"charFightlist",	RecordFightList,	"战队",	"repeated"},
	{"enemyGuildName",	"string",	"对手公会名"},
	{"enemyGuildLv",	"int",	"对手公会等级"},
	{"enemyName",	"string",	"对手战队名"},
	{"enemyFightlist",	RecordFightList,	"对手战队",	"repeated"},
	{"result",	"int",	"结果"},
}

GCKickRecord= {
	{"record",	KickRecord,		"踢馆记录",	"repeated"}
}

CGKickRecord = {
}

Enemy = {
	{"name",	"string",	"英雄"},
	{"pos",	"int",	"位置"},
	{"lv",	"int",	"等级"},
	{"quality",	"int",	"品阶"},
}

KickMemberData = {
	{"guildId",	"int",	"公会id"},
	{"memberId",	"int",	"公会成员id"},
	{"name",	"string",	"名字"},
	{"icon",	"int",	"图标"},
	{"lv",	"int",	"等级"},
	{"fightVal",	"int",	"战斗力"},
	{"fightList",	Enemy,	"出战阵容",		"repeated"},
}

GCKickMember = {
	{"member",	KickMemberData,		"对手",	"repeated"}
}

CGKickMember = {
	{"id",	"int",	"公会id"}
}

--英雄动态属性
HeroDyAttr = 
{
	{"maxHp",			"int",				"血量上限"},
	{"hpR",				"int",				"血量回复值"},
	{"assist",			"int",				"援助回复值"},
	{"rageR",			"int",				"怒气回复值"},
	{"atkSpeed",		"int",				"攻速值"},
	{"atk",				"int",				"攻击值"},
	{"def",				"int",				"防御值"},
	{"crthit",			"int",				"暴击值"},
	{"antiCrthit",		"int",				"防爆值"},
	{"block",			"int",				"格挡值"},
	{"antiBlock",		"int",				"破挡值"},
	{"damage",			"int",				"真实伤害值"},
	{"rageRByHp",		"int",				"每损失1%血量获得的怒气值"},
	{"rageRByWin",		"int",				"战胜一个敌人获得的怒气值"},
	{"finalAtk","int","必杀攻击值"},
	{"finalDef","int","必杀防御值"},
	{"initRage","int","初始怒气值"},
}

GroupInfo = 
{
    {"groupId",     "int",      "技能组ID"},
    {"lv",     		"int",      "等级"},
    {"equipType",   "int",      "装备的位置"},
    {"isOpen",      "int",      "是否已开启"},
    --{"skillList",     "int",    "技能ID列表",	"repeated"},
}

EnemyHeroData ={
    {"name",      		"string",  			"名字"},
    {"exp",				"int",				"经验"},
    {"quality",			"int",				"品质"},
    {"lv",				"int",				"等级"},
    {"dyAttr",			HeroDyAttr,			"动态属性"},
    {"skillGroupList",		GroupInfo,			"技能列表",		"repeated"},
	{"gift",	"int", "天赋id", "repeated"}
}

EnemyData = {
	{"fightList",	EnemyHeroData,	"出战阵容",		"repeated"},
}

GCKickBegin= {
	{"retCode",	"int",	"返回码"},
	{"guildId",		"int",		"公会id"},
	{"memberId",	"int",		"成员id"},
	{"fightList",	HeroData,	"出战阵容",		"repeated"},
	{"enemy",	EnemyData,	"对手"}
}

CGKickBegin= {
	{"guildId",	"int",	"公会id"},
	{"memberId",	"int",	"成员id"},
	{"fightList",	HeroData,	"出战阵容",		"repeated"},
}

GCKickEnd= {
	{"result",		"int",		"结果"},
}

CGKickEnd= {
	{"result",		"int",		"结果"},
	{"guildId",		"int",		"公会id"},
	{"memberId",	"int",		"成员id"},
}

GuildShopData = {
	{"id",		"int",		"商品id"},
	{"itemId",		"int",	"物品id"},
	{"cnt",		"int",		"物品数量"},
	{"buy",		"int",		"是否已经购买"},
	{"price",	"int",		"消耗"},
}

GCGuildShopQuery = {
	{"shopData",	GuildShopData,	"商店物品",		"repeated"},
	{"refreshTimes",		"int",			"已经刷新次数"}
}

CGGuildShopQuery = {

}

GCGuildShopRefresh = {
	{"ret",		"int",		"刷新返回码"}
}

CGGuildShopRefresh = {
}

GCGuildShopBuy = {
	{"id",		"int",		"商品id"},
	{"ret",		"int",		"购买返回码"}
}

CGGuildShopBuy = {
	{"id",		"int",		"商品id"}
}

CGWineQuery = {
}

GCWineQuery = {
	{"lv",	"int",	"等级"},
	{"exp",	"int",	"经验"},
	{"cnt",	"int",	"今日次数"},
}

CGWineStart = {
	{"id",	"int",	"索引"},
}

Reward = {
	{"titleId",	"int",	"标题id"},
	{"id",	"int",	"道具id"},
	{"num",	"int",	"道具数量"},
}

GCWineStart = {
	{"ret",	"int",	"返回码"},
	{"rewards", 	Reward,		"奖励提示",		"repeated"}
}

CGWineDonate= {
	{"itemId",	"int",	"物品id"},
	{"num",	"int",	"数量"},
}

GCWineDonate= {
	{"ret",	"int",	"返回码"},
}

WineBuff = {
	{"id",	"int",	"物品id"},
	{"time",	"int",	"持续时间"},
}

CGWineBuffQuery = {
}

GCWineBuffQuery = {
	{"wineBuff",	WineBuff,	"酒吧buff",	"repeated"},
}

CGPaperQuery={
}
Paper = {
	{"id",	"int",	"红包id"},
	{"account",	"string",	"发红包玩家帐号"},
	{"name",	"string",	"发红包玩家名字"},
	{"sum",	"int",	"发红包总数"},
	{"get",	"int",	"抢到红包数"},
}

GCPaperQuery={
	{"paper",	Paper,	"红包数组",	"repeated"},
}
CGSendPaper={
	{"sum",	"int",	"总数"},
}
GCSendPaper={
	{"ret",	"int",	"返回码"},
}
CGGetPaper={
	{"id",	"int",	"红包id"},
}
GCGetPaper={
	{"id",	"int",	"红包id"},
	{"ret",	"int",	"返回码"},
	{"num",	"int",	"抢到数量"},
}

GCNewPaper={
}
CGGuildSceneEnter={
}

CGGuildBossQuery = {
}
GCGuildBossQuery = {
	{"hasStart",				"int",				"是否已经开始"},
	{"coolTime",				"int",				"冷却时间"},
	{"hurt",					"int",				"伤害"},
	{"heroList",			"string",			"英雄列表",			"repeated"},
}

CGGuildBossEnter = {
	{"heroList",			"string",			"英雄列表",			"repeated"},
}
GCGuildBossEnter = {
	{"retCode",					"int",				"返回码"},
	{"bossId",					"int",				"bossId"},
	{"hp",					"int",				"boss血量"},
}

CGGuildBossEnterQuery = {
}
GCGuildBossEnterQuery = {
	{"retCode",					"int",				"返回码"},
}

CGGuildBossHurt = {
	{"hurt",					"int",				"伤害"},
}
GCGuildBossHurt = {
	{"hp",					"int",				"血量"},
}
GCGuildBossStart = {
}
GCGuildBossEnd = {
}

CGGuildBossLeave = {
}
--排行榜
RankData = {
	{"rank",					"int",				"排名"},
	{"name",					"string",			"战队名"},
	{"icon",					"int",				"战队头像"},
	{"lv",						"int",				"战队等级"},
	{"hurt",					"int",				"伤害"},
	{"guild",					"string",			"公会名"},
}

CGGuildBossRank = {
}

GCGuildBossRank = {
	{"rankList",				RankData,			"排行列表",			"repeated"},
}

CGGuildBossCheckTeam = {
	{"rank",					"int",				"排名"},
}

--查看阵容
TeamHeroData = {
	{"name",					"string",			"英雄名"},
	{"lv",						"int",				"等级"},
	{"quality",					"int",				"品阶"},
}

GCGuildBossCheckTeam = {
	{"rank",					"int",				"排名"},
	{"fighting",				"int",				"战斗力"},
	{"flowerCount",				"int",				"鲜花数"},
	{"heroList",				TeamHeroData,			"英雄列表",			"repeated"},
}
